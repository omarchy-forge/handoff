# Changelog

## [0.1.0] - Unreleased

- Add the local-first Handoff MVP for pinned Git projects and next-step notes.
- Persist project context atomically in the user's XDG data directory.
- Open selected projects in a terminal without shell interpolation.
- Treat a missing state file as a clean first run while preserving malformed
  nonempty data for recovery.
- Add a reviewed panel-only preview using fictional project data.
- Disable Git hooks and filesystem monitors during project inspection.
