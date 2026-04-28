# Phase 35: Owned Endpoint Consumption and Truthful Surface - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-04-28
**Phase:** 35-owned-endpoint-consumption-and-truthful-surface
**Mode:** assumptions
**Areas analyzed:** Userinfo authentication contract, DPoP validation topology, discovery/support truth, operator and DCR configuration, public error/challenge semantics

## Assumptions Presented

### Userinfo Authentication Contract

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `userinfo` should accept bearer tokens as-is but require DPoP-bound tokens to use `Authorization: DPoP` plus a proof header, rejecting bearer downgrade for bound tokens. | Confident | `lib/lockspire/protocol/userinfo.ex`; `lib/lockspire/web/controllers/userinfo_controller.ex`; `lib/lockspire/domain/token.ex`; RFC 9449 protected-resource sections |

### DPoP Validation Topology

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `userinfo` should reuse protocol-owned DPoP validation, replay handling, and durable `cnf` checks rather than inventing controller-local proof logic. | Confident | `lib/lockspire/protocol/dpop.ex`; `lib/lockspire/protocol/token_endpoint_dpop.ex`; `test/lockspire/protocol/token_endpoint_dpop_test.exs` |

### Discovery and Support Truth

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Discovery/docs should advertise only the repo-proven DPoP slice and publish `dpop_signing_alg_values_supported` from the real validator allowlist. | Confident | `lib/lockspire/protocol/discovery.ex`; `test/lockspire/web/discovery_controller_test.exs`; `docs/supported-surface.md`; `test/lockspire/release_readiness_contract_test.exs`; RFC 9449 §5.1 |

### Operator and DCR Configuration

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Admin should mirror the PAR policy pattern and DCR should map RFC `dpop_bound_access_tokens` into durable client policy enums rather than metadata blobs. | Likely | `lib/lockspire/domain/client.ex`; `lib/lockspire/domain/server_policy.ex`; `lib/lockspire/admin/clients.ex`; `lib/lockspire/web/live/admin/policies_live/par.ex`; `lib/lockspire/protocol/registration.ex`; `lib/lockspire/protocol/registration_management.ex` |

### DCR Defaulting Choice

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| For self-registered clients, `dpop_bound_access_tokens: true` should persist `:dpop`; omission or `false` should persist explicit `:bearer` rather than `:inherit`. | Unclear | RFC 9449 default false behavior; existing client/server policy enums in `lib/lockspire/domain/client.ex` and `lib/lockspire/domain/server_policy.ex`; explicit rollout requirement in `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md` |

## Corrections Made

No corrections — all assumptions confirmed.
