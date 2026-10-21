---
phase: 163-app-lifetime-compatible-host-storage
verified: 2026-10-21T01:34:01Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-01-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-01-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-02-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-02-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-03-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-03-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-04-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-04-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-05-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-05-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-06-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-06-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-07-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-07-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-08-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-08-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-09-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-09-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-10-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-10-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-11-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-11-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-12-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-12-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-13-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-13-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-14-PLAN.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-14-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-COVERAGE.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-REVIEW-DISPOSITION.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-REVIEW-FIX-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-REVIEW.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-SECURITY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-SOURCE-AUDIT.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-VALIDATION.md
  - docs/architecture.md
  - docs/dynamic-registration.md
  - docs/upgrading/client-lifetimes.md
  - docs/upgrading/storage-prefix.md
  - lib/lockspire/ciba.ex
  - lib/lockspire/client_metadata.ex
  - lib/lockspire/clients.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/host/token_exchange_context.ex
  - lib/lockspire/protocol/authorization_flow.ex
  - lib/lockspire/protocol/authorization_request.ex
  - lib/lockspire/protocol/backchannel_authentication.ex
  - lib/lockspire/protocol/client_auth.ex
  - lib/lockspire/protocol/dcr_policy.ex
  - lib/lockspire/protocol/device_authorization.ex
  - lib/lockspire/protocol/device_verification.ex
  - lib/lockspire/protocol/introspection.ex
  - lib/lockspire/protocol/pushed_authorization_request.ex
  - lib/lockspire/protocol/registration.ex
  - lib/lockspire/protocol/registration_management.ex
  - lib/lockspire/protocol/revocation.ex
  - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
  - lib/lockspire/protocol/token_exchange/internal/authorization_code_grant.ex
  - lib/lockspire/protocol/token_exchange/internal/client_authentication.ex
  - lib/lockspire/protocol/token_exchange/internal/dependencies.ex
  - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
  - lib/lockspire/protocol/token_exchange/internal/grant_support.ex
  - lib/lockspire/protocol/token_exchange/internal/legacy_options.ex
  - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
  - lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex
  - lib/lockspire/protocol/token_exchange/internal/token_issuer.ex
  - lib/lockspire/protocol/token_lifetime.ex
  - lib/lockspire/protocol/userinfo.ex
  - lib/lockspire/storage/ciba_authorization_store.ex
  - lib/lockspire/storage/client_lifetime.ex
  - lib/lockspire/storage/client_store.ex
  - lib/lockspire/storage/device_authorization_store.ex
  - lib/lockspire/storage/ecto/client_record.ex
  - lib/lockspire/storage/ecto/repository.ex
  - lib/lockspire/storage/ecto/repository/ciba_authorization_store.ex
  - lib/lockspire/storage/ecto/repository/client_store.ex
  - lib/lockspire/storage/ecto/repository/device_authorization_store.ex
  - lib/lockspire/storage/ecto/repository/interaction_store.ex
  - lib/lockspire/storage/ecto/repository/token_store.ex
  - lib/lockspire/storage/ecto/server_policy_record.ex
  - lib/lockspire/storage/interaction_store.ex
  - lib/lockspire/storage/token_store.ex
  - lib/lockspire/storage/transaction_store.ex
  - lib/lockspire/web/controllers/registration_controller.ex
  - lib/lockspire/workers/ciba_notification_worker.ex
  - priv/repo/migrations/20261021000000_add_client_lifetime_contract.exs
  - scripts/acceptance/clean_room/build_provider.py
  - scripts/acceptance/clean_room/client_lifetime_upgrade.py
  - test/clean_room/lifetime_upgrade_scenarios.exs
  - test/integration/app_lifetime_authorization_test.exs
  - test/integration/app_lifetime_ciba_approval_test.exs
  - test/integration/app_lifetime_ciba_push_test.exs
  - test/integration/app_lifetime_code_redemption_test.exs
  - test/integration/app_lifetime_device_test.exs
  - test/integration/app_lifetime_management_test.exs
  - test/integration/app_lifetime_migration_test.exs
  - test/integration/app_lifetime_online_consumers_test.exs
  - test/integration/app_lifetime_packaged_upgrade_test.exs
  - test/integration/app_lifetime_poll_issuance_test.exs
  - test/integration/app_lifetime_refresh_test.exs
  - test/integration/app_lifetime_registration_test.exs
  - test/integration/app_lifetime_rfc8693_test.exs
  - test/integration/phase15_par_authorization_e2e_test.exs
  - test/integration/phase30_device_authorization_e2e_test.exs
  - test/integration/phase31_generated_host_verification_e2e_test.exs
  - test/integration/phase32_device_flow_token_exchange_e2e_test.exs
  - test/integration/phase36_auth_code_dpop_e2e_test.exs
  - test/integration/phase37_protocol_strictness_e2e_test.exs
  - test/integration/phase38_session_logout_e2e_test.exs
  - test/integration/phase3_oidc_token_lifecycle_e2e_test.exs
  - test/integration/phase41_fapi_2_0_e2e_test.exs
  - test/integration/phase43_fapi_milestone_e2e_test.exs
  - test/integration/phase48_token_exchange_e2e_test.exs
  - test/integration/phase51_ciba_poll_mode_e2e_test.exs
  - test/integration/phase52_host_delegation_e2e_test.exs
  - test/integration/phase53_ciba_delivery_modes_e2e_test.exs
  - test/integration/phase54_resource_indicators_e2e_test.exs
  - test/integration/phase55_rar_intake_e2e_test.exs
  - test/integration/phase57_rar_introspection_verification_e2e_test.exs
  - test/integration/phase62_private_key_jwt_e2e_test.exs
  - test/integration/phase6_onboarding_e2e_test.exs
  - test/lockspire/admin/clients_test.exs
  - test/lockspire/admin/consents_test.exs
  - test/lockspire/admin/tokens_test.exs
  - test/lockspire/audit/audit_writer_test.exs
  - test/lockspire/client_lifecycle_test.exs
  - test/lockspire/client_lifetime_guidance_test.exs
  - test/lockspire/compatibility_baseline_contract_test.exs
  - test/lockspire/install/migrations_test.exs
  - test/lockspire/protocol/app_lifetime_policy_test.exs
  - test/lockspire/protocol/authorization_flow_test.exs
  - test/lockspire/protocol/authorization_request_test.exs
  - test/lockspire/protocol/backchannel_authentication_test.exs
  - test/lockspire/protocol/client_app_authentication_test.exs
  - test/lockspire/protocol/client_auth_test.exs
  - test/lockspire/protocol/device_authorization_test.exs
  - test/lockspire/protocol/device_verification_test.exs
  - test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs
  - test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs
  - test/lockspire/protocol/fapi20_enforcer_plug_test.exs
  - test/lockspire/protocol/introspection_test.exs
  - test/lockspire/protocol/pushed_authorization_request_test.exs
  - test/lockspire/protocol/refresh_exchange_test.exs
  - test/lockspire/protocol/registration_management_test.exs
  - test/lockspire/protocol/revocation_test.exs
  - test/lockspire/protocol/rfc8693_exchange_test.exs
  - test/lockspire/protocol/token_exchange/authorization_code_test.exs
  - test/lockspire/protocol/token_exchange/dependencies_test.exs
  - test/lockspire/storage/client_lifetime_client_wait_test.exs
  - test/lockspire/storage/client_lifetime_conformance_test.exs
  - test/lockspire/storage/client_lifetime_grant_wait_test.exs
  - test/lockspire/storage/client_lifetime_promotion_test.exs
  - test/lockspire/storage/client_lifetime_rollback_test.exs
  - test/lockspire/storage/ecto/client_record_test.exs
  - test/lockspire/storage/repository_concurrency_test.exs
  - test/lockspire/storage/repository_test.exs
  - test/lockspire/web/authorize_controller_test.exs
  - test/lockspire/web/consent_context_test.exs
  - test/lockspire/web/end_session_controller_test.exs
  - test/lockspire/web/interaction_controller_test.exs
  - test/lockspire/web/introspection_controller_test.exs
  - test/lockspire/web/live/admin/clients_live/show_test.exs
  - test/lockspire/web/live/admin/clients_live_test.exs
  - test/lockspire/web/live/admin/consents_live_test.exs
  - test/lockspire/web/live/admin/dcr_live_test.exs
  - test/lockspire/web/live/admin/overview_live_test.exs
  - test/lockspire/web/live/admin/policies_live/dpop_test.exs
  - test/lockspire/web/live/admin/policies_live/par_test.exs
  - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
  - test/lockspire/web/live/admin/tokens_live_test.exs
  - test/lockspire/web/live/consent_live_test.exs
  - test/lockspire/web/pushed_authorization_request_controller_test.exs
  - test/lockspire/web/revocation_controller_test.exs
  - test/lockspire/web/token_controller_test.exs
  - test/lockspire/web/userinfo_controller_test.exs
  - test/lockspire/workers/backchannel_logout_delivery_worker_test.exs
  - test/mix/tasks/lockspire_doctor_remote_jwks_cold_test.exs
  - test/mix/tasks/lockspire_doctor_remote_jwks_test.exs
  - test/mix/tasks/lockspire_doctor_token_format_cold_test.exs
  - test/mix/tasks/lockspire_doctor_token_format_test.exs
  - test/support/architecture/public_compatibility_manifest.ex
  - test/support/client_lifetime_race_helpers.ex
  - test/support/token_exchange_case.ex
covered_digest: "v3:sha256:6e0a902a9edb3b4f91347d4f8db8cbac1c904d94212dc4ba432abf2056a1353d"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 163: App Lifetime & Compatible Host Storage Verification Report

**Phase Goal:** New and existing Phoenix hosts can store and enforce the selected app lifetime through an explicit schema and storage upgrade path.
**Verified:** 2026-10-21T01:34:01Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | New registrations persist an explicit version 1 app lifetime snapshot; equality and disabled state are enforced separately across applicable online consumers. | ✓ VERIFIED | `Client` contains the explicit `lifetime_version` and `client_expires_at`; the registration path snapshots policy; `app_lifetime_registration_test.exs` exercises persistence through repository fetch and deadline evaluation. The mapped C-APP-01–18 cases exercise authorization, PAR, device/CIBA, redemption, refresh, RFC 8693, online token consumers, management, discovery/JWKS and host-owned sessions. Fresh `mix test.fast`: 2291 tests, 0 failures. |
| 2 | Applicable online protocol consumers recheck current app state at decision and durable issuance boundaries, and access/refresh token expiry is capped consistently without relying on a pruning worker. | ✓ VERIFIED | `GrantPersistence` locks and reloads participating current clients before capturing the final time; `TokenLifetime.effective_expiry/3` feeds durable token rows, JWT `exp`, and `expires_in`. C-TOK-01–03 tests cover code, refresh, poll/push and RFC 8693 signed/opaque output, equality, and preserved grant/family state. Independent PostgreSQL client/grant wait and rollback tests passed (13 tests, 0 failures). |
| 3 | Existing hosts preserve ambiguous historical dates as legacy/unlimited, and the additive upgrade/cutover procedure is executable for old and candidate packages. | ✓ VERIFIED | Migration is additive/prefix-aware and introduces explicit v0 with nullable dates; promotion canonicalizes unrelated legacy dates atomically. Fresh packaged proof ran pinned 1.6.1 and candidate builds against `public` and `tenant_auth`, preserved all 37 old migration checksums, checked five historical-date shapes in each prefix, stopped old writers before first v1 write, retained v1 rows, and completed cleanup. Receipt revalidated with `client_lifetime_upgrade.py --check-receipt`. |
| 4 | Fresh and custom client storage can round-trip supported lifetime state under declared shared transaction authority; unsupported or lossy adapters fail explicitly. | ✓ VERIFIED | `ClientLifetime.adapt/2` requires an adapter-owned v1 declaration, current-row guard, and matching structured transaction authority. Positive built-in/custom adapter conformance covers finite, unlimited and v0 state; negative fixtures for missing/unknown declarations, missing guard, dropped version/deadlines and split authority fail. The post-review dropped-field fixtures assert registration/fetch callbacks ran, proving the test reaches the lossy-storage behavior. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| 14 phase plans' declared artifacts | Implementation and focused executable evidence | ✓ VERIFIED | `gsd-tools query verify.artifacts` evaluated each plan; all 34 declared artifacts exist and passed substantive checks. |
| Client registration, domain, Ecto record and migration | Explicit version/deadline persistence and additive v0 expansion | ✓ VERIFIED | Actual field mapping and migration code inspected; registration integration test covers database round trip. |
| Client lifetime adapter and token issuance core | Declared support, current-row guarding and a single effective expiry | ✓ VERIFIED | Actual typed adapter, dependency validation, grant persistence and token expiry source inspected; focused conformance and issuance behavior tests are mapped in coverage. |
| Upgrade runner, receipt and host guidance | Executable pre-lifetime-to-candidate upgrade and accurate procedure | ✓ VERIFIED | Receipt check passed; docs describe actual prefix journey and old-writer cutover boundary. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Registration metadata | Ecto client record and migration | Changeset/domain mapping and additive fields | WIRED | Inspected `ClientRecord` mapping in both directions and migration schema; exercised by PostgreSQL registration and migration tests. |
| Adapter declaration | Dependency adaptation and client consumers | Typed support plus transaction-authority validation | WIRED | `LegacyOptions` adapts once; `Dependencies.validate` checks participating stores; conformance tests assert matching and mismatching authorities. |
| Protocol paths | Current app row and final issuance | Stable current-client locks, then fresh time and shared expiry | WIRED | `GrantPersistence` and its authorization-code, refresh, polling and RFC 8693 callers use lock/reload/eligibility paths; independent lock-wait tests confirm the behavior after real PostgreSQL waits. |
| Issuance result | Durable row, signed token, response | One effective expiry value | WIRED | Durable `expires_at`, JWT `exp`, and `expires_in` are asserted equal/capped in C-TOK tests. |
| Packaged installer | New migration | Existing migration copy/checksum mechanism | WIRED | Installer tests assert migration checksum preservation and no overwrite; package receipt confirms prior 37 migration checksums across both prefixes. |

The generic key-link query uses literal-reference checks and returned false negatives for these relationships; the links above were traced in implementation and behavior tests rather than treating those false negatives as missing wiring.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Registration → client row | `lifetime_version`, `client_expires_at` | Resolved policy and registration decision time, persisted through Ecto | Yes; fetched back from PostgreSQL | ✓ FLOWING |
| Guarded issuance → token row | effective access/refresh expiry | Current locked app deadline and final post-wait decision time | Yes; persisted and compared in integration tests | ✓ FLOWING |
| Signed issuance → JWT/response | `exp`, `expires_in` | Same effective durable expiry | Yes; decoded/observed in focused tests | ✓ FLOWING |
| Custom storage → consumers | lifetime state | Adapter fetch/lock callbacks and explicit contract | Yes; custom conformance stores and dropped-field negative fixtures | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command / evidence | Result | Status |
|---|---|---|---|
| Phase regression gate | Fresh `mix test.fast`, `/private/tmp/phase163-final-test-fast.log` | 2 properties, 2291 tests, 0 failures; 398 excluded and 6 skipped | ✓ PASS |
| Real client/grant lock waits and rollback | Focused Phase 163-12 and post-review regression commands | 13 PostgreSQL tests, 0 failures | ✓ PASS |
| Actual packaged legacy upgrade | `python3 scripts/acceptance/clean_room/client_lifetime_upgrade.py --check-receipt /private/tmp/lockspire-163-13-all-receipt.json` | Receipt verified; public and tenant_auth; old writer drain, v1 retention and cleanup recorded | ✓ PASS |
| Adapter conformance including post-review dropped-state proof | Focused review-fix run | 18 tests across client authentication and conformance, 0 failures | ✓ PASS |

### Probe Execution

Not applicable. Phase 163 is an application/storage implementation phase with no declared shell probe; its PostgreSQL and package journeys are checked above.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| DCR-05 | 01, 03, 06, 11, 12, 14 | New app lifetime persistence and distinct disabled/expired outcomes | ✓ SATISFIED | Registration round-trip and consumer equality/disabled tests; C-APP coverage. |
| DCR-06 | 03–12, 14 | Consistent current-state checks and selected issued-token behavior | ✓ SATISFIED | C-APP-01–18 and C-TOK-01–03 map to implementation/tests; PostgreSQL wait and rollback evidence supplements fresh full suite. |
| DCR-13 | 01, 02, 11–14 | Legacy upgrade without guessed deadlines | ✓ SATISFIED | v0 promotion tests plus verified 1.6.1-to-candidate package receipt across both prefixes. |
| DCR-14 | 01, 02, 04–14 | Fresh/custom storage contract and explicit unsupported outcome | ✓ SATISFIED | Built-in/custom adapter conformance, dropped-state failures, migration/installer tests, package journey and guidance. |

All four requirements assigned to Phase 163 appear in plans. No additional Phase 163 requirement mapping was found in `REQUIREMENTS.md`.

### Decision Coverage

The decision-coverage gate reports 24/24 trackable `163-CONTEXT.md` decisions honored; `not_honored` is empty. This is a non-blocking coverage result.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | No unreferenced `TBD`, `FIXME`, or `XXX` markers or implementation stubs found in the inspected changed implementation and focused test files. | — | — |

The app consumer matrix covers C-APP-01–18 and C-TOK-01–03. C-APP-18 is explicitly an unaffected-boundary disposition: host sessions/account policy remain host-owned and no immediate logout propagation is claimed. Phase 164/165 credential expiry and Phase 166's complete cross-phase proof remain open by their roadmap assignment and are not claimed as Phase 163 requirements.

### Human Verification Required

None. The phase's outcomes are backend, storage, protocol and upgrade contracts with executable behavior evidence; no visual or operator-judgment criterion is required for this phase goal.

### Gaps Summary

No phase-goal gaps found. The broad fast suite excludes 398 tests and skips 6; the separate focused PostgreSQL wait/rollback and package-upgrade evidence covers the phase-specific excluded behaviors. The verified package receipt is stored outside the repository at `/private/tmp/lockspire-163-13-all-receipt.json` and was revalidated during this verification.

---

_Verified: 2026-10-21T01:34:01Z_  
_Verifier: the agent (gsd-verifier)_
