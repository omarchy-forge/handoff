# Handoff project memory

Last updated: August 26, 2026

## Current status

Handoff's add-project workflow has been repaired and clarified on the
`fix/pin-persistence` branch. Newly added Git projects remain visible, invalid
input remains available for correction, and the panel now explains that
Handoff remembers Git context and one human next step so users can resume work.

The implementation commit is `fa5463d` (`fix: keep added projects visible`) and
is pushed to `origin/fix/pin-persistence`. It has not been merged, tagged, or
released. Open the review at:

`https://github.com/omarchy-forge/handoff/pull/new/fix/pin-persistence`

## Repository and installation

- Working repository: `/home/eddieor/omaforge-handoff`
- GitHub repository: `https://github.com/omarchy-forge/handoff`
- Working branch: `fix/pin-persistence`
- Base branch: `main`
- Current reviewed release: `v0.2.0`
- Plugin ID: `omaforge.handoff`
- Installed test copy: `~/.config/omarchy/plugins/omaforge.handoff`

The plugin is installed and enabled in the right bar section. Because the
official installer clones committed Git content, the test installation was
created through the official `omarchy plugin add` flow from a temporary local
Git snapshot containing the reviewed working-tree changes. The installed QML
and service files were verified to contain the fix and revised interface copy.

## Implemented changes

- Gate state hydration until the XDG data directory is ready and accept it only
  once, preventing late `FileView` startup callbacks from replacing live state.
- Clear the project-path field only after successful Git validation or when an
  already-saved project is selected.
- Track refresh work by canonical project path instead of mutable list index,
  preventing an unpin during refresh from updating the wrong project.
- Reject relative paths while continuing to accept absolute and `~/` paths.
- Treat unsupported state formats as errors without overwriting the source.
- Surface state-file save failures while retaining current in-memory data.
- Show a disabled `Checking…` state during project validation.
- Replace Pin/Unpin wording with Add project/Remove and explain the resume-work
  purpose directly in the panel and README.
- Use the active theme accent for clean/available project status.
- Add isolated runtime coverage that adds a real Git working tree and verifies
  the project remains visible.

The version-1 state format and storage location remain unchanged.

## Verification checkpoint

The following passed before commit and push:

```sh
./tests/run
./tests/runtime --trust-plugin-code --state ready
./tests/runtime --trust-plugin-code --state empty
./tests/runtime --trust-plugin-code --state error
./tests/runtime --trust-plugin-code --pin-path /home/eddieor/omaforge-handoff
omaforge check .
git diff --check
```

The updated ready-state panel was also rendered and visually inspected in the
isolated screenshot harness. Forge reported 0 errors and two existing `OF304`
warnings for the intentional hard-coded Omaforge orange and cyan brand colors.

## Product and safety boundaries

- Handoff reads only explicitly added local Git working trees and its own XDG
  state file; it does not scan broadly or modify project files.
- Git inspection disables hooks and filesystem monitors and passes paths as
  array-form process arguments.
- Never execute project code, hooks, builds, scripts, or QML.
- Keep normal operation local-first and functional without network access.
- Do not add telemetry, accounts, authentication, databases, package
  installation, privilege elevation, or hosted execution.
- Do not edit `/usr/share/omarchy`, installed plugin files, or
  `~/.config/omarchy/shell.json` directly during development.
- Do not push, merge, tag, release, publish, deploy, change visibility, or
  announce without the corresponding explicit owner approval.

## Working-tree notes

Two pre-existing untracked images were deliberately excluded from the fix:

- `images/handoff-design.png`
- `images/screenshot-2026-08-24_18-56-22.png`

Treat them as owner files unless their inclusion is explicitly requested.

## Next steps

1. Review and merge `fix/pin-persistence` through the repository's normal pull
   request flow.
2. Perform hands-on testing of Add project, Save note, Remove, refresh, and Open
   terminal using the enabled local test installation.
3. If the branch changes after testing, synchronize the installed copy through
   a new reviewed local snapshot or remove and reinstall it; do not edit the
   installation directly.
4. Prepare a new semantic version and release notes only with explicit approval
   for that version. A merge does not authorize a tag or GitHub release.

## Sources of truth

- `AGENTS.md`: repository workflow and safety boundaries
- `README.md`: user-facing behavior, privacy, and lifecycle
- `SECURITY.md`: trust boundaries and sensitive-data guidance
- `docs/ARCHITECTURE.md`: state model and process boundaries
- `docs/RELEASING.md`: candidate and publication gates
- `Panel.qml`: bar widget and user interface
- `services/DataService.qml`: persistence and Git metadata logic
- `tests/run` and `tests/runtime`: static and isolated runtime checks
- `CHANGELOG.md`: release history and current Unreleased work
