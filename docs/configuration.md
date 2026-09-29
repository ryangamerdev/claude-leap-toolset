# Leap configuration

Settings live at `~/.config/leap/leap.json`:

```json
{
  "logging": {
    "level": "info"
  },
  "insights": {
    "enabled": true
  }
}
```

`insights.enabled` (boolean, default true) controls automatic AX recording, post-action scans and
deltas, scroll analysis and failure captures. When false, explicit observations, checks and captures
still run. It must be a boolean; any other value blocks dispatch.

Responses include a `Diagnostics:` line only for warnings that add information (capture failures,
recovery, fallbacks). Events that restate the returned error or the action's route are stored but not
repeated in the response.

Supported levels: `debug`, `info`, `warning`, `error`. The default is `info`. Debug includes argument names, never argument values. Warning/error levels omit lower-severity events from disk, so an absent event is not proof that no action occurred. Unexpected warning responses remain visible even when their event was excluded by configuration. Restart the MCP after changes. Invalid configuration blocks dispatch with an explicit error; it is not silently ignored.

Diagnostics live in `~/.leap/logs/diagnostics.db` with SQLite WAL companions. Use `diagnostic_query` for bounded pages, filtering by interaction, recording session, severity (`issues` combines warnings/errors), or event kind. The log persists across MCP restarts independently of project `.leap/leap.db` UI recordings. Details are capped; error text may contain application content. No automatic pruning is implemented.

Installer creates the default file only if absent and preserves user settings. A diagnostic write failure before an input attempt prevents dispatch. A failure after dispatch is reported without replaying input. Optional low-level AX probes are summarized by capture-quality diagnostics, not exhaustively traced individually.
