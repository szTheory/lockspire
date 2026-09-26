---
phase: 139-required-truth-reconciliation
plan: "11"
subsystem: testing
tags: [lifecycle, capability-install, finalizer, exact-sha, planning-consistency]
requires:
  - phase: 139-required-truth-reconciliation
    provides: Sealed Phase 139 acceptance and post-transition receipt contracts
provides:
  - Deterministic portable and explicit installed-runtime lifecycle test modes
  - Authenticated post-transition planning-consistency check before ref movement
  - Validation map for repaired lifecycle and acceptance fixture proof
affects: [phase-140-entry-gate, verification, release-hygiene]
actuals:
  tokens: 3652
  tasks: 2
  commits: 2
  plan_head_before: 579f0086b5077ae68997e40224405640ca8a604a
tech-stack:
  added: []
  patterns: [explicit portable-versus-installed fixture selection, fail-closed post-transition test gate]
key-files:
  created:
    - .planning/phases/139-required-truth-reconciliation/139-11-SUMMARY.md
  modified:
    - .gsd-capabilities.json
    - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs
    - scripts/maintainer/finalize_phase_139_acceptance.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/139-required-truth-reconciliation/139-VALIDATION.md
key-decisions:
  - "The tracked host fixture selects portable mode unless GSD_TOOLS is explicitly supplied; explicit GSD_TOOLS selects installed-runtime parity."
  - "Run the planning-consistency test only after host receipt and sealed-relation authentication, and recheck sealed state before any ref movement."
  - "Keep Phase 140 exact-SHA receipt evidence pending until the existing blocking plan:pre boundary observes synchronized main."
requirements-completed: [HYGIENE-06, TRUTH-03, TRUTH-05]
coverage:
  - id: D1
    description: Portable host-contract and installed-capability lifecycle checks use deterministic runtime selection and byte/render parity.
    requirement: HYGIENE-06
    verification:
      - kind: integration
        ref: "LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs — 17 passed, 0 failed, 2 skipped"
        status: pass
      - kind: integration
        ref: "GSD_TOOLS=/Users/jon/.codex/gsd-core/bin/gsd-tools.cjs node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs — 17 passed, 0 failed, 2 skipped"
        status: pass
    human_judgment: false
  - id: D2
    description: The state-dependent planning-consistency command runs only after authenticated plan:pre receipt/relation checks and blocks ref movement while preserving pending recovery state on failure.
    requirement: TRUTH-03
    verification:
      - kind: integration
        ref: "GSD_TOOLS=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-core/bin/gsd-tools.cjs ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 MIX_ENV=test mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase139_final_acceptance --only phase139_acceptance_receipt — 2 passed, 0 failed"
        status: pass
    human_judgment: false
  - id: D3
    description: Installed hook identity remains bounded to the existing execute:post and plan:pre gates, with no publication or Phase 140 exact-SHA gate changes.
    requirement: TRUTH-05
    verification:
      - kind: integration
        ref: "test/support/lockspire/release_proof/package_assertions.ex#sealed candidate advances main through one exact fast-forward — source-order assertion preserves the existing boundary"
        status: pass
      - kind: integration
        ref: "tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs#installed capability renders fresh ordered lifecycle hooks"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-09-25
status: complete
---

# Phase 139 Plan 11: Explicit Lifecycle Modes and Authenticated Planning Proof

**Portable fixture selection is deterministic, installed capability parity refreshes from tracked source, and the post-transition planning proof blocks before ref movement.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-09-26T02:06:00Z
- **Completed:** 2026-09-26T02:24:00Z
- **Tasks:** 2
- **Files modified:** 5 planned artifacts

## Accomplishments

- A tracked `LOCKSPIRE_GSD_HOST_FIXTURE` now selects portable lifecycle coverage even when a global GSD runtime is discoverable; explicitly setting `GSD_TOOLS` selects installed-runtime parity.
- Refreshed the project capability from tracked source through `capability install`; active capability 1.2.0 passed installed byte parity and exact `execute:post` / `plan:pre` hook rendering.
- Added the pinned Phase 139 planning-consistency test after host receipt and sealed-candidate relation authentication, followed by a sealed-state check and before `fast_forward_main`.
- Acceptance fixtures assert exactly one pinned fake `mix` invocation on the authenticated path; forged or missing receipts, wrong lifecycle, and dirty relation cases invoke none. A failing test preserves refs and the pending host receipt.
- Updated the validation proof map without changing the 11 gap IDs or claiming a live synchronized-main receipt or Phase 140 readiness.

## Evidence

- Exact acceptance selectors: 2 tests, 0 failures.
- Portable lifecycle environment: 17 tests passed, 0 failed, 2 existing integration tests skipped.
- Installed-runtime lifecycle environment: 17 tests passed, 0 failed, 2 existing integration tests skipped.
- Shell syntax, workflow lint, and formatting checks passed.
- The actual state-dependent planning-consistency module was not run here: its only runtime entry remains the authenticated Phase 140 `plan:pre` lifecycle after canonical Phase 139 verification and transition.

## Task Commits

1. **Task 1: Make portable and installed lifecycle rendering modes explicit and reproducible** — `1534f735`.
2. **Task 2: Run the post-transition planning proof only behind the authenticated Phase 140 entry gate** — `7dc0559f`.

## Files Created/Modified

- `.gsd-capabilities.json` — records the supported project capability installation.
- `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` — prioritizes explicit fixture mode over automatic global runtime discovery.
- `scripts/maintainer/finalize_phase_139_acceptance.sh` — runs the planning-consistency command after sealed authentication and before ref movement.
- `test/support/lockspire/release_proof/package_assertions.ex` — asserts exact command environment/order and failure recovery semantics.
- `.planning/phases/139-required-truth-reconciliation/139-VALIDATION.md` — records current portable/live evidence and retains external receipt deferral.

## Decisions Made

- Portable fixture mode takes precedence over automatic home-directory runtime discovery; an explicit `GSD_TOOLS` opts into live parity.
- Test failure remains a hard stop before any local or remote main movement, with the host-owned pending receipt retained for recovery.
- Phase 140's exact-SHA receipt remains the only live acceptance boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture correction] Made the missing-receipt case prevent fixture receipt preparation**
- **Found during:** Task 2 verification.
- **Issue:** Removing the receipt alone correctly exercised the production preparation path, which recreated it and allowed the valid path to proceed; this did not test rejection of an unavailable receipt.
- **Fix:** The missing-receipt adversary also removes the fixture state helper, ensuring preparation fails before the planning proof can run. The separate injected fake-test failure verifies exact pending-receipt preservation.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`.
- **Verification:** Exact acceptance selectors passed; the failure matrix observed zero planning-test invocations for the missing-receipt case.
- **Committed in:** `7dc0559f`.

**Total deviations:** 1 auto-fixed (1 Rule 1)
**Impact on plan:** The fixture now represents the intended unavailable-receipt boundary while preserving the supported production preparation behavior.

## Issues Encountered

- The first supported install could not acquire the global GSD consent-store lock, so the capability installed but remained inactive. Retrying the same installer through the approved elevated path recorded consent; the project capability is active at version 1.2.0.
- The orchestrator's temporary `.planning/config.json` worktree setting remains modified and uncommitted; this plan did not stage or edit it.
- Per the user's explicit verification gate, `.planning/STATE.md`, `.planning/state.json`, and roadmap progression were not updated before canonical verification passes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 139 verification must run against the current covered files. Only after that canonical gate passes may the orchestrator reconcile planning state.
- Phase 140 remains blocked by its unchanged exact-SHA `plan:pre` gate until synchronized-main CI/Release evidence and the durable live receipt are authenticated.
- No human UAT, publication, workflow dispatch, ref mutation, or live receipt creation occurred in this plan.

## Self-Check: PASSED

- The summary exists and the GSD summary verifier confirms all declared created files and task commits.
- Task commits `1534f735` and `7dc0559f` exist in Git history.
- `.planning/STATE.md`, `.planning/state.json`, `.planning/ROADMAP.md`, and the orchestrator-owned `.planning/config.json` were not changed by this plan.
