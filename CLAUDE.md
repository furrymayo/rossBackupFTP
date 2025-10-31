# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Automated backup solution for ROSS Carbonite BLACK 3 M/E video switcher. This PowerShell-based tool connects to the switcher via FTP and creates scheduled, versioned backups of show files and switcher configurations using WinSCP .NET assembly.

**Key Technology:** PowerShell with WinSCP .NET library, Windows Task Scheduler for automation.

## Common Commands

### Running Backups

```powershell
# Run backup with default config.json
.\run-backup.bat

# Run PowerShell script directly
.\Backup-CarboniteFiles.ps1

# Run with custom configuration
.\Backup-CarboniteFiles.ps1 -ConfigFile ".\custom-config.json"
```

### Testing and Troubleshooting

```powershell
# View recent log entries
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Tail 50

# Monitor log in real-time
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Wait -Tail 20

# Search for errors in logs
Select-String -Path "C:\Backup\Carbonite\Logs\backup.log" -Pattern "ERROR"

# Check WinSCP session logs
Get-ChildItem "C:\Backup\Carbonite\Logs\winscp_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

### Configuration Setup

```powershell
# Copy template to create config
copy config.json.template config.json

# Edit config file (use your preferred editor)
notepad config.json
```

## Architecture

### Main Components

1. **Backup-CarboniteFiles.ps1** - Primary PowerShell script
   - Entry point: `Main` function at the bottom
   - Loads configuration from `config.json`
   - Uses WinSCP .NET assembly for FTP operations
   - Implements GFS (Grandfather-Father-Son) retention policy
   - Manages hourly/daily/weekly/monthly backup promotion

2. **run-backup.bat** - Simple batch launcher
   - Wrapper for PowerShell script execution
   - Sets execution policy bypass
   - Returns proper exit codes for Task Scheduler

3. **config.json** - Runtime configuration (not in git)
   - FTP connection details
   - Backup paths and retention settings
   - Email notification configuration
   - WinSCP executable path

4. **config.json.template** - Configuration template
   - Template with defaults and comments
   - Copy to `config.json` and customize

### Execution Flow

1. **Load Configuration**: `Load-Configuration` reads and parses `config.json`
2. **Initialize Logging**: `Initialize-Logging` creates log directory and file
3. **Perform Backup**: `Invoke-FTPBackup` connects via WinSCP and synchronizes files
   - Loads WinSCP .NET assembly (`WinSCPnet.dll`)
   - Creates FTP session with configured credentials
   - Uses `SynchronizeDirectories` in Local mode with Time criteria
   - Downloads new/modified files to timestamped directory
4. **Promote Backups**: `Invoke-BackupPromotion` creates daily/weekly/monthly copies
   - Hourly backups are promoted based on date/time rules
   - Daily: First backup of the day
   - Weekly: Sunday backups
   - Monthly: First day of month backups
5. **Apply Retention**: `Invoke-RetentionPolicy` removes old backups
   - Removes hourly backups older than configured hours
   - Removes daily/weekly/monthly backups based on retention settings
6. **Send Notifications**: `Send-EmailNotification` sends alerts (if enabled)

### Backup Directory Structure

```
C:\Backup\Carbonite\
├── hourly\          # All backups initially saved here
│   └── YYYYMMdd_HHmmss\
├── daily\           # Promoted daily backups
│   └── YYYYMMdd\
├── weekly\          # Promoted Sunday backups
│   └── YYYYMMdd\
├── monthly\         # Promoted monthly backups (1st of month)
│   └── YYYYMM\
└── Logs\            # All log files
    ├── backup.log
    └── winscp_*.log
```

### Key Functions

- `Load-Configuration()` - Loads and validates config.json
- `Initialize-Logging($LogPath)` - Sets up logging infrastructure
- `Write-Log($Message, $Level, $LogFile)` - Writes to console and log file
- `Invoke-FTPBackup($Config, $LogFile)` - Main backup logic using WinSCP
- `Invoke-RetentionPolicy($Config, $LogFile)` - Cleanup old backups
- `Invoke-BackupPromotion($Config, $LogFile, $LatestBackupPath)` - Promote to daily/weekly/monthly
- `Send-EmailNotification($Subject, $Body, $EmailConfig)` - Send email alerts
- `Main()` - Entry point orchestrating all operations

## Configuration

### config.json Structure

```json
{
  "FTP": {
    "Host": "192.168.1.100",      // Carbonite IP address
    "Port": 21,                    // FTP port
    "Username": "user",            // ROSS default: "user"
    "Password": "password",        // ROSS default: "password"
    "RemotePath": "/usb"           // USB path on switcher
  },
  "WinSCP": {
    "ExecutablePath": "C:\\Program Files (x86)\\WinSCP\\WinSCP.com"
  },
  "Backup": {
    "LocalPath": "C:\\Backup\\Carbonite",
    "Retention": {
      "HourlyKeepHours": 24,
      "DailyKeepDays": 7,
      "WeeklyKeepWeeks": 8,
      "MonthlyKeepMonths": 12
    }
  },
  "Logging": {
    "LogFile": "C:\\Backup\\Carbonite\\Logs\\backup.log"
  },
  "Email": {
    "Enabled": false,
    "NotifyOnSuccess": false,
    "SmtpServer": "smtp.example.com",
    "SmtpPort": 587,
    "UseSsl": true
  }
}
```

### ROSS Carbonite FTP Details

- **Default Username**: `user` (access to USB and general storage)
- **Default Password**: `password`
- **Other FTP Users**:
  - `xpression` - Media-Store channels and USB
  - `liveedl` - LiveEDL folder access
- **USB Path**: Typically `/usb` or `/usb1`
- **Format Preference**: FAT32 for USB drives

## Security

### Critical Security Rules

1. **NEVER commit `config.json`** - Contains FTP credentials
   - `.gitignore` is configured to exclude it
   - Only `config.json.template` should be in version control

2. **Protect Configuration File**
   - Set file permissions to restrict access
   - Store in secure location with limited user access

3. **Email Credentials**
   - Use App Passwords for Gmail/Office365, not account passwords
   - Consider Windows Credential Manager for sensitive data

4. **Network Security**
   - Isolate FTP traffic to management VLAN if possible
   - Change default ROSS passwords in production
   - Consider FTPS if switcher supports it

### Files in .gitignore

- `config.json` - Active configuration with credentials
- `*.log` - Log files
- `Backup/` - Backup directories
- `winscp_*.log` - WinSCP session logs

## Scheduling with Windows Task Scheduler

### Quick Setup

1. Open Task Scheduler
2. Create Basic Task: "Carbonite FTP Backup"
3. Trigger: Daily at 12:00 AM, repeat every 15 minutes for 1 day
4. Action: Run PowerShell script
   - Program: `PowerShell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "D:\Seafile\Seafile\opencode\scheduledFTPBackup\Backup-CarboniteFiles.ps1"`
   - Start in: `D:\Seafile\Seafile\opencode\scheduledFTPBackup`
5. Properties:
   - Run whether user is logged on or not
   - Run with highest privileges

### Recommended Schedule

- **Production Hours**: Every 15-30 minutes
- **Off-Hours**: Every 1 hour
- Configuration files are small (< 10MB), so frequent backups are practical

## Error Handling

### Common Issues

1. **"WinSCP executable not found"**
   - Install WinSCP from https://winscp.net
   - Update `WinSCP.ExecutablePath` in config.json

2. **"Cannot connect to FTP server"**
   - Verify switcher IP address
   - Check network connectivity: `ping <switcher-ip>`
   - Verify switcher is powered on

3. **"Configuration file not found"**
   - Copy `config.json.template` to `config.json`
   - Edit with your settings

4. **Email notifications failing**
   - Check SMTP settings
   - For Gmail, use App Password, not account password
   - Test with `NotifyOnSuccess: true` for verification

### Debugging

- Check main log: `C:\Backup\Carbonite\Logs\backup.log`
- Check WinSCP session logs: `C:\Backup\Carbonite\Logs\winscp_*.log`
- Run script manually to see real-time output
- Enable verbose logging in WinSCP if needed

## Development Notes

### Modifying the Script

**Key Areas:**

- **Retention Logic**: `Invoke-RetentionPolicy` function (Backup-CarboniteFiles.ps1:229)
- **Backup Promotion**: `Invoke-BackupPromotion` function (Backup-CarboniteFiles.ps1:276)
- **FTP Synchronization**: `Invoke-FTPBackup` function (Backup-CarboniteFiles.ps1:141)
- **Email Alerts**: `Send-EmailNotification` function (Backup-CarboniteFiles.ps1:78)

### Adding Features

**Examples:**

- Custom file filtering: Modify `SynchronizeDirectories` call
- Additional notification methods: Add functions similar to `Send-EmailNotification`
- Advanced retention: Modify `Invoke-RetentionPolicy` logic
- Pre/post backup hooks: Add function calls in `Main()`

### Testing Changes

```powershell
# Test with verbose output
$VerbosePreference = "Continue"
.\Backup-CarboniteFiles.ps1

# Test with custom config
.\Backup-CarboniteFiles.ps1 -ConfigFile ".\test-config.json"
```

## Dependencies

- **PowerShell**: Built into Windows (5.1+ recommended)
- **WinSCP**: Free FTP/SFTP client with .NET assembly
  - Download: https://winscp.net/eng/download.php
  - Requires full installation (not portable version)
- **.NET Framework**: Required by WinSCP .NET assembly (usually pre-installed on Windows)

## Additional Resources

- **README.md**: Comprehensive setup and usage guide
- **ROSS Carbonite FTP Docs**: https://help.rossvideo.com/carbonite-01/Topics/Setup/Network/FTP.html
- **WinSCP Scripting**: https://winscp.net/eng/docs/library_session_synchronizedirectories
- **PowerShell Task Scheduling**: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/
