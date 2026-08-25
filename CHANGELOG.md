# Changelog

## [0.2.0] - 2026-08-25

- Rename the plugin identifier from `org.omarchyforge.handoff` to
  `omaforge.handoff`. This is a breaking change: an existing installation must
  be removed and reinstalled under the new identifier, and the bar widget must
  be placed again.
- Saved projects and notes are unaffected. State remains at
  `$XDG_DATA_HOME/omarchy-handoff/state.json` in the version-1 format, which
  has never been keyed to the plugin identifier.

## [0.1.2] - 2026-08-24

- Add owner-project catalog metadata and document installation from the public
  Omarchy Forge repository.
- Refresh the panel with Omaforge branding, clearer project and action sections,
  improved status treatments, and a responsive scrollable layout.
- Add keyboard save support, enforce the 500-character note limit in the UI,
  and show the remaining note length.
- Keep the Handoff title precisely aligned beside the app logo across scaled
  Omarchy layouts.

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
