# Handoff 0.1.1 release notes

Release target: `v0.1.1` from the reviewed private `main` commit.

Handoff 0.1.1 is a development-tooling maintenance release with no change to
the plugin's user-facing product scope or persisted-data format.

## Included

- Adopt the Forge `v0.2.0` isolated Quickshell runtime harness.
- Exercise fictional ready, empty, and error states without installation or
  saved-data writes.
- Declare the panel-only Qt Quick screenshot target used by Forge capture.
- Support fresh isolated reruns through `omaforge dev --watch`.
- Pin private CI to the public Forge `v0.2.0` Action and CLI release.

## Privacy and security

Handoff remains local-first and private. It has no server, account, API key,
telemetry, analytics, or required network access. Runtime development commands
require explicit trust, use temporary HOME/XDG paths, and do not connect to the
live Omarchy Shell. Screenshot capture renders only the declared panel item and
cannot capture the desktop.

## Compatibility and verification

The candidate targets Omarchy 4 manifest schema 1. Official validation and
Forge checks passed. Ready, empty, and error states and a panel-only screenshot
passed in the isolated Quickshell runtime. Private CI passed with Forge
`v0.2.0`.

An independent exact-tag clone was installed with the official Omarchy plugin
command, exercised in ready, empty, and error states, and removed. Test data
was deleted, `shell.json` was restored byte-for-byte (SHA-256
`802fa2600cac1cd2971c48769661432a8f30eb5beb2eadb63f0356a913172f9f`),
and shell IPC returned `ok` afterward.

The repository remains private. This release does not submit Handoff to a
marketplace, announce it publicly, or authorize ongoing installation.
