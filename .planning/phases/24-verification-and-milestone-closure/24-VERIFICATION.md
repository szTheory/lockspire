---
phase: 24-verification-and-milestone-closure
plan: "01"
subsystem: testing
tags: [jar, verification, traceability, milestone-closure]

# Dependency graph
requires:
  - phase: 22-request-object-integration
    provides: request-object orchestration, signature validation, and integration proof
  - phase: 23-jar-operator-ux-and-discovery
    provides: discovery metadata and operator JAR policy controls
provides:
  - requirement traceability for the shipped JAR slice
  - explicit deferred-scope boundary for JAR-04
affects: [milestone closure, archive handoff, REQUIREMENTS.md traceability]

# Tech tracking
tech-stack:
  added: []
  patterns: [traceability matrix, evidence-based milestone closure, deferred-scope fence]

key-files:
  created:
    - .planning/phases/24-verification-and-milestone-closure/24-VERIFICATION.md
  modified: []

requirements-completed: [JAR-01, JAR-02, JAR-03, JAR-05, JAR-06]

# Metrics
duration: unknown
completed: 2026-04-26
---

# Phase 24 Plan 01: JAR Verification Traceability

**Shipped JAR requirements are traced to concrete implementation and test proof, while JAR-04 remains explicitly deferred and out of scope.**

## Traceability Table

| Requirement | Status | Implementation evidence | Test / proof evidence | Notes |
|-------------|--------|-------------------------|-----------------------|-------|
| JAR-01 | shipped | Phase 22 request-object orchestration spliced JAR into `/authorize` and `/par` via `lib/lockspire/protocol/request_object.ex` and `lib/lockspire/protocol/authorization_request.ex`; Phase 22-07 extended `test/integration/phase15_par_authorization_e2e_test.exs` with the JAR-via-PAR branch. | `mix test test/lockspire/web/authorize_controller_test.exs --trace` from Phase 22-06; `mix test test/integration/phase15_par_authorization_e2e_test.exs --include integration --trace` from Phase 22-07. | Phase 22 integration proof covers browser-boundary handoff and full PAR→authorize→consent→token flow. |
| JAR-02 | shipped | `lib/lockspire/protocol/jar.ex` verifies request-object signatures against client keys; `test/support/jar_test_helpers.ex` supplies signed JAR fixtures and client JWK fixtures for the request-object plans. | `mix test test/lockspire/protocol/jar_test.exs` from Phase 22-01; helper compile/usage proof from Phase 22-03 and controller/protocol tests in Phase 22-04/22-06. | Signature validation is keyed to the client’s own JWK material, not a shared server key. |
| JAR-03 | shipped | `lib/lockspire/protocol/jar.ex` enforces mandatory claim validation (`iss`, `aud`, `exp`) and max-age ceiling behavior; `lib/lockspire/config.ex` supplies the JAR max-age default used by the orchestrator. | `mix test test/lockspire/protocol/jar_test.exs` and `mix test test/lockspire/config_test.exs` from Phase 22-01/22-02; claim-validation integration proof is carried by Phase 22-04. | Mandatory-claim enforcement stays inside the request-object seam before host login logic resumes. |
| JAR-05 | shipped | Phase 23-01 added JAR capability metadata in `lib/lockspire/protocol/discovery.ex` and kept discovery source-of-truth accessors in `lib/lockspire/protocol/jar.ex`. | `mix test test/lockspire/web/discovery_controller_test.exs` from Phase 23-01. | Discovery only advertises supported request-object capabilities and omits unsupported encryption/request-uri claims. |
| JAR-06 | shipped | Phase 23-02 persisted `jar_policy` on server policies; Phase 23-03 added the effective-policy resolver and admin boundary; Phase 23-04 added client overrides; Phase 23-05/23-06 added the operator LiveView surfaces and docs. | `mix test test/lockspire/domain/server_policy_jar_test.exs`; `mix test test/lockspire/protocol/jar_policy_test.exs test/lockspire/admin/server_policy_test.exs`; `mix test test/lockspire/web/live/admin/policies_live/jar_test.exs test/lockspire/web/live/admin/policies_live/par_test.exs`; `mix test test/lockspire/web/live/admin/clients_live_test.exs`. | Operator controls are split across global policy, client override, and dedicated LiveView routes. |
| JAR-04 | deferred / out of scope | No implementation was shipped for request-object decryption. The requirement register marks it deferred. | No shipped-test evidence; it is intentionally absent from Phase 23 and the Phase 24 closure set. | Explicitly excluded from the shipped milestone scope. |

## Scope Boundary

JAR-04 is not counted as shipped milestone scope. The validated milestone covers JAR-by-value handling, signature validation, mandatory claims, discovery metadata, and operator policy controls only.
