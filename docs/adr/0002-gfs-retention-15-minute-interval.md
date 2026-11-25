# 0002. GFS-style retention (hourly/daily/weekly/monthly) with a 15-minute run interval

- **Status:** accepted
- **Date:** 2025-10-31 (first commit, 567d087; `docs/decisions.md` says 2024-10-31, see ADR 0001)
- **Deciders:** Caleb
- **Backfilled:** yes, 2026-11-24, from `docs/decisions.md`, `Backup-CarboniteFiles.ps1` (`Invoke-BackupPromotion`, `Invoke-RetentionPolicy`), `config.json.template` (`Backup.Retention`), `README.md` (Quick Start), `docs/architecture.md` ("Backup Promotion Logic", "Retention Policy (Default)")
- **Related:** ADR 0001

## Context

Carbonite configs are small: under 10 MB according to `docs/decisions.md`, and 5–10 MB each with about 1–2 GB of total backup storage according to `docs/architecture.md`. The aim is frequent copies plus longer history for recovery.

## Options considered

From `docs/decisions.md` (rationale written in the 2026-10-05 scaffold):
1. **GFS retention (chosen)**: "balances storage usage with recovery options; industry standard approach". Rejected: simple FIFO ("loses long-term history") and full mirrors ("excessive storage").
2. **15-minute interval (chosen)**: "Carbonite configs are small (<10MB); frequent backups catch more changes". Rejected: hourly ("misses changes") and 5 minutes ("excessive for static configs").

## Decision

- Task Scheduler runs the backup daily, repeating every 15 minutes (`README.md`, Quick Start).
- Every run lands in `hourly\<timestamp>` (ADR 0001). `Invoke-BackupPromotion` then copies it into `daily\<yyyyMMdd>` if today's daily doesn't exist yet. On a Sunday it also copies it into `weekly\<yyyyMMdd>`, and on the 1st into `monthly\<yyyyMM>`, if those don't exist yet.
- `Invoke-RetentionPolicy` deletes folders older than the configured windows, judged by folder creation time. The template defaults are 24 hours, 7 days, 8 weeks and 12 months (`config.json.template`, `Backup.Retention`).

## Consequences

- At steady state there are about 96 hourly copies, each a full copy (ADR 0001).
- Each tier's copy is the first successful run of its period. If the midnight run fails, that day's daily is a later copy.
- The schedule lives in Task Scheduler, outside the repo, set up by hand per `docs/runbooks/setup-scheduler.md`. The 15-minute interval is not in `config.json`.
