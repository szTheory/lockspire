---
phase: 134
slug: architecture-topology
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-27
---

# Phase 134 — Validation Strategy

> Compatibility-preserving architecture proof for five concrete Mix xref cycles, one neutral client metadata/lifecycle owner, strict dependency direction, and permanent fitness gates.

## Test Infrastructure

| Property | Value |
|---|---|
| **Framework** | ExUnit with repository-native AST parsing plus Mix xref graph output |
| **Config** | `test/test_helper.exs`, root `mix.exs`, existing PostgreSQL-backed repository test setup |
| **Quick run** | `mix test test/lockspire/architecture_fitness_test.exs` |
| **Focused topology** | `mix qa.architecture` (created by Plan 11) |
| **Full gate** | `mix compile --warnings-as-errors && mix test.fast && mix test.integration && mix qa && mix docs.verify` |
| **Feedback target** | Every task has a focused behavioral command; xref output is inspected after each cycle slice |

## Dependency and Wave Contract

| Wave | Plans | Independent file ownership |
|---:|---|---|
| 1 | 134-01, 134-03, 134-04, 134-05, 134-06, 134-07 | Client creation, discovery, config/prefix, JAR, DPoP/userinfo, and token-result primitives do not overlap |
| 2 | 134-02, 134-08 | Client lifecycle expansion depends on 01; refresh/RFC 8693 depends on token results; the two plans do not overlap |
| 3 | 134-09 | Converts grant leaves after lower token collaborators |
| 4 | 134-10 | Closes the token facade after every grant leaf is neutral |
| 5 | 134-11 | Consumes every completed slice and owns only permanent gates/aliases |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirements | Threats | Test type | Automated command |
|---|---|---:|---|---|---|---|
| 134-01-T1 | 134-01 | 1 | ARCH-02, ARCH-03 | T-134-01..03 | service + repository integration | `mix test test/lockspire/client_lifecycle_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/dcr_audit_attribution_test.exs` |
| 134-01-T2 | 134-01 | 1 | ARCH-03 | T-134-01, T-134-03 | public facade characterization | `mix test test/lockspire/clients_test.exs test/lockspire/client_lifecycle_test.exs test/lockspire/protocol/registration_test.exs` |
| 134-03-T1 | 134-03 | 1 | ARCH-01, ARCH-02 | T-134-08..09 | protocol/config compatibility | `mix test test/lockspire/discovery_routes_test.exs test/lockspire/protocol/discovery_test.exs` |
| 134-03-T2 | 134-03 | 1 | ARCH-01, ARCH-02 | T-134-08..09 | delivery + xref | `mix test test/lockspire/discovery_routes_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs && mix xref graph --format cycles` |
| 134-04-T1 | 134-04 | 1 | ARCH-01, ARCH-02 | T-134-10 | pure prefix utility | `mix test test/lockspire/storage/prefix_test.exs test/lockspire/storage/ecto/prefix_test.exs` |
| 134-04-T2 | 134-04 | 1 | ARCH-01, ARCH-02 | T-134-10 | config compatibility | `mix test test/lockspire/config_test.exs test/lockspire/storage/prefix_test.exs test/lockspire/storage/ecto/prefix_test.exs` |
| 134-04-T3 | 134-04 | 1 | ARCH-01, ARCH-02 | T-134-11 | crypto/config + xref | `mix test test/lockspire/security/policy_test.exs test/lockspire/config_test.exs test/lockspire/storage/prefix_test.exs test/lockspire/storage/ecto/prefix_test.exs && mix xref graph --format cycles` |
| 134-05-T1 | 134-05 | 1 | ARCH-01, ARCH-02 | T-134-12..13 | JAR unit | `mix test test/lockspire/protocol/request_object_test.exs` |
| 134-05-T2 | 134-05 | 1 | ARCH-01, ARCH-02 | T-134-12..13 | endpoint compatibility + xref | `mix test test/lockspire/protocol/request_object_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs && mix xref graph --format cycles` |
| 134-06-T1 | 134-06 | 1 | ARCH-01, ARCH-02 | T-134-14..15 | sender-constraint protocol | `mix test test/lockspire/protocol/protected_resource_dpop_test.exs` |
| 134-06-T2 | 134-06 | 1 | ARCH-01, ARCH-02 | T-134-14..16 | protocol/plug/controller + xref | `mix test test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/protocol/userinfo_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/web/userinfo_controller_test.exs && mix xref graph --format cycles` |
| 134-07-T1 | 134-07 | 1 | ARCH-01 | T-134-17, T-134-19 | value/compatibility | `mix test test/lockspire/protocol/token_result_test.exs test/lockspire/protocol/token_exchange_test.exs` |
| 134-07-T2 | 134-07 | 1 | ARCH-01 | T-134-17..19 | token collaborator characterization | `mix test test/lockspire/protocol/token_result_test.exs test/lockspire/protocol/access_token_signer_test.exs test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs` |
| 134-02-T1 | 134-02 | 2 | ARCH-02, ARCH-03 | T-134-04..05 | RFC 7592 + transaction integration | `mix test test/lockspire/client_lifecycle_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/dcr_audit_attribution_test.exs` |
| 134-02-T2 | 134-02 | 2 | ARCH-02, ARCH-03 | T-134-04..05 | DCR delete + transaction integration | `mix test test/lockspire/client_lifecycle_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/dcr_audit_attribution_test.exs` |
| 134-02-T3 | 134-02 | 2 | ARCH-03 | T-134-06..07 | admin facade + transaction integration | `mix test test/lockspire/admin/clients_test.exs test/lockspire/client_lifecycle_test.exs test/lockspire/protocol/registration_management_test.exs` |
| 134-08-T1 | 134-08 | 2 | ARCH-01 | T-134-20, T-134-22 | refresh lifecycle | `mix test test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/token_result_test.exs` |
| 134-08-T2 | 134-08 | 2 | ARCH-01 | T-134-21..22 | RFC 8693 exchange | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs test/lockspire/protocol/token_result_test.exs` |
| 134-09-T1 | 134-09 | 3 | ARCH-01 | T-134-23..25 | authorization-code/shared support | `mix test test/lockspire/protocol/token_exchange/authorization_code_test.exs test/lockspire/protocol/token_exchange/delegation_test.exs` |
| 134-09-T2 | 134-09 | 3 | ARCH-01 | T-134-23..25 | device/CIBA grant suites | `mix test test/lockspire/protocol/token_exchange/ciba_and_resource_test.exs test/lockspire/protocol/token_exchange/device_code_test.exs test/lockspire/protocol/token_exchange/delegation_test.exs` |
| 134-10-T1 | 134-10 | 4 | ARCH-01 | T-134-26..28 | public facade + xref | `mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/token_exchange/authorization_code_test.exs test/lockspire/protocol/token_exchange/ciba_and_resource_test.exs test/lockspire/protocol/token_exchange/device_code_test.exs test/lockspire/protocol/token_exchange/delegation_test.exs test/lockspire/documentation_contract_test.exs && mix xref graph --format cycles` |
| 134-11-T1 | 134-11 | 5 | ARCH-01..04 | T-134-29..32 | topology/AST/export fitness | `sh scripts/ci/check_architecture_topology.sh && mix test test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs` |
| 134-11-T2 | 134-11 | 5 | ARCH-01..04 | T-134-29..32 | repository gate | `mix qa.architecture && mix compile --warnings-as-errors && mix test.fast && mix test.integration && mix qa && mix docs.verify` |

## Wave 0 Requirements

Plan 01 and each independent cycle plan start with RED characterization before production movement. The following missing proof artifacts are created by the listed plans:

- [x] `test/lockspire/client_lifecycle_test.exs` — neutral service direct/DCR/admin and transaction rollback contracts (Plans 01-02).
- [x] `test/lockspire/discovery_routes_test.exs` — mounted-route input and legacy override compatibility (Plan 03).
- [x] `test/lockspire/storage/prefix_test.exs` and `test/lockspire/security/policy_test.exs` — explicit configuration input contracts (Plan 04).
- [x] `test/lockspire/protocol/userinfo_test.exs` — protocol-level userinfo adapter contract (Plan 06).
- [x] `test/lockspire/protocol/token_result_test.exs` — pure neutral result plus one-way helper-facade compatibility conversion (Plan 07).
- [x] `scripts/ci/check_architecture_topology.sh` plus expanded architecture/compatibility fitness and literal public manifest — authoritative zero-cycle and direction gate (Plan 11).

## Source Coverage Audit

| SOURCE | ID | Feature/Requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Compatible public module structure with explicit enforceable dependency direction | 01-11 | COVERED | Neutral services, five cycle slices, permanent fitness |
| REQ | ARCH-01 | Executable zero runtime/export cycles with retained public names | 03-11 | COVERED | All five cycles plus final xref/export gate |
| REQ | ARCH-02 | Protocol depends only inward, never Web/Admin | 01-06, 11 | COVERED | DCR/discovery inversions and AST enforcement |
| REQ | ARCH-03 | One neutral client metadata/lifecycle service | 01-02, 11 | COVERED | Direct, DCR, RFC 7592, admin, atomicity, ownership fitness |
| REQ | ARCH-04 | Fitness rejects direction, boundary, topology regressions | 11 | COVERED | Mix xref + AST + export + ownership rules |
| CONTEXT | D-01 | Directional topology | 01-11 | COVERED | Each slice assigns outer/neutral ownership; final AST gate |
| CONTEXT | D-02 | Retain public nested names/result shapes | 01-11 | COVERED | Boundary characterization and compatibility fitness |
| CONTEXT | D-03 | Remove all five current cycles | 03-11 | COVERED | Discovery, config, JAR, DPoP, token group, final zero gate |
| CONTEXT | D-04 | Mix + deterministic AST; no new dependency | 03-11 | COVERED | Project-native commands only |
| CONTEXT | D-05 | Neutral client metadata/lifecycle owner | 01-02 | COVERED | Explicit service artifacts |
| CONTEXT | D-06 | Preserve direct/DCR differences | 01-02 | COVERED | Required versus optional scope and result/RAT/IAT cases |
| CONTEXT | D-07 | Remove protocol-to-admin calls | 01-02, 09 | COVERED | Creation/management moved; AST guard |
| CONTEXT | D-08 | Preserve immutable/URI/logout/PKCE/atomicity/redaction | 01-02, 07-08 | COVERED | Positive/negative and failure-injection tests |
| CONTEXT | D-09 | Discovery route capability at delivery/config edge | 03 | COVERED | Route resolver + controller input |
| CONTEXT | D-10 | Pure prefix utility; compatible Config accessors | 04 | COVERED | Explicit normalization/options and wrappers |
| CONTEXT | D-11 | Narrow neutral protocol collaborators | 05-10 | COVERED | JAR, protected resource, token result seams |
| CONTEXT | D-12 | Expanded architecture fitness assertions | 11 | COVERED | Cycles, direction, delivery/Ecto, exports, shared owner |
| CONTEXT | D-13 | Public/DCR/admin characterization | 01-02, 03-10 | COVERED | Behavior-first tasks across affected endpoints |
| RESEARCH | — | Preserve DCR policy-first and RAT/IAT semantics | 01-02 | COVERED | DCR remains protocol-owned; atomic repository operations |
| RESEARCH | — | Preserve mounted/unmounted discovery truth and legacy override | 03 | COVERED | Delivery-edge capability characterization |
| RESEARCH | — | Avoid storage/grant mega-decomposition reserved for Phase 135 | 01-11 | COVERED | Only topology seams/results move; repository/grant ownership remains |
| RESEARCH | — | Exact cycle/edge diagnostics | 11 | COVERED | Full xref output retained on failure |

Deferred Phase 135 repository/grant decomposition, Phase 136 static-analysis cleanup, Phase 137 CI/release/conformance work, new grants, hosted auth, host policy, and UI redesign are excluded and are not coverage gaps.

## Validation Audit 2026-08-27

| Metric | Count |
|--------|------:|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

The previous lifecycle test only asserted the expected error from an unavailable
test repository. It is now a database-backed behavior test proving
`ClientLifecycle.create_dcr/1` persists a client and the matching DCR audit row
with its actor and resource attribution. The existing repository integration
tests remain the failure-injection proof that the shared
`Repository.transact_with_audit/2` primitive rolls back both the durable write
and audit row.

Current evidence was run after the Phase 134 review fixes:

- `mix qa.architecture` — 12 tests, zero Mix xref cycles.
- Client lifecycle, RFC 7592, DCR attribution, and repository atomicity suite — 57 tests.
- Direct/DCR public registration plus JAR/DPoP boundary suites — 97 tests.
- Discovery/config/prefix and all token-result/internal-dispatch suites — 103 tests.
- `sh scripts/ci/check_architecture_topology.sh` — no cycles found.

All commands exited successfully. The transient KeyCache startup log appears
before the test repository starts and did not produce a test failure.

## ASVS L1 Blocking Gate

All critical/high threats block the owning plan summary and Phase 134 completion.

| ASVS area | Blocking threats | Named evidence |
|---|---|---|
| V2 Authentication | T-134-01, 04, 06, 12, 14, 17, 20 | Registration, RAT, JAR, DPoP, and token grant focused suites |
| V3 Session Management | T-134-01, 07 | Exact logout URI/origin/session-required characterization |
| V4 Access Control | T-134-04, 07, 14, 20 | Invalid-token collapse, immutable fields, sender binding, grant auth |
| V5 Input Validation | T-134-01, 08, 10, 12 | Shape, discovery paths, prefix, and JAR contract suites |
| V6 Cryptography | T-134-03, 06, 11, 14, 19, 22 | Sealed credentials, explicit secret input, DPoP, redaction/error conversion |
| Architecture integrity | T-134-29..32 | `mix qa.architecture` and final compatibility/export gate |

## Phase Completion Gate

- `mix qa.architecture` reports zero Mix xref cycles and all AST/export/ownership fitness tests pass.
- `mix compile --warnings-as-errors` passes.
- `mix test.fast` passes.
- `mix test.integration` passes.
- `mix qa` passes and invokes architecture proof once.
- `mix docs.verify` passes.
- Phase security audit closes every critical/high threat with code and current automated evidence.
