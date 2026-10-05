# Architecture

**Last Updated**: 2024-12-30

## Overview

Automated backup solution for ROSS Carbonite BLACK 3 M/E video switcher. PowerShell-based tool that connects via FTP and creates scheduled, versioned backups using WinSCP .NET assembly.

## System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                     Windows Host                                 │
│  ┌─────────────────┐    ┌──────────────────┐                   │
│  │ Task Scheduler  │───▶│ run-backup.bat   │                   │
│  └─────────────────┘    └────────┬─────────┘                   │
│                                  │                              │
│                                  ▼                              │
│                    ┌─────────────────────────┐                 │
│                    │ Backup-CarboniteFiles.ps1│                 │
│                    │                         │                 │
│                    │  ┌───────────────────┐  │                 │
│                    │  │ WinSCPnet.dll     │  │                 │
│                    │  │ (.NET Assembly)   │  │                 │
│                    │  └─────────┬─────────┘  │                 │
│                    └────────────┼────────────┘                 │
│                                 │                              │
└─────────────────────────────────┼──────────────────────────────┘
                                  │ FTP (Port 21)
                                  ▼
                    ┌─────────────────────────┐
                    │  ROSS Carbonite BLACK   │
                    │  3 M/E Video Switcher   │
                    │                         │
                    │  /usb ──▶ Show Files    │
                    │          Configurations │
                    └─────────────────────────┘
```

## Main Components

### 1. Backup-CarboniteFiles.ps1
Primary PowerShell script handling all backup logic.

- **Entry point**: `Main` function at bottom of script
- **Configuration**: Loads from `config.json`
- **FTP Operations**: WinSCP .NET assembly
- **Retention**: GFS (Grandfather-Father-Son) policy
- **Backup tiers**: Hourly → Daily → Weekly → Monthly promotion

### 2. run-backup.bat
Simple batch launcher for Task Scheduler integration.

- Wrapper for PowerShell execution
- Sets execution policy bypass
- Returns proper exit codes

### 3. config.json
Runtime configuration (not in version control).

- FTP connection details
- Backup paths and retention settings
- Email notification configuration
- WinSCP executable path

### 4. config.json.template
Configuration template for new deployments.

## Execution Flow

```
┌──────────────────┐
│  Task Scheduler  │
│  (Every 15 min)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Load-Configuration│──▶ Reads config.json
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│Initialize-Logging │──▶ Creates log directory/file
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌─────────────────────────────┐
│ Invoke-FTPBackup │────▶│ 1. Load WinSCPnet.dll       │
└────────┬─────────┘     │ 2. Create FTP session       │
         │               │ 3. SynchronizeDirectories   │
         │               │    (Local mode, Time sync)  │
         │               │ 4. Download new/modified    │
         │               └─────────────────────────────┘
         ▼
┌────────────────────┐
│Invoke-BackupPromotion│──▶ Promote to daily/weekly/monthly
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│Invoke-RetentionPolicy│──▶ Remove old backups per policy
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│Send-EmailNotification│──▶ Alert on success/failure (if enabled)
└────────────────────┘
```

## Backup Directory Structure

```
C:\Backup\Carbonite\
├── hourly/                    # All backups initially saved here
│   ├── 20241230_080000/
│   ├── 20241230_081500/
│   └── 20241230_083000/
│
├── daily/                     # First backup of each day
│   ├── 20241230/
│   ├── 20241229/
│   └── 20241228/
│
├── weekly/                    # Sunday backups
│   ├── 20241229/             # (Sunday)
│   └── 20241222/
│
├── monthly/                   # First day of month backups
│   ├── 202412/
│   └── 202411/
│
└── Logs/                      # All log files
    ├── backup.log            # Main application log
    └── winscp_*.log          # WinSCP session logs
```

## Backup Promotion Logic

| Tier | Trigger | Naming |
|------|---------|--------|
| **Hourly** | Every backup | `YYYYMMdd_HHmmss` |
| **Daily** | First backup of the day | `YYYYMMdd` |
| **Weekly** | First backup on Sunday | `YYYYMMdd` |
| **Monthly** | First backup on 1st of month | `YYYYMM` |

## Retention Policy (Default)

| Tier | Retention | Typical Count |
|------|-----------|---------------|
| Hourly | 24 hours | ~96 (at 15-min intervals) |
| Daily | 7 days | 7 |
| Weekly | 8 weeks | 8 |
| Monthly | 12 months | 12 |

**Estimated Storage**: ~1-2 GB (typical switcher configs are 5-10 MB each)

## Dependencies

| Component | Purpose | Source |
|-----------|---------|--------|
| PowerShell 5.1+ | Script runtime | Built into Windows |
| WinSCP | FTP client + .NET assembly | https://winscp.net |
| .NET Framework | WinSCP dependency | Pre-installed on Windows |
| Windows Task Scheduler | Automation | Built into Windows |
