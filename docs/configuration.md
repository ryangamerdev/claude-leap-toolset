# Leap configuration

Settings live at `~/.config/leap/leap.json`:

```json
{
  "logging": {
    "level": "info"
  }
}
```

Supported levels: `debug`, `info`, `warning`, `error`. The default is `info`. Debug includes argument names, never argument values. Warning/error levels omit lower-severity events from disk, so an absent event is not proof that no action occurred. Unexpected warning responses remain visible even when their event was excluded by configuration. Restart the MCP after changes. Invalid configuration blocks dispatch with an explicit error; it is not silently ignored.

Diagnostics live in `~/.leap/logs/diagnostics.db` with SQLite WAL companions. Use `diagnostic_query` for bounded pages, filtering by interaction, recording session, severity (`issues` combines warnings/errors), or event kind. The log persists across MCP restarts independently of project `.leap/leap.db` UI recordings. Details are capped; error text may contain application content. No automatic pruning is implemented.

Installer creates the default file only if absent and preserves user settings. A diagnostic write failure before an input attempt prevents dispatch. A failure after dispatch is reported without replaying input. Optional low-level AX probes are summarized by capture-quality diagnostics, not exhaustively traced individually.
