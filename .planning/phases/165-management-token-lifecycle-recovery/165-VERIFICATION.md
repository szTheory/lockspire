---
phase: 165-management-token-lifecycle-recovery
verified: 2026-10-22T16:44:36Z
status: passed
score: 37/37 must-haves verified
covered_files:
  - ".planning/REQUIREMENTS.md"
  - ".planning/ROADMAP.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-01-PLAN.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-01-SUMMARY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-02-PLAN.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-02-SUMMARY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-03-PLAN.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-03-SUMMARY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-04-PLAN.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-04-SUMMARY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-05-PLAN.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-05-SUMMARY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-06-PLAN.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-06-SUMMARY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-07-PLAN.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-07-SUMMARY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-CONTEXT.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-DISCUSSION-LOG.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-EXECUTION-REFRESH.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-REGRESSION-FIX-SUMMARY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-REVIEW-DISPOSITION.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-REVIEW-FIX.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-REVIEW.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-SECURITY.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-UI-REVIEW.md"
  - ".planning/phases/165-management-token-lifecycle-recovery/165-VALIDATION.md"
  - "PRODUCT.md"
  - "docs/dynamic-registration.md"
  - "docs/operator-admin.md"
  - "docs/supported-surface.md"
  - "docs/upgrading/client-lifetimes.md"
  - "lib/lockspire/admin/clients.ex"
  - "lib/lockspire/client_lifecycle.ex"
  - "lib/lockspire/client_metadata.ex"
  - "lib/lockspire/domain/client.ex"
  - "lib/lockspire/protocol/dcr_policy.ex"
  - "lib/lockspire/protocol/registration.ex"
  - "lib/lockspire/protocol/registration_management.ex"
  - "lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex"
  - "lib/lockspire/protocol/token_exchange/internal/grant_support.ex"
  - "lib/lockspire/storage/client_lifetime.ex"
  - "lib/lockspire/storage/ecto/client_record.ex"
  - "lib/lockspire/storage/ecto/repository.ex"
  - "lib/lockspire/storage/ecto/repository/client_store.ex"
  - "lib/lockspire/storage/ecto/server_policy_record.ex"
  - "lib/lockspire/web/admin_router.ex"
  - "lib/lockspire/web/controllers/registration_controller.ex"
  - "lib/lockspire/web/live/admin/clients_live/show.ex"
  - "lib/lockspire/web/live/admin/policies_live/dcr.html.heex"
  - "lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex"
  - "lib/lockspire/web/registration_json.ex"
  - "test/integration/app_lifetime_management_test.exs"
  - "test/integration/client_lifetime_selected_store_test.exs"
  - "test/integration/install_generator_test.exs"
  - "test/integration/management_token_lifetime_access_test.exs"
  - "test/integration/management_token_lifetime_recovery_test.exs"
  - "test/integration/management_token_lifetime_registration_test.exs"
  - "test/integration/management_token_lifetime_update_test.exs"
  - "test/integration/phase3_oidc_token_lifecycle_e2e_test.exs"
  - "test/integration/phase57_rar_introspection_verification_e2e_test.exs"
  - "test/lockspire/audit/audit_writer_test.exs"
  - "test/lockspire/client_lifecycle_test.exs"
  - "test/lockspire/client_lifetime_guidance_test.exs"
  - "test/lockspire/compatibility_baseline_contract_test.exs"
  - "test/lockspire/install/verify_test.exs"
  - "test/lockspire/protocol/dcr_audit_attribution_test.exs"
  - "test/lockspire/protocol/dcr_telemetry_redaction_test.exs"
  - "test/lockspire/protocol/discovery_test.exs"
  - "test/lockspire/protocol/management_token_lifetime_policy_test.exs"
  - "test/lockspire/protocol/management_token_request_contract_test.exs"
  - "test/lockspire/protocol/registration_management_test.exs"
  - "test/lockspire/storage/client_lifetime_conformance_test.exs"
  - "test/lockspire/storage/client_lifetime_promotion_test.exs"
  - "test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs"
  - "test/lockspire/storage/ecto/server_policy_record_test.exs"
  - "test/lockspire/storage/management_token_client_wait_test.exs"
  - "test/lockspire/storage/management_token_mutation_race_test.exs"
  - "test/lockspire/storage/management_token_replacement_race_test.exs"
  - "test/lockspire/storage/management_token_rollback_test.exs"
  - "test/lockspire/storage/repository_test.exs"
  - "test/lockspire/web/admin_router_test.exs"
  - "test/lockspire/web/controllers/registration_controller_test.exs"
  - "test/lockspire/web/discovery_controller_test.exs"
  - "test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs"
  - "test/lockspire/web/live/admin/clients_live/show_test.exs"
  - "test/lockspire/web/live/admin/clients_live_test.exs"
  - "test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs"
  - "test/lockspire/web/live/admin/policies_live/dcr_test.exs"
  - "test/lockspire/web/live/admin/vocabulary_contract_test.exs"
  - "test/lockspire/web/registration_json_test.exs"
  - "test/support/architecture/public_compatibility_manifest.ex"
covered_digest: "v3:sha256:44a533aa4a71cd63ecc2b24756e2f54bcd4ba63065ec3bab8e4bb9d73aa88917"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 19
  total: 19
  not_honored: []
re_verification:
  previous_status: passed
  previous_score: 37/37
  gaps_closed: []
  gaps_remaining: []
  regressions: []
advisory: []
---

# Phase 165: Management-Token Lifecycle & Recovery Verification Report

**Phase Goal:** Clients can manage registrations under the selected token lifecycle, with explicit authorized recovery and safe rotation.
**Verified:** 2026-10-22T16:44:36Z
**Status:** passed
**Re-verification:** Yes — current-source and evidence refresh

## Goal Achievement

The Phase 165 contract includes its three ROADMAP success criteria, all 37 plan must-have truths, and DCR-10/11/12. The success criteria are mapped explicitly below and represented in the observable truths; CONTEXT decisions were checked separately, with 19/19 trackable decisions honored.

### Roadmap Success Criteria

| # | Criterion | Verification | Status |
|---|---|---|---|
| 1 | Issuance stores the chosen management-token lifetime, including finite and unlimited behavior. | Truths 7–10 trace issuance policy through persisted deadlines, effective JSON serialization, provenance boundaries and executable registration/policy tests. | ✓ VERIFIED |
| 2 | Read, update and delete enforce selected credential and app state with safe errors; authorized operator recovery works without bypassing approved permissions. | Truths 1–6, 11–12 and 17–18 trace current-row credential gates, endpoint errors, app-state exceptions, request binding and host-only recovery. Mounted recovery and endpoint tests exercise the paths. | ✓ VERIFIED |
| 3 | Rotation replaces hash and lifecycle atomically; stale and competing requests cannot retain or restore credentials contrary to contract. | Truths 13–16 and 19–30 trace transactional writers, adapter authority, rollback, PostgreSQL contention and redacted success disclosure. | ✓ VERIFIED |

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | D-03: finite management credentials are accepted strictly before their persisted UTC-second deadline and rejected at equality and afterward, using a decision clock sampled after client-row locking. | ✓ VERIFIED | `Client.management_eligibility/3` compares truncated UTC seconds strictly; current-row access tests and PostgreSQL wait tests exercise equality, post-wait expiry, and actual blockers. |
| 2 | D-04: registration/GET/PUT serializers expose server-derived numeric `lockspire_client_expires_at` and `lockspire_registration_access_token_expires_at`; effective unlimited is 0, and GET discloses neither credential. | ✓ VERIFIED | `RegistrationJSON` drops caller metadata aliases and writes effective deadlines from `Client`; registration, read, update, and serializer tests assert values and credential non-disclosure. |
| 3 | D-05: GET, PUT and DELETE bind URL, row identity and current management hash after locking; completed reads linearize at that check and rendering occurs after the transaction. | ✓ VERIFIED | `RegistrationManagement.with_current_client/5` locks/rechecks current row and returns the current value after `Repository.transact`; stale operation and completed-read PostgreSQL cases pass. |
| 4 | D-06: an enabled expired app with a current eligible token may GET/DELETE and receives 403 `registration_expired` on PUT; disablement blocks all three and closed intake leaves management available. | ✓ VERIFIED | Access and recovery integration matrices cover expired/disabled states and intake closure; expired-app invalid-body cases return 403 after token validation. |
| 5 | D-07: missing credentials receive a bare 401 Bearer challenge; supplied invalid credentials receive 401 `invalid_token`; unsupported storage/configuration remains a server error. | ✓ VERIFIED | Registration-controller and protocol tests assert distinct challenge/error and server-error paths; current code maps invalid lifetime state to a server error. |
| 6 | D-16: automated endpoint/protocol cases prove before/equality/after expiry, GET non-renewal, expired/disabled apps and intake closure. | ✓ VERIFIED | Focused access suite exercises these endpoint states; phase validation maps each item to concrete endpoint/protocol modules. |
| 7 | D-01: self-registration snapshots nil/zero as unlimited and a positive management duration from issuance; policy changes, lookups and GET do not renew the stored deadline, and direct/operator provenance keeps its existing boundary. | ✓ VERIFIED | `Client.management_deadline/3` and registration integration tests cover finite/unlimited issuance, provenance, changed policy, and GET stability. |
| 8 | D-02: supported policy write/use boundaries accept only nil or integer 0..2147483647; malformed configuration is a server error and cannot issue an unlimited credential. | ✓ VERIFIED | DCR policy and Ecto policy-record tests exercise bounds and malformed values; HTTP/policy test cases confirm no credential is issued on malformed persisted/in-memory policy. |
| 9 | D-04: issuance, read and update responses advertise effective persisted app/management extensions as Unix seconds or 0, including legacy/unlimited state. | ✓ VERIFIED | `RegistrationJSON` sources effective deadlines from the persisted domain client; registration/update/access/serializer tests cover Unix-second and unlimited output. |
| 10 | D-16: issuance tests cover finite/unlimited policy, changed policy, provenance and wire values independently of shared-secret authentication method. | ✓ VERIFIED | Registration integration covers public and public-key as well as confidential authentication; policy and serializer suites pass. |
| 11 | D-08: PUT requires an unchanged body `client_id` independently of the URL, uses replacement metadata, rejects forbidden standard management fields, and verifies any included `client_secret` against current material without secret rotation. | ✓ VERIFIED | Controller preserves path identity and raw body metadata; request-contract tests cover missing/mismatched identity, forbidden fields, matching secret, and no secret rotation. |
| 12 | D-08: lifecycle extension omission preserves server authority, identical echoes are accepted, changed echoes are `invalid_client_metadata`, and registration intake rejects client-supplied extensions. | ✓ VERIFIED | Management request-contract, registration intake, and serializer tests exercise omitted/identical/changed extensions and intake rejection. |
| 13 | D-09: committed PUT immediately replaces hash/deadline under current applicable policy, returns only its new management token, and preserves app/secret deadlines. | ✓ VERIFIED | Update integration and storage tests assert new token/deadline, old-token rejection, and unchanged app/secret expiry. |
| 14 | D-12: PUT metadata, management hash/deadline, whole-row lifetime promotion and required audit commit together from the current locked row, with no successful plaintext on rollback. | ✓ VERIFIED | ClientStore merges intended deltas into the locked row within the transaction; rollback, promotion, conformance, and mutation-race tests assert durable fields/audit and no credential disclosure on failure. |
| 15 | D-13: two PUTs with the same old token have one winner and stale requests cannot restore authority; management has no overlap or old-token response recovery. | ✓ VERIFIED | Competing PUT/recovery PostgreSQL schedules prove one winner; stale retries and lost-response integration tests reject old-token replay. |
| 16 | D-14: explicit management replacement canonicalizes v0 as a whole row, clears advisory unrelated dates, sets only its management deadline and promotes to v1; v1 preserves unrelated authoritative dates. | ✓ VERIFIED | Client domain promotion function and v0/v1 promotion tests assert whole-row clearing/preservation for both self PUT and host recovery. |
| 17 | D-11: the existing host-authorized rotation recovers lost/expired management authority and keeps the existing confirmation and one-time display boundary; client id, setup token, secret and expired token are not recovery authority. | ✓ VERIFIED | Mounted LiveView tests cover confirmation, committed one-time display, acknowledgement/navigation clearing, self-registration restriction, and rejection of public setup/client credentials. |
| 18 | D-11: recovery replaces only management hash/deadline; an expired enabled app still permits only GET/DELETE and a disabled app remains disabled and blocked. | ✓ VERIFIED | Recovery integration and mounted tests assert app/secret state preservation, expired-app GET/DELETE and blocked PUT, and disabled-state retention. |
| 19 | D-12: replacement hash/deadline/version/intended fields/audit commit or roll back as one operation, with no successful plaintext after failed storage or audit. | ✓ VERIFIED | Required-audit and write-failure tests inject rollback conditions for PUT and recovery and inspect persisted state and returned values. |
| 20 | D-13: recovery preserves current-hash stale-snapshot rejection; a stale host attempt loses and an authorized retry must refresh the current row. | ✓ VERIFIED | Recovery integration and replacement race suites assert stale rejection and refreshed current-snapshot retry. |
| 21 | D-14: v0 management replacement clears all advisory deadlines and sets only the new management deadline while preserving identity, enabled state, secret material and unrelated metadata. | ✓ VERIFIED | Promotion and recovery tests inspect those fields after a current-row v0 replacement. |
| 22 | D-15: aware adapter round trips, guarded writes and shared transaction/audit authority are exercised; unsupported or dropping adapters are explicit errors, using the existing contract and schema. | ✓ VERIFIED | Conformance tests execute built-in/custom adapters, dropped-field controls, deferred-clock behavior, transaction authority, and audit rollback. |
| 23 | D-17: independent PostgreSQL backend sessions and `pg_blocking_pids` prove actual client-lock waits before the injected decision clock advances across expiry. | ✓ VERIFIED | `management_token_client_wait_test.exs` uses independent sessions and asserts actual blocker relationships before advancing the clock; race batch passes 34/0. |
| 24 | D-17: GET/PUT/DELETE snapshots that wait behind a committed token replacement lose authority; completed reads are not retroactively invalidated. | ✓ VERIFIED | Client-wait suite covers stale GET/PUT/DELETE and accepted pre-replacement read completion under real locks. |
| 25 | D-13/D-17: competing old-token PUTs, PUT versus recovery and two stale-snapshot recoveries have one winner and cannot retain or restore the old hash. | ✓ VERIFIED | Replacement-race suite runs all competing schedules and checks stored hash, stale result, and retry behavior. |
| 26 | D-12/D-17: secret rotation, disablement and write/audit failure racing management preserve durable unrelated state and atomicity. | ✓ VERIFIED | Mutation-race and rollback suites verify secret and disabled-state preservation plus write/audit rollback. |
| 27 | Edge DCR-11/concurrency: each management operation linearizes under current-row authority after its actual lock wait and stale credentials cannot mutate or obtain a current read. | ✓ VERIFIED | Real blocker tests and current-hash checks establish the authority boundary for all operations. |
| 28 | Edge DCR-12/concurrency: one old fingerprint authorizes at most one committed replacement; intended lifecycle/metadata/audit changes commit or roll back together. | ✓ VERIFIED | Replacement race and rollback suites exercise one-winner commit and all-or-nothing failure paths. |
| 29 | D-18: exercised finite use, expiry rejection, self PUT and host recovery produce positively observed events with distinct self_registered_client/operator attribution. | ✓ VERIFIED | Telemetry and audit-attribution suites require positive event counts and distinct actors for self versus operator recovery. |
| 30 | D-18: captured audit, telemetry, log and public error payloads exclude plaintext old/new tokens, hashes, shared secrets and verifier material; a zero-event capture cannot pass. | ✓ VERIFIED | Redaction tests inspect captured channels after asserting nonzero events and use explicit secret/token materials as forbidden values. |
| 31 | D-10: existing mounted host recovery requires confirmation, permits self-registered apps only, reveals committed plaintext once and clears it on acknowledgement/navigation. | ✓ VERIFIED | Mounted recovery tests exercise confirmation, one-time delivery, clearing behavior, error path, and host/public route boundary. |
| 32 | D-11: operator recovery copy and behavior preserve disabled state and app/secret deadlines; recovery is not app renewal. | ✓ VERIFIED | LiveView recovery and guidance tests assert preserved lifecycle fields and copy stating no app/secret renewal. |
| 33 | D-19: admin copy uses PRODUCT.md vocabulary and states finite expiry, prospective policy, immediate replacement and lost-response host recovery accurately without redesign. | ✓ VERIFIED | PRODUCT vocabulary contract, policy LiveView, recovery UI, and guidance contract tests cover vocabulary and claims. |
| 34 | D-19: affected registration, upgrade, operator and supported-surface guidance describes implemented optional finite tokens, host recovery, immediate replacement and lost-response consequences, with executable examples. | ✓ VERIFIED | Guidance contract tests read the affected docs and assert lifetime examples, body/extensions, host recovery, and no-overlap claims. |
| 35 | D-16/D-17/D-18: focused boundary, adapter, rollback, observed-event and explicit PostgreSQL race checks run with positive test counts before phase verification. | ✓ VERIFIED | The current isolated refresh reports 84 lifecycle/actual-PostgreSQL-race/rollback/conformance tests and 70 recovery UI/route/copy/vocabulary/guidance/compatibility tests, all 0 failures. Exact selections and environment are in `165-VALIDATION.md` and `/tmp/phase165-validation-refresh-20261022.md`. |
| 36 | All three Phase 165 requirements and D-01 through D-19 have explicit source/task ownership; deferred Phase 166 packaged journeys, final CI/security/guidance proof and umbrella-todo closure retain their owner. | ✓ VERIFIED | Plan truth map covers D-01–D-19 and the validation map links task/threat evidence. Phase 166 records completed cross-phase proof and umbrella work for candidate `0bd4070d`; those receipts remain bound to that candidate, while root's final milestone revalidation owns the newer-candidate CI/package run. |
| 37 | Edge DCR-11/idempotency: GET is non-renewing; repeating a committed PUT with the old token is `invalid_token` and produces no second write/audit; repeating DELETE with disabled authority is rejected. | ✓ VERIFIED | Access, update, protocol, and replacement tests assert GET stability, old-token rejection, no duplicate mutation/audit, and disabled-client rejection. |

**Score:** 37/37 truths verified (0 present, behavior-unverified)

### Requirement Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| DCR-10 | 165-02, 165-07 | Issued management-token lifetime follows selected finite/unlimited policy. | ✓ SATISFIED | Registration issuance, typed policy write/use, wire extension, and guidance tests; current focused group passed. |
| DCR-11 | 165-01, 165-03–07 | Clients read/update/delete under lifecycle rules; host operator recovery remains authorized. | ✓ SATISFIED | Access/request/recovery endpoint tests; real current-row PostgreSQL waits; mounted host recovery tests. |
| DCR-12 | 165-03–07 | Rotation atomically replaces hash and lifecycle, rejecting stale/competing requests. | ✓ SATISFIED | Update, adapter, rollback, and race suites; independent PostgreSQL batch passed 34/0. |

All requirement IDs declared by the plans map to DCR-10/11/12. REQUIREMENTS.md assigns no additional requirement to Phase 165, so there are no orphaned IDs.

### Required Artifacts

The GSD artifact query passed every plan-declared artifact (18/18 plan entries; 17 unique paths). Each source file is substantive and connected to its caller or persistence path; each test artifact is a discovered `*_test.exs` module and has direct execution evidence. No artifact was missing or stubbed.

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/lockspire/domain/client.ex` | Effective app/management deadlines, eligibility, policy-derived deadline, legacy promotion | ✓ VERIFIED | Used by issuance, management, and serialization. |
| `test/integration/management_token_lifetime_access_test.exs` | HTTP-to-PostgreSQL access and operation matrix | ✓ VERIFIED | Executed; expiry and error precedence asserted. |
| `test/integration/management_token_lifetime_registration_test.exs` | Issuance snapshot and wire proof | ✓ VERIFIED | Executed; finite/unlimited and auth-method cases. |
| `test/lockspire/protocol/management_token_lifetime_policy_test.exs` | Policy write/use rejection | ✓ VERIFIED | Executed in focused policy group. |
| `lib/lockspire/storage/ecto/repository/client_store.ex` | Guarded intended fields and atomic audit persistence | ✓ VERIFIED | Called through lifecycle persistence; rollback/conformance tests exercise it. |
| `test/integration/management_token_lifetime_update_test.exs` | PUT replacement, no overlap, state preservation | ✓ VERIFIED | Executed; stored fields and prior-token rejection asserted. |
| `test/lockspire/protocol/management_token_request_contract_test.exs` | Body identity and field/extension contract | ✓ VERIFIED | Executed in focused request-contract group. |
| `test/integration/management_token_lifetime_recovery_test.exs` | Authorized host recovery and state preservation | ✓ VERIFIED | Executed; stale, expired, disabled, and lost-response cases. |
| `test/lockspire/storage/management_token_rollback_test.exs` | Write/audit rollback without plaintext success | ✓ VERIFIED | Executed in PostgreSQL batch. |
| `test/lockspire/storage/management_token_client_wait_test.exs` | Expiry/current authority after observed lock waits | ✓ VERIFIED | Executed; independent blocker proof. |
| `test/lockspire/storage/management_token_replacement_race_test.exs` | One-winner PUT/recovery schedules | ✓ VERIFIED | Executed; competing schedules. |
| `test/lockspire/storage/management_token_mutation_race_test.exs` | Secret/disablement preservation and contended rollback | ✓ VERIFIED | Executed; mutation races. |
| `test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs` | Confirmed one-time operator recovery | ✓ VERIFIED | Executed; confirmed display, clearing, and public boundary. |
| `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` | Positive observed events and redaction | ✓ VERIFIED | Executed; bundled with audit attribution. |
| `docs/dynamic-registration.md` | Wire/request/lifecycle guidance | ✓ VERIFIED | Exercised by guidance contract. |
| `docs/operator-admin.md` | Host recovery steps and limits | ✓ VERIFIED | Exercised by guidance contract and mounted UI tests. |
| `.planning/phases/165-management-token-lifecycle-recovery/165-VALIDATION.md` | Exact validation commands/results | ✓ VERIFIED | Cross-checked; current independent reruns recorded below. |

### Key Link Verification

The CLI lexical checker reported 12 links as “target not referenced in source”; manual tracing resolved these because several use Elixir aliases or represent shared typed validation rather than a literal module-path string. The remaining two links were recognized automatically. All 14 links were checked against implementation and test invocation.

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `RegistrationManagement` | `Repository` | Transaction and row lock before decision-time eligibility | ✓ WIRED | `with_current_client/5` calls the repository transaction and lock facade before `decision_now/1`. |
| `RegistrationJSON` | `Domain.Client` | Effective persisted deadline serialization | ✓ WIRED | Response fields call `effective_app_deadline/1` and `effective_management_deadline/1`. |
| `ClientMetadata` | `Domain.Client` | Issuance-time management deadline | ✓ WIRED | Registration construction calls `management_deadline/3` using issuance time. |
| `DcrPolicy` | `ServerPolicyRecord` | Matched typed duration bounds | ✓ WIRED | Resolver and record changeset enforce the same nil/integer range; policy tests exercise both boundaries. |
| `RegistrationController` | `RegistrationManagement` | Separate URL identity and untouched body metadata | ✓ WIRED | Controller reads `path_params` separately and passes `body_params` to update. |
| `ClientLifecycle` | `ClientStore` | Replacement callback writes intended fields into locked row | ✓ WIRED | Lifecycle replacement delegates to guarded repository persistence; integration and rollback tests observe persisted state. |
| `RegistrationManagement` | `ClientLifecycle` | Host rotation after current snapshot and policy/deadline resolution | ✓ WIRED | Recovery reloads/locks current row, obtains policy and deadline, then invokes lifecycle rotation. |
| DCR controller, protocol, and host recovery | `ClientLifetime.configured()` selected stores | Every management path uses the selected client/transaction stores and validates shared transaction authority | ✓ WIRED | `ClientLifetime.configured/0` checks required callbacks and that selected client, token, device, CIBA, audit, and transaction participants share one authority. `client_lifetime_selected_store_test.exs` exercises registration, GET/PUT/DELETE, secret rotation, host recovery, late-audit rollback, and invalid-composition no-consumption. |
| `ClientStore` | `Domain.Client` | Whole-row v0 canonicalization and v1 field preservation | ✓ WIRED | Store calls `credential_lifetime_changes/3` inside the shared transaction. |
| Client-wait tests | Race helper | Independent sessions, blocker and barrier clock | ✓ WIRED | Tests call `start_session`, blocker assertion, and clock barrier helper. |
| Replacement-race tests | `RegistrationManagement` | Separate PostgreSQL protocol entries | ✓ WIRED | Test schedules invoke update and host rotation through production entry points. |
| `RegistrationManagement` | `Observability` | Actor-attributed rotation event | ✓ WIRED | Self PUT and operator recovery emit distinct actor context; positive-count tests assert it. |
| Admin LiveView | `RegistrationManagement` | Confirmed `rotate_rat` only exposes committed token | ✓ WIRED | Handler calls host rotation after confirmation and assigns one-time result on success only. |
| Host admin mount | `Lockspire.Web.AdminRouter` | Generated `:require_operator` pipeline before admin forward | ✓ WIRED | `docs/operator-admin.md`, `install_generator_test.exs`, and `install/verify_test.exs` specify and assert the host-owned guard and mount order; Lockspire does not own staff authentication. |
| Guidance contract test | Dynamic-registration docs | Executable public guidance assertions | ✓ WIRED | Test reads the file and checks selected wire/lifecycle statements. |
| Validation record | PostgreSQL wait suite | Explicit `postgres_race` run | ✓ WIRED | Validation command names the wait suite and actual execution passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| DCR registration and management JSON | `client_expires_at`, `registration_access_token_expires_at` | Ecto-persisted client row mapped to the domain model; effective deadline functions serialize Unix seconds or 0 | Yes | ✓ FLOWING |
| Management GET response | Client metadata and lifecycle fields | Current locked client row returned after the authority transaction | Yes | ✓ FLOWING |
| PUT/recovery result | New management credential and deadline | Random replacement plaintext paired with persisted hash/deadline; plaintext returned only after successful commit | Yes | ✓ FLOWING |
| Admin recovery display | `revealed_rat` | Successful host rotation result in the mounted LiveView; cleared on acknowledgement/navigation | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Management issuance/access/PUT/recovery, real PostgreSQL waits/races, rollback and adapter conformance | Pinned `mix test --include integration --include postgres_race test/integration/management_token_lifetime_registration_test.exs test/lockspire/protocol/management_token_lifetime_policy_test.exs test/integration/management_token_lifetime_access_test.exs test/integration/management_token_lifetime_update_test.exs test/integration/management_token_lifetime_recovery_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/storage/management_token_client_wait_test.exs test/lockspire/storage/management_token_replacement_race_test.exs test/lockspire/storage/management_token_mutation_race_test.exs test/lockspire/storage/management_token_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs --max-failures 1 --timeout 55000` | 84 tests, 0 failures, fresh isolated DB; log details in validation receipt | ✓ PASS |
| Mounted host recovery, route boundaries, policy copy, vocabulary, guidance and compatibility | Pinned `mix test test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs test/lockspire/client_lifetime_guidance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000` | 70 tests, 0 failures, fresh isolated DB; host-only recovery and route boundaries included | ✓ PASS |
| Phase 54/57 audience-downscoping regression | `/tmp/phase165-regression-refresh-20261022.md` and Phase 165 validation record | 4 tests, 0 failures after the authorized fix | ✓ PASS (recorded gate) |

The regression refresh also retains Phase 162's 24 contract-mutation checks, Phase 163's 52 focused tests for unchanged paths, and Phase 164's 28/47 selections for unchanged secret-lifetime and copy paths. Phase 164's affected RFC 8693 boundary and PostgreSQL grant-wait paths were rechecked in the current 27-test green selection after its clock guard. These are explicit, scoped receipts, not a new broad-suite or package claim. Older fast-suite counts (2,413 tests, 0 failures, 485 excluded, 6 skipped) and CI/package evidence for candidate `0bd4070d` remain historical. The current Phase 165 runtime candidate is `9244417955efebd9a872100d49f3e88ad2db9fe5`; new-candidate CI/package proof remains pending final milestone revalidation.

The required prior-phase regression gate also exposed a pre-existing RAR audience-downscoping persistence defect. `GrantSupport` now carries the selected resource audience as an explicit intent; `GrantPersistence` revalidates it against the locked current authorization code and uses that narrowed audience for access and refresh persistence. The Phase 57 test asserts the audience through issue, refresh, rotation, and introspection. The independent Phase 54/57 impact run is recorded as 4/0; its broader fixture-isolation repairs are described in `165-REGRESSION-FIX-SUMMARY.md`. This is supplemental regression evidence, not a new Phase 165 product requirement.

### Probe Execution

No shell probe path is declared by the plans or summaries, and no `scripts/*/tests/probe-*.sh` exists. The “DCR-10/unclassified spec-less probe” is a descriptor/accounting row, not a runnable probe. Its concrete issuance and policy behaviors are exercised by the registration/policy tests and passed above; the descriptor itself remains unclassified and is not reported as historical probe evidence.

### Decision Coverage and Prohibitions

The decision-coverage query reports **19/19 Phase CONTEXT decisions honored**. Phase 04 and Phase 07 contain two test-tier prohibition statements, and their focused tests exercise the stated boundaries: host-owned non-renewing recovery, and guidance that does not imply a universal RFC timeout or old-token replay recovery. The broader project evidence map still retains two descriptor-less prohibition records as `flagged-unverified`; the adjacent Phase 165 tests are not represented as clearing those records or proving any undefined predicate. The DCR-10 spec-less probe likewise remains unclassified, and A-EDGE-16/17/19 remain unresolved. These accounting limits are preserved without inventing a probe, prohibition descriptor, approval rule, or new requirement.

The task 165-04 historical TDD/classifier mismatch remains documented as a limitation: the semantic ExUnit failure was observed, but no classifier-approved historical RED evidence is claimed. Plan 165-05's test-only additions do not claim RED/GREEN evidence; historical singleton-policy and LiveView environment cleanup failures remain recorded as corrected. Project `workflow.tdd_mode` is false. These caveats do not weaken the current behavior evidence or create a runtime goal gap.

### Test Quality Audit

Requirement-linked test modules are active and non-skipped. The executed tests assert concrete deadlines, statuses, durable hashes, metadata, audit rows, blocker PIDs, and redaction values; no disabled-only requirement path or circular expected-value generation was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No debt markers, placeholders, empty implementations, or disabled requirement-linked tests were found in the reviewed implementation paths. Independent bounded code review directly inspected 21 current paths and reported 0 critical, 0 warning, and 0 info findings; its unchanged reuse boundary is itemized in `165-REVIEW.md`. | — | — |

### Advisory (New Scope, Unevidenced)

None. The optional confirmation-copy suggestion and unscored visual/screen-reader areas are recorded as UI-review limits; they do not create a new code finding or phase acceptance criterion.

### Human Verification Required

None for Phase 165's observable protocol, storage, and host-recovery criteria. The current UI review scores copy 3/4 and experience 4/4; visual pillars remain unscored because no screenshot/rendered visual inspection was performed. Screen-reader announcement behavior is also unverified, and the generic “confirmation required” wording is an optional copy improvement. No visual acceptance criterion is specified by this phase; these limits are stated without a human-acceptance gate. Phase 166's packaged proof and umbrella work are complete for their recorded candidate; root's final milestone revalidation will run CI/package proof for the newer candidate after source freeze.

### Gaps Summary

No failed truths, missing/stub artifacts, unwired links, or blocking anti-patterns remain. All three ROADMAP success criteria, 37 plan must-have truths, and DCR-10/11/12 are evidenced by current implementation and focused tests. Registration issuance/lifecycle policy, current-row management operations, safe errors, host-authorized recovery, selected-store transaction/audit authority, atomic replacement and PostgreSQL races are present and wired. DCR-10's spec-less probe, three undefined Phase 166 edge assumptions, two descriptor-less prohibition flags, TDD/classifier history, and unscored visual pillars remain explicit limits; none is represented as a passed predicate. Broad current-candidate CI/package proof remains pending root's final milestone revalidation rather than being inferred from the historical 0bd candidate.

---

_Verified: 2026-10-22T16:44:36Z_
_Verifier: the agent (gsd-verifier)_
