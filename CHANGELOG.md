# Changelog

## Unreleased

## [0.1.1] - 2026-08-22

- Adopt Forge `v0.2.0` isolated runtime, fictional-state, plugin-only
  screenshot, and watch development contracts without changing live behavior.
- Pin private CI to the public Forge `v0.2.0` Action and CLI release.

## [0.1.0] - 2026-08-22

- Add the local-first Handoff MVP for pinned Git projects and next-step notes.
- Persist project context atomically in the user's XDG data directory.
- Open selected projects in a terminal without shell interpolation.
- Treat a missing state file as a clean first run while preserving malformed
  nonempty data for recovery.
- Add a reviewed panel-only preview using fictional project data.
- Disable Git hooks and filesystem monitors during project inspection.
