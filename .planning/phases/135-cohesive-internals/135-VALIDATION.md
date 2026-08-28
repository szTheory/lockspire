# Phase 135 — Plan Validation and Source Audit

## Dependency graph

| Wave | Plans | Dependency reason |
|---|---|---|
| 1 | 135-01 | Characterization and DB atomicity contracts precede movement. |
| 2 | 135-02, 135-06 | Storage client/audit tracer and token dependency normalization have no file overlap. |
| 3 | 135-03, 135-07 | Authorization-session aggregates and token validation/polling expand their respective proven slices. |
| 4 | 135-04, 135-08 | Async/replay storage and issue/persist/observe token slices remain independent. |
| 5 | 135-05 | Completes storage aggregates after prior facade edits. |
| 6 | 135-09 | Converges final storage and token trees into permanent fitness/full gates. |

Same-wave plans have no `files_modified` overlap. Every shared facade file is serialized through an explicit dependency.

## Goal-backward coverage

| Observable truth | Required artifacts/wiring | Plans |
|---|---|---|
| Maintainers navigate aggregate-specific Ecto owners behind Repository. | `storage/ecto/repository/*.ex`; Repository delegates every declared behavior and supplies one configured repo/support boundary. | 02–05, 09 |
| Code, refresh, DCR-audit, and keys retain atomic rollback/concurrency behavior. | DB characterization plus transaction-owning client/token/key collaborators. | 01, 02, 05, 09 |
| Token auth, resources, polling, issuance, persistence, and observability have focused owners. | Explicit collaborators composed by all five neutral grant coordinators behind TokenExchange. | 07–09 |
| Runtime dependencies are explicit while legacy injection remains compatible. | Private `Dependencies` struct, exhaustive `LegacyOptions`, source fitness. | 06–09 |
| Five grants preserve responses, errors, tokens, audit, and telemetry. | Stable-facade characterization harness run before and after every relevant slice. | 01, 06–09 |

## Multi-source coverage audit

| SOURCE | ID | Feature/Requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Storage and grant internals are navigable, explicit, and behaviorally stable behind existing public facades. | 01–09 | COVERED | Characterization precedes two bounded parallel refactor tracks and final convergence. |
| REQ | COH-01 | Aggregate-specific Ecto implementations behind Repository. | 02–05, 09 | COVERED | All fifteen behavior families are grouped into cohesive aggregate slices; facade remains configured entry point. |
| REQ | COH-02 | Atomic code, refresh, DCR-audit, and key transitions. | 01, 02, 05, 08, 09 | COVERED | DB rollback/concurrency contract plus complete transaction owners. |
| REQ | COH-03 | Focused token grant responsibilities behind stable facade. | 07–09 | COVERED | Authentication, resources, polling, issuance, persistence, observability. |
| REQ | COH-04 | Explicit bundles, no runtime capability/env branching, compatible injection. | 06–09 | COVERED | Exhaustive legacy map and permanent AST fitness. |
| REQ | COH-05 | Five-flow response/error/token/audit/telemetry characterization. | 01, 06–09 | COVERED | Code, refresh, device, CIBA, RFC 8693. |
| RESEARCH | — | Thin facade over behavior-complete aggregate delegates. | 02–05 | COVERED | Complete operations move; callers remain on Repository. |
| RESEARCH | — | Preserve transaction and row-lock ownership in aggregate operations. | 01, 02, 03, 04, 05 | COVERED | Locks and audit stay inside complete delegate entry points. |
| RESEARCH | — | Shared Ecto support without copied helpers or record leakage. | 02–05 | COVERED | One explicit repo/options support collaborator. |
| RESEARCH | — | Typed dependency bundle plus exhaustive legacy adapter. | 06 | COVERED | Every observed request option and default is table-tested. |
| RESEARCH | — | Grant coordinator responsibility map. | 07–08 | COVERED | Each named responsibility has one owner and explicit inputs. |
| RESEARCH | — | Reject capability sniffing, runtime environment branching, and downstream opts access. | 06, 09 | COVERED | Construction validation plus AST source gate. |
| RESEARCH | — | PostgreSQL concurrency and audit rollback proof. | 01, 02, 05 | COVERED | Real Ecto/PostgreSQL tests, not mocks. |
| RESEARCH | — | No external package installation. | 01–09 | COVERED | Plans use the locked stack only. |
| CONTEXT | — | No CONTEXT.md decisions exist; roadmap/requirements are binding. | 01–09 | COVERED | Assumptions and research explicitly preserve milestone compatibility boundaries. |

## Excluded without gaps

- Credo/Dialyzer and routine test-output cleanup remain Phase 136.
- CI coverage, conformance, artifact, and release evidence remain Phase 137.
- New grants, hosted authorization, host product policy, operator UI redesign, and breaking public removals remain outside the milestone scope.

## Nyquist coverage

Every production-code task starts with behavior assertions and has a focused automated command. The final plan runs architecture fitness, literal public compatibility, DB atomicity, five-flow characterization, compilation, fast/integration tests, QA, and docs verification from the converged tree.

## Nyquist Adversarial Validation — 2026-08-27

**Result:** FILLED — 5/5 requirements have executable evidence.

| Requirement | Behavioral evidence | Command | Result |
|---|---|---|---|
| COH-01 | Parse-once fitness verifies the configured Repository remains a behavior-complete facade without Ecto ownership, and aggregate delegates remain reachable. | `MIX_ENV=test mix qa.architecture` | 13 tests, 0 failures; no cycles |
| COH-02 | Ten independently checked-out PostgreSQL connections race to redeem one authorization code; exactly one commits and the other nine observe `:already_redeemed`. Existing rollback/reuse/DCR/key tests cover the remaining lifecycle boundaries. | `mix test test/lockspire/storage/repository_concurrency_test.exs --trace` | 1 test, 0 failures |
| COH-03 | Focused-owner fitness and five-grant contract tests exercise auth, resources, polling, issuance, persistence, and observability through the retained facade. | `mix test test/lockspire/architecture_fitness_test.exs test/lockspire/protocol/token_exchange/characterization_test.exs` | 15 tests, 0 failures |
| COH-04 | Legacy option normalization and deterministic missing-capability behavior are exercised alongside the no-probe AST gate. | `mix test test/lockspire/protocol/token_exchange/dependencies_test.exs test/lockspire/architecture_fitness_test.exs` | 13 tests, 0 failures |
| COH-05 | Public success/error, durable token state, audit/telemetry, and the five supported grants are characterized at the stable token facade. | `mix test test/lockspire/protocol/token_exchange/characterization_test.exs` | 5 tests, 0 failures |

### Gap filled

The prior authorization-code “one winner” check made two sequential calls, so it could not establish that the `FOR UPDATE` transaction remained correct under independent database connections. `test/lockspire/storage/repository_concurrency_test.exs` is intentionally outside the shared SQL sandbox: it persists isolated fixtures, synchronizes ten task contenders, runs each redemption with its own non-sandbox connection, asserts the one-success/nine-rejection contract, verifies durable redemption, then removes only those fixtures. This test fails if two contenders can redeem the same code.

No implementation files were modified.
