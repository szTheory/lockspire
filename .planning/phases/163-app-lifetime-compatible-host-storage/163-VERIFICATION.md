---
phase: 163-app-lifetime-compatible-host-storage
verified: 2026-10-22T16:52:36Z
status: passed
score: 46/46 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
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
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-COVERAGE.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-EXECUTION-REFRESH.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-REVIEW-DISPOSITION.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-REVIEW-FIX-SUMMARY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-REVIEW.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-SECURITY.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-SOURCE-AUDIT.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-UI-REVIEW.md
  - .planning/phases/163-app-lifetime-compatible-host-storage/163-VALIDATION.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-REVIEW.md
  - .planning/phases/164-client-secret-expiry-atomic-rotation/164-SECURITY.md
  - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-12-SUMMARY.md
  - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-CI-EVIDENCE.json
  - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-EVIDENCE-MAP.json
  - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-VALIDATION.md
  - docs/architecture.md
  - docs/dynamic-registration.md
  - docs/examples/client-lifetime-adapter.md
  - docs/upgrading/client-lifetimes.md
  - docs/upgrading/storage-prefix.md
  - lib/lockspire/client_metadata.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/protocol/authorization_flow.ex
  - lib/lockspire/protocol/authorization_request.ex
  - lib/lockspire/protocol/backchannel_authentication.ex
  - lib/lockspire/protocol/client_auth.ex
  - lib/lockspire/protocol/device_authorization.ex
  - lib/lockspire/protocol/device_verification.ex
  - lib/lockspire/protocol/introspection.ex
  - lib/lockspire/protocol/registration.ex
  - lib/lockspire/protocol/registration_management.ex
  - lib/lockspire/protocol/revocation.ex
  - lib/lockspire/protocol/token_exchange/internal/authorization_code_grant.ex
  - lib/lockspire/protocol/token_exchange/internal/client_authentication.ex
  - lib/lockspire/protocol/token_exchange/internal/dependencies.ex
  - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
  - lib/lockspire/protocol/token_exchange/internal/legacy_options.ex
  - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
  - lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex
  - lib/lockspire/protocol/token_lifetime.ex
  - lib/lockspire/protocol/userinfo.ex
  - lib/lockspire/storage/client_lifetime.ex
  - lib/lockspire/storage/client_store.ex
  - lib/lockspire/storage/ecto/client_record.ex
  - lib/lockspire/storage/ecto/repository.ex
  - lib/lockspire/storage/ecto/repository/client_store.ex
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
  - test/lockspire/client_lifetime_guidance_test.exs
  - test/lockspire/install/migrations_test.exs
  - test/lockspire/protocol/app_lifetime_policy_test.exs
  - test/lockspire/protocol/client_app_authentication_test.exs
  - test/lockspire/protocol/rfc8693_exchange_test.exs
  - test/lockspire/storage/client_lifetime_client_wait_test.exs
  - test/lockspire/storage/client_lifetime_conformance_test.exs
  - test/lockspire/storage/client_lifetime_grant_wait_test.exs
  - test/lockspire/storage/client_lifetime_promotion_test.exs
  - test/lockspire/storage/client_lifetime_rollback_test.exs
  - test/support/client_lifetime_race_helpers.ex
covered_digest: "v3:sha256:b237cc88c5cc222572540f380ae0cb47263e8e1e51376078c575691da8017c37"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 46/46
  delta_reverified:
    - "RFC 8693 final exchange clock accepts only DateTime and returns a controlled error without token issuance or audit on malformed callback output."
    - "Existing truths, including D-24 host guidance and storage/upgrade behavior, were regression-checked against unchanged covered paths."
  gaps_closed: []
  gaps_remaining: []
  regressions: []
advisory: []
---

# Phase 163: App Lifetime & Compatible Host Storage Verification Report

**Phase Goal:** New and existing Phoenix hosts can store and enforce the selected app lifetime through an explicit schema and storage upgrade path.
**Verified:** 2026-10-22T16:07:50Z
**Status:** passed
**Re-verification:** Yes — after D-24 guidance gap closure

## Goal Achievement

### Observable Truths

The four roadmap success criteria are non-negotiable. The 42 plan-level truths add detail; each plan row below represents its three declared truths, with the plan identifiers and corresponding source/test evidence. All four roadmap criteria and all 42 plan truths pass. This bounded re-verification rechecks the final RFC 8693 clock-guard delta and regression evidence while retaining the previously verified unchanged-path evidence.

| # | Truth | Status | Evidence |
|---|---|---|---|
| R1 | New registrations persist the selected effective lifetime; request-time eligibility follows the Phase 162 consumer inventory, including no-secret clients. | ✓ VERIFIED | `ClientMetadata` creates version 1 snapshots; `ClientRecord` persists the version and deadlines. Current registration/authorization tests are included in the fresh focused run (52 tests, 0 failures; `163-VALIDATION.md`). Coverage maps C-APP-01–18 and C-TOK-01–03. |
| R2 | Existing hosts upgrade under the approved legacy treatment; ambiguous historical dates do not silently activate rejection, and rollout/rollback procedures have executable coverage. | ✓ VERIFIED | Additive migration defaults existing rows to v0 and keeps old secret dates advisory; `Client.app_eligibility/3` treats v0 as unlimited. The current candidate's Phase 166 package lane records both prefixes, old-writer drain before v1, preserved migration history and retained v1 state (166-VALIDATION.md, 166-12-SUMMARY.md). |
| R3 | Fresh generated schema and custom storage satisfy the selected contract; unsupported capabilities produce the documented outcome. | ✓ VERIFIED | Migration/installer tests, candidate-package upgrade tests and the documented custom adapter composition establish the path. `ClientLifetime` checks explicit version, current-row callback and shared authority; negative conformance cases cover missing/dropped state. |
| R4 | Focused tests demonstrate expiry boundaries, disabled-versus-expired behavior and issued-token behavior without relying on pruning. | ✓ VERIFIED | The 52-test current focused run includes registration, authorization, code redemption, online consumers, management, adapter conformance, promotion and migration. Recorded Phase 163 PostgreSQL wait/rollback tests pass 13/13; capped durable/JWT/response expiry is mapped in C-TOK-01–03. |
| P1 | Plans 01–02: explicit v1 registration and v0 migration round-trip; selected policy/clock semantics; adapters declare version 1 and matching transaction authority; lossy state or missing guards fail closed; fetch preserves disabled/expired rows. | ✓ VERIFIED | Current schema/domain/adapter code inspected. `app_lifetime_registration_test.exs`, `app_lifetime_policy_test.exs` and `client_lifetime_conformance_test.exs` provide behavior evidence; all declared artifacts pass. |
| P2 | Plan 03: all supported client authentication methods check current enabled/app state; configuration/store errors remain server errors; injected time and verified identity survive adaptation for final writers. | ✓ VERIFIED | Client authentication adapts typed lifetime support and preserves time/identity; current auth tests cover public, secret, private-key and mTLS cases. |
| P3 | Plan 04: authorization intake rejects before host handoff, completion rechecks current app after locks, and JARM construction/rendering occurs after commit. | ✓ VERIFIED | Authorization request/flow call sites were traced; current authorization integration tests include host-handoff, resume/approval and equality rollback cases. |
| P4 | Plan 05: device and CIBA creation, verification and approval use current app state, explicit clocks and post-lock rechecks; delayed host/network work stays outside locks. | ✓ VERIFIED | Device and CIBA sources were traced through their stores; current device and CIBA approval tests cover expiry/disablement and rejection without durable approval writes. |
| P5 | Plan 06: code redemption rechecks locked current app/credential after waits, failed redemption leaves no partial writes, and durable/JWT/response expiry shares the final cap. | ✓ VERIFIED | `GrantPersistence` locks/reloads current client state and uses one final effective expiry. The current code-redemption suite covers untouched grant on equality and equal capped output representations. |
| P6 | Plan 07: refresh issuance rechecks current app/credential after ordered locks, caps access and replacement refresh TTLs independently, and preserves replay/rollback behavior. | ✓ VERIFIED | Refresh flow reaches shared guarded persistence; current refresh integration behavior is in the mapped C-APP/C-TOK matrix. The saved focused rollback run covers refresh family/write failure behavior. |
| P7 | Plan 08: approved device/CIBA requests cannot issue after app expiry/disablement; poll/push sample after locks, cap outputs uniformly and deliver push after lock release. | ✓ VERIFIED | Poll, CIBA grant and worker paths were traced. Focused poll/push cases and recorded wait/rollback tests exercise final equality and post-commit delivery. |
| P8 | Plan 09: RFC 8693 checks requester, subject and actor independently, locks participating clients in stable order, rolls back writes together and caps signed/opaque outputs. | ✓ VERIFIED | The public exchange path retains ordered client/token locks, current issuer checks and transactional issuance. The final clock is sampled after locks and before validity/eligibility/issuance; only `%DateTime{}` is accepted, and malformed/raised callback results become controlled `server_error(:clock_unavailable)`. The public `exchange/2` regression asserts that outcome, unchanged stored-token inventory and no audit events. The current post-guard RFC/app-RFC/secret-poll/PostgreSQL grant-wait selection passed 27 tests, 0 failures; the additional root-attributed RFC/guidance selection passed 19 tests, 0 failures. See `163-REVIEW.md` and `/tmp/phase163-final-delta-20261022.md`. |
| P9 | Plan 10: UserInfo and introspection read current issuer state, revocation checks caller eligibility, while provider discovery/JWKS, host sessions and offline VerifyToken remain outside app-lifetime checks. | ✓ VERIFIED | Online-consumer behavior tests cover current custom stores, inactive owned tokens, unknown-token revocation and discovery. `VerifyToken` remains offline; the host boundary is explicit in architecture docs. |
| P10 | Plan 11: expired enabled apps retain allowed GET/DELETE but cannot PUT; disabled apps are denied; legacy credential replacement promotes the locked row atomically and stale snapshots cannot restore prior state. | ✓ VERIFIED | Registration management/controller and repository delta mutations were inspected. Current management/promotion tests cover operation outcomes, atomic v0 promotion and rollback. |
| P11 | Plan 12: independent PostgreSQL holder/contender sessions confirm the actual blockers; post-wait equality/disablement/replacement and write/audit rollback preserve durable state. | ✓ VERIFIED | Recorded exact focused command in `163-12-SUMMARY.md`: 13 PostgreSQL tests, 0 failures. Helpers compare backend PIDs and `pg_blocking_pids` before advancing the clock; rollback tests inspect durable state. |
| P12 | Plan 13: generated and upgraded public/custom-prefix schemas converge; PostgreSQL DDL lock handling is bounded; real old/candidate package processes preserve old checksums and enforce the writer-drain boundary. | ✓ VERIFIED | `163-13-SUMMARY.md` records the actual old/candidate package journey. The current Phase 166 candidate package partition re-proves inherited public/tenant_auth upgrade outcomes and adds current legacy HTTP/promotion evidence. The old Phase 163 receipt no longer validates against the evolved runner schema; it is not counted as current proof. |
| P13 | Plan 14 D-24: host storage/migration guidance matches observed runtime/package behavior without product UI versions or an immediate offline-revocation promise. | ✓ VERIFIED | [The guide](/Users/jon/projects/lockspire/docs/upgrading/client-lifetimes.md:214) now identifies runtime candidate `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`, links the 7/7 CI run and committed evidence map, states that three edge probes and two descriptor-less prohibitions remain unverified, and says the later text correction was not part of that CI run. The 8-test guidance contract passes. |
| P14 | Plan 14 D-01–D-24 coverage is explicit; no dependency/service/admin redesign was introduced, and later credential requirements remain in their owning phases. | ✓ VERIFIED | `163-COVERAGE.md` maps C-APP/C-TOK cases; `163-SOURCE-AUDIT.md` maps all 24 decisions. `mix.exs`/`mix.lock` and dependency boundary are unchanged; shared-secret and management-token policy remain assigned to their later owning scopes. |

**Score:** 46/46 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| 14 plans' declared artifacts | Current implementation and focused evidence | ✓ VERIFIED | `gsd-tools query verify.artifacts` evaluated every plan: 34/34 artifacts exist and passed substantive checks. |
| Schema, migration, client lifetime domain and adapter | Explicit lifetime state, v0 compatibility and fail-closed adapter contract | ✓ VERIFIED | Inspected current schema mapping, migration, eligibility, adapter declaration/current-row validation and shared authority checks. |
| Authorization, token issuance and management paths | Current-app checks and consistent expiry across applicable online consumers | ✓ VERIFIED | Source call chains and current focused integration evidence cover the selected consumer inventory. |
| Upgrade scripts, clean-room tests and host guidance | Executable expansion/cutover and adopter-facing schema/custom-store instructions | ✓ VERIFIED | Core upgrade instructions are current, and the Phase 166 status paragraph now reflects the final runtime-candidate evidence while disclosing that the documentation correction postdates CI. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Registration metadata | Ecto client record and additive migration | Changeset/domain mapping and persisted fields | WIRED | V1 fields flow from `ClientMetadata` through the domain and `ClientRecord`; migration adds version/default/deadline columns. Registration round-trip test passed in the fresh focused run. |
| Adapter declaration | Typed lifetime support and dependency consumers | One-time adaptation and transaction-participant validation | WIRED | `ClientLifetime.configured/adapt` validates adapter declaration, guard callback, client/transaction stores and selected participant authority; `LegacyOptions` attaches the typed value and `Dependencies.validate` verifies grant-specific participants. |
| Protocol request | Current client state and decision boundary | Store fetch/lock then eligibility | WIRED | Authorization, device/CIBA, online consumer and management callers reach current-row reads/locks before host side effects or durable decisions. Covered by the mapped current integration cases. |
| Grant/refresh/RFC 8693 issuance | Current client + grant/token transaction | Ordered locks, fresh time, common persistence | WIRED | `GrantPersistence` handles final client guards and sends effective expiry to row, signer and response; focused current tests plus 13 PostgreSQL wait/rollback tests cover the transitions. |
| Packaged installer and runner | Additive migration and old/candidate host journey | Existing migration checksum/copy flow and isolated process roots | WIRED | Installer delegates migration copying with checksum/no-overwrite checks; package scenario tests and current Phase 166 exact-candidate package evidence cover both prefixes. |
| Upgrade guidance | Executable upgrade/custom-store path | Commands, adapter example, cutover procedure | WIRED | The procedure points to executable package/conformance evidence and accurately labels the runtime CI result and later documentation correction. |

The literal key-link query returned 2/30 links verified and 28 false negatives because it searched for the target path as source text. I checked each relationship through the actual modules/call sites and behavior evidence above; no disconnected implementation link was found. The final RFC clock guard is directly wired between the post-lock callback and issuance decision, and its public-facade regression checks the failure boundary.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Registration → client row | `lifetime_version`, `client_expires_at` | Resolved policy and registration time, persisted through Ecto | Yes; database round-trip test | ✓ FLOWING |
| Current app guard → protocol outcome | active state and app deadline | Current store row after the applicable lock/fetch | Yes; current integration tests assert outcomes and durable state | ✓ FLOWING |
| Final issuance → row, JWT, response | effective access/refresh expiry | Post-wait decision time capped by the app deadline | Yes; focused signed/opaque cases compare expiry outputs | ✓ FLOWING |
| Existing host → candidate schema | v0 record and advisory historical secret dates | Actual prefix-aware additive migration and old/candidate package processes | Yes; package evidence retains old records, v0 interpretation, v1 cutover and cleanup | ✓ FLOWING |
| Upgrade guide status addendum | CI/review completion status and evidence limits | Maintainer-reviewed static guidance | Yes; it identifies the historical runtime candidate/CI and separately dates the later documentation correction | ✓ VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Current app lifetime registration, equality and online consumers | Current isolated focused run recorded in `163-VALIDATION.md`; eight named ExUnit files | 52 tests, 0 failures | ✓ PASS |
| Real PostgreSQL client/grant waits and rollback | Exact command recorded in `163-12-SUMMARY.md` | 13 tests, 0 failures; observed independent blockers and durable state | ✓ PASS |
| Packaged legacy upgrade and custom prefix | Current exact-candidate Phase 166 package lane, `166-VALIDATION.md` and `166-CI-EVIDENCE.json` | Candidate `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`; 7/7 required contexts, 9/9 scenarios, 49/49 checks passed; cleanup complete | ✓ PASS |
| D-24 guidance correction | Old guide red log, corrected guide green log; format and whitespace results recorded in `163-REVIEW.md` | Old wording fails the contract as expected; corrected guide passes 8 tests with 0 failures; formatting/diff checks pass | ✓ PASS |
| RFC 8693 malformed final-clock handling | Public `Rfc8693Exchange.exchange/2` regression in `test/lockspire/protocol/rfc8693_exchange_test.exs`; root-attributed command and environment in `/tmp/phase163-final-delta-20261022.md` | `MIX_ENV=test mix test test/lockspire/protocol/rfc8693_exchange_test.exs test/lockspire/client_lifetime_guidance_test.exs`; 19 tests, 0 failures (seed 742898). The related post-guard RFC/app-RFC/secret-poll/PostgreSQL grant-wait selection also passed 27 tests, 0 failures. | ✓ PASS |
| Phase 163 standalone receipt recheck | `python3 scripts/acceptance/clean_room/client_lifetime_upgrade.py --check-receipt /private/tmp/lockspire-163-13-all-receipt.json` | Failed with `PackageInputError`; that dated receipt predates the evolved receipt schema. The current candidate package proof above uses the later receipt contract. | Informational; not counted as a product behavior failure |

### Probe Execution

Not applicable. No phase plan or success criterion declares a shell probe or probe marker.

### Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| DCR-05 | 01, 03, 06, 11, 12, 14 | New app lifetime persistence and distinct disabled/expired behavior | ✓ SATISFIED | V1 registration round-trip plus consumer equality/disabled tests; current focused run passed. |
| DCR-06 | 03–12, 14 | Consistent current-state checks and selected issued-token behavior | ✓ SATISFIED | C-APP-01–18/C-TOK-01–03 mapping; current focused behavior and PostgreSQL wait/rollback evidence. |
| DCR-13 | 01, 02, 11–14 | Existing-host upgrade without guessed deadlines from ambiguous legacy dates | ✓ SATISFIED | V0 treatment and promotion, additive migration, and exact-candidate packaged upgrade evidence. |
| DCR-14 | 01–14 | Fresh/custom storage contract and explicit unsupported outcome | ✓ SATISFIED | Built-in/custom adapter conformance, generated-prefix migration and package evidence, and host storage guidance. The stale release-status addendum is reported under plan truth D-24. |

All four roadmap-assigned requirements appear in plan frontmatter. No orphaned Phase 163 requirement mapping was found.

### Decision Coverage

The decision coverage gate reports 24/24 trackable `163-CONTEXT.md` decisions honored; `not_honored` is empty. This gate is non-blocking. The source audit also maps D-01–D-24 individually. The three unresolved A-EDGE assumptions and two descriptor-less prohibitions remain explicit evidence limits; they are not reclassified as passes or converted into new predicates/human approval gates. Historical TDD caveats remain: `tdd_mode` was false, and the non-semantic initial RED/missing recorded RED-GREEN cases are not certified as strict TDD evidence.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | No debt markers, placeholder implementation, empty handler or hard-coded empty user-visible result in the inspected lifetime/storage/consumer paths. | — | — |

### Re-verification

The prior verification passed 46/46; this re-verification addresses its only newly stale input, `grant_persistence.ex`, by directly inspecting the final RFC 8693 clock guard and its public-facade regression. The callback now fails closed with a controlled server error before issuance or audit, and the test checks no token or audit mutation. The existing client/token lock order, current app/issuer eligibility, transaction boundary, and no-write-on-error behavior remain intact. Unchanged-path truths and D-24 guidance were regression-checked using recorded Phase 163 and Phase 166 evidence; the guide accurately labels the historical candidate/CI and later correction. No regressions were found. CI run 39776185275 and package 9/49 remain historical for candidate `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`; final CI run 39816801430 belongs to the root workflow and is not claimed here.

### Advisory (New Scope, Unevidenced)

None. No new-scope concern without deterministic evidence was identified.

### Human Verification Required

None. All goal and plan truths have code or behavioral evidence; the D-24 wording is covered by an executable contract test.

### Gaps Summary

The codebase implements the app lifetime schema, adapter contract, online enforcement, selected expiry behavior and executable legacy upgrade path. The prior D-24 documentation gap is closed, and the remaining truths pass. The correction postdates the runtime candidate CI and is explicitly identified as such; the updated guidance contract passes.

---

_Verified: 2026-10-22T16:52:36Z_
_Verifier: the agent (gsd-verifier)_
