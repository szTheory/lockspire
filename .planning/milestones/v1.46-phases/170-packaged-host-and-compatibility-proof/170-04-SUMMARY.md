---
phase: 170-packaged-host-and-compatibility-proof
plan: "04"
subsystem: ci-proof
tags: [github-actions, elixir, phoenix, liveview, chrome, receipts]
requires:
  - phase: 170-03
    provides: Exact locked/floor package selection and three-mount browser journeys.
provides:
  - Required locked and floor CI jobs invoke the bounded packaged host proof and upload validated safe receipts.
  - Strict receipt validation and fake-tool regressions cover failed status, timeout, signals, redaction, identity, duration, and safe staging.
affects: [170-05, ci, compatibility-proof]
actuals:
  tokens: 8224
  tasks: 2
  commits: 3
  plan_head_before: 51e98bd56f8a2b25c1718cbd10cfc60367e7e834
  plan_head_after: b20a36d9
tech-stack:
  added: []
  patterns:
    - Bounded pair-specific CI wrapper with independently checked source, package, pair, runtime, and run identities.
    - Artifact staging contains only validated sanitized receipts and lifecycle evidence.
key-files:
  created:
    - scripts/ci/run_host_integration_proof.sh
    - test/lockspire/host_integration_ci_contract_test.exs
    - .planning/phases/170-packaged-host-and-compatibility-proof/170-04-task2-red-evidence.json
  modified:
    - .github/workflows/ci.yml
    - scripts/acceptance/clean_room/admin_receipts.py
    - scripts/acceptance/clean_room_admin_journey.py
    - test/clean_room/test_admin_journey.py
    - test/lockspire/compatibility_baseline_contract_test.exs
key-decisions:
  - Keep existing required job names, triggers, immutable pins, and 30-minute job limits; each proof pair has its own 900-second deadline.
  - Upload only validated safe evidence, while preserving nonzero proof status and requiring artifacts to exist.
  - Report local proof results separately; no remote CI run was dispatched or observed.
patterns-established:
  - Inject fake tools only through the explicit test-mode seam to verify status and timeout propagation.
requirements-completed: [HPROOF-01, HPROOF-02, HPROOF-03]
coverage:
  - id: D1
    description: Existing Integration Checks and Minimum Supported Elixir/OTP jobs run the locked and floor packaged proof.
    requirement: HPROOF-03
    verification:
      - kind: contract
        ref: test/lockspire/host_integration_ci_contract_test.exs (10 focused ExUnit tests passed with baseline contract)
        status: pass
    human_judgment: false
  - id: D2
    description: Each pair emits separate lifecycle and three-mount browser evidence bound to the candidate package.
    requirement: HPROOF-03
    verification:
      - kind: integration
        ref: .artifacts/phase170/ci-locked (43 lifecycle tests; 3 mounts passed in 143s)
        status: pass
      - kind: integration
        ref: .artifacts/phase170/ci-floor (44 lifecycle tests; 3 mounts passed in 141s)
        status: pass
    human_judgment: false
  - id: D3
    description: Failed, stale, coerced, timed-out, signalled, or secret-bearing evidence paths fail closed.
    requirement: HPROOF-03
    verification:
      - kind: unit
        ref: python3 -m unittest discover -s test/clean_room -p test_admin_journey.py (28 passed)
        status: pass
      - kind: lint
        ref: bash scripts/ci/lint_workflows.sh
        status: pass
    human_judgment: false
metrics:
  duration: "~31min"
  completed: 2026-10-24
  commits: 3
  status: complete
---

# Phase 170 Plan 04: Required CI Proof Summary

**Existing required jobs now run the 900-second packaged proof for locked and exact-floor dependency pairs, with safe source-bound receipts and failure-preserving status.**

## Accomplishments

- Added the canonical pair wrapper to the existing Integration Checks (`locked`) and Minimum Supported Elixir/OTP (`floor`) jobs. Preserved job names, triggers, immutable pins, protocol checks, and 30-minute job caps. Artifact uploads require validated files and cannot mask a proof failure.
- Bound lifecycle and browser receipts to independently measured source revision, candidate version/archive/tree hashes, selected pair, runtime, unique run IDs, and mount. Strict validation rejects non-integer, negative, non-finite, and boolean durations; the success CLI rejects a well-formed receipt whose result is `failed`.
- Added a guarded fake-tool test seam covering ordinary exit codes, signals, timeout status, redaction, stale output removal, validator failure, and sanitized successful staging.
- Ran the exact package locally for both pairs. Both used candidate Lockspire `1.6.1`, archive SHA-256 `418060d9b6a786a0272fb02085da3d757100431005a81beb4d74fdd4a4d805cb`, and tree SHA-256 `aa9213a0eb1be4ca98a94f1fb388fe99a388ccdf8ca67c401d3130c89277face`.

## Verification

- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair locked --receipt-dir .artifacts/phase170/ci-locked` — passed in 143 seconds; lifecycle 43 passed; each of `/lockspire`, `/teams/ops/identity`, and `/` passed all 16 cases with successful cleanup. Observed Phoenix 1.8.13 / LiveView 1.2.10, Elixir 1.20.4 / OTP 29, Node 26.10.0, Chrome 155.0.8059.85.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair floor --receipt-dir .artifacts/phase170/ci-floor` — passed in 141 seconds; lifecycle 44 passed; each of the same three mounts passed all 16 cases with successful cleanup. Observed Phoenix 1.8.5 / LiveView 1.1.28, Elixir 1.20.4 / OTP 29, Node 26.10.0, Chrome 155.0.8059.85.
- `python3 -m unittest discover -s test/clean_room -p test_admin_journey.py` — 28 passed.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/host_integration_ci_contract_test.exs test/lockspire/compatibility_baseline_contract_test.exs` — 10 passed.
- `bash scripts/ci/lint_workflows.sh` and `git diff --check` — passed.
- No remote workflow run was dispatched or observed; these results establish local execution and executable workflow wiring only.

## TDD Gate Compliance

- **RED:** `d86afeaa` added a regression with a structurally valid failed receipt. The CLI incorrectly returned zero; the focused Python suite reported 20 passed and one failure. The canonical evidence check returned `RED_EVIDENCE_OK`; evidence is recorded in `170-04-task2-red-evidence.json`.
- **GREEN:** `b20a36d9` made the success CLI reject failed receipts and completed wrapper failure/status and strict duration regressions. The Python suite passed 28 tests, the focused Elixir contracts passed 10, and both full pair wrappers passed.
- **REFACTOR:** No separate refactor was needed.

## Task Commits

1. **Task 1: Wire locked required proof and safe evidence boundary** — `4a8a2d94`.
2. **Task 2 RED: Reject failed receipt evidence** — `d86afeaa`.
3. **Task 2 GREEN: Preserve required proof failures and validate evidence** — `b20a36d9`.

## Deviations from Plan

None. The local Chrome proof required the authorized normal browser permissions; this did not change the CI topology or claim a remote run.

## Known Stubs

None found in files created or modified by this plan.

## Self-Check: PASSED

- Both pair receipt directories contain lifecycle evidence and three unique, passing, 16-case browser receipts with all cleanup flags true.
- Task commits `4a8a2d94`, `d86afeaa`, and `b20a36d9` are ancestors of the plan head.
- `.planning/state.json` remains byte-for-byte equal to `/private/tmp/lockspire-phase170-original-state.json` and was not staged.
