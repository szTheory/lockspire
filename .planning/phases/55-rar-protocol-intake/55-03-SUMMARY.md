---
phase: 55
plan: 03
subsystem: integration
tags: [rar, rfc-9396, par, authorize, interaction, e2e, integration-tests]
requires:
  - phase: 55-01
    provides: ":authorization_details JSONB column and domain field on PAR + Interaction"
  - phase: 55-02
    provides: "Validated.authorization_details intake with 2048-byte direct cap and PAR/Interaction propagation"
provides:
  - "End-to-end integration coverage for RAR intake across /par, /authorize (request_uri), direct /authorize, length cap, and malformed JSON paths"
  - "Black-box assertion that the durable Interaction.authorization_details column mirrors the pushed RAR list (read-back via Repository.fetch_interaction/1)"
  - "Black-box assertion that the durable PAR record persists the decoded RAR list (read-back via Repository.fetch_active_pushed_authorization_request/1)"
affects:
  - .planning/phases/56-rar-validation-storage/
  - .planning/phases/57-rar-introspection-e2e/
tech-stack:
  added: []
  patterns:
    - "Sibling-shape integration test mirroring `test/integration/phase54_resource_indicators_e2e_test.exs` (host resolver stub, manual SQL sandbox, key bootstrap)"
    - "Black-box JSONB round-trip verification via Repository fetch helpers instead of asserting on protocol-internal structs"
key-files:
  created:
    - test/integration/phase55_rar_intake_e2e_test.exs
  modified: []
key-decisions:
  - "Mirror the Phase 54 integration test's setup boilerplate (resolver, sandbox, key activation, client registration) so future phases can compose new RAR scenarios without re-deriving the harness"
  - "Verify the PAR persistence round-trip via `Repository.fetch_active_pushed_authorization_request/1` rather than reaching into protocol internals — this keeps the assertion at the trust boundary the storage column is meant to defend"
  - "Verify the Interaction carry-through via `Repository.fetch_interaction/1` against the `interaction_id` parsed from the consent redirect — this is the same path the consent UI and the eventual introspection surface (Phase 57) will read"
  - "Build the >2048-byte payload from a single bulky `actions[0]` string so the JSON is structurally valid (passing decode + shape) and the cap is the only thing that can reject it; this isolates the cap from the malformed-JSON case"
  - "Use distinct `nonce` values per test so test parallelism (when re-enabled) cannot collide on the OIDC nonce"
patterns-established:
  - "Phase-NN e2e tests in `test/integration/phaseNN_*_e2e_test.exs` consistently use `:integration` moduletag, manual SQL sandbox, and an inline host resolver stub"
requirements-completed: [RAR-01]
duration: 1min
completed: 2026-05-06
---

# Phase 55 Plan 03: RAR Intake End-to-End Verification Summary

**Locks down the Phase 55 RAR intake surface with an integration suite that exercises PAR push, PAR→Authorize carry-through, direct intake, the 2048-byte direct-request cap, and malformed-JSON rejection — asserting durable Interaction and PAR storage round-trips at the same trust boundary downstream phases will read from.**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-05-06T07:39:20Z
- **Completed:** 2026-05-06T07:40:45Z
- **Tasks:** 1
- **Files created:** 1
- **Files modified:** 0

## Accomplishments

- Added `test/integration/phase55_rar_intake_e2e_test.exs` mirroring the Phase 54 sibling shape (host resolver stub, manual SQL sandbox, key generate/publish/activate, confidential client registration with `client_secret_post`).
- Five black-box scenarios cover the full RAR intake matrix:
  1. **PAR intake** — `POST /par` with `authorization_details` returns 201 and the decoded RAR list survives into `Repository.fetch_active_pushed_authorization_request/1`'s domain struct.
  2. **PAR → Authorize → Interaction** — Following the `request_uri` to `/authorize` lands a redirect to `/consent/<id>` whose Interaction record carries the same RAR list when read back via `Repository.fetch_interaction/1`.
  3. **Direct intake (success)** — Small `authorization_details` on a direct `GET /authorize` request is accepted, the consent redirect is issued, and the persisted Interaction mirrors the payload.
  4. **Direct intake (length cap)** — A structurally-valid RAR JSON with `byte_size(encoded) > 2048` produces a redirect-safe `error=invalid_request` response back to the registered redirect URI and never reaches the consent stage.
  5. **Malformed JSON** — `"{not-json"` surfaces the RFC 9396 §5.4 `error=invalid_authorization_details` redirect-safe code without leaking parser state and never reaches the consent stage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create integration tests for RAR intake** — `9a64415` (test)

## Files Created/Modified

- `test/integration/phase55_rar_intake_e2e_test.exs` — Five `describe`-grouped scenarios (PAR intake, PAR→Authorize carry, direct success, direct length cap, malformed JSON) plus shared `setup` registering a confidential client with PKCE S256 challenge and an inline `RarHostResolver` host implementation.

## Verification

- `MIX_ENV=test mix test test/integration/phase55_rar_intake_e2e_test.exs --include integration` — **5 tests, 0 failures**.
- `MIX_ENV=test mix test test/integration/ --include integration` — **77 tests, 0 failures** (full integration suite, no regression to Phase 54 or other neighbouring e2e suites).

The plan's verification command (`mix test ...`) was executed under `MIX_ENV=test --include integration` because the test file carries `@moduletag :integration` (matching the Phase 54 sibling); ExUnit's default config excludes that tag. This is a tooling-flag detail — not a behavioural deviation — so it is not tracked under the deviation rules.

## Decisions Made

- **Black-box assertions only.** Each test asserts via the Repository's public domain-side reads (`fetch_active_pushed_authorization_request/1`, `fetch_interaction/1`) rather than reaching into `Validated` or any other protocol-internal struct. This keeps the suite anchored to the same boundary downstream phases (introspection in 57) will read, so a regression in any layer between the wire and the JSONB column will fail this suite.
- **Length-cap payload uses a single bulky `actions[0]` string.** The shape stays valid (one map with `type` and `actions`) so the parser and shape guard pass — meaning the >2048-byte cap is the only reason the request can be rejected. This isolates the cap from the malformed-JSON case below.
- **Distinct nonces per test.** Each test uses a unique `nonce-N` so that, even when the integration suite is later flipped to `async: true`, the OIDC nonce won't collide across cases.

## Deviations from Plan

None — plan executed exactly as written. The single task landed in one commit with all five required scenarios (PAR intake, PAR→Authorize carry, direct success, direct rejection, malformed JSON) green on first execution.

## Threat Surface

The plan's `<threat_model>` lists `T-55-04` (Information Disclosure / Error Responses / mitigate). That mitigation is verified by this suite:

- The **length-cap** assertion confirms the rejection redirects to the registered `redirect_uri` with `error=invalid_request` and **does not** include any internal state — no Jason error message, no decoder offset, no payload echo. It also never lands on `/consent/`, confirming the cap stops processing before any persistent state is written.
- The **malformed-JSON** assertion confirms the dedicated `error=invalid_authorization_details` code per RFC 9396 §5.4, again with no internal state leakage and no consent-side state mutation.

No new external surface (HTTP endpoint, host callback, file IO) is introduced — the suite only exercises endpoints already shipped by 55-01 / 55-02. No new threat flags to raise.

## Issues Encountered

None. The Phase 54 sibling test (`phase54_resource_indicators_e2e_test.exs`) provided a fully-formed harness shape that composed cleanly over the 55-02 protocol surface. The Repository's `fetch_active_pushed_authorization_request/1` exists precisely for non-consuming reads, which made the PAR round-trip assertion a one-call check.

## User Setup Required

None — no external service configuration required. The integration suite uses `Lockspire.TestRepo` with `Ecto.Adapters.SQL.Sandbox` in manual mode and `Lockspire.Web.Endpoint` in `server: false` test mode.

## Next Phase Readiness

- **Phase 56 (RAR validation framework)** can now layer schema/policy validation on top of the intake surface knowing that the boundary it inherits is exercised end-to-end. Any regression in the schema validator will surface in this suite via the carry-through assertions.
- **Phase 57 (RAR introspection / e2e)** can rely on `Interaction.authorization_details` being populated from the same wire input the introspection response will need to surface, and can extend this suite with token-exchange/introspection assertions without re-deriving the consent-redirect parse.

## Self-Check: PASSED

Verified each created file exists on disk and the task commit is reachable from `HEAD`.

- FOUND: test/integration/phase55_rar_intake_e2e_test.exs
- FOUND commit: 9a64415 (Task 1)

---
*Phase: 55-rar-protocol-intake*
*Completed: 2026-05-06*
