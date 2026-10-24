---
phase: end-to-end-lifetime-security-guidance-proof
plan: "11"
subsystem: testing
tags: [elixir, postgres, oauth, dynamic-registration, client-lifetimes, documentation]
requires:
  - phase: 162
    provides: Normative lifetime semantics and upgrade contract
  - phase: 166-08
    provides: Executed packaged PostgreSQL adapter example
  - phase: 166-10
    provides: Sanitized nine-scenario receipt aggregation and CI artifact contract
provides:
  - Evidence-aligned adopter, operator, architecture, onboarding, and supported-surface guidance for independent lifetimes
  - Copyable host-test instructions for the exact package-shipped ExUnit/Ecto example
  - Contract tests for public selectors, truthful package evidence, expiry distinctions, and host-session boundaries
affects: [DCR-19, operator-guidance, onboarding, supported-surface, phase166-12]
actuals:
  tokens: 5401.25
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns:
    - Keep adopter-run example instructions separate from maintainer checkout suites and scripts
    - State storage support only for the named adapter composition exercised with shared PostgreSQL authority
key-files:
  created: []
  modified:
    - docs/upgrading/client-lifetimes.md
    - docs/dynamic-registration.md
    - docs/architecture.md
    - docs/operator-admin.md
    - docs/supported-surface.md
    - docs/install-and-onboard.md
    - test/lockspire/client_lifetime_guidance_test.exs
key-decisions:
  - "Name only the existing :client_store and :transaction_store selectors and the delegated PostgreSQL composition established by packaged proof."
  - "Keep the package example copyable as an adopter test while identifying internal repository helpers as test setup, not adapter APIs."
  - "Keep final-candidate CI and independent security review pending; local package receipts do not close those gates."
patterns-established:
  - "Describe app, shared-secret, and app management-token expiry as independent issuance snapshots with distinct renewal events."
  - "Use PRODUCT.md operator vocabulary and keep lifecycle storage internals in maintainer upgrade guidance."
requirements-completed: [DCR-19]
coverage:
  - id: D1
    description: "Adopter and maintainer storage guidance names the proven composition, explains cutover and legacy limits, and links the executed package example."
    requirement: DCR-19
    verification:
      - kind: unit
        ref: "test/lockspire/client_lifetime_guidance_test.exs#adopter storage guidance names only the executed public composition and example"
        status: pass
    human_judgment: false
  - id: D2
    description: "Operator, onboarding, and supported-surface guidance distinguishes expiry, disablement, online checks, and host sessions without changing admin UI behavior."
    requirement: DCR-19
    verification:
      - kind: unit
        ref: "test/lockspire/client_lifetime_guidance_test.exs; test/lockspire/web/live/admin/vocabulary_contract_test.exs; test/lockspire/release_readiness_contract_test.exs"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-10-22
status: complete
commits: 3
plan_head_before: d08f87c82507a3d937ed7dbe0fda39bd545c4c3a
plan_head_after: a8e86ae63e72cc68b9342a8c57253d9f6b8722da
---

# Phase 166 Plan 11: Lifetime Security Guidance Summary

**Independent expiry rules and bounded adapter support are documented with the exact executed host example and honest final-proof limits.**

## Performance

- **Duration:** 4 minutes.
- **Started:** 2026-10-22T03:30:34Z.
- **Completed:** 2026-10-22T03:34:24Z.
- **Tasks:** 2.
- **Files modified:** 7.

## Accomplishments

- Documented `nil`/zero unlimited policy, positive-duration snapshots, and the distinct events that renew shared-secret and management-token lifetimes. App expiry has no renewal event.
- Linked the exact Markdown ExUnit/Ecto example executed from the candidate package, named the existing public storage selectors, and limited the support claim to the demonstrated shared-PostgreSQL delegating composition.
- Labeled repository `test/` and `scripts/` commands as maintainer checkout tooling, and clarified legacy grandfathering, whole-row promotion, old-writer drain, and retained-state rollback limits.
- Aligned operator, onboarding, architecture, and canonical support guidance while preserving existing admin UI tasks and vocabulary.
- Recorded the prior local nine-scenario package partition as 49 executed, 49 passed, 0 failed, and 0 skipped, bound to observed source revision `8050a398`; archive and extracted-tree identity were checked against commit `5709092d`. The broader canonical matrix failures, final-candidate CI run, and independent security review remain pending and are not represented as passing.

## Task Commits

1. **Task 1: Publish verified configuration/storage/migration and adapter instructions** — `a597802a` (`docs`).
2. **Task 2: Align operator/support and installation guidance with verified jobs** — `c15aa241` (`docs`).
3. **Task 2 wording correction:** `a8e86ae6` (`docs`), clarifying where sanitized maintainer receipt identity is retained.

**Plan metadata:** summary committed separately after the task commits.

## Verification

- `mix test.setup` with the inherited Elixir/OTP and test database environment — storage already existed; migrations were current.
- Task 1 guidance command — 7 tests, 0 failures.
- Task 2 guidance, vocabulary, and release-readiness command — 11 tests, 0 failures.
- `git diff --check` — passed.
- The plan did not rerun the broad canonical matrix, final-candidate CI, or independent security review; those remain assigned to Plan 12.

## Files Created/Modified

- `docs/upgrading/client-lifetimes.md` — migration, adapter composition, copyable test, recovery, and rollback guidance.
- `docs/dynamic-registration.md` — lifetime policy and renewal behavior.
- `docs/architecture.md` — bounded public storage composition.
- `docs/operator-admin.md` — distinct expiry and disabled states, preserving host session ownership.
- `docs/supported-surface.md` — canonical lifetime and offline-token limits.
- `docs/install-and-onboard.md` — onboarding link to the lifetime upgrade contract.
- `test/lockspire/client_lifetime_guidance_test.exs` — focused cross-document contract assertions.

## Decisions Made

- The documented host-storage support claim is limited to the named adapter composition that delegates through the built-in Ecto repository under shared PostgreSQL transaction authority.
- The example's internal repository calls are identified as test setup and observation helpers, not host adapter APIs.
- No admin UI copy, controls, confirmation flows, or vocabulary-map entries changed.

## Deviations from Plan

None. The final wording correction was committed separately because the initially committed sentence pointed to a maintainer evidence record without a package-available link.

## Issues Encountered

- New contract assertions initially assumed an exact phrase across wrapped documentation lines. The assertions were corrected to normalize whitespace and match the implemented wording; the targeted suites then passed.
- Parent-owned `.planning/STATE.md`, `.planning/state.json`, and `.planning/ROADMAP.md` already had uncommitted changes when execution began. They were preserved and were not staged or updated.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 11 guidance is complete and DCR-19 documentation contracts pass. Phase 166 remains in progress; Plan 12 must investigate the existing broad-matrix failures, rerun final-candidate required CI, and obtain the scoped independent security review before the lifetime umbrella can close.

---
*Phase: end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-22*

## Self-Check: PASSED

- The Plan 11 summary exists.
- Task commits `a597802a`, `c15aa241`, and `a8e86ae6` are ancestors of `HEAD`.
