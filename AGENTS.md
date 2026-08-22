# Agent guidance

- Read `README.md`, `SECURITY.md`, and the Omarchy Forge compatibility evidence
  before changing plugin contracts.
- Inspect installed Omarchy source instead of assuming QML or manifest APIs.
- Never edit `/usr/share/omarchy`, user plugin installations, or
  `~/.config/omarchy/shell.json` while developing this repository.
- Keep Handoff local-first and functional without network access.
- Do not add telemetry, analytics, accounts, authentication, databases,
  package installation, privilege elevation, or hosted execution.
- Pass paths as array-form process arguments; never interpolate them into shell
  commands.
- Never execute pinned-project code, hooks, build scripts, or QML.
- Add tests for behavior and run official validation plus Forge checks.
- Do not push, publish, release, deploy, change visibility, install the plugin,
  or announce it without explicit user approval.
- Treat release notes and checks as preparation only. Never create or push a
  tag or GitHub release without approval for the exact version and commit.
