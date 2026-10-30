---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "06"
subsystem: auth
tags: [client-secret-jwt, verifier-custody, phoenix, postgresql, clean-room, recovery, issuance]
requires:
  - phase: 178-02
    provides: Host-owned delegated storage adapter and bounded maintenance barriers
  - phase: 175
    provides: Frozen age, custody, and authentication compatibility contracts
provides:
  - Four installed recovery receipts across locked/floor and builtin/delegated hosts
  - Two installed delegated stale-identity issuance receipts across locked/floor hosts
  - Strict mounted HTTP status, OAuth error, retry, preservation, and readiness receipt contracts
affects: [178-07, 178-08, 178-09, VPROOF-02]
actuals:
  tokens: 16193
  tasks: 2
  commits: 19
plan_head_before: 7c7ee259aee6dfafd72c043707160d51c3b8fada
plan_head_after: 539cb802a1b44222af72ee7d53b2347eb32dde06
commits: 19
tech-stack:
  added: []
  patterns: [Python-owned host lifecycle, monitored same-VM HTTP barriers, allowlisted outcome summaries]
key-files:
  created: []
  modified:
    - scripts/acceptance/clean_room/build_provider.py
    - scripts/acceptance/clean_room/verifier_endpoints.py
    - scripts/acceptance/clean_room/verifier_receipts.py
    - scripts/acceptance/clean_room/verifier_recovery.py
    - test/acceptance/client_verifier_recovery_test.py
    - test/acceptance/client_verifier_transactions_test.py
    - test/clean_room/provider_host/lib/clean_room_provider/verifier_recovery.ex
key-decisions:
  - "Keep all six group receipts partial; VPROOF-02 remains pending until the remaining Phase 178 evidence owners pass."
  - "Run issuance probes inside the owned host VM so actual mounted HTTP callbacks share the serving process and barrier state."
  - "Use fixed HTTP status/error enums and field-name-only failure summaries; never retain child diagnostics."
patterns-established:
  - "Recovery fixtures use Python-owned server restarts with private 0700/0600 handoffs."
  - "Issuance barriers are released before same-JTI and fresh-JTI controls, and workers are monitored without linking failures to the proof process."
requirements-completed: []
coverage:
  - id: D1
    description: "Installed custody preservation, retry reconciliation, missing-key restoration/rotation, and expired migration recovery across four cells."
    verification:
      - kind: integration
        ref: ".artifacts/phase178/recovery-final-matrix-539cb802 (four strict recovery receipts)"
        status: pass
      - kind: unit
        ref: "python3 -m unittest discover -s test/acceptance -p 'client_verifier_recovery_test.py'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Actual mounted HTTP issuance rejects stale authenticated identity and replay after committed maintenance, then accepts a fresh JTI."
    verification:
      - kind: integration
        ref: ".artifacts/phase178/issuance-final-matrix-539cb802 (two strict issuance receipts)"
        status: pass
      - kind: integration
        ref: "mix test --include integration test/integration/client_secret_verifier_maintenance_issuance_test.exs test/integration/client_secret_verifier_guarded_issuance_test.exs"
        status: pass
    human_judgment: false
duration: 2h 28m
completed: 2026-10-26
status: complete
---

# Phase 178 Plan 06: Installed Recovery and Guarded Issuance Summary

**Installed recovery and issuance witnesses now prove custody preservation, fail-closed recovery, and stale-identity rejection across both dependency pairs.**

## Performance

- **Duration:** 2h 28m, including the resumed execution and final metadata update from the original Plan 06 start.
- **Started:** 2026-10-26T21:47:13Z.
- **Completed:** 2026-10-27T00:14:47Z.
- **Tasks:** 2/2.
- **Source files modified:** 7.

## Accomplishments

- Accepted four recovery cells: locked/builtin, locked/delegated, floor/builtin, and floor/delegated.
- Accepted two delegated issuance cells: locked and floor. Both observed discovery HTTP 200, stale identity and same-JTI replay as HTTP 401 `invalid_client`, and a fresh-JTI HTTP 200 success with no incorrect grant/token effects.
- Verified exact preserved age metadata, ciphertext/hash and partner-secret preservation, no-op repeat behavior, interruption/partial readiness separation, fresh complete reconciliation, missing-key startup rejection with Basic/Post controls, original-key restoration, authorized rotation, and expired migrated-custody rejection.
- Kept the underlying package at source/candidate/runner revision `539cb802a1b44222af72ee7d53b2347eb32dde06`; each receipt binds archive, tree, vendor, compiled candidate, resolved dependencies, lockfile, and host runtime identity.

## Accepted Receipt Matrix

All receipts are partial evidence objects and pass the shared CLI validator.

| Group | Pair | Store | Receipt |
|---|---|---|---|
| Recovery | locked | builtin | `.artifacts/phase178/recovery-final-matrix-539cb802/locked-builtin/receipt.json` |
| Recovery | locked | delegated | `.artifacts/phase178/recovery-final-matrix-539cb802/locked-delegated/receipt.json` |
| Recovery | floor | builtin | `.artifacts/phase178/recovery-final-matrix-539cb802/floor-builtin/receipt.json` |
| Recovery | floor | delegated | `.artifacts/phase178/recovery-final-matrix-539cb802/floor-delegated/receipt.json` |
| Issuance | locked | delegated | `.artifacts/phase178/issuance-final-matrix-539cb802/locked-delegated/receipt.json` |
| Issuance | floor | delegated | `.artifacts/phase178/issuance-final-matrix-539cb802/floor-delegated/receipt.json` |

Common matrix identity: package version `1.6.1`; archive SHA-256 `8be113c5d8cd630ee9fefba3494aac2c236350589a5cd9e7c98600a11a8d1e91`; source and vendor tree SHA-256 `2af2082226f0be0e47b1f761cb4e98dd526effc0f93800fbacacce1f3a46b243`; source and runner revision `539cb802a1b44222af72ee7d53b2347eb32dde06`; Elixir `1.19.5`, OTP `28`, PostgreSQL `14.17`. Resolved dependencies were verified for every receipt. Compiled candidate, lockfile, and Phoenix/LiveView versions are specific to each host cell:

| Group | Pair | Store | Phoenix | LiveView | Lock SHA-256 | Compiled candidate SHA-256 |
|---|---|---|---|---|---|---|
| Recovery | locked | builtin | 1.8.13 | 1.2.10 | `f77638eeed00fc0a7fa524219ad2fe0c0fd3c147b0436979b925bc4f236f4404` | `fc49656a59e963eb514663bf59159735c83cb0398e7602b0ac5e66f7904c8e01` |
| Recovery | locked | delegated | 1.8.13 | 1.2.10 | `f77638eeed00fc0a7fa524219ad2fe0c0fd3c147b0436979b925bc4f236f4404` | `e2beccd358be47caaad569eed7a04c028222cb471fd5b7cf5139437ba9f6690f` |
| Recovery | floor | builtin | 1.8.5 | 1.1.28 | `74212156d931add8c5acae6ad67928d08951a6c698cc6f29fec88992af38a954` | `bb4dae001598cff73b103140b9068b3504a0538862b658f352d0b51a77708186` |
| Recovery | floor | delegated | 1.8.5 | 1.1.28 | `74212156d931add8c5acae6ad67928d08951a6c698cc6f29fec88992af38a954` | `0e5f3f8b45d984bed8f73cd37d42c78829f534bbd2bd1fbe17e9b1f75a0b9d3c` |
| Issuance | locked | delegated | 1.8.13 | 1.2.10 | `f77638eeed00fc0a7fa524219ad2fe0c0fd3c147b0436979b925bc4f236f4404` | `aa697916e8cc005247c6bb9de11dcd960910b77f6b30113a3ca486beeff9c167` |
| Issuance | floor | delegated | 1.8.5 | 1.1.28 | `74212156d931add8c5acae6ad67928d08951a6c698cc6f29fec88992af38a954` | `96e09fa1897effcea03ef790d575c5c6ef7c5fc7bd65f079d9f22edf639c7163` |

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' MIX_ENV=test mix test --include integration test/lockspire/security/client_secret_verifier_maintenance_test.exs test/integration/client_secret_verifier_maintenance_test.exs test/integration/client_secret_jwt_legacy_age_test.exs test/integration/client_secret_verifier_maintenance_issuance_test.exs test/integration/client_secret_verifier_guarded_issuance_test.exs` — 28 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 -m unittest discover -s test/acceptance -p '*_test.py'` — 118 tests, 0 failures.
- Focused Python recovery acceptance — 13 tests, 0 failures; focused transaction/receipt acceptance — 5 tests, 0 failures.
- All six receipts independently revalidated through `clean_room_verifier_upgrade.py --validate-receipts` with their expected pair/store; each returned `validated: true`.
- An independent post-plan check revalidated the six accepted receipts through the common CLI (four recovery and two issuance) and reran full Python acceptance with the documented process-local ASDF/ERL environment: 118 tests, 0 failures. Its first test invocation omitted those environment settings and exited 126 at startup; the corrected invocation passed. No source or receipt was changed by these post-checks.
- The runner code's cleanup path stops owned servers, drops the run's isolated database, and removes its temporary directory. This summary has no independent final-matrix inventory confirming those resources were absent after each accepted run; no resource IDs were reconstructed from raw logs. Final-matrix cleanup absence therefore remains unverified for a later custody reconciliation.
- The host recovery fixture compiles with `mix run --no-start -e 'Code.compile_file("test/clean_room/provider_host/lib/clean_room_provider/verifier_recovery.ex")'`. It reports expected root-context warnings for generated host modules that exist only in the installed fixture.
- Python syntax checks and `git diff --check` passed.

## TDD Gate Compliance

- Preserved prior RED evidence, including `178-06-01-red-evidence.json`, the qualified HTTP pruning regression `178-06-ROOT-HTTP-RED-QUALIFIED.json`, and the preliminary HTTP RED `178-06-ROOT-HTTP-RED.json`; no historical result was restamped.
- The current GSD RED-evidence checker returns `RED_EVIDENCE_OK` for `178-06-01-red-evidence.json`. It classifies both retained root HTTP JSON records as `INVALID_RED` because their report format is unsupported; their original diagnostic and qualification history remains unchanged and is not reclassified here.
- Added focused regressions for safe issuance case-ID casing, monitored barriers, barrier release before positive controls, bounded failure-field classification, and integer HTTP status validation. The implementation was already present when this continuation resumed, so no fresh RED was fabricated for that existing work.
- Final focused and full acceptance results are recorded above.

## Task Commits

All 19 commits after the Plan 06 continuation base (`7c7ee259`) are task commits:

1. `1c29f013` — add recovery group and private host lifecycle.
2. `6f2d379c` — retain bounded interruption substage facts.
3. `93e75ff4` — size the owned recovery pool for concurrent blockers.
4. `a0b4df45` — classify safe recovery failures.
5. `9c71e2a9` — assert public partial-check readiness.
6. `6f98b9ab` — bind partial cursor to public readiness.
7. `ec6baabb` — use an empty cursor suffix for the readiness control.
8. `e9bc9429` — separate cursor traversal from fresh-check readiness.
9. `509314f6` — bind recovery outcomes to mounted HTTP.
10. `88b2ef4d` — isolate delegated interruption cancellation.
11. `ca6c101c` — bind monitored issuance witnesses.
12. `e56a152c` — label bounded host setup failures.
13. `4508b082` — serve issuance probes in the owned host VM.
14. `1566ea53` — bind issuance to mounted host readiness.
15. `f918e92a` — isolate issuance request failure stages.
16. `ca03fb3e` — release issuance barriers before retries.
17. `3d7a7a4b` — validate discovery status as an integer.
18. `a1119512` — bind issuance HTTP failures to status/error outcomes.
19. `539cb802` — retain the safe status/error tuple for expired authentication.

## Deviations from Plan

### Auto-fixed issues

1. **Rule 1 — Interrupted delegated worker was linked to the proof process.** Killing it could terminate the caller before its safe result. Replaced the linked task with a monitored worker and waited for termination before reading persisted state. Verified with the installed delegated recovery cell.
2. **Rule 2 — Issuance barriers remained armed for follow-up requests.** The current-row guard was client-ID scoped and caught the fresh-JTI request after the stale witness. Cleared the first-JTI control after observing the stale response, before replay/fresh controls. Both pair receipts now pass.
3. **Rule 3 — Installed issuance required minimal shared harness glue.** The actual endpoint, callback controls, and PG pool must share the same owned Mix VM. The runner enables the endpoint for issuance, records a mounted discovery status, and uses fixed stage/error categories; no production endpoint or policy changed.
4. **Rule 1 — HTTP receipt type contract omitted the mounted discovery status and used an incorrect stale-status expectation.** Added typed integer status and allowlisted OAuth categories based on the source-owned 401 contract. The strict validator rejects booleans, strings, and unexpected status codes.

No runtime dependencies, schema changes, production APIs, authentication policies, or remote actions were added.

## Failed Attempts and Historical Incidents

- Several source revisions produced no accepted issuance receipt while the host lifecycle, barrier correlation, status typing, and error-stage classification were corrected. Their safe failures included generic setup/child errors, `issuance_auth_barrier`, `expired_http_timeout`, `issuance_fresh_jti_retry`, and strict schema rejection. None of those attempts was treated as a passing receipt; the final accepted matrix was run after the final source commit.
- The initial recovery matrix at an earlier committed revision stopped on locked/delegated interruption. The unlinked cancellation correction was committed before the fresh four-cell matrix.
- The original Plan 06 checkpoint and root diagnosis remain unchanged and retain their earlier failed attempts. The three historical harness disclosure incidents remain documented for the planned security review. This continuation did not inspect raw tails or emit child stdout/stderr, request bodies, secrets, stacks, or exception text.

## Remaining Scope

- Plan 06 is complete, but the six receipts are intentionally partial. They do not mark `VPROOF-02` complete; Plans 07–12 still own additional proof groups.
- The time-sensitive HTTP observations report actual wall-clock outcomes. Exact equality/precision policy remains owned by the frozen Phase 175/source test owners; no private clock, synthetic HTTP timestamp, or extra validity window was introduced.
- No merge, push, PR, release, or publication was performed.

## Self-Check: PASSED

- All six listed receipt files exist and were revalidated by the shared strict CLI.
- Task commit ancestry was measured from `7c7ee259aee6dfafd72c043707160d51c3b8fada` to `539cb802a1b44222af72ee7d53b2347eb32dde06`: 19 commits.
- The worktree was clean before this summary and metadata update.
