# Runbook: Setup Windows Task Scheduler

**Last Updated**: 2024-12-30

## Prerequisites

- [ ] WinSCP installed
- [ ] `config.json` created and configured
- [ ] Manual backup test successful (`.\run-backup.bat`)

## Procedure

### Option A: GUI Method

1. **Open Task Scheduler**
   - Press `Win + R`, type `taskschd.msc`, press Enter
   - Or: Start → search "Task Scheduler"

2. **Create Basic Task**
   - Right panel → "Create Basic Task..."
   - Name: `Carbonite FTP Backup`
   - Description: `Automated backup of ROSS Carbonite show files`

3. **Configure Trigger**
   - When: Daily
   - Start: `12:00:00 AM`
   - Recur every: 1 day

4. **Configure Action**
   - Action: Start a program
   - Program/script: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "D:\Path\To\Backup-CarboniteFiles.ps1"`
   - Start in: `D:\Path\To\` (script directory)

5. **Configure Repetition**
   - After creating, right-click task → Properties
   - Triggers tab → Edit trigger
   - Check "Repeat task every": `15 minutes`
   - For a duration of: `1 day`

6. **Configure Run Settings**
   - General tab:
     - [x] Run whether user is logged on or not
     - [x] Run with highest privileges
   - Settings tab:
     - [ ] Stop the task if it runs longer than (uncheck)
     - [x] If the task fails, restart every: 5 minutes
     - Attempt to restart up to: 3 times

7. **Save and Test**
   - Click OK
   - Enter Windows password when prompted
   - Right-click task → Run
   - Check `C:\Backup\Carbonite\Logs\backup.log` for results

### Option B: PowerShell Method

Run as Administrator:

```powershell
$scriptPath = "D:\Path\To\Backup-CarboniteFiles.ps1"
$workingDir = "D:\Path\To"

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`"" `
    -WorkingDirectory $workingDir

$trigger = New-ScheduledTaskTrigger -Daily -At "12:00AM"

# Add 15-minute repetition
$trigger.Repetition = (New-ScheduledTaskTrigger -Once -At "12:00AM" `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration (New-TimeSpan -Days 1)).Repetition

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5)

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask `
    -TaskName "Carbonite FTP Backup" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Automated backup of ROSS Carbonite show files"
```

## Verification

```powershell
# Check task exists
Get-ScheduledTask -TaskName "Carbonite FTP Backup"

# Check task status
Get-ScheduledTaskInfo -TaskName "Carbonite FTP Backup"

# View last run result (0 = success)
(Get-ScheduledTaskInfo -TaskName "Carbonite FTP Backup").LastTaskResult
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Task doesn't run | Check "Run whether user is logged on or not" is enabled |
| Access denied | Enable "Run with highest privileges" |
| Script not found | Verify path in Arguments and Start in fields |
| Returns error code | Check backup.log for details |

## Rollback

To remove the scheduled task:

```powershell
Unregister-ScheduledTask -TaskName "Carbonite FTP Backup" -Confirm:$false
```
