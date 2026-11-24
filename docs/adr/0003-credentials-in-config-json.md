# 0003. FTP and SMTP credentials live in a local, gitignored `config.json`

- **Status:** accepted
- **Date:** 2025-10-31 (first commit, 567d087; `docs/decisions.md` says 2024-10-31, see ADR 0001)
- **Deciders:** Caleb
- **Backfilled:** yes, 2026-11-24, from `docs/decisions.md`, `Backup-CarboniteFiles.ps1` (`Load-Configuration`, `Invoke-FTPBackup`, `Send-EmailNotification`), `.gitignore`, `.env.example`, `config.json.template`, `README.md` (Security), `docs/reference/security.md` ("Credential Management", "Network Security")
- **Related:** ADR 0001

## Context

The script runs unattended from Task Scheduler and needs the switcher's FTP host, port, user name and password, plus optional SMTP credentials for email alerts. It reads one JSON config file with `ConvertFrom-Json` (`Load-Configuration`). This is a public repo.

## Options considered

From `docs/decisions.md` (rationale written in the 2026-10-05 scaffold):
1. **`config.json` (chosen)**: "native PowerShell JSON pattern; script already uses ConvertFrom-Json; .env parsing awkward in PS".
2. **`.env` file**: rejected, "requires custom parsing".
3. **Windows Credential Manager**: rejected, "more complex".

## Decision

All settings, credentials included, are in `config.json` next to the script. `.gitignore` excludes it, and the repo ships `config.json.template` with placeholder values. `.env.example` holds no values; it only says that credentials go in `config.json` (42c914e). The FTP password goes to WinSCP's `SessionOptions` in-process, not on a command line (`Invoke-FTPBackup`). The SMTP password becomes a `PSCredential` for the email alert (`Send-EmailNotification`).

## Consequences

- `config.json` is a plaintext secret on disk. Its protection depends on file ACLs and optional EFS/BitLocker, which `docs/reference/security.md` recommends but the script does not check or enforce.
- FTP sends the credentials in clear text on the wire. The compensating control `docs/reference/security.md` suggests is network isolation (a management VLAN for the switcher).
- Credentials are not encrypted per user (no DPAPI or Credential Manager). Anyone who can read the file can use them.
