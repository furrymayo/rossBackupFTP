# ROSS Carbonite FTP Backup

**Last Updated**: 2024-12-30
**Status**: Active
**Primary OS**: Windows

## Overview

Automated backup solution for ROSS Carbonite BLACK 3 M/E video switcher. PowerShell script connects via FTP, downloads show files and configurations, and maintains versioned backups with GFS (Grandfather-Father-Son) retention policy using WinSCP .NET assembly.

## Current State

- Core backup functionality complete and tested
- Task Scheduler integration documented
- Documentation restructured to standard format (2024-12-30)

## Quick Reference

| Item | Value |
|------|-------|
| Carbonite IP | `192.168.1.100` (configure in config.json) |
| FTP Port | `21` |
| FTP User | `user` / `password` (ROSS defaults) |
| Remote Path | `/usb` |
| Backup Location | `C:\Backup\Carbonite\` |
| Log File | `C:\Backup\Carbonite\Logs\backup.log` |
| Config File | `config.json` (copy from template) |

## File Map

| Need to know... | See |
|-----------------|-----|
| System design & data flow | `docs/architecture.md` |
| Host details, IPs, FTP config | `docs/infrastructure.md` |
| Why decisions were made | `docs/decisions.md` |
| Current blockers/issues | `docs/known-issues.md` |
| How to set up Task Scheduler | `docs/runbooks/setup-scheduler.md` |
| How to troubleshoot | `docs/runbooks/troubleshooting.md` |
| How to restore from backup | `docs/runbooks/restore-backup.md` |
| Script internals & modification | `docs/reference/development.md` |
| Security considerations | `docs/reference/security.md` |

## Common Commands

```powershell
# Run backup manually
.\run-backup.bat

# Run with custom config
.\Backup-CarboniteFiles.ps1 -ConfigFile ".\custom-config.json"

# View recent logs
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Tail 50

# Monitor log in real-time
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Wait -Tail 20

# Search for errors
Select-String -Path "C:\Backup\Carbonite\Logs\backup.log" -Pattern "ERROR"
```

## Setup (Quick Start)

1. Install WinSCP from https://winscp.net
2. Copy config: `copy config.json.template config.json`
3. Edit `config.json` with your Carbonite IP
4. Test: `.\run-backup.bat`
5. Schedule: See `docs/runbooks/setup-scheduler.md`

## Project Structure

```
./
├── CLAUDE.md                    # This file (session map)
├── README.md                    # User-facing documentation
├── Backup-CarboniteFiles.ps1    # Main PowerShell script
├── run-backup.bat               # Batch launcher for Task Scheduler
├── config.json.template         # Configuration template
├── config.json                  # Active config (gitignored)
├── .env.example                 # Credential documentation
├── .gitignore
├── docs/
│   ├── architecture.md          # System design
│   ├── infrastructure.md        # Hosts, IPs, connections
│   ├── decisions.md             # Decision log
│   ├── known-issues.md          # Current blockers
│   ├── runbooks/
│   │   ├── setup-scheduler.md   # Task Scheduler setup
│   │   ├── troubleshooting.md   # Common issues & fixes
│   │   └── restore-backup.md    # Restore procedure
│   └── reference/
│       ├── development.md       # Script internals
│       └── security.md          # Security considerations
├── scripts/
│   └── utils/
│       ├── update_docs.sh       # Doc update checklist (Linux)
│       └── update_docs.ps1      # Doc update checklist (Windows)
└── archive/                     # Outdated docs
```

## Recent Activity

- 2024-12-30: Restructured documentation to standard format; created docs/, scripts/, archive/ directories
- 2024-10-31: Initial commit - core backup functionality

## Dependencies

| Component | Purpose | Install |
|-----------|---------|---------|
| PowerShell 5.1+ | Script runtime | Built into Windows |
| WinSCP | FTP client + .NET assembly | https://winscp.net |

## External Resources

- [ROSS Carbonite FTP Docs](https://help.rossvideo.com/carbonite-01/Topics/Setup/Network/FTP.html)
- [WinSCP .NET Documentation](https://winscp.net/eng/docs/library)
- [WinSCP SynchronizeDirectories](https://winscp.net/eng/docs/library_session_synchronizedirectories)
