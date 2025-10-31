<#
.SYNOPSIS
    Automated FTP backup script for ROSS Carbonite BLACK video switcher

.DESCRIPTION
    This script connects to a ROSS Carbonite BLACK switcher via FTP and backs up
    show files and switcher configurations to a local directory with versioning
    and retention policies.

.PARAMETER ConfigFile
    Path to the configuration JSON file (default: config.json)

.EXAMPLE
    .\Backup-CarboniteFiles.ps1
    .\Backup-CarboniteFiles.ps1 -ConfigFile ".\custom-config.json"
#>

param(
    [string]$ConfigFile = ".\config.json"
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFilePath = Join-Path $ScriptPath $ConfigFile

# Load configuration
function Load-Configuration {
    if (-not (Test-Path $ConfigFilePath)) {
        Write-Error "Configuration file not found: $ConfigFilePath"
        Write-Host "Please copy config.json.template to config.json and configure it."
        exit 1
    }

    try {
        $config = Get-Content $ConfigFilePath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-Error "Failed to load configuration: $_"
        exit 1
    }
}

# Setup logging
function Initialize-Logging {
    param([string]$LogPath)

    $logDir = Split-Path -Parent $LogPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    return $LogPath
}

# Write log message
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogFile
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to console
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }

    # Write to file
    Add-Content -Path $LogFile -Value $logMessage
}

# Send email notification
function Send-EmailNotification {
    param(
        [string]$Subject,
        [string]$Body,
        [object]$EmailConfig
    )

    if (-not $EmailConfig.Enabled) {
        return
    }

    try {
        $smtpParams = @{
            SmtpServer = $EmailConfig.SmtpServer
            Port = $EmailConfig.SmtpPort
            From = $EmailConfig.From
            To = $EmailConfig.To
            Subject = $Subject
            Body = $Body
            UseSsl = $EmailConfig.UseSsl
        }

        if ($EmailConfig.Username -and $EmailConfig.Password) {
            $securePassword = ConvertTo-SecureString $EmailConfig.Password -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential($EmailConfig.Username, $securePassword)
            $smtpParams.Credential = $credential
        }

        Send-MailMessage @smtpParams
    }
    catch {
        Write-Warning "Failed to send email notification: $_"
    }
}

# Perform FTP backup using WinSCP
function Invoke-FTPBackup {
    param(
        [object]$Config,
        [string]$LogFile
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $Config.Backup.LocalPath "hourly\$timestamp"

    # Create backup directory
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Write-Log "Created backup directory: $backupDir" -LogFile $LogFile
    }

    # Check if WinSCP is installed
    if (-not (Test-Path $Config.WinSCP.ExecutablePath)) {
        Write-Log "WinSCP executable not found at: $($Config.WinSCP.ExecutablePath)" -Level "ERROR" -LogFile $LogFile
        Write-Log "Please install WinSCP or update the path in config.json" -Level "ERROR" -LogFile $LogFile
        throw "WinSCP not found"
    }

    # Create WinSCP session options
    try {
        # Load WinSCP .NET assembly
        Add-Type -Path (Join-Path (Split-Path $Config.WinSCP.ExecutablePath) "WinSCPnet.dll")

        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol = [WinSCP.Protocol]::Ftp
            HostName = $Config.FTP.Host
            PortNumber = $Config.FTP.Port
            UserName = $Config.FTP.Username
            Password = $Config.FTP.Password
        }

        $session = New-Object WinSCP.Session

        try {
            # Enable session logging
            $session.SessionLogPath = Join-Path (Split-Path $LogFile) "winscp_$timestamp.log"

            # Connect
            Write-Log "Connecting to FTP server: $($Config.FTP.Host)" -LogFile $LogFile
            $session.Open($sessionOptions)
            Write-Log "Connected successfully" -Level "SUCCESS" -LogFile $LogFile

            # Synchronize files
            Write-Log "Starting file synchronization from $($Config.FTP.RemotePath) to $backupDir" -LogFile $LogFile

            $synchronizationResult = $session.SynchronizeDirectories(
                [WinSCP.SynchronizationMode]::Local,
                $backupDir,
                $Config.FTP.RemotePath,
                $false,  # Remove files (use $true to mirror exactly)
                $false,  # Mirror mode
                [WinSCP.SynchronizationCriteria]::Time
            )

            # Check for errors
            $synchronizationResult.Check()

            # Log results
            Write-Log "Files downloaded: $($synchronizationResult.Downloads.Count)" -LogFile $LogFile
            Write-Log "Files removed: $($synchronizationResult.Removals.Count)" -LogFile $LogFile

            foreach ($download in $synchronizationResult.Downloads) {
                Write-Log "  Downloaded: $($download.FileName)" -LogFile $LogFile
            }

            if ($synchronizationResult.Downloads.Count -eq 0 -and $synchronizationResult.IsSuccess) {
                Write-Log "No new or modified files found (backup is up to date)" -LogFile $LogFile
            }

            Write-Log "Backup completed successfully" -Level "SUCCESS" -LogFile $LogFile

            return @{
                Success = $true
                FilesDownloaded = $synchronizationResult.Downloads.Count
                BackupPath = $backupDir
            }
        }
        finally {
            # Disconnect
            $session.Dispose()
        }
    }
    catch {
        Write-Log "Backup failed: $($_.Exception.Message)" -Level "ERROR" -LogFile $LogFile
        throw
    }
}

# Apply retention policy
function Invoke-RetentionPolicy {
    param(
        [object]$Config,
        [string]$LogFile
    )

    Write-Log "Applying retention policy..." -LogFile $LogFile

    $retentionConfig = $Config.Backup.Retention
    $basePath = $Config.Backup.LocalPath

    # Hourly backups - keep last N hours
    $hourlyPath = Join-Path $basePath "hourly"
    if (Test-Path $hourlyPath) {
        $cutoffDate = (Get-Date).AddHours(-$retentionConfig.HourlyKeepHours)
        $oldBackups = Get-ChildItem $hourlyPath -Directory | Where-Object { $_.CreationTime -lt $cutoffDate }

        foreach ($backup in $oldBackups) {
            Write-Log "Removing old hourly backup: $($backup.Name)" -LogFile $LogFile
            Remove-Item $backup.FullName -Recurse -Force
        }

        if ($oldBackups.Count -eq 0) {
            Write-Log "No hourly backups to remove" -LogFile $LogFile
        }
    }

    # Daily backups - keep last N days
    $dailyPath = Join-Path $basePath "daily"
    if (Test-Path $dailyPath) {
        $cutoffDate = (Get-Date).AddDays(-$retentionConfig.DailyKeepDays)
        $oldBackups = Get-ChildItem $dailyPath -Directory | Where-Object { $_.CreationTime -lt $cutoffDate }

        foreach ($backup in $oldBackups) {
            Write-Log "Removing old daily backup: $($backup.Name)" -LogFile $LogFile
            Remove-Item $backup.FullName -Recurse -Force
        }
    }

    # Weekly backups - keep last N weeks
    $weeklyPath = Join-Path $basePath "weekly"
    if (Test-Path $weeklyPath) {
        $cutoffDate = (Get-Date).AddDays(-($retentionConfig.WeeklyKeepWeeks * 7))
        $oldBackups = Get-ChildItem $weeklyPath -Directory | Where-Object { $_.CreationTime -lt $cutoffDate }

        foreach ($backup in $oldBackups) {
            Write-Log "Removing old weekly backup: $($backup.Name)" -LogFile $LogFile
            Remove-Item $backup.FullName -Recurse -Force
        }
    }

    # Monthly backups - keep last N months
    $monthlyPath = Join-Path $basePath "monthly"
    if (Test-Path $monthlyPath) {
        $cutoffDate = (Get-Date).AddMonths(-$retentionConfig.MonthlyKeepMonths)
        $oldBackups = Get-ChildItem $monthlyPath -Directory | Where-Object { $_.CreationTime -lt $cutoffDate }

        foreach ($backup in $oldBackups) {
            Write-Log "Removing old monthly backup: $($backup.Name)" -LogFile $LogFile
            Remove-Item $backup.FullName -Recurse -Force
        }
    }

    Write-Log "Retention policy applied" -LogFile $LogFile
}

# Promote hourly backups to daily/weekly/monthly
function Invoke-BackupPromotion {
    param(
        [object]$Config,
        [string]$LogFile,
        [string]$LatestBackupPath
    )

    $basePath = $Config.Backup.LocalPath
    $now = Get-Date

    # Promote to daily (if it's the first backup of the day)
    $dailyPath = Join-Path $basePath "daily"
    $todayDaily = Join-Path $dailyPath ($now.ToString("yyyyMMdd"))

    if (-not (Test-Path $todayDaily)) {
        Write-Log "Promoting to daily backup" -LogFile $LogFile
        if (-not (Test-Path $dailyPath)) {
            New-Item -ItemType Directory -Path $dailyPath -Force | Out-Null
        }
        Copy-Item $LatestBackupPath $todayDaily -Recurse -Force
    }

    # Promote to weekly (if it's Sunday and first backup of the week)
    if ($now.DayOfWeek -eq 'Sunday') {
        $weeklyPath = Join-Path $basePath "weekly"
        $thisWeekly = Join-Path $weeklyPath ($now.ToString("yyyyMMdd"))

        if (-not (Test-Path $thisWeekly)) {
            Write-Log "Promoting to weekly backup" -LogFile $LogFile
            if (-not (Test-Path $weeklyPath)) {
                New-Item -ItemType Directory -Path $weeklyPath -Force | Out-Null
            }
            Copy-Item $LatestBackupPath $thisWeekly -Recurse -Force
        }
    }

    # Promote to monthly (if it's the first day of the month)
    if ($now.Day -eq 1) {
        $monthlyPath = Join-Path $basePath "monthly"
        $thisMonthly = Join-Path $monthlyPath ($now.ToString("yyyyMM"))

        if (-not (Test-Path $thisMonthly)) {
            Write-Log "Promoting to monthly backup" -LogFile $LogFile
            if (-not (Test-Path $monthlyPath)) {
                New-Item -ItemType Directory -Path $monthlyPath -Force | Out-Null
            }
            Copy-Item $LatestBackupPath $thisMonthly -Recurse -Force
        }
    }
}

# Main execution
function Main {
    $startTime = Get-Date

    # Load configuration
    $config = Load-Configuration

    # Initialize logging
    $logFile = Initialize-Logging -LogPath $config.Logging.LogFile

    Write-Log "========================================" -LogFile $logFile
    Write-Log "ROSS Carbonite Backup Started" -LogFile $logFile
    Write-Log "========================================" -LogFile $logFile

    try {
        # Perform backup
        $result = Invoke-FTPBackup -Config $config -LogFile $logFile

        # Promote backup to daily/weekly/monthly if applicable
        Invoke-BackupPromotion -Config $config -LogFile $logFile -LatestBackupPath $result.BackupPath

        # Apply retention policy
        Invoke-RetentionPolicy -Config $config -LogFile $logFile

        # Calculate duration
        $duration = (Get-Date) - $startTime
        Write-Log "Backup completed in $($duration.TotalSeconds) seconds" -LogFile $logFile

        # Send success notification if enabled
        if ($config.Email.NotifyOnSuccess) {
            $subject = "Carbonite Backup Successful"
            $body = @"
Carbonite FTP backup completed successfully.

Files Downloaded: $($result.FilesDownloaded)
Backup Location: $($result.BackupPath)
Duration: $($duration.TotalSeconds) seconds
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
            Send-EmailNotification -Subject $subject -Body $body -EmailConfig $config.Email
        }

        Write-Log "========================================" -LogFile $logFile
        exit 0
    }
    catch {
        Write-Log "Backup failed with error: $($_.Exception.Message)" -Level "ERROR" -LogFile $logFile
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR" -LogFile $logFile

        # Send failure notification
        if ($config.Email.Enabled) {
            $subject = "URGENT: Carbonite Backup Failed"
            $body = @"
Carbonite FTP backup has FAILED.

Error: $($_.Exception.Message)
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Please investigate immediately.
"@
            Send-EmailNotification -Subject $subject -Body $body -EmailConfig $config.Email
        }

        Write-Log "========================================" -LogFile $logFile
        exit 1
    }
}

# Execute main function
Main
