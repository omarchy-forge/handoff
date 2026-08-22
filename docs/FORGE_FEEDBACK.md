# Omarchy Forge dogfooding feedback

Handoff was bootstrapped with the Forge bar-widget template on 2026-08-22.
The exercise confirmed that the generated manifest, theme-aware panel shell,
demo IPC, official validation, and publish-readiness checks provide a useful
starting point.

It also exposed these follow-up opportunities for Forge:

1. `omaforge init` treats a freshly cloned repository containing only `.git`
   as nonempty. `--force` safely generated Handoff while preserving `.git`, but
   a Git-only directory should likely be accepted without that alarming flag.
2. The template provides a deliberately generic date-backed service. A future
   service-plus-widget template would reduce replacement work for stateful
   plugins such as Handoff.
3. Generated tests validate structure but do not load the entry point in an
   isolated Quickshell runtime. Handoff added that verification manually during
   development; Forge could eventually provide a reusable harness.

These are observations, not shipped Forge behavior. Any Forge changes should
be designed and reviewed in the Forge repository as a separate milestone.
