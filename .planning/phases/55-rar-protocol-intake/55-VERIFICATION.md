---
phase: 55-rar-protocol-intake
verified: 2026-05-06T07:52:00Z
status: passed
score: 3/3 must-haves verified
overrides_applied: 0
deferred:
  - truth: "JAR (Request Object) projection carries authorization_details into the validated /authorize pipeline"
    addressed_in: "Phase 57"
    evidence: "Phase 57 V-02 success criterion: 'Verify FAPI 2.0 compatibility when RAR is used (exact matching, PAR enforcement)'. FAPI 2.0 mandates signed Request Objects; the JAR-RAR interop gap is structurally part of the FAPI-RAR e2e verification, not the phase 55 protocol-edge intake. Phase 55 ROADMAP success criteria scope to '/par and /authorize requests' generically; the three SCs (parse, persist, length-cap) are each demonstrably TRUE in the live codebase via integration test scenarios 1-5."
  - truth: "Consent UI surfaces authorization_details to the end user"
    addressed_in: "Phase 57"
    evidence: "Phase 57 success criterion 3: 'E2E tests verify that a complex RAR request results in correct consent UI and token introspection.' RFC 9396 §6 user-display requirement is the consent surface's responsibility; Phase 55 is explicitly 'Protocol Intake' per the 55-RESEARCH.md scope note ('host display deferred to later phases'). The RAR field is correctly carried into the Interaction record (verified end-to-end), which is the data dependency the consent surface in Phase 57 will consume."
  - truth: "Empty-array authorization_details rejected per RFC 9396 §2 (must be at least one element)"
    addressed_in: "Phase 56"
    evidence: "Phase 56 success criterion 2: 'Invalid RAR payloads are rejected with RFC-compliant error messages.' Empty-array semantics, type whitelisting, and structural shape validation are validation-tier concerns scoped to Phase 56's RAR Domain Validation framework. Phase 55 RAR-01 says 'Support authorization_details parameter (JSON array)' — intake, not schema enforcement."
  - truth: "PAR-consume re-validation through pushed_request_to_params does not double-validate or strand-mismatch with pushed-mode rules"
    addressed_in: "Phase 56"
    evidence: "Phase 56 will introduce structural validation; the WR-04 coupling becomes observable only once that validation lands. Reviewer notes: 'Today this is benign because validate_authorization_details_length only runs for is_binary(value) — a list bypasses it.' Spot-check: integration test 2 (PAR→Authorize carry-through) does push a small RAR through both pipelines and the Interaction record mirrors the input exactly, so the current behavior is locked in by the suite."
---

# Phase 55: RAR Protocol Intake Verification Report

**Phase Goal:** Clients can submit structured authorization details via PAR and Authorization requests.
**Verified:** 2026-05-06T07:52:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Lockspire accepts and parses the `authorization_details` JSON array | VERIFIED | `validate_authorization_details/2` at `lib/lockspire/protocol/authorization_request.ex:570-590` accepts both binary JSON (decoded via `Jason.decode/1` at line 608-613) and pre-decoded lists (line 584-585). Acceptance proven end-to-end by integration tests 1 and 3 in `test/integration/phase55_rar_intake_e2e_test.exs` (PAR intake + direct intake). 5/5 integration tests pass. 76/76 protocol-edge unit tests pass. |
| 2 | PAR correctly persists RAR details for subsequent authorization | VERIFIED | `Validated.authorization_details` is threaded into `PushedAuthorizationRequestState.issue/2` at `lib/lockspire/protocol/pushed_authorization_request.ex:113`; persisted via `PushedAuthorizationRequestRecord.changeset/2` (line 42 in cast list); read back via `pushed_request_to_params/1` at `lib/lockspire/protocol/authorization_request.ex:730`; carried into the Interaction by `build_interaction/5` at `lib/lockspire/protocol/authorization_flow.ex:260`. End-to-end carry-through proven by integration test 2 — `interaction.authorization_details == details` after follow-up `/authorize?request_uri=...`. JSONB column verified applied via `mix ecto.migrations` showing `up 20260506020000`. |
| 3 | Authorization requests without PAR are rejected if RAR details are too large (URI length protection) | VERIFIED | `validate_authorization_details_length/3` at `lib/lockspire/protocol/authorization_request.ex:592-606` enforces `byte_size > 2048` only when `pushed? == false` (the direct `/authorize` path). Returns `:redirect_error` with `error: "invalid_request"` and stable reason code `:authorization_details_too_large`. Proven by integration test 4 — a 2100-byte action string produces a 302 with `error=invalid_request` in the redirect Location and `refute location =~ "/consent/"`. PAR pipeline correctly bypasses the cap via `validate_authorization_details_length(_, true, _) :: :ok` at line 606. |

**Score:** 3/3 truths verified

### Deferred Items

Items observed by the code reviewer but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | JAR (Request Object) projection carries `authorization_details` | Phase 57 (V-02 FAPI 2.0 compatibility) | `lib/lockspire/protocol/request_object.ex:283-298` — `project_to_params/2` allowlist omits `authorization_details`. Real defect, but its scope is FAPI/JAR-RAR interop, which is Phase 57's V-02 territory. Phase 55 SCs scope to "/par and /authorize" generically and all three are TRUE for non-JAR transport. |
| 2 | Consent UI renders `authorization_details` to the end user | Phase 57 (SC #3 consent UI e2e) | `lib/lockspire/web/live/consent_live.ex:45-83` renders `@requested_scopes` only. RFC 9396 §6 user-display is a consent-surface concern; Phase 55 carries the data into `Interaction.authorization_details` (verified) so the Phase 57 consent rendering has a populated field to consume. |
| 3 | Empty-array `authorization_details=[]` rejected | Phase 56 (SC #2 invalid RAR rejection) | `ensure_authorization_details_shape/2` at line 615-621 accepts `[]` because `Enum.all?([], &is_map/1) == true`. RFC 9396 §2 element-presence is a validation-tier concern scoped to Phase 56. |
| 4 | `pushed_request_to_params` re-validation coupling | Phase 56 | Becomes observable only when Phase 56 adds structural validation. Currently benign per reviewer (length check only runs for `is_binary(value)`). Spot-check confirms current PAR→Authorize roundtrip preserves payload identity. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `priv/repo/migrations/20260506020000_add_rar_intake_state.exs` | Adds `authorization_details {:array, :map}` to PAR + Interaction tables, default `[]` | VERIFIED | Migration applied (`mix ecto.migrations` shows `up 20260506020000`). Adds column to both `lockspire_pushed_authorization_requests` and `lockspire_interactions` with `default: []`. |
| `lib/lockspire/domain/pushed_authorization_request.ex` | `:authorization_details` field on PAR domain struct, threaded through `issue/2` | VERIFIED | Field declared in typespec (line 22), defstruct (line 48), and `issue/2` wraps via `List.wrap` at line 70. |
| `lib/lockspire/domain/interaction.ex` | `:authorization_details` field on Interaction struct | VERIFIED | Field declared in typespec (line 18), defstruct (line 52). |
| `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex` | Schema field + cast in `changeset/2` + projection in `to_domain/2` | VERIFIED | Schema (line 18), cast list (line 42), `to_domain/2` projection (line 70). |
| `lib/lockspire/storage/ecto/interaction_record.ex` | Schema field + cast in `changeset/2` + projection in `to_domain/1` | VERIFIED | Schema (line 21), cast list (line 61), `to_domain/1` projection (line 112). |
| `lib/lockspire/protocol/authorization_request.ex` | `Validated.authorization_details` slot, `validate_authorization_details/2`, byte-size length cap, projection in `pushed_request_to_params/1` | VERIFIED | `Validated` struct (line 33, 54), validate function (570-590), length cap (592-606), shape check (615-623), error helper (625-633), projection (730), build_validated arity-9 (789-815). |
| `lib/lockspire/protocol/pushed_authorization_request.ex` | Pass `validated.authorization_details` into `PushedAuthorizationRequestState.issue/2` | VERIFIED | Line 113 — `authorization_details: validated.authorization_details`. |
| `lib/lockspire/protocol/authorization_flow.ex` | `build_interaction/5` projects `validated.authorization_details` onto Interaction | VERIFIED | Line 260 — `authorization_details: validated.authorization_details`. |
| `test/integration/phase55_rar_intake_e2e_test.exs` | 5 black-box scenarios | VERIFIED | File present, 5/5 tests passing under `MIX_ENV=test mix test ... --include integration`. Asserts read-back via `Repository.fetch_active_pushed_authorization_request/1` and `Repository.fetch_interaction/1`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `authorization_request.ex:Validated` | `pushed_authorization_request.ex:persist_pushed_request/3` | `validated.authorization_details` argument | WIRED | Line 113. |
| `authorization_request.ex:Validated` | `authorization_flow.ex:build_interaction/5` | `validated.authorization_details` argument | WIRED | Line 260. |
| `domain/pushed_authorization_request.ex` | `storage/ecto/pushed_authorization_request_record.ex` | `Map.from_struct` + `cast` + `to_domain` | WIRED | Cast at line 42; to_domain at line 70. JSONB column round-trip proven by integration test 1 read-back. |
| `domain/interaction.ex` | `storage/ecto/interaction_record.ex` | `Map.from_struct` + `cast` + `to_domain` | WIRED | Cast at line 61; to_domain at line 112. JSONB column round-trip proven by integration test 2 read-back. |
| `authorization_request.ex:pushed_request_to_params/1` | re-entrant `validate_with_client/3` (PAR consume path) | `"authorization_details" => request.authorization_details` | WIRED | Line 730. List bypasses length cap (line 606 takes pushed-style path on the binary clause; list clause goes straight to `ensure_authorization_details_shape/2`). |
| `web/controllers/par_controller` -> `protocol/pushed_authorization_request.push/1` | `Validated.authorization_details` populated | direct call | WIRED | Verified by integration test 1: POST /par returns 201 and `stored_par.authorization_details == details`. |
| `web/controllers/authorize_controller` -> `protocol/authorization_request.validate/1` | `Validated.authorization_details` -> `Interaction.authorization_details` | direct call | WIRED | Verified by integration tests 2 and 3: GET /authorize → 302 to /consent/<id> → `interaction.authorization_details == details`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `authorization_request.ex:Validated.authorization_details` | `authorization_details` field | `validate_authorization_details/2` parses input params | Yes — Jason.decode of binary or list passthrough | FLOWING |
| `pushed_authorization_request_record.authorization_details` (DB column) | JSONB column | `changeset/2` cast from PAR domain struct | Yes — round-trip proven by `assert stored_par.authorization_details == details` (integration test 1) | FLOWING |
| `interaction_record.authorization_details` (DB column) | JSONB column | `changeset/2` cast from Interaction domain struct | Yes — round-trip proven by `assert interaction.authorization_details == details` (integration tests 2, 3) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 55 integration suite is green | `MIX_ENV=test mix test test/integration/phase55_rar_intake_e2e_test.exs --include integration` | 5 tests, 0 failures | PASS |
| Protocol-edge unit suites are green | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/protocol/authorization_flow_test.exs` | 76 tests, 0 failures | PASS |
| RAR migration applied to test DB | `MIX_ENV=test mix ecto.migrations \| grep 20260506020000` | `up 20260506020000 add_rar_intake_state` | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| RAR-01 | 55-01, 55-02, 55-03 | Support `authorization_details` parameter (JSON array) in PAR and Authorization requests | SATISFIED | Roadmap Phase 55 maps RAR-01 → Phase 55. All three roadmap success criteria for Phase 55 (parse JSON array, persist via PAR, length-cap on direct) are verified by codebase + integration tests. No orphaned requirements: REQUIREMENTS.md lists only RAR-01 against Phase 55, and all three plan frontmatters declare `requirements: [RAR-01]`. |

No orphaned requirements. No undeclared requirement IDs from REQUIREMENTS.md were left unmapped.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/lockspire/protocol/request_object.ex` | 283-298 | `project_to_params/2` allowlist omits `authorization_details` | Info | Real defect (WR-01) — JAR-wrapped requests silently drop RAR. Deferred to Phase 57 (V-02 FAPI 2.0 compatibility). Does not block Phase 55 SCs. |
| `lib/lockspire/protocol/authorization_request.ex` | 615-621 | `ensure_authorization_details_shape/2` accepts `[]` (empty list) as valid | Info | RFC 9396 §2 ambiguity (WR-03). Deferred to Phase 56 (validation tier). Does not block Phase 55 intake SCs. |
| `lib/lockspire/web/live/consent_live.ex` | 45-83 | Reference consent surface does not render `authorization_details` | Info | RFC 9396 §6 surface-tier concern (WR-02). Deferred to Phase 57 (SC #3 consent UI e2e). The data is correctly carried into Interaction; surfacing is a consent-tier responsibility. |
| `lib/lockspire/protocol/authorization_request.ex` | 723-739 | `pushed_request_to_params/1` re-feeds `authorization_details` through `validate_with_client/3` on PAR consume | Info | Today benign (WR-04). Will require attention when Phase 56 introduces structural validation. Spot-checked: integration test 2 confirms current roundtrip identity. |
| `test/lockspire/protocol/authorization_request_test.exs` | 897 | Test description says "characters" but cap is bytes | Info | IN-01 cosmetic. No behavioural impact. |

No critical or warning anti-patterns affect the Phase 55 success criteria. All four reviewer warnings are documentable as either Phase 56/57 territory (validation tier, consent surface, JAR/FAPI interop) or non-blocking coupling concerns surfaced for future authors.

### Human Verification Required

None. All three roadmap success criteria are exercised by the integration suite at the same trust boundary (Repository read-back) that downstream phases will read from. Visual consent rendering of RAR is explicitly deferred to Phase 57.

### Gaps Summary

No gaps block Phase 55 goal achievement. The reviewer-flagged warnings (WR-01 JAR projection, WR-02 consent UI, WR-03 empty-array, WR-04 round-trip coupling) are valid issues, but each maps cleanly to a later milestone phase's success criteria — they are out-of-scope follow-ups for Phase 55, not goal-blocking gaps.

The phase delivers exactly what the goal states: clients can submit structured authorization details via PAR and Authorization requests. The three roadmap SCs are demonstrably true in the live codebase, locked in by 5 black-box integration scenarios that round-trip the JSONB column through the same Repository fetch helpers that Phase 57's introspection will use.

---

_Verified: 2026-05-06T07:52:00Z_
_Verifier: Claude (gsd-verifier)_
