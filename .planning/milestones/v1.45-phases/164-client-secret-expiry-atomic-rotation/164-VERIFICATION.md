---
phase: 164-client-secret-expiry-atomic-rotation
verified: 2026-10-22T16:28:05Z
status: passed
score: 26/26 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-01-PLAN.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-01-SUMMARY.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-02-PLAN.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-02-SUMMARY.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-03-PLAN.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-03-SUMMARY.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-04-PLAN.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-04-SUMMARY.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-05-PLAN.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-05-SUMMARY.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-06-PLAN.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-06-SUMMARY.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-CONTEXT.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-COVERAGE.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-EXECUTION-REFRESH.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-REVIEW-DISPOSITION.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-REVIEW-FIX.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-REVIEW.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-SECURITY.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-SOURCE-AUDIT.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-UI-REVIEW.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-VALIDATION.md
  - PRODUCT.md
  - docs/client-secret-jwt-host-guide.md
  - docs/dynamic-registration.md
  - docs/upgrading/client-lifetimes.md
  - lib/lockspire/admin/clients.ex
  - lib/lockspire/client_lifecycle.ex
  - lib/lockspire/client_metadata.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/protocol/client_auth.ex
  - lib/lockspire/protocol/dcr_policy.ex
  - lib/lockspire/protocol/registration.ex
  - lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex
  - lib/lockspire/protocol/token_exchange/internal/device_code_grant.ex
  - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
  - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
  - lib/lockspire/storage/client_lifetime.ex
  - lib/lockspire/storage/client_store.ex
  - lib/lockspire/storage/ecto/repository.ex
  - lib/lockspire/storage/ecto/repository/client_store.ex
  - lib/lockspire/storage/ecto/server_policy_record.ex
  - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
  - lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex
  - lib/lockspire/web/registration_json.ex
  - test/integration/app_lifetime_ciba_push_test.exs
  - test/integration/client_secret_lifetime_code_refresh_test.exs
  - test/integration/client_secret_lifetime_existing_tokens_test.exs
  - test/integration/client_secret_lifetime_poll_exchange_test.exs
  - test/integration/client_secret_lifetime_registration_test.exs
  - test/integration/client_secret_lifetime_rotation_test.exs
  - test/lockspire/admin/clients_test.exs
  - test/lockspire/client_lifecycle_test.exs
  - test/lockspire/client_lifetime_guidance_test.exs
  - test/lockspire/protocol/client_secret_lifetime_auth_test.exs
  - test/lockspire/protocol/client_secret_lifetime_jwt_boundary_test.exs
  - test/lockspire/protocol/client_secret_lifetime_policy_test.exs
  - test/lockspire/protocol/dcr_telemetry_redaction_test.exs
  - test/lockspire/protocol/rfc8693_exchange_test.exs
  - test/lockspire/storage/client_lifetime_conformance_test.exs
  - test/lockspire/storage/client_lifetime_promotion_test.exs
  - test/lockspire/storage/client_lifetime_rollback_test.exs
  - test/lockspire/storage/client_secret_lifetime_client_wait_test.exs
  - test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs
  - test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs
  - test/lockspire/web/controllers/registration_controller_test.exs
  - test/lockspire/web/introspection_controller_test.exs
  - test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs
  - test/lockspire/web/live/admin/policies_live/dcr_test.exs
  - test/lockspire/web/registration_json_test.exs
  - test/lockspire/web/revocation_controller_test.exs
  - test/lockspire/web/token_controller_test.exs
covered_digest: "v3:sha256:315aa027b3fd7aa14fc05b5b97cf5f9c11a5659475cf5b90babd53358710feb3"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 26/26
  gaps_closed:
    - "WR-01 / D-02: malformed post-lock RFC 8693 decision time returns controlled server_error before issuance or audit."
  gaps_remaining: []
  regressions: []
decision_coverage:
  honored: 18
  total: 18
  not_honored: []
---

# Phase 164: Client-Secret Expiry & Atomic Rotation Verification Report

**Phase Goal:** Apps can rely on shared-secret expiry metadata matching authentication and operator rotation.
**Verified:** 2026-10-22T16:28:05Z
**Status:** passed
**Re-verification:** Yes — after WR-01 correction

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Registration persists and advertises the effective unset/zero/positive secret expiry, including omission for non-secret methods, and Basic follows the strict deadline. | ✓ VERIFIED | `Client.secret_deadline/3` validates and snapshots whole-second UTC time; `ClientMetadata` persists it; registration serialization uses `effective_secret_deadline/1`. The real registration integration test verifies fetched PostgreSQL state, wire Unix time, and Basic before/equality/after. |
| 2 | Basic, post, and secret-JWT authentication share strict secret expiry; JWT assertion timing and replay protections remain independent. | ✓ VERIFIED | `Client.secret_eligibility/3` is called after verified material/assertion. Auth matrix and finite-JWT boundary tests cover strict equality, assertion claims, algorithm, and one-time JTI use. |
| 3 | Operator rotation atomically applies current policy to replacement material while preserving prior-credential, concurrency, and rollback semantics. | ✓ VERIFIED | The Ecto client store reloads under row lock, reads current applicable policy, samples its deferred clock, writes hash/verifier/deadline/version/timestamps, and participates in required audit transaction. Rotation, promotion, rollback, and PostgreSQL competing-rotation tests cover the contract. |
| 4 | Nil/zero mean unlimited; malformed policy is rejected at write/use boundaries and corrupt policy maps to server_error. | ✓ VERIFIED | DCR resolver, changeset, form, and domain validator enforce nil or bounded integer; focused policy tests cover rejected values and error mapping. |
| 5 | DCR defaults follow registration provenance; no-secret methods omit expiry even with dormant material; direct registration retains its existing policy boundary. | ✓ VERIFIED | DCR construction sets self-registration provenance and method; `effective_secret_deadline/1` marks non-secret methods inapplicable. Registration and serializer tests cover these cases. |
| 6 | Legacy v0 secret dates remain advisory on reads, updates, and authentication; policy edits do not recalculate stored deadlines or disclose plaintext. | ✓ VERIFIED | Version-aware effective deadline treats v0 as unlimited; metadata serialization omits raw secret dates before adding the effective value. Focused v0, policy-edit, and no-plaintext tests pass. |
| 7 | Code and refresh finalizers recheck verified method/material identity and secret eligibility using a fresh time after client and token locks. | ✓ VERIFIED | Grant persistence and refresh builder lock current client/token state before sampling the final time and invoking `validate_current_authority/4`. Code/refresh integration tests exercise stale identity, deadline, and no-consumption paths. |
| 8 | Secret-JWT assertion signature, algorithm, claims, expiry, and JTI checks remain independent; final issuance does not consume the JTI twice. | ✓ VERIFIED | Client-auth verification and final current-identity validation are separate. The named finite-JWT boundary test passed: valid pre-deadline assertion, replay denial, then strict secret equality denial with a fresh still-valid assertion. |
| 9 | Expired callers retain generic invalid_client/challenge responses; issued tokens keep their own validity; confidential refresh still requires current authentication. | ✓ VERIFIED | Endpoint and integration tests assert established challenges/error shapes, preserved existing-token validity, and refresh authentication. Secret expiry is not used to cap/revoke issued tokens. |
| 10 | Invalid durable lifetime state or clock/configuration failures map to server_error at ingress and final authority checks. | ✓ VERIFIED | Domain validation and authentication/finalizer mappings return server_error. The current public RFC 8693 regression supplies a valid initial time and malformed post-input-lock final time; it observes `server_error/:clock_unavailable`, unchanged token inventory, and no audit. The original failure was reproduced as FunctionClauseError (8 tests, 1 failure); the corrected path is covered by the current 27-test green selection. |
| 11 | Rotation uses current locked provenance and policy; replacement hash, verifier, time, deadline, version, and audit commit together using post-lock decision time. | ✓ VERIFIED | `rotate_client_secret/5` queries the current row with a lock, reads policy for eligible self-registered methods, invokes the supplied clock afterward, then writes the complete replacement lifecycle. Rotation and rollback coverage verifies atomicity. |
| 12 | V0 replacement clears all historical deadlines and sets only the replacement secret deadline; v1 replacement preserves app and management deadlines. | ✓ VERIFIED | `credential_lifetime_changes/3` clears all three v0 dates before v1 promotion and changes only the secret date for v1. Promotion and replacement tests assert durable values. |
| 13 | Authorized rotation accepts expired secrets without old-secret proof, does not renew disabled/expired apps, preserves dormant-method behavior, and serializes last-commit-winner rotation. | ✓ VERIFIED | The operator facade requires existing host authorization only; lifecycle tests and PostgreSQL rotation race tests prove current-row winner semantics and preserved app state. |
| 14 | Built-in and declared custom adapters share replacement/rollback authority; unsupported/lossy adapters fail explicitly and failures return no plaintext success. | ✓ VERIFIED | `ClientLifetime` declares/validates the adapter contract and transaction participants. Adapter conformance and injected write/audit failure tests prove callbacks, durable rollback, and no successful plaintext handoff. |
| 15 | Only committed replacement emits success audit/telemetry; stored secrets remain hashed and verifier protection remains intact. | ✓ VERIFIED | Audit construction consumes the committed client timestamp; repository persists hash and protected JWT verifier. Rotation, audit rollback, and redaction tests cover these channels. |
| 16 | Device/CIBA authenticated polling and RFC 8693 requester issuance recheck current secret authority after required request/input-token locks with a fresh decision instant. | ✓ VERIFIED | Device/CIBA poll and RFC requester paths call current authority checks inside final transaction builders after their blocking locks. Real PostgreSQL later-lock tests cover the waits and no-consumption result. |
| 17 | Secret expiry gates requester authentication only; it does not revoke/cap existing tokens or gate issuer validity, online targets, or queued CIBA push. | ✓ VERIFIED | Existing-token, issuer/requester, online target, and queued push integration cases assert the exemptions. CIBA entry points overwrite internal authority context so request data cannot select the queued-push path. |
| 18 | Non-secret methods retain existing final issuance paths even when dormant secret material is expired. | ✓ VERIFIED | Shared eligibility returns inapplicable for `none`, private-key JWT, and both mTLS methods; authentication and poll/exchange integration tests cover these routes. |
| 19 | Rejected polls/exchanges write no output token and do not consume approved grants while existing grant expiry, replay, app-state, and endpoint behavior remains intact. | ✓ VERIFIED | Poll/exchange tests compare grant/token/JTI state around denial and assert existing endpoint outcomes. The finalizer transaction rolls back all guarded writes. |
| 20 | Independent PostgreSQL sessions prove a preverified secret cannot issue after a confirmed current-client lock wait when it expires or rotates. | ✓ VERIFIED | Dedicated client-wait race module uses distinct backend sessions, `pg_blocking_pids`, and a barrier clock; its case is included in the final 38-test PostgreSQL selection. |
| 21 | Code, refresh, device/CIBA poll, and RFC requester finalizers resample eligibility after confirmed later grant/request/input-token waits without replaying JTI. | ✓ VERIFIED | Grant-wait race tests prove blockers and clock advancement after the wait for all five finalizers. Final PostgreSQL selection reports no exclusions. |
| 22 | Competing rotations serialize; post-wait policy/provenance/time and whole-row promotion are reflected in durable current state. | ✓ VERIFIED | Rotation race tests run independent sessions and inspect the committed row after serialized replacements. V0 and v1 cases check retained/cleared deadlines. |
| 23 | Injected write or audit failure leaves credential/lifecycle/audit state unchanged and returns no successful plaintext, including under contention. | ✓ VERIFIED | Failure triggers in rollback and rotation race tests compare complete persisted state and output shape; the explicit PostgreSQL selection ran these cases. |
| 24 | Real finite-secret issuance, use, rejection, and rotation produce nonempty observed redaction evidence across audit, telemetry, logs, and public errors. | ✓ VERIFIED | Redaction tests require positive per-event counts, exercise finite Basic and JWT lifecycle operations, unseal persisted verifier material for scanning, and include missing-count/nested-tuple negative controls. Independent security re-audit closed 24/24 threats. |
| 25 | Admin and host guidance match enforced unlimited/finite, prospective, legacy replacement, token-validity, and operator behavior in PRODUCT vocabulary. | ✓ VERIFIED | Rendered DCR copy, hint, vocabulary, and host guidance tests passed; replaced phrases were added to PRODUCT’s retired wording. UI copy review closed both initial findings. |
| 26 | Normal, PostgreSQL, adapter, architecture, and compatibility checks pass with exclusions visible; later-phase scope remains accurately bounded. | ✓ VERIFIED | Final gate log records compile success, 2,349 tests/0 failures (440 excluded, 6 skipped), and 38 PostgreSQL cases/0 failures/no exclusions. Guidance assigns management-token lifecycle to Phase 165 and cross-phase packaged proof to Phase 166. |

**Score:** 26/26 truths verified (0 present, behavior-unverified). The three ROADMAP success criteria are represented by truths 1–3.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| Plan 164-01 artifacts | Domain eligibility, actual registration tracer, policy validation | ✓ VERIFIED | All 3 declared artifacts exist and pass substantive checks. |
| Plan 164-02 artifacts | Auth matrix, code/refresh behavior, final authority | ✓ VERIFIED | All 3 declared artifacts exist and pass substantive checks. |
| Plan 164-03 artifacts | Rotation tracer, current-row store, adapter conformance | ✓ VERIFIED | All 3 declared artifacts exist and pass substantive checks. |
| Plan 164-04 artifacts | Poll/exchange and existing-token behavior | ✓ VERIFIED | Both declared test artifacts exist and pass substantive checks. |
| Plan 164-05 artifacts | Client wait, later grant wait, rotation-race evidence | ✓ VERIFIED | All 3 declared test artifacts exist and pass substantive checks. |
| Plan 164-06 artifacts | Non-vacuous redaction, host guidance, integrated validation | ✓ VERIFIED | All 3 declared artifacts exist and pass substantive checks. |

## Key Link Verification

The generic `verify.key-links` query returned false negatives because its literal-reference matcher does not resolve Elixir aliases or descriptive endpoints. I traced each declared link through call sites and behavior tests; none is unwired.

| Link group | Status | Evidence |
|---|---|---|
| Registration metadata → domain deadline helper; auth methods → domain eligibility; response serializer → effective deadline | WIRED | `ClientMetadata` calls `Client.secret_deadline/3`; `ClientAuth` calls `Client.secret_eligibility/3`; `RegistrationJson` calls `Client.effective_secret_deadline/1`. |
| Refresh finalizer → reusable current authority; operator facade → lifecycle → repository; current-row store → domain lifecycle changes; shared transaction → audit | WIRED | Refresh calls `GrantPersistence.validate_current_authority/4`; lifecycle delegates to repository replacement inside `transact_with_audit`; store invokes domain promotion logic under the locked row. |
| Authenticated CIBA/device polling → internal poll context; finalizers → current-authority guard | WIRED | Trusted entry points overwrite `authentication_authority`; persisted polling builders call the common current-state guard. |
| PostgreSQL wait tests → independent-session race helpers and final issuance builders | WIRED | Both race suites use the shared helper, distinct sessions, blocker evidence and deferred clocks, then exercise code/refresh/poll/RFC finalizers. |
| Actual finite-secret lifecycle → redaction assertions; PRODUCT vocabulary → rendered admin hints | WIRED | Redaction test performs registration/authentication/rotation before scanning observed output; rendered page/hint tests enforce current language and retired wording. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| DCR registration and response | `client_secret_expires_at` | Validated current DCR policy and registration time → domain helper → Ecto client row → effective serializer | Yes; fetched durable row and wire value asserted in PostgreSQL integration test | ✓ FLOWING |
| Basic/post/JWT decision | secret eligibility | Stored current client state, verified credential material/assertion, and decision clock | Yes; actual method and boundary tests | ✓ FLOWING |
| Guarded issuance | current authority and token/grant writes | Locked current client/grant/token rows and post-wait clock inside transactional persistence | Yes; integration and independent PostgreSQL sessions assert persisted state | ✓ FLOWING |
| Operator rotation | replacement hash/verifier/deadline/version/audit | Current locked client row, current applicable policy, deferred clock, atomic repository/audit transaction | Yes; PostgreSQL durable-state and rollback assertions | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Finite secret-JWT boundary and single-use assertion | Named `client_secret_lifetime_jwt_boundary_test.exs` selection recorded in `164-VALIDATION.md` | 1 test, 0 failures; valid before deadline, replay rejected, strict equality rejected | ✓ PASS |
| Integrated implementation regression | `/private/tmp/lockspire164-final-fast.log` | 2 properties, 2,349 tests, 0 failures; 440 excluded and 6 skipped are explicit | ✓ PASS |
| Real PostgreSQL waits, rotations, rollback, and adapter contract | `/private/tmp/lockspire164-final-postgres.log` | 38 tests, 0 failures, no exclusions | ✓ PASS |
| Database cleanup and isolation | `/private/tmp/lockspire164-final-db-cleanup.log` | New dedicated database confirmed; no client/token/JTI/device/CIBA fixtures remained; three audit-only rows belong to earlier Phase 163 regression fixtures | ✓ PASS |

All preceding rows are retained historical evidence for the pre-WR-01 candidate, not current-tree runtime proof. The current WR-01 runtime change was independently verified by the bounded red/green selection below; the broad suite and package gate were not rerun during this verification, and new-candidate CI/package proof remains pending final milestone revalidation.

| Malformed final RFC 8693 clock after input-token lock fails closed | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs test/integration/app_lifetime_rfc8693_test.exs test/integration/client_secret_lifetime_poll_exchange_test.exs test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs --include integration --include postgres_race --max-failures 1 --timeout 55000` (isolated database; `/tmp/phase164-clock-green.log`) | 27 tests, 0 failures. Public facade returns controlled server_error; token inventory is unchanged and audit is empty. Includes affected Phase 163 RFC coverage and PostgreSQL grant waits. | ✓ PASS |

The malformed-clock regression was first run red against the old helper: the public facade raised `FunctionClauseError` (8 tests, 1 failure before the stop; `/tmp/phase164-clock-red.log`). This confirms the named regression detected the defect rather than merely exercising the passing branch.

## Probe Execution

Not applicable. No phase plan or success criterion declares a shell probe; this is a protocol/storage implementation phase with executable Mix and PostgreSQL behavior checks.

## Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| DCR-07 | 01, 03, 05, 06 | Stored and advertised shared-secret expiry matches effective policy and excludes non-secret methods | ✓ SATISFIED | Registration, serializer, rotation, redaction, and rendered-guidance coverage above. |
| DCR-08 | 01–06 | Basic/post/JWT enforce the same expiry with independent JWT controls and preserved token semantics | ✓ SATISFIED | Auth matrix, code/refresh/poll/RFC issuance, JWT-boundary, and PostgreSQL wait evidence above. |
| DCR-09 | 03, 05, 06 | Operator rotation applies selected policy atomically and preserves lifecycle/rollback semantics | ✓ SATISFIED | Current-row storage path, adapter conformance, promotion, rotation races, and write/audit rollback evidence above. |

All requirements assigned to Phase 164 appear in plan frontmatter; no orphaned Phase 164 requirement mapping was found. Requirements remain marked pending in `REQUIREMENTS.md` because planning completion bookkeeping is outside verification and was not changed here.

### Decision Coverage

The decision-coverage query reports **18/18 trackable CONTEXT decisions honored**, with no unhonored decisions. The three plan assumptions marked `unclassified` remain limits on source-audit classification; concrete cases specified by D-01–D-18 are covered above. Phase 166's three undefined edge probes and two descriptor-less prohibitions also remain unresolved/unverified; these are explicitly retained as evidence limits and are not counted as Phase 164 requirements or silently marked passed. Historical `workflow.tdd_mode: false` and the task-specific TDD caveats remain in force. None creates an additional Phase 164 must-have or a human-approval gate.

## Test Quality Audit

Requirement-linked tests contain no disabled-test markers. Assertions check values, state transitions, lock waits, and rollback rather than only symbol presence. The phase records no phase-wide strict TDD claim: the 164-06 redaction seam did not produce classifier-validated semantic RED evidence, and fixture setup failures are not presented as product-behavior REDs.

## Anti-Patterns Found

No blocking debt markers or implementation stubs were found in the reviewed source, test, and documentation paths. Broad stub-pattern scans matched ordinary test cleanup callbacks and embedded fixture data only; these do not flow to production output. Independent review's direct scope and reused paths are separated in the current review artifact; its bounded follow-up is clean, and security re-audit closed 24/24 threats. The copy-only UI review covers text only (4/4); the other visual pillars remain unscored and no screenshot/live-visual claim is made.

## Human Verification Required

None. The phase goal is protocol, storage, transaction, and metadata behavior. Changed admin wording is asserted against rendered output; the UI review found no visual or interaction change requiring manual inspection.

## Gaps Summary

No Phase 164 goal gaps found. The three roadmap success criteria and all 26 plan must-haves are evidenced by real code paths, connected storage and protocol consumers, focused behavior tests, and PostgreSQL concurrency evidence. The new WR-01 regression is behaviorally covered by 27 passing related tests, including actual grant-wait coverage. The old full-suite counts (2,349 passed, 440 excluded, 6 skipped) and 38-test PostgreSQL gate belong to the reviewed pre-WR-01 candidate, not this current runtime tree. New-candidate CI/package proof remains pending final milestone revalidation. Management-token enforcement and packaged cross-phase proof remain owned by Phases 165 and 166.

---

_Verified: 2026-10-22T16:28:05Z_
_Verifier: the agent (gsd-verifier)_
