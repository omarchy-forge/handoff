# Handoff 0.1.0 release notes

Status: final release candidate; not released.

Handoff 0.1.0 is the first local-first project handoff widget for Omarchy 4.

## Highlights

- Pin reviewed local Git projects from the native Omarchy bar panel.
- Save one focused next-step note per project.
- See branch, clean/dirty state, latest commit subject, and timestamps.
- Open the selected project in the configured terminal.
- Keep all Handoff state in an atomically written XDG-local JSON file.
- Exercise ready, empty, and error UI states with fictional in-memory demos.

## Privacy and security

- No account, server, API key, telemetry, analytics, or required network access.
- Project paths are passed as discrete process arguments, never interpolated
  into a shell command.
- Git hooks and filesystem monitors are disabled during metadata inspection.
- Handoff does not execute project builds, scripts, hooks, or QML.
- The state file may contain sensitive paths and notes; it is never uploaded by
  Handoff.

## Compatibility

The candidate targets Omarchy 4, manifest schema 1, and the verified
bar-widget contract. It requires Git and `xdg-terminal-exec`.

## Verification evidence

- Official `omarchy plugin validate` passed.
- Omarchy Forge reported no findings.
- Private GitHub CI passed.
- Isolated Quickshell first-run, persistence, Git metadata, and opened-panel
  harnesses passed.
- A hostile-fixture test configured an external Git filesystem monitor;
  Handoff read the project metadata without executing that program.
- A controlled live Omarchy 4 session verified ready, empty, error, refresh,
  close, and cleanup behavior.
- The live installation was removed, its test data deleted, `shell.json`
  restored byte-for-byte, and shell health confirmed afterward.

## Known limits

- Projects are pinned by path; Handoff does not scan the filesystem.
- There is one current note per project, with no history or synchronization.
- Handoff opens a terminal but does not launch an editor or coding agent.
- Version 0.1.0 has not been submitted to an Omarchy marketplace.
