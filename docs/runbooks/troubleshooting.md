# Runbook: Troubleshooting

**Last Updated**: 2024-12-30

## Quick Diagnostics

```powershell
# View recent log entries
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Tail 50

# Search for errors
Select-String -Path "C:\Backup\Carbonite\Logs\backup.log" -Pattern "ERROR"

# Monitor log in real-time
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Wait -Tail 20

# Check latest WinSCP session log
Get-ChildItem "C:\Backup\Carbonite\Logs\winscp_*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 |
    Get-Content
```

---

## Common Issues

### "WinSCP executable not found"

**Symptom**: Error in log: `WinSCP executable not found at: ...`

**Cause**: WinSCP not installed or path incorrect in config.json

**Resolution**:

1. Verify WinSCP is installed:
   ```powershell
   Test-Path "C:\Program Files (x86)\WinSCP\WinSCP.com"
   ```

2. If not installed, download from https://winscp.net/eng/download.php

3. Update `config.json`:
   ```json
   "WinSCP": {
     "ExecutablePath": "C:\\Program Files (x86)\\WinSCP\\WinSCP.com"
   }
   ```

---

### "Cannot connect to FTP server"

**Symptom**: Connection timeout or refused

**Cause**: Network issue, wrong IP, or switcher offline

**Resolution**:

1. Verify switcher is powered on

2. Test network connectivity:
   ```powershell
   ping 192.168.1.100
   ```

3. Test FTP port:
   ```powershell
   Test-NetConnection -ComputerName 192.168.1.100 -Port 21
   ```

4. Try manual FTP connection:
   ```powershell
   ftp 192.168.1.100
   # Enter credentials when prompted
   ```

5. Check firewall rules allow outbound FTP

---

### "Access Denied" or "Authentication Failed"

**Symptom**: FTP login rejected

**Cause**: Wrong credentials

**Resolution**:

1. Verify credentials in `config.json`:
   ```json
   "Username": "user",
   "Password": "password"
   ```

2. Test with WinSCP GUI:
   - Open WinSCP
   - New Session → FTP
   - Enter credentials
   - Try to connect

3. Default ROSS credentials:
   - Username: `user`
   - Password: `password`

4. Contact facility manager if defaults were changed

---

### "Configuration file not found"

**Symptom**: Script exits immediately with config error

**Cause**: `config.json` doesn't exist

**Resolution**:

1. Copy template:
   ```powershell
   Copy-Item config.json.template config.json
   ```

2. Edit `config.json` with your settings:
   ```powershell
   notepad config.json
   ```

3. Verify file exists:
   ```powershell
   Test-Path .\config.json
   ```

---

### "Email notifications failing"

**Symptom**: Backup succeeds but no email received

**Cause**: SMTP configuration issue

**Resolution**:

1. Check email settings in `config.json`:
   ```json
   "Email": {
     "Enabled": true,
     "SmtpServer": "smtp.gmail.com",
     "SmtpPort": 587,
     "UseSsl": true
   }
   ```

2. For Gmail:
   - Use App Password, not account password
   - Generate at: https://myaccount.google.com/apppasswords

3. Test with success notifications:
   ```json
   "NotifyOnSuccess": true
   ```

4. Check spam folder

---

### "Task Scheduler not running"

**Symptom**: Scheduled task doesn't execute

**Cause**: Task configuration issue

**Resolution**:

1. Open Task Scheduler and check task status

2. Check "Last Run Result":
   - `0x0` = Success
   - `0x1` = Error (check logs)
   - `0x41301` = Task is running

3. Right-click task → Run (manual test)

4. Verify settings:
   - [x] Run whether user is logged on or not
   - [x] Run with highest privileges

5. Check task history:
   - View → Show All Task History (if disabled)

---

### "Disk space issues"

**Symptom**: Backups fail with disk full errors

**Cause**: Retention policy not cleaning old backups

**Resolution**:

1. Check disk space:
   ```powershell
   Get-PSDrive C | Select-Object Used, Free
   ```

2. Manually clean old backups:
   ```powershell
   # List old hourly backups
   Get-ChildItem "C:\Backup\Carbonite\hourly" |
       Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-2) }

   # Remove (after verification)
   Get-ChildItem "C:\Backup\Carbonite\hourly" |
       Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-2) } |
       Remove-Item -Recurse -Force
   ```

3. Adjust retention in `config.json`:
   ```json
   "Retention": {
     "HourlyKeepHours": 12,
     "DailyKeepDays": 3
   }
   ```

---

## Log Analysis

### Log Format

```
[2024-12-30 09:00:00] [INFO] Message here
[2024-12-30 09:00:01] [ERROR] Error message
[2024-12-30 09:00:02] [SUCCESS] Success message
[2024-12-30 09:00:03] [WARNING] Warning message
```

### Key Log Messages

| Message | Meaning |
|---------|---------|
| `ROSS Carbonite Backup Started` | Script began execution |
| `Connected successfully` | FTP connection established |
| `Files downloaded: N` | N files were new/modified |
| `No new or modified files found` | Backup is current |
| `Backup completed successfully` | All operations succeeded |
| `Backup failed with error:` | Check following line for details |

---

## Escalation

If issues persist after troubleshooting:

1. Collect logs:
   - `C:\Backup\Carbonite\Logs\backup.log`
   - Latest `winscp_*.log` file

2. Document:
   - Error messages
   - Steps already tried
   - Network configuration

3. Resources:
   - ROSS Support: support@rossvideo.com
   - ROSS Help: https://help.rossvideo.com/carbonite-01/
   - WinSCP Forum: https://winscp.net/forum/
