# Infrastructure

**Last Updated**: 2024-12-30

## Network Topology

```
┌─────────────────────┐         ┌─────────────────────┐
│   Backup Server     │         │  ROSS Carbonite     │
│   (Windows)         │◀───────▶│  BLACK 3 M/E        │
│                     │  FTP    │                     │
│   192.168.x.x       │  :21    │   192.168.1.100     │
└─────────────────────┘         └─────────────────────┘
```

## Hosts

### ROSS Carbonite BLACK 3 M/E Switcher

| Property | Value | Notes |
|----------|-------|-------|
| **IP Address** | `192.168.1.100` | Update in config.json |
| **FTP Port** | `21` | Standard FTP |
| **Protocol** | FTP (unencrypted) | FTPS not typically supported |
| **USB Path** | `/usb` or `/usb1` | Depends on USB slot used |

### Backup Server (Windows)

| Property | Value | Notes |
|----------|-------|-------|
| **OS** | Windows 10/11 or Server | PowerShell 5.1+ required |
| **Backup Path** | `C:\Backup\Carbonite` | Configurable in config.json |
| **Log Path** | `C:\Backup\Carbonite\Logs` | Auto-created |

## ROSS Carbonite FTP Users

The Carbonite switcher has three built-in FTP accounts:

| Username | Password | Access |
|----------|----------|--------|
| `user` | `password` | General storage, USB drives (recommended) |
| `xpression` | `password` | Media-Store channels, USB drives |
| `liveedl` | `password` | LiveEDL folder access |

**Note**: These are factory defaults. Check with your facility if changed.

## Connection Details

### FTP Configuration

```json
{
  "FTP": {
    "Host": "192.168.1.100",
    "Port": 21,
    "Username": "user",
    "Password": "password",
    "RemotePath": "/usb"
  }
}
```

### WinSCP Path

Default installation paths:

| Windows Version | Path |
|-----------------|------|
| 64-bit Windows | `C:\Program Files (x86)\WinSCP\WinSCP.com` |
| 32-bit Windows | `C:\Program Files\WinSCP\WinSCP.com` |

Required files in WinSCP directory:
- `WinSCP.com` - Command-line interface
- `WinSCPnet.dll` - .NET assembly (used by script)

## Storage Paths

### Local Backup Structure

| Path | Purpose | Retention |
|------|---------|-----------|
| `C:\Backup\Carbonite\hourly\` | All backups | 24 hours |
| `C:\Backup\Carbonite\daily\` | Daily snapshots | 7 days |
| `C:\Backup\Carbonite\weekly\` | Sunday backups | 8 weeks |
| `C:\Backup\Carbonite\monthly\` | Monthly archives | 12 months |
| `C:\Backup\Carbonite\Logs\` | Log files | Manual cleanup |

### Remote Paths (Carbonite)

| Path | Contents |
|------|----------|
| `/usb` | USB drive root (primary backup source) |
| `/usb1` | Alternate USB slot |

## Email Notification (Optional)

### SMTP Configuration

| Provider | Server | Port | SSL |
|----------|--------|------|-----|
| Gmail | `smtp.gmail.com` | 587 | Yes |
| Office 365 | `smtp.office365.com` | 587 | Yes |
| Custom | Your SMTP server | 25/587 | Varies |

**Gmail Note**: Requires App Password, not account password. Generate at: https://myaccount.google.com/apppasswords

## Firewall Requirements

### Outbound (Backup Server)

| Port | Protocol | Destination | Purpose |
|------|----------|-------------|---------|
| 21 | TCP | Carbonite IP | FTP control |
| 1024-65535 | TCP | Carbonite IP | FTP data (passive mode) |
| 587 | TCP | SMTP server | Email notifications |

### Inbound (Carbonite)

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 21 | TCP | Backup server | FTP access |

## USB Drive Best Practices

Based on ROSS documentation:

1. **Format**: FAT32 (from Windows) for best compatibility
2. **Wait time**: 2-3 seconds after saving before removing USB
3. **Ejection**: Always safely eject before physical removal
4. **Capacity**: 32GB or less recommended for FAT32

## Verification Commands

### Test FTP Connectivity

```powershell
# Ping test
ping 192.168.1.100

# Manual FTP test (Windows)
ftp 192.168.1.100
# Enter: user / password
# Commands: ls, cd /usb, ls, quit
```

### Test with WinSCP GUI

1. Open WinSCP
2. New Session → FTP
3. Host: `192.168.1.100`, Port: `21`
4. User: `user`, Password: `password`
5. Login → Navigate to `/usb`
