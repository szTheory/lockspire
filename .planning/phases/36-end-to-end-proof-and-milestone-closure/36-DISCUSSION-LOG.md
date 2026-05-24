# Phase 36: End-to-End Proof and Milestone Closure - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `36-CONTEXT.md`; this log preserves the analysis path.

**Date:** 2026-04-28
**Phase:** 36-End-to-End Proof and Milestone Closure
**Mode:** assumptions
**Areas analyzed:** End-to-End Proof Topology, Introspection Truth, Binding-Surface Boundaries,
Milestone Closure Artifacts

## Assumptions Presented

### End-to-End Proof Topology

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 36 should add DPoP browser-flow proof by extending the existing repo-native integration test style, not by introducing a new acceptance harness or external demo-app layer. | Confident | `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`, `test/integration/phase15_par_authorization_e2e_test.exs`, `test/integration/phase32_device_flow_token_exchange_e2e_test.exs`, `.planning/ROADMAP.md`, `.planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md`, `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md` |

### Introspection Truth

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 36 should make introspection expose durable DPoP binding truth by adding `cnf` for active DPoP-bound tokens, while preserving the current inactive-response collapse and confidential-caller gate. | Confident | `lib/lockspire/protocol/introspection.ex`, `test/lockspire/protocol/introspection_test.exs`, `test/lockspire/web/introspection_controller_test.exs`, `.planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` |

### Binding-Surface Boundaries

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 36 should keep the public DPoP claim narrow: `/token` issuance, Lockspire-owned `userinfo`, and truthful introspection visibility, without turning introspection or docs into a generic host protected-resource story. | Confident | `docs/supported-surface.md`, `lib/lockspire/protocol/discovery.ex`, `test/lockspire/release_readiness_contract_test.exs`, `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md` |

### Milestone Closure Artifacts

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 36 closure should treat `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, and `.planning/EPIC.md` as the authoritative milestone-truth set that must be synchronized together when DPoP-12 through DPoP-14 close. | Confident | `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/EPIC.md` |

## Corrections Made

No corrections. The assumptions were accepted as-is with `proceed`.

## External Research Applied

None. Codebase evidence was sufficient for all presented assumptions.

## Notes

- The main open implementation work is not product-shape ambiguity; it is coordinated proof and
  closure execution.
- The strongest live gap observed during analysis was introspection omitting `cnf` even though
  token binding truth is already durably stored on DPoP-bound tokens.

