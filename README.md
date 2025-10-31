# ROSS Carbonite FTP Backup Automation

Automated backup solution for ROSS Carbonite BLACK 3 M/E video switcher show files and configurations. This tool connects to your Carbonite switcher via FTP and creates scheduled, versioned backups with automatic retention management.

## Features

- **Automated FTP Backups**: Scheduled downloads of show files and switcher configurations
- **Versioned Backups**: Hourly, daily, weekly, and monthly backup retention
- **Smart Retention**: Automatic cleanup of old backups based on configurable policies
- **Email Notifications**: Optional alerts on backup success or failure
- **Detailed Logging**: Comprehensive logs for troubleshooting and audit trails
- **Windows Integration**: Native PowerShell script with Windows Task Scheduler support

## Prerequisites

1. **WinSCP** - Free FTP/SFTP client with scripting support
   - Download: https://winscp.net/eng/download.php
   - Install the full application (not just the portable version)
   - Default installation path: `C:\Program Files (x86)\WinSCP\`

2. **Windows PowerShell** - Built into Windows (no installation needed)
   - Windows 7 or later

3. **Network Access** - FTP connectivity to your ROSS Carbonite switcher
   - Default ROSS Carbonite FTP credentials: username `user`, password `password`

## Quick Start

### 1. Install WinSCP

1. Download WinSCP from https://winscp.net/eng/download.php
2. Run the installer and follow the setup wizard
3. Use default installation options
4. Note the installation path (typically `C:\Program Files (x86)\WinSCP\`)

### 2. Configure the Backup Script

1. Copy `config.json.template` to `config.json`:
   ```
   copy config.json.template config.json
   ```

2. Edit `config.json` with your settings:
   ```json
   {
     "FTP": {
       "Host": "192.168.1.100",          // Your Carbonite switcher IP address
       "Port": 21,                        // FTP port (usually 21)
       "Username": "user",                // ROSS default username
       "Password": "password",            // ROSS default password
       "RemotePath": "/usb"               // Path to USB drive on switcher
     },
     "Backup": {
       "LocalPath": "C:\\Backup\\Carbonite"  // Where to store backups
     }
   }
   ```

3. Update the following fields:
   - `FTP.Host`: Your Carbonite switcher's IP address
   - `FTP.RemotePath`: Path to your USB drive (typically `/usb` or `/usb1`)
   - `Backup.LocalPath`: Local directory for storing backups
   - `WinSCP.ExecutablePath`: Path to WinSCP (if not default location)

### 3. Test the Backup

Run a manual backup to verify everything works:

```powershell
.\run-backup.bat
```

Or run PowerShell directly:

```powershell
PowerShell.exe -ExecutionPolicy Bypass -File .\Backup-CarboniteFiles.ps1
```

**Expected Output:**
```
[2025-10-31 09:00:00] [INFO] ========================================
[2025-10-31 09:00:00] [INFO] ROSS Carbonite Backup Started
[2025-10-31 09:00:00] [INFO] ========================================
[2025-10-31 09:00:01] [INFO] Connecting to FTP server: 192.168.1.100
[2025-10-31 09:00:02] [SUCCESS] Connected successfully
[2025-10-31 09:00:02] [INFO] Starting file synchronization...
[2025-10-31 09:00:05] [SUCCESS] Backup completed successfully
```

### 4. Schedule Automatic Backups

#### Using Windows Task Scheduler:

1. Open **Task Scheduler** (Start → search "Task Scheduler")

2. Click **"Create Basic Task"** in the right panel

3. Configure the task:
   - **Name**: `Carbonite FTP Backup`
   - **Description**: `Automated backup of ROSS Carbonite show files`
   - **Trigger**: Daily at 12:00 AM
   - **Repeat task every**: 15 minutes
   - **For a duration of**: 1 day
   - **Action**: Start a program
   - **Program/script**: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
   - **Add arguments**: `-ExecutionPolicy Bypass -File "D:\Seafile\Seafile\opencode\scheduledFTPBackup\Backup-CarboniteFiles.ps1"`
   - **Start in**: `D:\Seafile\Seafile\opencode\scheduledFTPBackup`

4. After creating the task:
   - Right-click the task → **Properties**
   - Under **General** tab:
     - Check "Run whether user is logged on or not"
     - Check "Run with highest privileges"
   - Under **Settings** tab:
     - Uncheck "Stop the task if it runs longer than"
     - Check "If the task fails, restart every: 5 minutes, Attempt to restart up to: 3 times"

5. Click **OK** and enter your Windows password when prompted

#### Using PowerShell to Create the Task:

Run this PowerShell command as Administrator:

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"D:\Seafile\Seafile\opencode\scheduledFTPBackup\Backup-CarboniteFiles.ps1`""

$trigger = New-ScheduledTaskTrigger -Daily -At "12:00AM"
$trigger.Repetition = New-ScheduledTaskTrigger -Once -At "12:00AM" -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 1) | Select-Object -ExpandProperty Repetition

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "Carbonite FTP Backup" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Automated backup of ROSS Carbonite show files" `
    -RunLevel Highest
```

## Configuration Reference

### FTP Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `Host` | IP address of your Carbonite switcher | `192.168.1.100` |
| `Port` | FTP port number | `21` |
| `Username` | FTP username | `user` |
| `Password` | FTP password | `password` |
| `RemotePath` | Remote directory to backup | `/usb` |

**Note**: ROSS Carbonite has three FTP users:
- `user` - General storage and USB drives (recommended)
- `xpression` - Media-Store channels and USB drives
- `liveedl` - LiveEDL folder access

### Backup Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `LocalPath` | Local directory for backups | `C:\Backup\Carbonite` |
| `HourlyKeepHours` | Hours to keep hourly backups | `24` |
| `DailyKeepDays` | Days to keep daily backups | `7` |
| `WeeklyKeepWeeks` | Weeks to keep weekly backups | `8` |
| `MonthlyKeepMonths` | Months to keep monthly backups | `12` |

### Email Notification Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `Enabled` | Enable email notifications | `false` |
| `NotifyOnSuccess` | Send email on successful backups | `false` |
| `SmtpServer` | SMTP server address | `smtp.example.com` |
| `SmtpPort` | SMTP port | `587` |
| `UseSsl` | Use SSL/TLS encryption | `true` |
| `Username` | SMTP authentication username | - |
| `Password` | SMTP authentication password | - |
| `From` | Email sender address | - |
| `To` | Email recipient address | - |

**Example Email Configuration (Gmail):**

```json
"Email": {
  "Enabled": true,
  "NotifyOnSuccess": false,
  "SmtpServer": "smtp.gmail.com",
  "SmtpPort": 587,
  "UseSsl": true,
  "Username": "your-email@gmail.com",
  "Password": "your-app-password",
  "From": "your-email@gmail.com",
  "To": "admin@yourcompany.com"
}
```

**Note**: For Gmail, you need to use an [App Password](https://support.google.com/accounts/answer/185833), not your regular password.

## Backup Structure

The backup system creates a hierarchical structure:

```
C:\Backup\Carbonite\
├── hourly\
│   ├── 20251031_080000\
│   ├── 20251031_081500\
│   ├── 20251031_083000\
│   └── ...
├── daily\
│   ├── 20251031\
│   ├── 20251030\
│   └── ...
├── weekly\
│   ├── 20251027\  (Sunday backups)
│   └── ...
├── monthly\
│   ├── 202510\
│   └── ...
└── Logs\
    ├── backup.log
    ├── winscp_20251031_080000.log
    └── ...
```

### Backup Promotion Logic

- **Hourly**: Every backup is saved to `hourly/`
- **Daily**: First backup each day is copied to `daily/`
- **Weekly**: First backup on Sunday is copied to `weekly/`
- **Monthly**: First backup on the 1st of the month is copied to `monthly/`

### Retention Policy

- **Hourly**: Kept for 24 hours (96 backups if running every 15 minutes)
- **Daily**: Kept for 7 days
- **Weekly**: Kept for 8 weeks (~2 months)
- **Monthly**: Kept for 12 months

**Estimated Storage Requirements:**
- Average backup size: ~5-10 MB (typical for switcher configs)
- Total storage needed: ~1-2 GB

## Troubleshooting

### "WinSCP executable not found"

**Problem**: The script can't find WinSCP.

**Solution**:
1. Verify WinSCP is installed
2. Update `WinSCP.ExecutablePath` in `config.json` with the correct path
3. Default paths:
   - 64-bit Windows: `C:\Program Files (x86)\WinSCP\WinSCP.com`
   - 32-bit Windows: `C:\Program Files\WinSCP\WinSCP.com`

### "Cannot connect to FTP server"

**Problem**: Unable to establish FTP connection.

**Solution**:
1. Verify the Carbonite switcher IP address
2. Test FTP connection manually using WinSCP GUI
3. Check firewall settings
4. Verify the switcher is powered on and network cable is connected
5. Try pinging the switcher IP: `ping 192.168.1.100`

### "Access Denied" or "Permission Denied"

**Problem**: Incorrect FTP credentials.

**Solution**:
1. Verify username and password in `config.json`
2. Default ROSS credentials: username `user`, password `password`
3. If changed, contact your facility manager for credentials
4. Try connecting manually with WinSCP to verify credentials

### "Configuration file not found"

**Problem**: `config.json` doesn't exist.

**Solution**:
1. Copy the template: `copy config.json.template config.json`
2. Edit `config.json` with your settings
3. Ensure the file is in the same directory as the script

### Task Scheduler Not Running

**Problem**: Scheduled task doesn't execute.

**Solution**:
1. Open Task Scheduler and check task history
2. Right-click the task → **Run** to test manually
3. Check "Last Run Result" (should be 0x0 for success)
4. Verify the task is enabled
5. Ensure "Run whether user is logged on or not" is checked
6. Check the account has necessary permissions

### Logs Show Errors

**Problem**: Backup log contains errors.

**Solution**:
1. Check the main log: `C:\Backup\Carbonite\Logs\backup.log`
2. Check WinSCP session logs: `C:\Backup\Carbonite\Logs\winscp_*.log`
3. Look for specific error messages
4. Common issues:
   - Network timeouts: Check network connectivity
   - Permission errors: Verify FTP credentials
   - Disk space: Ensure backup drive has sufficient space

## Restoring from Backup

### To restore files to the Carbonite switcher:

1. Open **WinSCP** GUI application

2. Create a new session:
   - **File protocol**: FTP
   - **Host name**: Your Carbonite IP (e.g., `192.168.1.100`)
   - **Port**: 21
   - **Username**: `user`
   - **Password**: `password`

3. Click **Login** to connect

4. Navigate to the USB directory on the switcher (usually `/usb`)

5. On the local side, navigate to your backup directory:
   - `C:\Backup\Carbonite\hourly\[timestamp]\`
   - Or the appropriate daily/weekly/monthly backup

6. Select the files you want to restore

7. Drag and drop or click **Upload** to copy files back to the switcher

8. **Important**: On the Carbonite, reload the show file or configuration after uploading

### To restore files locally (for reference or testing):

Simply copy files from the backup directory to your desired location:

```
C:\Backup\Carbonite\hourly\20251031_080000\
```

## ROSS Carbonite USB Best Practices

Based on ROSS documentation and your experience:

1. **Always wait 2-3 seconds** after saving settings before removing USB
2. **Format USB drives as FAT32** (from Windows) for best compatibility
3. **Safely eject USB** before physical removal to prevent corruption
4. **Keep backups** - This automated system prevents total data loss
5. **Verify backups periodically** - Test restores monthly

## Security Considerations

### Protecting Credentials

- **Never commit `config.json`** to version control (it's in `.gitignore`)
- Store `config.json` with restricted permissions (right-click → Properties → Security)
- Consider using Windows Credential Manager for sensitive passwords
- Use FTPS (FTP over SSL) if your switcher supports it

### Network Security

- Isolate backup traffic to a management VLAN if possible
- Use firewall rules to restrict FTP access
- Monitor FTP logs for unauthorized access attempts
- Change default passwords on the Carbonite

## Advanced Usage

### Running Backup Manually

```powershell
# Run with default config.json
.\Backup-CarboniteFiles.ps1

# Run with custom configuration
.\Backup-CarboniteFiles.ps1 -ConfigFile ".\custom-config.json"
```

### Viewing Logs

```powershell
# View recent log entries
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Tail 50

# Monitor log in real-time
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Wait -Tail 20

# Search for errors
Select-String -Path "C:\Backup\Carbonite\Logs\backup.log" -Pattern "ERROR"
```

### Customizing Retention Policies

Edit `config.json`:

```json
"Retention": {
  "HourlyKeepHours": 48,      // Keep 2 days of hourly backups
  "DailyKeepDays": 14,        // Keep 2 weeks of daily backups
  "WeeklyKeepWeeks": 12,      // Keep 3 months of weekly backups
  "MonthlyKeepMonths": 24     // Keep 2 years of monthly backups
}
```

### Changing Backup Frequency

**For more frequent backups (every 5 minutes):**

In Task Scheduler, edit the trigger:
- Repeat task every: **5 minutes**

**For less frequent backups (hourly):**

In Task Scheduler, edit the trigger:
- Repeat task every: **1 hour**

## Support

### ROSS Carbonite Resources

- **ROSS Help Portal**: https://help.rossvideo.com/carbonite-01/
- **FTP Documentation**: https://help.rossvideo.com/carbonite-01/Topics/Setup/Network/FTP.html
- **ROSS Technical Support**: support@rossvideo.com

### WinSCP Resources

- **Official Documentation**: https://winscp.net/eng/docs/start
- **Scripting Guide**: https://winscp.net/eng/docs/scripting
- **Forum**: https://winscp.net/forum/

### This Project

For issues with this backup script:
1. Check the troubleshooting section above
2. Review the backup logs
3. Test manual WinSCP connection to the switcher
4. Open an issue on the project repository

## License

This project is provided as-is for backing up ROSS Carbonite video switcher configurations.

## Acknowledgments

- ROSS Video for the Carbonite BLACK switcher platform
- WinSCP project for the excellent FTP/SFTP client and .NET library
