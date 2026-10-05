# Development Reference

**Last Updated**: 2024-12-30

## Script Structure

### Backup-CarboniteFiles.ps1

Main PowerShell script (~400 lines).

```
┌─────────────────────────────────────────────────┐
│ Parameters & Configuration (lines 1-26)         │
├─────────────────────────────────────────────────┤
│ Load-Configuration (lines 28-43)                │
├─────────────────────────────────────────────────┤
│ Initialize-Logging (lines 46-55)                │
├─────────────────────────────────────────────────┤
│ Write-Log (lines 58-78)                         │
├─────────────────────────────────────────────────┤
│ Send-EmailNotification (lines 81-114)           │
├─────────────────────────────────────────────────┤
│ Invoke-FTPBackup (lines 117-207)                │
├─────────────────────────────────────────────────┤
│ Invoke-RetentionPolicy (lines 210-274)          │
├─────────────────────────────────────────────────┤
│ Invoke-BackupPromotion (lines 277-326)          │
├─────────────────────────────────────────────────┤
│ Main (lines 329-397)                            │
└─────────────────────────────────────────────────┘
```

## Key Functions

### Load-Configuration()

**Location**: `Backup-CarboniteFiles.ps1:28`

Reads and parses `config.json`.

```powershell
$config = Get-Content $ConfigFilePath -Raw | ConvertFrom-Json
```

**Returns**: PSCustomObject with configuration settings

---

### Initialize-Logging($LogPath)

**Location**: `Backup-CarboniteFiles.ps1:46`

Creates log directory if needed, returns log file path.

---

### Write-Log($Message, $Level, $LogFile)

**Location**: `Backup-CarboniteFiles.ps1:58`

Writes timestamped messages to console (with color) and log file.

**Levels**: INFO, WARNING, ERROR, SUCCESS

---

### Send-EmailNotification($Subject, $Body, $EmailConfig)

**Location**: `Backup-CarboniteFiles.ps1:81`

Sends SMTP email if notifications enabled.

---

### Invoke-FTPBackup($Config, $LogFile)

**Location**: `Backup-CarboniteFiles.ps1:117`

Main backup logic using WinSCP .NET assembly.

**Key operations**:
1. Create timestamped backup directory
2. Load WinSCPnet.dll assembly
3. Create FTP session with credentials
4. Call `SynchronizeDirectories()` in Local mode
5. Return result object with file counts

**Returns**:
```powershell
@{
    Success = $true
    FilesDownloaded = 5
    BackupPath = "C:\Backup\Carbonite\hourly\20241230_090000"
}
```

---

### Invoke-RetentionPolicy($Config, $LogFile)

**Location**: `Backup-CarboniteFiles.ps1:210`

Removes old backups based on retention settings.

**Logic per tier**:
```powershell
$cutoffDate = (Get-Date).AddHours(-$retentionConfig.HourlyKeepHours)
$oldBackups = Get-ChildItem $path -Directory |
    Where-Object { $_.CreationTime -lt $cutoffDate }
```

---

### Invoke-BackupPromotion($Config, $LogFile, $LatestBackupPath)

**Location**: `Backup-CarboniteFiles.ps1:277`

Copies hourly backups to daily/weekly/monthly tiers.

**Promotion rules**:
- Daily: First backup of the day
- Weekly: Sunday backups
- Monthly: First day of month

---

### Main()

**Location**: `Backup-CarboniteFiles.ps1:329`

Entry point orchestrating all operations.

## Modifying the Script

### Adding File Filtering

Modify the `SynchronizeDirectories` call in `Invoke-FTPBackup`:

```powershell
# Before synchronization, set transfer options
$transferOptions = New-Object WinSCP.TransferOptions
$transferOptions.FileMask = "*.cfg|*.show"  # Only these extensions

$synchronizationResult = $session.SynchronizeDirectories(
    [WinSCP.SynchronizationMode]::Local,
    $backupDir,
    $Config.FTP.RemotePath,
    $false,
    $false,
    [WinSCP.SynchronizationCriteria]::Time,
    $transferOptions  # Add this parameter
)
```

### Adding Pre/Post Backup Hooks

Add function calls in `Main()`:

```powershell
function Main {
    # ... existing setup ...

    try {
        # Pre-backup hook
        Invoke-PreBackupHook -Config $config -LogFile $logFile

        # Perform backup
        $result = Invoke-FTPBackup -Config $config -LogFile $logFile

        # Post-backup hook
        Invoke-PostBackupHook -Config $config -LogFile $logFile -Result $result

        # ... rest of Main ...
    }
}

function Invoke-PreBackupHook {
    param($Config, $LogFile)
    Write-Log "Running pre-backup hook..." -LogFile $LogFile
    # Custom logic here
}

function Invoke-PostBackupHook {
    param($Config, $LogFile, $Result)
    Write-Log "Running post-backup hook..." -LogFile $LogFile
    # Custom logic here
}
```

### Adding Custom Notifications

Add functions similar to `Send-EmailNotification`:

```powershell
function Send-SlackNotification {
    param(
        [string]$Message,
        [string]$WebhookUrl
    )

    $body = @{
        text = $Message
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType "application/json"
}
```

## Testing

### Verbose Output

```powershell
$VerbosePreference = "Continue"
.\Backup-CarboniteFiles.ps1
```

### Custom Config

```powershell
.\Backup-CarboniteFiles.ps1 -ConfigFile ".\test-config.json"
```

### Dry Run (Manual)

Comment out destructive operations in `Invoke-RetentionPolicy` to test logic without deletion.

## WinSCP .NET Reference

### Session Methods

| Method | Purpose |
|--------|---------|
| `Open()` | Connect to server |
| `SynchronizeDirectories()` | Sync local/remote directories |
| `GetFiles()` | Download files |
| `PutFiles()` | Upload files |
| `Dispose()` | Close session |

### SynchronizationMode

| Mode | Direction |
|------|-----------|
| `Local` | Remote → Local (download) |
| `Remote` | Local → Remote (upload) |
| `Both` | Bidirectional |

### SynchronizationCriteria

| Criteria | Comparison |
|----------|------------|
| `Time` | File modification time |
| `Size` | File size |
| `Either` | Time or size |
| `None` | Always sync |

### Documentation

- WinSCP .NET: https://winscp.net/eng/docs/library
- SynchronizeDirectories: https://winscp.net/eng/docs/library_session_synchronizedirectories
