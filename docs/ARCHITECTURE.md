# Architecture

Handoff is one Omarchy `bar-widget` plugin. `Panel.qml` owns presentation and
terminal launch behavior; `services/DataService.qml` owns persistence, Git
metadata, selection, and demo state.

## Data model

The version-1 state file contains a `projects` array. Each record stores:

- canonical Git worktree path and display name;
- one next-step note;
- branch and clean/dirty state;
- latest commit hash, subject, and commit time;
- added and last-checked timestamps.

The file lives at `$XDG_DATA_HOME/omarchy-handoff/state.json`, falling back to
`~/.local/share/omarchy-handoff/state.json`. Quickshell `FileView` performs
atomic writes. Invalid JSON produces a visible error and is not overwritten.

## Process boundary

Handoff invokes only:

- `mkdir -p <data-directory>` for its own XDG data directory;
- `git -C <path> rev-parse --show-toplevel` to validate and canonicalize a
  project;
- `git -C <path> status --porcelain=v2 --branch` for branch and dirty state;
- `git -C <path> log -1 ...` for latest commit metadata;
- `xdg-terminal-exec --dir=<path>` when the user explicitly opens a project.

Every command uses a QML argument array. Project paths are never interpolated
into a shell program. Every Git invocation also sets
`core.hooksPath=/dev/null` and `core.fsmonitor=false`, preventing repository or
user configuration from turning status inspection into external hook or
filesystem-monitor execution. Handoff does not execute repository builds,
scripts, or QML and does not inspect remotes.

## Runtime behavior

Git refreshes are serialized to avoid simultaneous processes and out-of-order
updates. Records are cloned before mutation so QML bindings observe changes.
The state file is written after user mutations and after a refresh queue
completes.

Demo states are in-memory and suppress persistence and Git refreshes. They are
safe to use against an installed development checkout without changing saved
Handoff data.

## Deliberate limits

- Projects are pinned by path; broad filesystem scanning is out of scope.
- There is one note per project, not a task manager or history feed.
- State is local; sync, accounts, and hosted storage are out of scope.
- Handoff opens a terminal but does not start an editor, agent, or project
  command.
