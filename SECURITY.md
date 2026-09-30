# Security

Leap operates applications on the user's behalf with Accessibility (and optionally Screen
Recording) permission. Treat it like any tool that can type and click for you.

## Model

- Leap runs locally over stdio; it opens no network listener. The optional `wda` backend talks
  to a WebDriverAgent endpoint on localhost that you start yourself.
- Control can be restricted to specific apps with `LEAP_ALLOWED_APPS` (display names, bundle
  ids or paths, comma-separated).
- Evidence stores (`<project>/.leap/`) and diagnostics (`~/.leap/logs/`) can contain
  application content visible in observed windows. They stay local and are excluded from Git.
  Secure text-field values are masked in observations, and recorded action intents omit their
  arguments so typed secrets are not retained.
- An agent driving your apps can take any action you could. Review what you ask it to do, and
  prefer dedicated APIs or CLIs where they exist.

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub's "Report a vulnerability" (Security
Advisories) on this repository rather than in a public issue. Include steps to reproduce and
the affected version or commit.
