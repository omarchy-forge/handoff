# Handoff 0.2.0 release notes

Release target: `v0.2.0` from the reviewed `main` commit.

Handoff 0.2.0 renames the plugin identifier from `org.omarchyforge.handoff` to
`omaforge.handoff`. This is a breaking identity change and the only change in
this release. Local-first scope, runtime behavior, and the version-1
persisted-data format are unchanged.

## Included

- Set the manifest `id` to `omaforge.handoff`.
- Update the panel `moduleName` and `ipcTarget` to the new identifier.
- Update the demo harness shell invocations to the new identifier.
- Update the manifest identity assertion in the plugin checks.
- Update the documented update and removal commands.

## Upgrading

An installation of 0.1.2 or earlier is registered under the previous
identifier and is not migrated automatically:

```bash
omarchy plugin remove org.omarchyforge.handoff
omarchy plugin add omaforge.handoff
```

The bar widget must be placed again after reinstalling.

Saved projects and notes are preserved. State remains at
`$XDG_DATA_HOME/omarchy-handoff/state.json` in the version-1 format, which has
never been keyed to the plugin identifier. Removing the previous installation
does not delete that file.

## Privacy and security

Handoff remains local-first. It has no server, account, API key, telemetry,
analytics, or required network access. This release does not change process
invocations, project inspection, persistence, or the version-1 data format.

## Compatibility and verification

The candidate targets Omarchy 4 manifest schema 1. Official plugin validation,
Forge checks, and repository whitespace checks pass. Because the identifier is
the shell IPC target, the live install, visual, remove, and restore procedure
must be repeated before publication.
