# Security Reference

**Last Updated**: 2024-12-30

## Credential Management

### Current Approach

Credentials stored in `config.json` (excluded from version control).

```
config.json.template  ──▶  Git repository (safe, placeholder values)
config.json           ──▶  Local only, gitignored (contains real credentials)
```

### config.json Security

| Requirement | Implementation |
|-------------|----------------|
| Not in Git | Listed in `.gitignore` |
| File permissions | Restrict to backup service account |
| Encryption at rest | Windows EFS or BitLocker (optional) |

### Setting File Permissions (Windows)

```powershell
# Remove inherited permissions and grant only to current user
$acl = Get-Acl ".\config.json"
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "Allow")
$acl.AddAccessRule($rule)
Set-Acl ".\config.json" $acl
```

Or via GUI:
1. Right-click `config.json` → Properties
2. Security tab → Advanced
3. Disable inheritance → Remove all
4. Add → Select your user → Full control

## Network Security

### FTP Limitations

- FTP transmits credentials in **plaintext**
- Consider network isolation for FTP traffic

### Recommendations

| Control | Implementation |
|---------|----------------|
| VLAN isolation | Place Carbonite on management VLAN |
| Firewall rules | Restrict FTP to backup server IP only |
| FTPS | Use if Carbonite firmware supports it |
| VPN | Route FTP over encrypted tunnel if remote |

### Change Default Passwords

ROSS Carbonite ships with default credentials:
- Username: `user`, Password: `password`

**Action**: Change via Carbonite control panel if your environment requires it.

## Email Security

### App Passwords

For Gmail/Office365, use App Passwords instead of account passwords:

| Provider | App Password URL |
|----------|------------------|
| Gmail | https://myaccount.google.com/apppasswords |
| Microsoft | https://account.live.com/proofs/AppPassword |

### SMTP Configuration

```json
"Email": {
  "UseSsl": true,
  "SmtpPort": 587
}
```

Always use:
- TLS/SSL encryption (`UseSsl: true`)
- Port 587 (submission) or 465 (SMTPS)
- Never port 25 unencrypted

## Backup Security

### Protecting Backup Files

Backups may contain sensitive configuration:

| Control | Purpose |
|---------|---------|
| NTFS permissions | Restrict backup folder access |
| Encryption | BitLocker or EFS for backup drive |
| Retention | Don't keep backups longer than needed |

### Backup Folder Permissions

```powershell
$path = "C:\Backup\Carbonite"
$acl = Get-Acl $path
$acl.SetAccessRuleProtection($true, $false)

# Add backup service account
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "DOMAIN\BackupService", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)

# Add administrators
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)

Set-Acl $path $acl
```

## Secrets in Version Control

### Never Commit

| File | Contains |
|------|----------|
| `config.json` | FTP password, SMTP password |
| `*.log` | May contain IP addresses, paths |
| WinSCP session logs | Connection details |

### .gitignore Coverage

```gitignore
# Credentials
config.json

# Logs
*.log
Logs/
winscp_*.log

# Backups
Backup/
C:/Backup/
```

### Pre-commit Check

Before committing, verify no secrets:

```powershell
# Search for potential secrets
Select-String -Path *.json, *.ps1 -Pattern "password|secret|key|token" -SimpleMatch
```

## Task Scheduler Security

### Service Account

Run scheduled task as dedicated service account:

1. Create local user: `CarboniteBackup`
2. Grant minimal permissions:
   - Read/Execute on script directory
   - Full control on backup directory
   - Log on as batch job right

### Credential Storage

Task Scheduler stores credentials securely:
- Encrypted in Windows Credential Manager
- Accessible only to SYSTEM and task owner

## Audit Trail

### Log Retention

Keep logs for compliance/auditing:

```powershell
# Archive old logs monthly
$archivePath = "C:\Backup\Carbonite\Logs\Archive"
Get-ChildItem "C:\Backup\Carbonite\Logs\*.log" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddMonths(-1) } |
    Move-Item -Destination $archivePath
```

### Log Contents

Logs contain:
- Timestamps of all operations
- Files transferred
- Errors and warnings
- Connection events

## Incident Response

### Suspected Credential Compromise

1. Change Carbonite FTP password
2. Update `config.json` with new password
3. Change SMTP password if configured
4. Review logs for unauthorized access
5. Check backup files for tampering

### Backup Integrity Verification

```powershell
# Compare recent backup to known-good state
$recent = Get-ChildItem "C:\Backup\Carbonite\hourly" |
    Sort-Object CreationTime -Descending |
    Select-Object -First 1

# List files with hashes
Get-ChildItem $recent.FullName -Recurse -File |
    Get-FileHash -Algorithm SHA256
```
