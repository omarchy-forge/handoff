# Security policy

Report suspected vulnerabilities privately through GitHub's security reporting
for `omarchy-forge/handoff`. Do not include secrets or private project notes in
a public issue.

## Trust boundaries

Omarchy plugins run unsandboxed in the user's long-lived shell process. Review
the source and its Git history before enabling Handoff.

Handoff reads Git metadata for paths the user explicitly pins and stores its
own local JSON record. It does not execute repository hooks, builds, scripts,
or project QML; modify project files; alter Omarchy configuration; install
packages; use privilege elevation; or require network access.

The project path is passed as one argument to `git -C` and to
`xdg-terminal-exec --dir`. It is never interpolated into a shell command. Git
commands override `core.hooksPath` with `/dev/null` and disable
`core.fsmonitor`, preventing project or user configuration from causing an
external hook or filesystem-monitor command during inspection.

The state file can contain sensitive project paths and notes. It belongs under
the user's XDG data directory and must not be uploaded automatically.
