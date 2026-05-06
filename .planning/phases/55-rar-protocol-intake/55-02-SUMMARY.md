---
phase: 55
plan: 02
subsystem: protocol
tags: [rar, rfc-9396, par, authorize, interaction, validation, jason]
requires:
  - phase: 55-01
    provides: ":authorization_details domain field on PushedAuthorizationRequest and Interaction plus JSONB persistence"
provides:
  - "Validated.authorization_details typed slot on the /authorize protocol surface"
  - "Binary-JSON parse + already-decoded list passthrough for authorization_details"
  - "2048-byte direct-request length cap (skipped on the pushed pipeline) with stable :authorization_details_too_large reason code"
  - ":invalid_authorization_details redirect-safe error for non-array / non-object / malformed payloads"
  - "Validated.authorization_details propagation into PAR persistence and Interaction state"
affects:
  - .planning/phases/55-rar-protocol-intake/55-03-PLAN.md
  - .planning/phases/56-rar-validation-storage/
  - .planning/phases/57-rar-introspection-e2e/
tech-stack:
  added: []
  patterns:
    - "Pushed-aware validation: a single validator branches on the pushed? flag instead of duplicating the pipeline"
    - "Project-then-pass: validated structs carry RAR via the same shape used for resources/scopes/prompt"
key-files:
  created:
    - .planning/phases/55-rar-protocol-intake/55-02-SUMMARY.md
  modified:
    - lib/lockspire/protocol/authorization_request.ex
    - lib/lockspire/protocol/pushed_authorization_request.ex
    - lib/lockspire/protocol/authorization_flow.ex
    - test/lockspire/protocol/authorization_request_test.exs
    - test/lockspire/protocol/pushed_authorization_request_test.exs
    - test/lockspire/protocol/authorization_flow_test.exs
key-decisions:
  - "Apply the 2048-byte length cap on byte_size (not String.length) so multibyte payloads cannot bypass the URL-budget motivation behind the cap"
  - "Default the slot to [] rather than nil so callers (PAR persistence, Interaction state, downstream introspection) stay branch-free and the wire shape matches the storage shape from 55-01"
  - "Skip the length cap on the pushed pipeline because POST /par carries the payload in the request body — the cap exists to protect the GET/POST /authorize URL/form budget, not the PAR body"
  - "Use :invalid_authorization_details as both the OAuth `error` and `reason_code` to align with RFC 9396 §5.4 and to give telemetry a stable redirect-safe code"
patterns-established:
  - "Pushed-aware validators: take a pushed? boolean and short-circuit transport-level guards (length, conflict checks) when invoked from the PAR pipeline"
requirements-completed: [RAR-01]
duration: 12min
completed: 2026-05-06
---

# Phase 55 Plan 02: RAR Protocol Intake Summary

**Parses RFC 9396 `authorization_details` at the /authorize and /par protocol edge, enforces a 2048-byte cap on direct requests, and wires the parsed list through PAR persistence and Interaction state without disturbing the existing validation pipeline.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-06T07:29:00Z
- **Completed:** 2026-05-06T07:41:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `:authorization_details` to `Lockspire.Protocol.AuthorizationRequest.Validated` and routed it through `validate_with_client/3`, `build_validated/9`, and `pushed_request_to_params/1`.
- Implemented `validate_authorization_details/2` accepting binary JSON (decoded with `Jason.decode/1`) **and** already-decoded lists projected from a Request Object, while enforcing list-of-maps shape.
- Capped direct-request payloads at 2048 bytes with the dedicated redirect-safe reason code `:authorization_details_too_large`; PAR-side intake intentionally bypasses the cap because the body, not the URL, carries the payload.
- Threaded RAR through `Protocol.PushedAuthorizationRequest.persist_pushed_request/3` so the JSONB column from 55-01 is populated, and through `Protocol.AuthorizationFlow.build_interaction/5` so the Interaction state mirrors the validated request.
- Locked behaviour with new tests: 6 RAR tests on `AuthorizationRequest`, 1 round-trip test on PAR, and 2 end-state tests on `AuthorizationFlow` — all 76 protocol-edge tests in the affected suites green, plus the broader `test/lockspire/protocol/` directory at 377/0.

## Task Commits

Each task was committed atomically:

1. **Task 1: Update AuthorizationRequest validation and parsing** — `e56c4ac` (feat)
2. **Task 2: Update PAR protocol logic and persistence** — `f151691` (feat)
3. **Task 3: Update AuthorizationFlow to carry RAR to Interaction** — `5118661` (feat)

## Files Created/Modified

- `lib/lockspire/protocol/authorization_request.ex` — RAR field on `Validated`, `validate_authorization_details/2`, length cap, decode/shape guards, `pushed_request_to_params/1` projection
- `lib/lockspire/protocol/pushed_authorization_request.ex` — Pass `validated.authorization_details` into `PushedAuthorizationRequestState.issue/2`
- `lib/lockspire/protocol/authorization_flow.ex` — Project `validated.authorization_details` onto the persisted `Interaction` struct
- `test/lockspire/protocol/authorization_request_test.exs` — Acceptance, default, length cap, shape rejection, list passthrough, pushed-skip cases
- `test/lockspire/protocol/pushed_authorization_request_test.exs` — End-to-end PAR round-trip asserting RAR survives storage
- `test/lockspire/protocol/authorization_flow_test.exs` — RAR carried into Interaction; default-empty case

## Verification

- `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs` — 49 tests, 0 failures (was 43, +6 RAR cases).
- `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs` — 10 tests, 0 failures (was 9, +1 round-trip).
- `MIX_ENV=test mix test test/lockspire/protocol/authorization_flow_test.exs` — 17 tests, 0 failures (was 15, +2 RAR cases).
- `MIX_ENV=test mix test test/lockspire/protocol/` — 377 tests, 0 failures (50 tagged-excluded), confirming no regression to neighbouring protocol modules (JAR, DPoP, FAPI, CIBA, token exchange, refresh, etc.).

The verification command in the plan (`mix test ...`) was executed under `MIX_ENV=test` because this worktree was freshly created and the plan's bare `mix test` falls back to the runtime env once the test database is provisioned. This is a tooling reference — not a behavioural deviation — so it is not tracked under the deviation rules.

## Decisions Made

- **Byte-size cap, not character cap.** `byte_size/1` (not `String.length/1`) anchors the 2048 cap to the wire-format budget the cap exists to protect.
- **Empty list default.** `[]` keeps downstream call sites (PAR persistence, Interaction state, eventual introspection in Phase 57) branch-free and matches the storage default landed in 55-01.
- **Pushed pipeline bypasses the length cap.** The cap protects the URL/form budget on direct GET/POST `/authorize`. POST `/par` carries the payload in the request body, so applying the cap there would penalize the protocol path that is *meant* to carry rich authorization details.
- **`invalid_authorization_details` is its own error, not `invalid_request`.** RFC 9396 §5.4 calls out the dedicated error code; reusing it as the telemetry `reason_code` keeps the surface stable for operators.

## Deviations from Plan

None — plan executed exactly as written. The plan's structure-and-cap behaviour, signature changes, and three-task split all landed unchanged.

## Threat Surface

The plan's `<threat_model>` lists two mitigations; both are satisfied:

- **T-55-02 (Denial of Service / AuthorizationRequest / mitigate).** The 2048-byte cap is enforced before `Jason.decode/1` runs, preventing a hostile client from forcing the server to allocate-and-parse arbitrarily large JSON on the direct `/authorize` path. The cap is intentionally **not** applied on the pushed pipeline, where the body has already been authenticated and the surface is bounded by Plug's request-body size limit. Telemetry surfaces `:authorization_details_too_large` so operators can observe abuse attempts.
- **T-55-03 (Tampering / Jason.decode / mitigate).** Parsing uses `Jason.decode/1` (not `decode!/1`), so a malformed payload returns `{:error, _}` and is mapped to a redirect-safe `:invalid_authorization_details` rather than raising. Shape validation (`is_list/1` + `Enum.all?(&is_map/1)`) rejects scalars, mixed arrays, and stringly-typed top levels before any further plan plugs into the validated content schema.

No new external surface (HTTP endpoint, host callback, file IO) is introduced — intake reuses the existing `/authorize` and `/par` Plug routes, so no new threat flags are raised.

## Issues Encountered

None. The pre-existing `Validated` struct was already shaped to accept new optional list slots (compare `:resources`, `:prompt`, `:scopes`), so the additive change required no signature reshuffling beyond the documented `build_validated/8` → `build_validated/9` callers.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 55-03** can now consume `Validated.authorization_details`, the populated PAR `authorization_details` column, and the populated Interaction `authorization_details` column to drive whatever cross-pipeline assertions and end-to-end coverage are scoped there.
- **Phase 56 (RAR validation framework)** has the canonical "raw, post-parse, pre-binding" representation (`[map()]`) that the schema validator can plug into without revisiting transport-level guards.
- **Phase 57 (introspection / e2e)** can rely on the Interaction state already containing the RAR list, which is the same representation the introspection response will surface.

## Self-Check: PASSED

Verified each modified file exists on disk and each task commit is reachable from `HEAD`.

- FOUND: lib/lockspire/protocol/authorization_request.ex (modified)
- FOUND: lib/lockspire/protocol/pushed_authorization_request.ex (modified)
- FOUND: lib/lockspire/protocol/authorization_flow.ex (modified)
- FOUND: test/lockspire/protocol/authorization_request_test.exs (modified)
- FOUND: test/lockspire/protocol/pushed_authorization_request_test.exs (modified)
- FOUND: test/lockspire/protocol/authorization_flow_test.exs (modified)
- FOUND commit: e56c4ac (Task 1)
- FOUND commit: f151691 (Task 2)
- FOUND commit: 5118661 (Task 3)

---
*Phase: 55-rar-protocol-intake*
*Completed: 2026-05-06*
