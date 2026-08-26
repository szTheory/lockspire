---
phase: 131-executable-installation
plan: "07"
subsystem: generated-consent-liveview
tags: [phoenix, liveview, oauth, oidc, consent, installer, security]
requires:
  - phase: 131-03
    provides: generated host consent route, safe ConsentContext, and approval-to-token proof
provides:
  - a non-interactive initial consent loading render
  - asynchronous authoritative consent resolution using the existing ConsentContext boundary
  - generated-host coverage for loading, resolved, error, terminal, and submission states
affects: [phase-131, install-dx, oauth-authorization-flow]
tech-stack:
  added: []
  patterns:
    - snapshot only host assigns and connect info during mount before deferred resolver work
    - consume tagged async results into allowlisted consent UI states
key-files:
  created: []
  modified:
    - priv/templates/lockspire.install/consent_live.ex
    - test/support/generated_host_app_web/live/lockspire_consent_live.ex
    - test/integration/install_generator_test.exs
    - test/integration/phase6_onboarding_e2e_test.exs
key-decisions:
  - "The static consent render is always a host-styled status and never queries or exposes protocol context."
  - "Deferred resolver work receives only mount-time server-owned assigns and connect info, avoiding a copied LiveView socket while preserving host account resolution."
requirements-completed: [INST-02]
completed: 2026-08-26
status: complete
---

# Phase 131 Plan 07: Generated Consent Loading Summary

**The installed host consent page now renders a safe, semantic loading state before resolving its authoritative review context, while preserving the existing controller completion flow.**

## Accomplishments

- Deferred `ConsentContext.load/2` until the LiveView is connected; the disconnected response has `role="status"` and no decision controls or protocol-derived facts.
- Consumed successful, terminal redirect, stable error, unexpected result, and task-exit outcomes without exposing task reasons, redirects, interaction identifiers, account data, or other protocol state.
- Kept installer-template and executable-fixture bytes identical and expanded real generated-host coverage through empty, error, redirect, submission, and token-exchange states.

## Task Commits

1. **Task 1: Render loading first, then resolve one real consent review**
   - `b1c74e8` `test(131-07): specify safe generated consent loading`
   - `78c750e` `feat(131-07): defer generated consent context loading`
2. **Task 2: Lock down safe loading, error, terminal, empty, and submission transitions**
   - `727272b` `test(131-07): cover deferred consent terminal states`

## Verification

- `mix test test/integration/install_generator_test.exs` — passed (12 tests).
- `mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` — passed (3 tests).
- `mix test.fast` — passed.
- `mix qa` — passed: formatting, warnings-as-errors compilation, Credo, and Sobelow.
- `git diff --exit-code -- lib/lockspire/web/consent_context.ex` — passed; the authoritative context contract is unchanged.

## ASVS High-Severity Evidence

- **V4 / T-131-25 and T-131-27:** the generated-host integration test proves static and connected loading are control-free; only the resolved valid context reaches the native approval-to-token flow.
- **V7 / T-131-26:** generated-host error and task-exit coverage seeds sensitive interaction, subject, and redirect values and asserts they never reach rendered HTML.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - LiveView mount-context lifetime] Preserve mount-only resolver data for deferred loading**

- **Found during:** Task 1
- **Issue:** Passing the full socket to `start_async/3` triggers a LiveView socket-copy warning; reconstructing a socket with assigns alone breaks host resolvers that read mount-only connect info.
- **Fix:** Snapshot only the server-owned assigns and `connect_info` during `mount/3`, then reconstruct the narrow resolver context inside the deferred task.
- **Files modified:** `priv/templates/lockspire.install/consent_live.ex`, `test/support/generated_host_app_web/live/lockspire_consent_live.ex`
- **Verification:** real generated-host async resolution, submit, and token exchange pass with no new compile warning.
- **Commit:** `78c750e`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Self-Check: PASSED

- The installer template, executable fixture, and generated-host integration tests exist and are covered by the targeted suites.
- Task commits `b1c74e8`, `78c750e`, and `727272b` exist in git history.
