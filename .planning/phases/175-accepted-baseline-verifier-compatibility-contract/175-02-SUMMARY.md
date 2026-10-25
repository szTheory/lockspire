---
phase: 175-accepted-baseline-verifier-compatibility-contract
plan: "02"
subsystem: security-qualification
tags: [client-secret-jwt, plug-crypto, legacy-compatibility, postgres]

# Dependency graph
requires:
  - phase: 175-01
    provides: Fresh accepted baseline and retained custody context
provides:
  - Persisted-caller evidence for legacy verifier age, lifecycle boundaries, and durable effects
  - Public authenticated metadata-reader evidence on root and declared-floor dependencies
  - Owner-approved native and migrated verifier age policy with explicit supported/recovery dispositions
affects: [175-03, verifier-compatibility, client-secret-jwt]

# Actuals (#2632)
actuals:
  tokens: 10094
  tasks: 3
  commits: 3
commits: 3
plan_head_before: c8d9ebd25cccba5a592ece0b5cff696deb0f6530
plan_head_after: c6df0a877f8c4975662b14ef26ad7df940eb803a

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Qualify Plug wall-clock verifier age separately from injected client lifecycle time
    - Record only case IDs, outcomes, dependency identities, and durable-effect booleans in qualification evidence

key-files:
  created:
    - test/integration/client_secret_jwt_legacy_age_test.exs
    - test/lockspire/security/client_secret_verifier_compatibility_test.exs
    - test/support/client_secret_verifier_fixtures.ex
    - .planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-POLICY-REVISION.md
  modified:
    - .planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-QUALIFICATION.json
    - .planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTEXT.md

key-decisions:
  - "Owner approved the recommended D-20 revision on 2026-10-25 with the exact response 'Approve the recommended revision'."
  - "Native dedicated verifier validity follows configured client-secret lifetime; migrated legacy rows preserve their authenticated original finite deadline and equality-valid/strict-after-expiry boundary."
  - "Unsupported or unbounded migration inputs remain unchanged and require authorized secret rotation/reprovision; approval authorizes policy qualification, not implementation or publication."

patterns-established:
  - "Separate Plug storage-age observations from client and secret lifecycle expiry, which rejects at equality."
  - "Keep metadata decoding behind public authenticated decrypt and safe-term APIs, with malformed and unsupported forms explicitly classified."

requirements-completed: []

coverage:
  - id: D1
    description: Persisted legacy caller and public metadata compatibility evidence with redacted outcomes and exact dependency identities
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test --include integration test/integration/client_secret_jwt_legacy_age_test.exs (10 tests, 0 failures; task feedback rerun 9/9)"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_compatibility_test.exs (root and declared floor, 9 tests each, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: Explicit owner-approved D-20 policy and qualified material gate for dependent planning
    verification:
      - kind: other
        ref: "Literal 175-02 Task 03 material-gate Python assertion; JSON parse; git diff --check"
        status: pass
    human_judgment: false

# Metrics
duration: "10min+"
completed: 2026-10-25
status: complete
---

# Phase 175 Plan 02: Legacy Verifier Qualification Summary

**Persisted caller evidence now distinguishes Plug's authenticated legacy age from configured lifecycle expiry, and the owner-approved native/migrated policy clears the material gate for Plan 03.**

## Performance

- **Duration:** At least 10 minutes from the earliest recorded artifact timestamp; earlier execution timing was not captured in this continuation.
- **Started:** 2026-10-25T18:44:12Z (earliest recorded task artifact timestamp)
- **Completed:** 2026-10-25T18:53:50Z
- **Tasks:** 3/3
- **Files modified:** 6

## Accomplishments

- Qualified actual persisted `ClientAuth.authenticate/3` outcomes with distinct fresh assertions/JTIs, including usable fresh and 23-hour material, expired/future/malformed/wrong-key/missing verifier cases, client lifecycle boundaries, v0 unlimited lifetime, and durable effect observations.
- Qualified public authenticated metadata reading and safe decoding on root-locked Phoenix 1.8.13 / LiveView 1.2.10 / Plug.Crypto 2.2.1 and declared-floor Phoenix 1.8.5 / LiveView 1.1.28 / Plug.Crypto 2.2.1. Supported historical tuple-three, tuple-two, and map shapes are recorded; unsupported shapes and recovery remain explicit.
- Recorded the owner's exact approval of the D-20 revision in the policy proposal, qualification record, and context. The native-age and public-metadata material gates now pass, and dependent planning is ready for Plan 03 only.

## Task Commits

Each task was committed atomically:

1. **Task 1: Qualify persisted fresh and aged JWT clients through the actual caller** - `c7cedee9` (`test(175-02): qualify persisted legacy verifier callers`)
2. **Task 2: Qualify public authenticated metadata and helper compatibility boundaries** - `e8aa26f5` (`test(175-02): qualify Plug metadata and verifier compatibility`)
3. **Task 3: Record the native and migrated age policy gate** - `c6df0a87` (`docs(175-02): record approved native verifier age policy`)

## Files Created/Modified

- `test/integration/client_secret_jwt_legacy_age_test.exs` - PostgreSQL-backed legacy age and lifecycle caller cases.
- `test/support/client_secret_verifier_fixtures.ex` - Authenticated historical verifier fixtures and qualification-only metadata reader.
- `test/lockspire/security/client_secret_verifier_compatibility_test.exs` - Public helper, authenticated metadata-shape, and finite deadline compatibility cases.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-QUALIFICATION.json` - Exact identities, redacted results, owner approval, and qualified material gates.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-POLICY-REVISION.md` - Proposed D-20 policy with the exact owner response and approved scope.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTEXT.md` - Preserved historical D-20 recommendation plus explicit owner disposition.

## Decisions Made

- The owner approved native dedicated validity based on configured client-secret lifetime, including `nil`/`0` and v0-unlimited lifetimes beyond 24 hours, while client-app expiry remains separate.
- Migrated legacy material must retain its authenticated original finite deadline and the equality-valid/strict-after-expiry boundary. Unsupported future, malformed, tampered, wrong-key, unsupported-shape, and unbounded-age inputs remain unchanged and recover through authorized rotation/reprovision.
- `within_approved_policy` remains `false` for the original policy basis; `approved_revision_ref` names the explicitly approved revision. This is planning qualification, not production implementation.

## Deviations from Plan

### Recorded execution deviations

**1. Task 02 expansion began before the Task 01 tracer feedback gate.**
- **Found during:** Task 02
- **Issue:** Compatibility expansion started before the Task 01 commit and tracer feedback rerun.
- **Fix:** After Task 01 commit `c7cedee9`, reran the literal persisted-caller command; it passed 9/9. The completed Task 02 caller cases then passed 10/10.
- **Files modified:** Qualification evidence records the sequence and rerun.
- **Verification:** Task 01 tracer feedback 9/9; final caller suite 10/10.
- **Committed in:** `e8aa26f5` (deviation record); Task 01 evidence remains in `c7cedee9`.

**2. Initial Task 01/02 edits preceded the supplied-root pin check.**
- **Found during:** Continuation at Task 03
- **Issue:** The initial execution had not recorded the orchestrator-supplied project-root guard before its first writes.
- **Fix:** Re-ran the supplied pin guard before Task 03 edits; it confirmed `/Users/jon/projects/lockspire`, the expected milestone branch, and a clean tree at `e8aa26f5`.
- **Files modified:** No additional files; all Task 03 writes remained under the pinned repository root.
- **Verification:** Supplied-root pin passed before Task 03 edits and the Task 03 commit.
- **Committed in:** `c6df0a87`.

**Total deviations:** 2 recorded execution deviations (ordering and root-pin protocol).
**Impact on plan:** Both were surfaced and corrected; no unrelated source checks were rerun, and no production code, dependency, schema, or authentication default changed.

## Issues Encountered

- The native-age gate initially awaited a human policy decision. The owner supplied the explicit response “Approve the recommended revision” on 2026-10-25; approval is recorded with its full scope and limits.
- The original one-day Plug age and configured lifecycle expiry use distinct clocks and boundary behavior. The summary preserves those distinctions and does not infer adopter impact from synthetic aged fixtures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 is complete. Both material gates pass and Plan 03 may freeze the finite contract and reconcile final source. Phase 175 remains in progress at Plan 3 of 3; VBASE-02 remains pending until its finite contract is complete. No Phase 176 planning, production implementation, publication, deployment, or cleanup is authorized by this plan.

---
*Phase: 175-accepted-baseline-verifier-compatibility-contract*
*Completed: 2026-10-25*

## Self-Check: PASSED

- Task artifacts exist and the policy gate command passed.
- Task commits `c7cedee9`, `e8aa26f5`, and `c6df0a87` are ancestors of HEAD.
- Persisted plan ledger measures 3 commits from `c8d9ebd25cccba5a592ece0b5cff696deb0f6530` through `c6df0a877f8c4975662b14ef26ad7df940eb803a`.
