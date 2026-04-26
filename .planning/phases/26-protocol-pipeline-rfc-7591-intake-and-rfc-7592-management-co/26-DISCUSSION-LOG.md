# Phase 26: Protocol Pipeline — RFC 7591 Intake and RFC 7592 Management Core - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `26-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-04-26
**Phase:** 26-protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
**Mode:** assumptions
**Areas analyzed:** Module Layout & Naming, Hash-at-Rest Primitive Reconciliation, Atomic IAT Redemption Mechanism, DCR Audit Actor Shape, Telemetry Event Shape & Redaction Test Strategy

## Assumptions Presented

### Module Layout & Naming

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Four sibling protocol modules: `Registration` (intake orchestrator), `RegistrationManagement` (RFC 7592), `InitialAccessToken` (redeem lifecycle, distinct from `Domain.InitialAccessToken`), `RegistrationAccessToken` (RAT primitives). Validator lives inside `Registration` as private functions, not a separate `IntakeValidator`. | Likely | `lib/lockspire/protocol/pushed_authorization_request.ex:13-39, 66`; `Lockspire.Domain.X` vs `Lockspire.Protocol.X` namespace axis (Phase 25 D-15); `.planning/research/ARCHITECTURE.md:124-129` |

### Hash-at-Rest Primitive Reconciliation

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `client_secret` uses `Lockspire.Security.Policy.hash_client_secret/1` (salted, parity with operator-created path); IAT and RAT use `hash_token/1` (unsalted, required by `unique_index([:token_hash])` lookup). | Likely | `policy.ex:84-89` (`hash_token/1`), `policy.ex:91-114` (`hash_client_secret/1` + `verify_client_secret/2`), `clients.ex:52-56` (`rotate_secret_hash/0`), Phase 25 D-14 + D-03 |

### Atomic IAT Redemption Mechanism

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `redeem/1` accepts plaintext IAT, hashes internally, delegates to new `Repository.redeem_initial_access_token/1` using `Repository.transact/1` + `lock("FOR UPDATE")`. Public return collapses `:not_found / :expired / :revoked / :already_used` to `{:error, :invalid_token}`; discriminator emitted only to telemetry (defense against IAT enumeration). | Confident | `lib/lockspire/storage/ecto/repository.ex:521, 534-555, 702, 744`; project-wide use of `lock("FOR UPDATE")` not `Ecto.Multi`; `pushed_authorization_request.ex:177` (`wrap_jar_error/1` error-collapsing precedent); RFC 6749 §5.2 |

### DCR Audit Actor Shape

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Tighten `actor_from_attrs/1` in place at `lib/lockspire/admin/clients.ex:397-419` — change three silent `:operator` fallbacks (lines 407, 414, 419) to raise `ArgumentError`. DCR codepath: `:dcr` actor for intake, `:self_registered_client` for RFC 7592 management. Regression test queries `lockspire_audit_events` and refuses `action LIKE 'dcr_%' AND actor_type = 'operator'`. | Likely | `clients.ex:397-419` (three silent fallbacks); audit-row vs telemetry assertion determinism; `.planning/research/PITFALLS.md:247` (Pitfall 10 — "tighten in place") |

### Telemetry Event Shape & Redaction Test Strategy

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Emit via existing `Lockspire.Observability.emit/3` (NOT raw `:telemetry.execute/3`). Atom-singleton event names (`:dcr_registration_succeeded`, `:iat_redeemed`, etc.) — namespace inferred from atom prefix; satisfies `[:lockspire, :dcr, ...]` / `[:lockspire, :iat, ...]` SC via project-convention 2-segment shape. Reuses `Redaction.for_telemetry/1`. Single-sweep redaction test asserts no plaintext RAT/IAT/`client_secret` in any captured event. | Unclear (resolved by user) | `observability.ex:15-29` (current 2-segment shape); `redaction.ex:8-53` (existing sieve); `tokens.ex:276-292` (`Admin.Tokens.emit/4` precedent with `restore_unredacted_ids/2`) |

## Corrections Made

No corrections — all five assumptions confirmed via the "Yes, proceed" choice.

## Auto-Resolved

The Telemetry Event Shape area (originally Unclear, with two viable paths) was resolved during the confirmation question by selecting the recommended atom-singleton convention (Option b) over extending `Observability.emit/3` to accept multi-segment paths (Option a). The recommended path matches existing project convention; the alternative remains tracked under Deferred Ideas as a one-shot fix if a future audit demands stricter namespace satisfaction.

## External Research

None — codebase analysis (12+ files read by `gsd-assumptions-analyzer`) plus Phase 25 carry-forward provided sufficient evidence for all five areas. The DCR research corpus in `.planning/research/` was consulted but no external (web/library-docs) research was needed; the open question about telemetry-shape grading was a project-convention choice, not a knowledge gap.
