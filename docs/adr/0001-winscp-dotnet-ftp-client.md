# 0001. Use the WinSCP .NET assembly from PowerShell as the FTP client

- **Status:** accepted
- **Date:** 2025-10-31 (first commit, 567d087). `docs/decisions.md` dates the row 2024-10-31, a year before the first commit and its sample logs, which are all 2025-10-31; that year looks like a typo.
- **Deciders:** Caleb
- **Backfilled:** yes, 2026-11-24, from `docs/decisions.md`, `Backup-CarboniteFiles.ps1` (`Invoke-FTPBackup`), `config.json.template`, `README.md` (Prerequisites, Troubleshooting), commits 567d087, 42c914e (PR #1)
- **Related:** ADR 0002, ADR 0003

## Context

The tool backs up show files and configuration from a Ross Carbonite switcher over FTP (remote path `/usb` in `config.json.template`) to a Windows machine, run by Task Scheduler (`README.md`). It is one PowerShell script, `Backup-CarboniteFiles.ps1`, started by `run-backup.bat`.

## Options considered

From `docs/decisions.md` (the rationale column was written in the 2026-10-05 scaffold, 42c914e):
1. **WinSCP .NET assembly (chosen)**: "robust FTP handling, good PowerShell integration, handles passive mode automatically".
2. **Native .NET `FtpWebRequest`**: rejected, "limited features".
3. **PSFTP**: rejected, "less reliable".

## Decision

`Invoke-FTPBackup` loads `WinSCPnet.dll` from the folder of the configured `WinSCP.ExecutablePath` and opens a `WinSCP.Session` with `Protocol = Ftp` and the host, port, user and password from `config.json`. It then calls `SynchronizeDirectories` in `Local` mode with `Time` criteria and no removals, from the remote path into a new `hourly\<yyyyMMdd_HHmmss>` folder. WinSCP writes a session log next to the backup log.

## Consequences

- WinSCP must be installed on the backup machine; it is not in the repo, and the script stops with "WinSCP not found" if the path is wrong. Its version is whatever was installed.
- Each run synchronises into a fresh empty folder, so every run downloads the whole remote tree. Nothing is skipped as unchanged. Storage use is set by retention (ADR 0002), not by deltas.
- The script sets no FTP mode or TLS options, so it uses WinSCP's defaults over plain FTP. Credentials cross the network in clear text (`docs/reference/security.md`, "Network Security"; ADR 0003).
