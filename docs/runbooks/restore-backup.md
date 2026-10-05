# Runbook: Restore from Backup

**Last Updated**: 2024-12-30

## Overview

This procedure restores show files and configurations from backup to a ROSS Carbonite switcher.

## Prerequisites

- [ ] WinSCP installed (GUI or command-line)
- [ ] Network access to Carbonite switcher
- [ ] FTP credentials
- [ ] Backup files to restore identified

## Identify Backup to Restore

### List Available Backups

```powershell
# List recent hourly backups
Get-ChildItem "C:\Backup\Carbonite\hourly" |
    Sort-Object CreationTime -Descending |
    Select-Object Name, CreationTime -First 10

# List daily backups
Get-ChildItem "C:\Backup\Carbonite\daily" |
    Sort-Object CreationTime -Descending

# List weekly backups
Get-ChildItem "C:\Backup\Carbonite\weekly" |
    Sort-Object CreationTime -Descending

# List monthly backups
Get-ChildItem "C:\Backup\Carbonite\monthly" |
    Sort-Object CreationTime -Descending
```

### View Backup Contents

```powershell
# List files in a specific backup
Get-ChildItem "C:\Backup\Carbonite\hourly\20241230_090000" -Recurse |
    Select-Object FullName, Length, LastWriteTime
```

## Restore Procedure

### Option A: WinSCP GUI (Recommended)

1. **Open WinSCP**
   - Start → WinSCP

2. **Connect to Carbonite**
   - File protocol: FTP
   - Host name: `192.168.1.100` (your switcher IP)
   - Port: `21`
   - User name: `user`
   - Password: `password`
   - Click Login

3. **Navigate Directories**
   - Left panel (local): Navigate to backup folder
     - Example: `C:\Backup\Carbonite\daily\20241230\`
   - Right panel (remote): Navigate to `/usb`

4. **Select Files to Restore**
   - In left panel, select files/folders to restore
   - Review what will be overwritten on right panel

5. **Upload Files**
   - Drag selected files from left to right panel
   - Or press F5 (Copy)
   - Confirm overwrite if prompted

6. **Verify Upload**
   - Check files appear on right panel
   - Compare file sizes

7. **Disconnect**
   - Session → Disconnect
   - Close WinSCP

### Option B: PowerShell Script

```powershell
# Configure restore parameters
$backupPath = "C:\Backup\Carbonite\daily\20241230"  # Backup to restore
$carboniteHost = "192.168.1.100"
$carboniteUser = "user"
$carbonitePass = "password"
$remotePath = "/usb"

# Load WinSCP assembly
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

# Create session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Ftp
    HostName = $carboniteHost
    PortNumber = 21
    UserName = $carboniteUser
    Password = $carbonitePass
}

# Connect and upload
$session = New-Object WinSCP.Session
try {
    $session.Open($sessionOptions)

    # Upload all files from backup to remote
    $transferOptions = New-Object WinSCP.TransferOptions
    $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

    $result = $session.PutFiles("$backupPath\*", "$remotePath/", $false, $transferOptions)
    $result.Check()

    foreach ($transfer in $result.Transfers) {
        Write-Host "Uploaded: $($transfer.FileName)"
    }

    Write-Host "Restore completed successfully"
}
finally {
    $session.Dispose()
}
```

## Post-Restore Steps

### On the Carbonite Switcher

1. **Reload Configuration**
   - Navigate to: Setup → System → Load Configuration
   - Or: Press and hold SHIFT + LOAD on panel

2. **Reload Show File**
   - Navigate to: Shows → Load Show
   - Select the restored show file
   - Press LOAD

3. **Verify Operation**
   - Check all sources are assigned correctly
   - Test key transitions
   - Verify macros function properly
   - Check DVE and effects

### Verification Checklist

- [ ] Show file loaded without errors
- [ ] All ME banks show correct sources
- [ ] Aux outputs mapped correctly
- [ ] Macros execute as expected
- [ ] Custom labels restored
- [ ] User preferences intact

## Rollback

If restored files cause issues:

1. **Load Previous Backup**
   - Use older backup from `daily/`, `weekly/`, or `monthly/`
   - Repeat restore procedure

2. **Factory Reset** (Last Resort)
   - Consult ROSS documentation
   - Contact ROSS support: support@rossvideo.com

## Safety Notes

- **Warning**: Restoring files will overwrite current configuration
- **Recommendation**: Create a manual backup before restoring
- **Best Practice**: Test restores periodically to verify backup integrity
- **Important**: Wait 2-3 seconds after restore before removing USB
