# Handoff 0.1.2 release notes

Release target: `v0.1.2` from the reviewed `main` commit.

Handoff 0.1.2 refreshes the plugin interface while preserving its local-first
scope and version-1 persisted-data format.

## Included

- Add the Omaforge app icon and branded Handoff header.
- Clarify pinned-project, project-detail, note, and action sections.
- Improve clean, dirty, branch, selection, and local-only status treatments.
- Add a scrollable panel layout for constrained displays.
- Add Ctrl+S note saving and an in-panel 500-character note limit and counter.
- Align the title at a fixed four-unit margin beside the logo.
- Add owner-project catalog metadata and public repository installation docs.

## Privacy and security

Handoff remains local-first. It has no server, account, API key, telemetry,
analytics, or required network access. This release does not change process
invocations, project inspection, persistence, or the version-1 data format.

## Compatibility and verification

The candidate targets Omarchy 4 manifest schema 1. Official plugin validation,
Forge checks, isolated ready/empty/error runtime states, QML formatting, and
repository whitespace checks pass. The refreshed ready-state preview contains
fictional project data only.
