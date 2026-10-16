---
phase: 157-host-surfaces-redaction-sweep-release-proof
plan: 03
subsystem: testing
tags: [signing-keys, key-encryption, kek-rotation, integration-test, ci, clean-room, safe-01]

requires:
  - phase: 155
    provides: envelope-aware signing consumers
  - phase: 156
    provides: keys.reencrypt task, --check, doctor key_encryption
  - phase: 157
    provides: demo seed rewrite and :reject runtime config (157-02), sweep legs (157-06), docs (157-04)
provides:
  - PROOF-01 upgrade and rotation journey test over six consumers
  - SigningConsumers test-support drivers fed by stored rows
  - adoption-demo CI steps and clean-room child commands for --check and doctor
  - recorded SAFE-01 gate against v1.42
affects: [157-VERIFICATION, release]

actuals:
  tokens: 9000
  tasks: 3
  commits: 4
plan_head_before: 2b51a132ed2f1ba00c0c2e3de70d9a5081ef2f26
plan_head_after: d170ef0b936bec3c30a9ab1fdafe43bf03137f19

tech-stack:
  added: []
  patterns:
    - "Committed-data integration journey with repo stopped at start, own kid prefix, on_exit cleanup"

key-files:
  created:
    - test/support/signing_consumers.ex
    - test/integration/signing_key_upgrade_journey_test.exs
  modified:
    - .github/workflows/ci.yml
    - scripts/acceptance/clean_room_saas_journey.py

key-decisions:
  - "Verify key and JWE target derive from the seeded legacy private JWK (helper rows share one RSA key, public_jwk stub has no n/e)"
  - "Separate CI steps for --check and doctor for clearer failure output"

requirements-completed: [PROOF-01, SAFE-01]

coverage:
  - id: D1
    description: "Journey: legacy JSON and ETF sig and enc rows migrate to test-1 envelopes, all six consumers work under allow, reject and after rotation to test-2 with the old key removed"
    requirement: PROOF-01
    verification:
      - kind: integration
        ref: "test/integration/signing_key_upgrade_journey_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "adoption-demo and clean-room run keys.reencrypt --check and doctor key_encryption"
    requirement: PROOF-01
    verification:
      - kind: e2e
        ref: "mix test.clean-room.e2e"
        status: pass
    human_judgment: true
    rationale: "The adoption-demo CI job only runs on GitHub Actions; the new steps are verified by YAML parse and the clean-room replay locally"
  - id: D3
    description: "SAFE-01 gate recorded against v1.42"
    requirement: SAFE-01
    verification:
      - kind: other
        ref: "SAFE-01 gate section below"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-16
status: complete
---

# Phase 157 Plan 03: Upgrade Journey and SAFE-01 Gate Summary

**One integration journey proves legacy plaintext and ETF signing keys become KEK envelopes, keep signing and decrypting across six consumers under :allow, :reject and a test-1 to test-2 rotation, and the SAFE-01 gate against v1.42 is green.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-10-16T16:43Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- `Lockspire.TestSupport.SigningConsumers` drives ID token, logout token, JARM, introspection JWT, access-token signer and JAR decrypt from `SigningKey` structs read back from the database, and checks signature and kid.
- The journey seeds four legacy rows (JSON and ETF for `:sig` and `:enc`), runs the real reencrypt task and `--check` (first fails on legacy rows, then passes), asserts the LSK version-1 header, `envelope_kek_id` and no private member bytes, flips to `:reject`, rotates to `test-2` (zero journey rows on `test-1` by a prefix-scoped read), removes `test-1`, and repeats all six consumers across every sig/enc pair.
- CI `adoption-demo` has "Check demo signing keys are sealed" and "Doctor key encryption" steps; the clean-room journey runs the same commands after `Bootstrap.provision!`. `--check` fails on any legacy plaintext, unknown-KEK or old-KEK row (Phase 156 MIG-02, re-proven in the journey where `--check` first returns an error on a legacy row), so these are table-wide assertions that stored rows are current-KEK envelopes, which cannot hold plaintext `d` or `k`.

## Task Commits

1. **Task 1: tracer journey** - `e4ae2883` (test)
2. **Task 2: full journey** - `00170082` (test)
3. **Task 3: CI and clean-room commands** - `1b5066de` (ci)
4. **Credo fix in the journey (found by `mix qa`)** - `d170ef0b` (test)

## Files Created/Modified
- `test/support/signing_consumers.ex` - six consumer drivers plus `sign_all/1` and `verify_jwt/3`
- `test/integration/signing_key_upgrade_journey_test.exs` - tracer test and full journey
- `.github/workflows/ci.yml` - two adoption-demo steps
- `scripts/acceptance/clean_room_saas_journey.py` - two child commands after provisioning

## SAFE-01 gate

Run on 1.19.5-otp-28 (HEX_HOME=/private/tmp/lockspire-hex) over the final tree of the phase (HEAD `d170ef0b`, all of 157-01, -02, -04, -05, -06 landed). No permanent tag-relative CI test or script was added (`grep -rlE "v1\.42" .github/workflows scripts/ci` finds 0 files).

| # | Command | Exit | Evidence |
|---|---------|------|----------|
| 1 | `git diff --exit-code v1.42 -- mix.lock priv/repo/migrations` | 0 | empty diff |
| 2 | `git diff v1.42 -- mix.exs` filtered for dependency lines | none matched | diff is 3 insertions, 1 deletion (docs extras from 157-04) |
| 3 | `grep -rq private_jwk_encrypted priv/repo/migrations` | 0 | column still so named |
| 4 | `git log origin/main..HEAD --format=%B` through the D-22 grep (`BREAKING` or `type(scope)!:`) | grep exit 1, no output | 125 unpushed commits, no major-bump marker |
| 5 | `mix test test/lockspire/architecture_fitness_test.exs test/lockspire/config_key_encryption_test.exs test/lockspire/key_cache_test.exs` | 0 | 32 tests, 0 failures |
| 6 | `mix qa` | 0 | after the credo fix (first run failed on `Enum.count` in the journey test, fixed in `d170ef0b`; the final run is recorded) |
| 7 | `mix qa.dialyzer` | 0 | "done (passed successfully)" |
| 8 | `MIX_ENV=test mix test --include integration` | 0 | 2 properties, 2083 tests, 0 failures, 6 skipped |
| 9 | `mix test.clean-room.e2e` | 0 | full journey through "evidence scan complete" and "cleanup complete" |
| 10 | removed assert/refute lines in `test/lockspire/protocol` and `test/lockspire/security` since v1.42 | n/a | 2 lines, mapped below |

Removed assertions (`/private/tmp/lockspire-157-removed-asserts.txt`), both in `test/lockspire/protocol/private_jwk_test.exs`, owned by Phase 155 plan 03 (commit `47e94cb2`, envelope-aware map-form `PrivateJwk.decode` replaced by struct-form decode):

- `-assert {:ok, %{"kty" => "RSA"}} = PrivateJwk.decode(~s({"kty":"RSA"}))` - kept in the stronger struct form `PrivateJwk.decode(struct)` carrying `private_jwk_encrypted: ~s({"kty":"RSA"})`.
- `-assert {:ok, %{kty: :RSA}} = PrivateJwk.decode(:erlang.term_to_binary(%{kty: :RSA}))` - kept as `PrivateJwk.decode(row(:erlang.term_to_binary(%{kty: :RSA})))` (line 27).

No assertion was loosened or left unowned. Example, compat and clean-room lock differences from v1.42 are the DEP-01 bump only (not part of the root `mix.lock` check).

## Decisions Made
- Verify key and JWE target derive from the seeded legacy private JWK, because helper rows share one RSA key and their stub `public_jwk` has no `n` or `e`.
- Separate CI steps (not folded into the smoke script) for clearer failure output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Credo warning in the journey test**
- **Found during:** Task 3 (`mix qa` in the SAFE-01 gate)
- **Issue:** `Enum.count/2 == 0` flagged as expensive
- **Fix:** `refute Enum.any?/2`
- **Files modified:** test/integration/signing_key_upgrade_journey_test.exs
- **Verification:** `mix qa` exit 0 on the final run
- **Committed in:** `d170ef0b`

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** none on scope.

The `:enc` ETF row was built with the same `legacy_etf_row/2` helper (`use: :enc`); no special handling was needed.

## Issues Encountered
- The refute on a quoted `"d"` or `"k"` inside random envelope bytes has a negligible (about 6e-8 per row) chance of a false hit; accepted as in the plan.
- The `adoption-demo` CI job itself runs only on GitHub Actions; locally the YAML parses and the clean-room replay (which runs the same commands) is green. 157-02's demo seed rewrite is proven once that job passes (D-29).

## User Setup Required
None - no external service configuration required.

## Known Stubs
None.

## Next Phase Readiness
All 157 plans have a summary; the phase is ready for verification.

## Self-Check: PASSED

---
*Phase: 157-host-surfaces-redaction-sweep-release-proof*
*Completed: 2026-10-16*
