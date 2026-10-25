---
phase: 174-packaged-proof-delivery-handoff
plan: "01"
subsystem: testing
tags: [elixir, phoenix, oauth, acceptance, package-proof, receipts]

requires:
  - phase: 173
    provides: PAR package/source contracts and host-boundary decisions used by the authorization proof.
provides:
  - Bounded selected_authorization_par runner for the A171-001–006 slice and strict independent receipt validator.
  - Actual package tracer and six-case authorization proof receipts, both explicitly partial.
  - Host-owned clean-room auth_time fixtures and source-CI bridge for receipt contract tests.
affects: [174-02, 174-03, packaged-acceptance, clean-room]

actuals:
  tokens: 15839
  tasks: 2
  commits: 9

tech-stack:
  added: []
  patterns: [strict standard-library receipt validation, package-bound source and compiled identity, host-owned synthetic freshness fixtures]

key-files:
  created:
    - scripts/acceptance/clean_room/selected_receipts.py
    - test/acceptance/selected_receipt_test.py
  modified:
    - scripts/acceptance/clean_room_saas_journey.py
    - scripts/acceptance/clean_room/build_provider.py
    - test/lockspire/clean_room_release_source_contract_test.exs
    - test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex
    - test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex

key-decisions:
  - "Selected receipts bind the exact source revision, archive, package tree, vendor tree, dependency resolution, and compiled candidate before accepting observations."
  - "Synthetic auth_time is supplied and stored by the clean-room host; Lockspire account and policy ownership remain unchanged."
  - "The six authorization cases are explicitly partial evidence; PAR expansion and final twelve-case acceptance remain with later plans."

patterns-established:
  - "Receipt check mode validates externally supplied source revision and receipt digest without starting hosts."
  - "Only bounded statuses and booleans are retained for authorization observations; redaction and owned cleanup must both pass."

requirements-completed: [CPROOF-01, CPROOF-02]
coverage:
  - id: D1
    description: "Run A171-003 from a package archive through a valid query control and rejected binary response_mode request."
    requirement: CPROOF-01
    verification:
      - kind: integration
        ref: ".artifacts/phase174/tracer.json; selected receipt check against source revision 5951029bbc842d0feece38b696ec48d026b2cd4e and SHA-256 9058a725ae90eaa49075bfd55d54e189f523c52b948beefe8c757b2fe58801e8"
        status: pass
    human_judgment: false
  - id: D2
    description: "Prove packaged A171-001/002/004/005/006 behavior with host-supplied freshness values and strict receipt validation."
    requirement: CPROOF-02
    verification:
      - kind: integration
        ref: ".artifacts/phase174/authorization.json; selected receipt check against source revision 869f983039b88bfc4cc4af8d4c6675f2dc6709db and SHA-256 b180587b20fecbc7c46f5b0bf0478d8a848a7ec5a87fded13a320e9341fbafde"
        status: pass
      - kind: unit
        ref: "python3 test/acceptance/selected_receipt_test.py (11 tests) and clean-room source contract ExUnit test (7 tests)"
        status: pass
    human_judgment: false

plan_head_before: 6c4381920af749807ea7bfa591ef3a49f91f6fb3
plan_head_after: 869f983039b88bfc4cc4af8d4c6675f2dc6709db
commits: 9
duration: 84min
completed: 2026-10-25
status: complete
---

# Phase 174 Plan 01: Packaged Authorization Proof Summary

**A real packaged host passed the A171-003 tracer and a six-case authorization slice with bound package identity, redaction, and cleanup evidence.**

## Performance

- **Duration:** 84 min
- **Started:** 2026-10-25T00:07:10Z
- **Completed:** 2026-10-25T01:31:27Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `selected_authorization_par`, the strict selected receipt schema/writer/checker, and 11 standard-library behavioral tests. Empty, null, duplicate, unknown, mismatched, substituted, failed, unobserved, and partial-as-complete evidence is rejected.
- Proved A171-003 from locally built `lockspire-1.6.1` archive through vendor, resolver, and compiled host binding. The query control reached host login; unsupported binary mode returned HTTP 400 with HTML, no `Location`, and no structured OAuth error parameters.
- Added six selected cases A171-001–006. The clean-room host owns the synthetic login identity and auth_time value. Stale auth is rejected under max_age/prompt=none; fresh auth is signed and observed through max_age and claims paths. Callback, state, error, and no-login assertions remain bounded.
- Both accepted receipts record observed redaction and successful process/database/temp-root cleanup. The tracer is one of twelve planned cases; the authorization receipt is six of twelve. Neither is final all-case acceptance.

## Actual Proof Artifacts

Artifacts are retained in the ignored run-output directory and are not committed as source:

| Artifact | Source revision | Receipt SHA-256 | Scope and result |
| --- | --- | --- | --- |
| `.artifacts/phase174/tracer.json` | `5951029bbc842d0feece38b696ec48d026b2cd4e` | `9058a725ae90eaa49075bfd55d54e189f523c52b948beefe8c757b2fe58801e8` | A171-003; 1 executed, 1 passed, explicitly partial |
| `.artifacts/phase174/authorization.json` | `869f983039b88bfc4cc4af8d4c6675f2dc6709db` | `b180587b20fecbc7c46f5b0bf0478d8a848a7ec5a87fded13a320e9341fbafde` | A171-001–006; 6 executed, 6 passed, explicitly partial |

Both receipts bind archive SHA-256 `ed16245dcd73c9f3d0a5542ca8ed16c6f02497ba5413cc282a9ae04a33b1e039`, package tree and vendor tree SHA-256 `47a678918f89b350b01beab736e433fbf0ce5146a36eb98f34cd4a988e4f5e1d`, and `resolved_dependency_verified: true`. Compiled candidate SHA-256 values are recorded independently in each receipt. Both have all cleanup and redaction observations true. The independent checker accepted each receipt only when supplied its exact source revision and digest.

## Verification

- Packaged tracer: passed against A171-003 from archive/vendor/resolved/compiled candidate.
- Packaged six-case run: 6/6 executed and passed; 0 failed, 0 skipped.
- `python3 test/acceptance/selected_receipt_test.py`: 11 tests passed, including the independent negative mutations.
- `mix test test/lockspire/clean_room_release_source_contract_test.exs`: 7 tests passed; includes the Python validator bridge.
- `python3 -m py_compile` for the changed Python runner/builder/validator/test and `git diff --check`: passed.
- Existing DCR lifetime receipt validator and its flags/restrictions were left intact.

## Task Commits

1. **Task 1: Prove A171-003 end to end from archive through HTTP and a validated partial receipt** — `ce835f85` (test), `5951029b` (feat).
2. **Task 2: Expand packaged authorization proof with host-owned freshness and callback controls** — `3003d79f` (feat), `7e4e83ea`, `47e55dac`, `afb03118`, `9242a967`, `0dba2278`, `869f9830` (fixes).

The final six-case receipt is bound to `869f9830`. Intermediate diagnostic commits remain in history; the final source has the safe failure handling plus the verified host-session and authenticated-consent fixes.

## Files Created/Modified

- `scripts/acceptance/clean_room/selected_receipts.py` — strict selected receipt validation and atomic writing, with no planning runtime dependency.
- `test/acceptance/selected_receipt_test.py` — independent positive and negative receipt contract tests.
- `scripts/acceptance/clean_room_saas_journey.py` — selected dispatch, package binding, six bounded authorization cases, and receipt CLI.
- `scripts/acceptance/clean_room/build_provider.py` — synthetic email scope in generated clean-room client config.
- `test/lockspire/clean_room_release_source_contract_test.exs` — source-CI bridge to the Python receipt tests.
- `test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex` — resolve account and auth_time from the same fetched host session.
- `test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex` — guarded run-owned synthetic host auth_time fixtures.

## Decisions Made

- Keep the package proof independent of the source checkout runtime: the host was prepared from the actual archive and its resolved/vendor/compiled candidate markers.
- Keep host account, session, login, claims, consent, and product policy ownership in the clean-room host.
- Mark the current receipts as partial and leave A171-007–012 and all final acceptance for the later plans.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Read account identity and auth_time from the fetched host session**
- **Found during:** Task 2, packaged A171-005.
- **Issue:** The resolver fetched the session only in a temporary pipeline for account ID, then read auth_time from the original connection. The forwarded host route therefore produced an `ArgumentError`/HTTP 500 for the stale-auth scenario.
- **Fix:** Bind the fetched connection once and read both values from it. No Lockspire policy or host ownership changed.
- **Files modified:** `test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex`.
- **Verification:** Focused A171-005 package run passed; final six-case package run passed.
- **Committed in:** `0dba2278`.

**2. [Rule 1 - Bug] Follow the authenticated consent redirect in A171-006**
- **Found during:** Task 2, packaged A171-006.
- **Issue:** The shared authorization helper assumed every redirect used the unauthenticated interactions path, while the authenticated host correctly used its direct consent route.
- **Fix:** Accept and assert the existing direct consent boundary alongside the unauthenticated interaction route.
- **Files modified:** `scripts/acceptance/clean_room_saas_journey.py`.
- **Verification:** Focused A171-006 package run passed; final six-case package run passed.
- **Committed in:** `869f9830`.

**Total deviations:** 2 auto-fixed bugs. **Impact:** Both were necessary to make the planned host-auth cases pass without changing product behavior or scope.

## Issues Encountered

- Older randomly named clean-room provider databases were visible during read-only inspection. Their ownership was not established, so they were preserved. This run's owned resources reported successful cleanup; older database custody remains for the parent delivery owner to review.
- The source-CI host test encountered the same host session seam first observed in packaged A171-005; the focused package stage and read-only debugging localized it to the clean-room resolver.

## Next Phase Readiness

Plan 174-02 can extend the selected authorization proof with PAR cases. Plan 174-03 owns the final all-twelve receipt and delivery checks. Existing unresolved prohibitions remain in force until their later scoped review. No verifier report, candidate CI, accepted-main status, PR, merge, publication, or dispatch is claimed here.

---
*Phase: 174-packaged-proof-delivery-handoff*
*Plan: 01*
*Completed: 2026-10-25*

## Self-Check: PASSED

- Both proof artifacts exist at their documented ignored output paths.
- Task commits `ce835f85` and `869f9830` are ancestors of the current plan head.
- Stub-pattern scan found no TODO, FIXME, placeholder, or coming-soon markers in the seven plan files.
- `git diff --check` passed; only this summary is untracked before the planning-state update.
