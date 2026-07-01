---
phase: 100-sender-constraint-end-to-end-proof
plan: "02"
subsystem: testing
tags: [elixir, jwt, aud, contract-test, verify-token, sender-constraint, pipeline-ordering]

# Dependency graph
requires:
  - phase: 100-sender-constraint-end-to-end-proof-01
    provides: EnforceSenderConstraints and RequireToken plugs wired with binding_verified breadcrumb

provides:
  - BIND-03 structural layer: contract test asserting all four RECIPE-01 sites order VerifyToken → EnforceSenderConstraints → RequireToken
  - byte_offset/2 private helper in release_readiness_contract_test.exs for offset-comparison assertions
  - A1 resolved: confirmed VerifyToken accepts list-valued aud claim (signer emits ["billing-api"])

affects:
  - 100-03-PLAN
  - future integration tests for BIND-01/BIND-02

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "byte_offset/2 via :binary.match/2 for anti-cheat offset ordering in contract tests"
    - "A1 Wave-0 spike pattern: resolve open assumptions with targeted assertions before integration tests"

key-files:
  created: []
  modified:
    - test/lockspire/release_readiness_contract_test.exs
    - test/lockspire/plug/verify_token_test.exs

key-decisions:
  - "Used :binary.match offset comparison (not regex) for BIND-03 ordering assertion — self-evidently fails on transposition"
  - "A1 confirmed: list aud accepted; BIND-01/02 can rely on signer-emitted list aud without mitigation"

patterns-established:
  - "BIND-03/D-05 contract clause: reuse extract_canonical_pipeline!/2 + four {path,kind} tuples verbatim from audience clause"
  - "A1 spike pattern: assert specific open assumption with targeted test before integration phase"

requirements-completed: [BIND-03, BIND-01, BIND-02]

# Metrics
duration: 8min
completed: 2026-05-28
---

# Phase 100 Plan 02: Sender-Constraint End-to-End Proof — BIND-03 Contract Clause + A1 List-Aud Spike Summary

**BIND-03 contract test added asserting all four RECIPE-01 pipeline sites order VerifyToken→EnforceSenderConstraints→RequireToken via byte-offset comparison; A1 assumption confirmed: VerifyToken accepts list-valued aud (the signer's wire shape) without mitigation needed.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-28T19:55:00Z
- **Completed:** 2026-05-28T19:59:18Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added BIND-03/D-05 ordering clause to `release_readiness_contract_test.exs` using the existing `extract_canonical_pipeline!/2` helper and four-file `{path, kind}` iteration — no parallel extractor added
- Added `byte_offset/2` private helper using `:binary.match/2`; offset comparison `v < e and e < r` genuinely fails if EnforceSenderConstraints and RequireToken are transposed
- Resolved A1 open assumption: `normalize_token_audiences/1` in `verify_token.ex` already handles list aud at lines 275-280 — a single-element list `["billing-api"]` passes with `audience: "billing-api"` set; BIND-01/02 can rely on signer-emitted list aud without special handling
- Full suite: 1035 tests, 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Add D-05 BIND-03 pipeline-ordering clause + byte_offset/2 helper** - `3f395ed` (test)
2. **Task 2: A1 Wave-0 spike — prove VerifyToken accepts list-valued aud** - `16e03e3` (test)

## Files Created/Modified

- `test/lockspire/release_readiness_contract_test.exs` — New test `"all four RECIPE-01 sites order VerifyToken → EnforceSenderConstraints → RequireToken (BIND-03/D-05)"` and `byte_offset/2` private helper
- `test/lockspire/plug/verify_token_test.exs` — New test `"A1: accepts a single-element list aud claim with audience: set (signer emits list aud)"`

## Decisions Made

- Used `:binary.match/2` offset comparison in `byte_offset/2` rather than a multiline regex; offset is self-evidently correct and cannot be fooled by permutation-tolerant patterns
- A1 spike confirmed list-aud acceptance; no mitigation path needed for BIND-01/02 — the signer emits `["billing-api"]` and VerifyToken accepts it

## Deviations from Plan

None — plan executed exactly as written. The A1 spike confirmed acceptance (the expected/happy path); the escalation branch in the task action was not needed.

## Issues Encountered

The worktree does not have a local `deps/` or `_build/` directory. Tests were run using `MIX_DEPS_PATH` and `MIX_BUILD_PATH` environment variables pointing to the main project's shared deps while building the worktree's test files. This is the expected worktree pattern and produced correct results.

## Known Stubs

None — no stub patterns introduced. Both new tests are fully wired assertions.

## Threat Flags

None — this plan adds test-only files. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## A1 Assumption Resolution

**RESOLVED: list aud is accepted.** `normalize_token_audiences/1` in `lib/lockspire/plug/verify_token.ex` (lines 275-280) handles the `is_list(audiences)` case and returns `{:ok, audiences}` when all elements are non-empty strings. A single-element list `["billing-api"]` passes `Enum.all?(audiences, &non_empty_string?/1)` and then matches via `Enum.member?(token_audiences, expected_audience)`. The A1 spike test confirms this with a real signed token through the live plug pipeline.

**BIND-01/02 implication:** Plan 100-03 can mint tokens with `aud: ["billing-api"]` (signer's list shape) and assert acceptance through `VerifyToken` with `audience: "billing-api"` set. No string-aud workaround or `audiences:` option needed.

## Next Phase Readiness

- BIND-03 structural layer is live and CI-enforced; canonical pipeline ordering is asserted across all four RECIPE-01 sites
- A1 resolved; Plan 100-03 (BIND-01/02 integration proof) can proceed with signer-emitted list aud without mitigation
- No blockers

---
*Phase: 100-sender-constraint-end-to-end-proof*
*Completed: 2026-05-28*
