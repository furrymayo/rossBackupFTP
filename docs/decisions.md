> **Legacy log (2026-11-24).** New decisions go in `docs/adr/` as ADRs (index: `docs/adr/README.md`). This file is kept for history and takes no new entries. Where the entries went: WinSCP → ADR 0001; GFS retention + 15-minute interval → ADR 0002; credentials in `config.json` → ADR 0003. "Adopt standard docs structure" is docs scaffolding and has no ADR. The 2024-10-31 dates below come a year before the first commit (2025-10-31), so the ADRs use 2025-10-31.

# Decision Log

**Last Updated**: 2024-12-30

Record of architectural and implementation decisions with rationale.

## Decisions

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2024-10-31 | Use WinSCP .NET assembly for FTP | Robust FTP handling, good PowerShell integration, handles passive mode automatically | Native .NET FtpWebRequest (limited features), PSFTP (less reliable) |
| 2024-10-31 | GFS retention policy (hourly/daily/weekly/monthly) | Balances storage usage with recovery options; industry standard approach | Simple FIFO (loses long-term history), full mirrors (excessive storage) |
| 2024-10-31 | Store credentials in config.json (not .env) | Native PowerShell JSON pattern; script already uses ConvertFrom-Json; .env parsing awkward in PS | .env file (requires custom parsing), Windows Credential Manager (more complex) |
| 2024-10-31 | 15-minute backup interval default | Carbonite configs are small (<10MB); frequent backups catch more changes | Hourly (misses changes), 5-min (excessive for static configs) |
| 2024-12-30 | Adopt standard docs structure | Consistent organization across projects; easier onboarding | Keep flat structure (harder to navigate) |

## Pending Decisions

<!-- Add items here that need discussion -->

None currently.

## Decision Template

When adding new decisions, use this format:

```markdown
| YYYY-MM-DD | [What was decided] | [Why this choice was made] | [What else was considered] |
```
