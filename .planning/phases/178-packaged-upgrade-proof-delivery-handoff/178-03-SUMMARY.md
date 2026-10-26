---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "03"
subsystem: testing
tags: [elixir, phoenix, verifier-custody, packaged-upgrade, rollout]
requires:
  - phase: 178-02
    provides: shared clean-room builder and adapter seams
provides:
  - Four installed old/new rollout proofs across locked/floor and builtin/delegated compositions
  - Separate pinned public 1.6.1 locked/builtin legacy producer/adopter control
  - Safe persisted-row projections and strict rollout transition checks
affects: [phase-178, packaged-upgrade-proof, verifier-custody]
actuals:
  tokens: 14579
  tasks: 2
  commits: 31
tech-stack:
  added: []
  patterns: ["Run-owned old/new processes with legacy writes through overlap and explicit post-drain activation", "Allowlisted persisted-row and process evidence"]
key-files:
  created: []
  modified:
    - scripts/acceptance/clean_room/verifier_rollout.py
    - scripts/acceptance/clean_room_verifier_upgrade.py
    - test/clean_room/provider_host/verifier_rollout.exs
    - test/acceptance/client_verifier_rollout_test.py
key-decisions:
  - "Keep one-off Mix commands from binding the serving HTTP port; only owned listener processes enable the endpoint server."
  - "Keep VPROOF-02 pending until the remaining Phase 178 proof plans complete their assigned coverage."
patterns-established:
  - "During mixed-version overlap, both writers remain legacy; dedicated activation follows observed predecessor exit."
  - "Public release source and candidate runner/source revisions are recorded independently."
requirements-completed: []
coverage:
  - id: D1
    description: "Installed four-cell shared-store reader-first rollout, activation, rollback, and switch-back controls"
    requirement: VPROOF-02
    verification:
      - kind: integration
        ref: ".artifacts/phase178/rollout/{locked-builtin,locked-delegated,floor-builtin,floor-delegated}/receipt.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "Separately attributed public 1.6.1 locked/builtin legacy producer/adopter control through the lifetime prerequisite"
    requirement: VPROOF-02
    verification:
      - kind: integration
        ref: ".artifacts/phase178/public-legacy/locked-builtin/receipt.json"
        status: pass
    human_judgment: false
duration: 59min
completed: 2026-10-26
status: complete
plan_head_before: 7759ce7c3f2dece05094385663d81fff3561d8a7
plan_head_after: 94e9d6b7b00412d2a251a8e4e5cc005e469a85dd
---

# Phase 178 Plan 03: Packaged Upgrade Proof & Delivery Handoff Summary

**Installed mixed-version verifier rollout proof across four dependency/storage cells, plus a separately pinned public 1.6.1 legacy control.**

## Performance

- **Duration:** 59 min from the execution state start timestamp; recovery work continued from the documented attempt-limit checkpoint.
- **Started:** 2026-10-26T19:08:03Z
- **Completed:** 2026-10-26T20:06:57Z
- **Tasks:** 2
- **Files modified:** 4
- **Measured plan commits:** 31 commits after baseline `7759ce7c3f2dece05094385663d81fff3561d8a7`; actuals tokens are the realized tracked diff size divided by four (58,319 characters / 4).

## Accomplishments

- Executed all four installed rollout cells (`locked`/`floor` × `builtin`/`delegated`) with the accepted predecessor at `173059a166e9ade0f5f57c9980b7b2400a98538c` and candidate/runner at `94e9d6b7b00412d2a251a8e4e5cc005e469a85dd`. All receipts report `outcome=pass`, predecessor drain observed, legacy shared-store writes and reads during overlap, dedicated write after drain, compatible-reader rollback retaining dedicated reads, switch-back preserving the dedicated row, and isolated old-code legacy success plus dedicated-format rejection.
- Ran the separate locked/builtin public 1.6.1 legacy control against actual mounted HTTP. The public artifact SHA-256 is `629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d`, linked to public source `d04be40262e975a4eb8d8567eb0d1458a9c23181` by retained release evidence. The receipt records lifetime prerequisite migration, verifier-specific adoption, successful HTTP authentication, dedicated format after adoption, preserved client hash, and preserved authenticated finite deadline. It is not a complete public-release matrix.
- Corrected listener ownership for one-off Mix commands, rollout fixture output and argument handling, authenticated age inspection with an independent reader context, exact old-code HTTP rejection recognition, activation ordering, readiness-failure cleanup, bounded public HTTP startup, and redacted process failure evidence. Signing-key setup occurs before the public adopter starts serving; custody proof does not rotate endpoint or signing keys.
- Added behavioral coverage for listener roles, projection protocol, fixture preamble/argv handling, independent verifier reader context, transition ordering, public HTTP status observations, and retained-log redaction. Existing task 2 RED commit `791e7973` remains part of history; it was not recreated or restamped.

## Task Commits

The original partial commits and all continuation commits are preserved. Task-related commits measured from the immutable plan ledger (in order):

`6dff93df`, `5c4bcb9a`, `77e762bd`, `f07581aa`, `2c9202e8`, `a7a02a79`, `8871aa02`, `791e7973`, `e3eee96b`, `57a7724a`, `b483644c`, `bcac793e`, `51d94a99`, `8ebdaaa4`, `7d0291d9`, `191cf096`, `e90419e0`, `0eaed9e8`, `3f95896c`, `d1962c9c`, `02fcb1d4`, `213014df`, `0a4cd062`, `ff76d6bd`, `71bb1c2f`, `2213e485`, `9cdf9cc3`, `68992fc4`, `2c6e5ff7`, `183d4d90`, `94e9d6b7`.

Task 1 is represented by `b483644c` and `bcac793e` plus the directly related corrective commits in that sequence. Task 2's original RED evidence is `791e7973`; its implementation and public-control corrections are included in the remaining sequence. These are source/task commits; this summary and state metadata are committed separately.

## Files Created/Modified

- `scripts/acceptance/clean_room/verifier_rollout.py` — installed rollout sequence, evidence collection, failure handling, and public control.
- `scripts/acceptance/clean_room_verifier_upgrade.py` — shared installed HTTP probe support for the public control.
- `test/clean_room/provider_host/verifier_rollout.exs` — host-owned fixture setup and safe persisted-row/age projections.
- `test/acceptance/client_verifier_rollout_test.py` — focused harness behavior and transition contracts.

## Verification

- `python3 -m unittest discover -s test/acceptance -p 'client_verifier_rollout_test.py'` — 14 tests passed.
- `python3 -m py_compile scripts/acceptance/clean_room_verifier_upgrade.py scripts/acceptance/clean_room/verifier_rollout.py` — passed.
- `git diff --check` — passed.
- Four-cell installed rollout: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group rollout --receipt-dir .artifacts/phase178/rollout` — exit 0, executed count 4.
- Public control: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store builtin --group legacy-control --receipt-dir .artifacts/phase178/public-legacy` — exit 0, executed count 1.
- All five final receipts identify runner/candidate `94e9d6b7b00412d2a251a8e4e5cc005e469a85dd`, contain non-null process identities, and retain `partial: true`. No sensitive marker scan hits were found in the final rollout/public receipt directories.

## Decisions Made

- Runtime endpoint listeners are explicitly enabled only for owned HTTP-serving processes; app-starting one-off Mix commands keep the listener disabled to avoid binding the serving port.
- Both predecessor and candidate use legacy writes during overlap. Dedicated activation starts only after the predecessor process exit is observed.
- Public 1.6.1 evidence remains a narrow locked/builtin compatibility control, and is attributed to the public release source independently from the candidate runner/source revision.
- VPROOF-02 remains pending until remaining Phase 178 plans complete their assigned evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made runtime listener ownership explicit and cleaned up failed server starts**
- **Found during:** Task 1 and public control recovery.
- **Issue:** One-off `mix run -e` booted a listener on the owned server port, and readiness failure could leave an owned child/log handle behind.
- **Fix:** The rollout host defaults its runtime endpoint server setting off; `_start_server` sets it on in a copied environment only for real listener processes and cleans resources on readiness failure.
- **Files modified:** `scripts/acceptance/clean_room/verifier_rollout.py`.
- **Verification:** Focused tests and both installed proof groups passed.
- **Committed in:** `bcac793e` and follow-up corrections.

**2. [Rule 1 - Bug] Corrected fixture projection and authenticated legacy-age inspection**
- **Found during:** Task 1.
- **Issue:** The fixture's Python-style preamble was invalid Elixir; Mix argv separator and helper output filtering prevented safe row projections; the legacy inspection needed the real configured verifier key and a reader context independent of writer mode.
- **Fix:** Made the fixture executable Elixir, stripped the Mix separator, retained only allowlisted projection fields, and inspected authenticated age metadata through an independent dedicated reader context using the configured Lockspire key.
- **Files modified:** `test/clean_room/provider_host/verifier_rollout.exs`, `scripts/acceptance/clean_room/verifier_rollout.py`.
- **Verification:** Focused tests and all four installed cells passed.
- **Committed in:** `8ebdaaa4`, `191cf096`, `0eaed9e8`, `02fcb1d4` and related tests.

**3. [Rule 1 - Bug] Enforced reader-first activation and exact old-code rejection evidence**
- **Found during:** Task 1.
- **Issue:** Candidate dedicated writes began before the old process drained, and the old-code probe did not recognize the installed HTTP 401 rejection shape.
- **Fix:** Kept both writers in legacy mode during overlap, observed old-process exit before dedicated activation, and recognized only the actual bounded HTTP 401 rejection while retaining a valid legacy control.
- **Files modified:** `scripts/acceptance/clean_room/verifier_rollout.py`, `test/clean_room/provider_host/verifier_rollout.exs`, `test/acceptance/client_verifier_rollout_test.py`.
- **Verification:** All four installed cells passed with drain, dedicated, rollback, and switch-back observations.
- **Committed in:** `bcac793e`, `b483644c`, `0a4cd062` and follow-up corrections.

**4. [Rule 1 - Bug] Bound public adopter startup and provision signing material before serving**
- **Found during:** Task 2.
- **Issue:** The public adopter control needed a bounded HTTP readiness wait and an active signing key before token HTTP, while preserving key custody boundaries.
- **Fix:** Provisioned the required key through the installed public facade before the serving process starts and retained process identities; did not rotate endpoint/signing keys as part of verifier custody proof.
- **Files modified:** `scripts/acceptance/clean_room/verifier_rollout.py`, `scripts/acceptance/clean_room_verifier_upgrade.py`.
- **Verification:** Final public control passed actual mounted HTTP authentication and retained hash/deadline observations.
- **Committed in:** `68992fc4`, `2c6e5ff7`.

**5. [Rule 2 - Missing Critical] Kept failure evidence bounded and redacted**
- **Found during:** Task 2.
- **Issue:** A failure logger path initially retained raw parameter lines that could include authentication material.
- **Fix:** Removed the unsafe retained log field and changed failure retention to fixed allowlisted labels, bounded status/error observations, command/exit/source identity, and shared redaction matching. The unsafe ignored attempt record was scrubbed; the attempt itself remains transparently documented as an incident and earlier failures without durable raw logs remain labeled as such.
- **Files modified:** `scripts/acceptance/clean_room/verifier_rollout.py`, `test/acceptance/client_verifier_rollout_test.py`.
- **Verification:** Focused redaction tests passed; final artifact scan found no sensitive marker hits.
- **Committed in:** `ff76d6bd`, `71bb1c2f`, `2213e485`, `9cdf9cc3`.

**Total deviations:** 5 auto-fixed (4 correctness issues and 1 evidence-disclosure safeguard). All were necessary to complete the planned proof; no production API, schema, dependency, or protocol changes were introduced.

## Issues Encountered

- The original executor reached its three-auto-fix limit and stopped at the recorded blocking checkpoint. The original history remains in `178-03-RECOVERY.md`; continuation approval was workflow automation, not human verification. Earlier failed attempts whose raw logs were not durably captured remain labeled without reconstructed logs.
- The checkout's retained public `lockspire-1.6.1.tar` did not match the public artifact pin. It was preserved unchanged; a fresh run-owned pinned artifact was fetched and independently matched to retained release source evidence.
- A transient unsafe failure-log artifact was scrubbed before final proof and the logger was corrected; the failed attempt was not restamped as a passing receipt.

## User Setup Required

None.

## Next Phase Readiness

- Plan 03's two tasks and assigned proof groups are complete. The receipts remain deliberately partial and do not establish fleet parity, fleet quiescence, backup availability, or rollback safety.
- VPROOF-02 remains pending until the remaining Phase 178 proof plans finish. Merge, publication, and integrated-main acceptance remain separate lifecycle steps.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Completed: 2026-10-26*

## Self-Check: PASSED

- Summary file exists at the planned phase path.
- All 31 plan-ledger commits are ancestors of the verified plan head; the original and continuation commits are preserved.
- The changed acceptance/fixture files contain no TODO, FIXME, placeholder, coming-soon, or not-available stubs.
