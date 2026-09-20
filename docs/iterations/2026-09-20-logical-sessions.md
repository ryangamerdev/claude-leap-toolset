# 2026-09-20 — Named logical sessions and discoverable retention

## Outcome and evidence

Ryan asked to resolve the session-management gaps before the next install/restart. The retention audit proved earlier records remain, but empty asset directories obscured where the data lived and capture sessions could not represent a named multi-app task across restarts. The loaded MCP connection does not expose the prior candidate's interaction_timeline/interaction_delta tools, so native acceptance remains pending; no new application input was sent this iteration.

## Rationale and alternatives

Keep existing session/interaction/snapshot IDs stable. Add a named grouping above application capture epochs rather than redefining old session IDs or reusing accessibility handles after restart. Explicit resume selects a group after restart; a new capture epoch records the new observed interval. Switching groups closes existing app captures and leaves earlier membership intact. This avoids retrospectively attributing old inputs to a new task. Stopped apps stay suppressed until recording_start. End closes grouping, not automatic project recording; subsequent captures are ungrouped. Existing history remains ungrouped.

A bounded discovery tool exposes counts and storage rather than generating redundant JSON copies. WAL size is not a logical record count. Empty interaction strings are how unassociated observer records were stored; filtering only SQL NULL produced spurious timeline entries. Exclude both forms from the timeline and retain them in event queries.

## Changes

- recording_group(action: start/resume/end, name/group_id) manages logical tasks after project binding. Group IDs are separate from existing per-app session IDs. Valid transitions close current captures; invalid resume leaves them alone. No application input is dispatched.
- recording_sessions(view: groups/recordings, group_id, after, limit) lists at most 20 items with timestamps, member/record/interaction/snapshot counts and database/WAL/SHM sizes. Queries do not initialize stores. Existing v1 stores remain readable for ungrouped discovery.
- interaction_timeline accepts group_id across captures and excludes empty/unassociated interaction IDs. Each record still retains its original session/interaction identity.
- Additive transactional schema v1→v2 adds group and membership tables. Old rows/payloads stay intact; app-session membership insertion is transactional. Older binaries refuse v2 writers rather than silently ignoring the schema. No automatic destructive downgrade; retain a pre-migration local backup.
- Action summaries and observation footers include the active group when selected. Skill/server instructions explain discovery, explicit resume and capture gaps; no new native pass is claimed.
- Installer now parses options before mutations. During this iteration, invoking the old install.py --help unexpectedly reinstalled the existing dist bundle and refreshed the same leap registration. That behavior is recorded rather than hidden. Help, unknown options and conflicting modes now exit without installation/removal/registration side effects. Final development install uses a staged signed bundle and unchanged registration.

## Validation and delivery

Seven focused Swift tests passed: EvidenceTests and RecordingGroupTests. New cases verify v1 migration preserves exact prior payload, interruption marking, explicit resume across store reopening, separate cross-app capture IDs, end→ungrouped capture, grouped timeline filtering, summary pagination and retained unassociated events. These use ignored repo-local fixture stores, not the live MCP. Installer tests mock all mutation entrypoints and verify help/unknown/conflicting arguments invoke none. Skill validator passed.

Commands: TOOLCHAINS=org.swift.640202609131a swift test --filter 'EvidenceTests|RecordingGroupTests'; python3 scripts/test-install-options.py; python3 scripts/bundle.py; python3 scripts/install.py --skills-only. Local logs/fixtures: artifacts/test-runs/20260920-timeline-filter/. Tracked install metadata and validation summary will record final identity. Build/install is not native acceptance.

## Remaining work

After restart, recording_sessions must show the existing 11 captures and 589 records before any new app reads. Bind to migrate additively, start a named Simulator acceptance group, read the iPad and iPhone to establish separate observed data under the group (both are one Simulator process), then inspect group members and timeline. Verify historical deltas for 2ED5EA8E-0C89-4A74-92F8-932D6B328A7C and E0224AF5-A319-4CB9-B591-3B1B48DC4B03; perform and restore a reversible iPad view toggle and inspect the automatic delta. A subsequent restart must resume the same group with a new capture epoch and retained history. Native group lifecycle, fresh schemas and automatic delta acceptance remain pending. Session discovery has live counts rather than a frozen inventory snapshot. Logical grouping does not relax cross-epoch UI diff identity restrictions. Temporal predicates, controlled retained-earlier timeout coverage and paired Blender construction remain separate unfinished acceptance work.

## Delivery result

Signed release installed: SHA-256 `444130a908e54dff63cb2a618a60bde37c75121fc33713da4334e98ecf8521db`. [Install metadata](../../artifacts/test-runs/20260920-timeline-filter/install.json). Local-only rollback app and pre-migration SQLite backup are recorded there. Live store remains schema 1, 11 sessions and 589 records before restart. Skills-only refresh completed and all installed skill files match source. Registration remains leap. Native group/timeline/delta verification requires session restart.
