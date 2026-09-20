# 2026-09-20 — Recording retention audit

## Outcome and evidence

Ryan observed `.leap` shrinking from about 9 MB to 7 MB and empty session folders. A read-only audit found 11 sessions, 589 records (sequence 1–589), 40 nonempty interaction IDs and 82 snapshots. SQLite `PRAGMA quick_check` returned `ok`. All eleven session folders are empty; observations and event payloads are stored in the shared `.leap/leap.db`, not JSON files in those folders.

Compared complete record tuples (seq, session, interaction, kind, wall, monotonic, payload) against four older local-only backups:

| Local-only artifact under artifacts/test-runs/ | Rows compared | Missing | Changed |
|---|---:|---:|---:|
| 20260920-integrated-fixes/native-evidence.db | 395 | 0 | 0 |
| 20260920-recording-checks/native-evidence.db | 285 | 0 | 0 |
| 20260920-insights/native-evidence.db | 341 | 0 | 0 |
| 20260920-recording-query-fix/native-evidence.db | 85 | 0 | 0 |

These overlap; counts are not additive. All earlier records in these backups remain unchanged. Historical snapshots 9, 370, 380, 484, 506, 560, 572, 582 and 584 remain present. This establishes retention of these records, not completeness of every possible application event.

## Rationale and alternatives

Recording.swift opens the existing database, creates tables only for an empty store, inserts a UUID per attachment and appends records. Reopening marks unfinished sessions interrupted; stopping marks a session ended. Neither deletes history. The 256 MiB budget stops capture instead of pruning evidence. Installer replacement targets app/skill directories, not this store.

At inspection, the database was 5,709,824 bytes, WAL 881,712 and SHM 32,768. SQLite WAL checkpoint/reuse can reduce physical storage while retaining logical history; see https://sqlite.org/wal.html. No earlier file-size breakdown exists here to prove the exact cause of the reported size decrease. Do not describe that explanation as confirmed.

A shared database keyed by session and interaction supports the desired persistent history without separate databases. Current session lifecycle is per application recording attachment, however, not a named logical campaign spanning app attachments or restarts. Simulator windows share an application recorder. A logical campaign/group identifier with separate capture epochs would better support feature tests across apps without claiming continuous observation through restart. This remains planned, not implemented.

## Changes

Documentation only: record retention evidence and track logical session grouping/storage discoverability. No initialization, clearing, checkpoint, vacuum, or migration was requested or performed in this audit. Empty directories currently reserve asset space; materialized assets are separate from inline database payloads. Recordings are not the agent conversation transcript or all application internals.

## Validation and delivery

Used Python sqlite3 connections with `file:...?...mode=ro` (URI mode), SELECT counts/grouping, `PRAGMA quick_check`, and per-sequence tuple comparisons against read-only backup connections. Source inspection covered initialization, attach, append, finish, budget handling and installer paths. This is retained-store/source evidence, not new native interaction acceptance.

No binary or skill behavior changed; no build/install or restart needed for this audit. Installed candidate remains SHA-256 beb4b0b373f57b352c08f9cca50df423d35178c26853bbba28749239eb317e73, with timeline/delta native acceptance still pending the restart checkpoint.

## Remaining work

Expose clearer session/storage summaries and implement named logical grouping independently of per-app capture epochs. Preserve old session/interaction references. Verify timeline discovery excludes records with empty interaction IDs (unassociated observer/lifecycle records); these should remain accessible through event queries. Next native acceptance remains the historical timeline/delta queries and reversible iPad toggle documented in SESSION-CONTINUATION.md.
