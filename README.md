# ROSS Carbonite FTP Backup Automation

Automated backup solution for ROSS Carbonite BLACK 3 M/E video switcher show files and configurations. Connects via FTP and creates scheduled, versioned backups with automatic retention management.

## Features

- Automated FTP backups via Windows Task Scheduler
- Versioned backups: hourly, daily, weekly, monthly
- Smart GFS retention policy with automatic cleanup
- Optional email notifications
- Comprehensive logging

## Quick Start

### Prerequisites

1. **WinSCP** - Download from https://winscp.net/eng/download.php
2. **Windows PowerShell** - Built into Windows
3. **Network access** - FTP connectivity to your Carbonite switcher

### Installation

```powershell
# 1. Copy configuration template
copy config.json.template config.json

# 2. Edit config.json with your settings
notepad config.json
# Update: FTP.Host (your Carbonite IP address)

# 3. Test the backup
.\run-backup.bat
```

### Configuration

Edit `config.json`:

```json
{
  "FTP": {
    "Host": "192.168.1.100",    // Your Carbonite IP
    "Port": 21,
    "Username": "user",          // ROSS default
    "Password": "password",      // ROSS default
    "RemotePath": "/usb"
  },
  "Backup": {
    "LocalPath": "C:\\Backup\\Carbonite"
  }
}
```

### Schedule Automatic Backups

See [docs/runbooks/setup-scheduler.md](docs/runbooks/setup-scheduler.md) for detailed instructions.

**Quick version:**
1. Open Task Scheduler
2. Create task: "Carbonite FTP Backup"
3. Trigger: Daily, repeat every 15 minutes
4. Action: `PowerShell.exe -ExecutionPolicy Bypass -File "path\to\Backup-CarboniteFiles.ps1"`

## Documentation

| Topic | Location |
|-------|----------|
| System architecture | [docs/architecture.md](docs/architecture.md) |
| Network & host details | [docs/infrastructure.md](docs/infrastructure.md) |
| Task Scheduler setup | [docs/runbooks/setup-scheduler.md](docs/runbooks/setup-scheduler.md) |
| Troubleshooting | [docs/runbooks/troubleshooting.md](docs/runbooks/troubleshooting.md) |
| Restore procedure | [docs/runbooks/restore-backup.md](docs/runbooks/restore-backup.md) |
| Security considerations | [docs/reference/security.md](docs/reference/security.md) |
| Development guide | [docs/reference/development.md](docs/reference/development.md) |

## Backup Structure

```
C:\Backup\Carbonite\
├── hourly\          # All backups (kept 24 hours)
├── daily\           # Daily snapshots (kept 7 days)
├── weekly\          # Sunday backups (kept 8 weeks)
├── monthly\         # Monthly archives (kept 12 months)
└── Logs\            # Log files
```

## Troubleshooting

**Can't connect to FTP?**
```powershell
ping 192.168.1.100  # Test network
```

**WinSCP not found?**
- Install WinSCP from https://winscp.net
- Update `WinSCP.ExecutablePath` in config.json

**View logs:**
```powershell
Get-Content "C:\Backup\Carbonite\Logs\backup.log" -Tail 50
```

See [docs/runbooks/troubleshooting.md](docs/runbooks/troubleshooting.md) for more solutions.

## ROSS Carbonite FTP Users

| Username | Password | Access |
|----------|----------|--------|
| `user` | `password` | General storage, USB (recommended) |
| `xpression` | `password` | Media-Store, USB |
| `liveedl` | `password` | LiveEDL folder |

## Security

- **Never commit `config.json`** - Contains credentials (gitignored)
- Change default ROSS passwords in production
- See [docs/reference/security.md](docs/reference/security.md) for details

## Resources

- [ROSS Carbonite FTP Documentation](https://help.rossvideo.com/carbonite-01/Topics/Setup/Network/FTP.html)
- [WinSCP .NET Library](https://winscp.net/eng/docs/library)
- [ROSS Support](mailto:support@rossvideo.com)

## License

This project is provided as-is for backing up ROSS Carbonite video switcher configurations.
