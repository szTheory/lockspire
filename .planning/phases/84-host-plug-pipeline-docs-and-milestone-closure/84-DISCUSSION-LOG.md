# Phase 84: Host Plug Pipeline, Docs, and Milestone Closure - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `84-CONTEXT.md` are authoritative.

**Date:** 2026-05-24
**Phase:** 84-host-plug-pipeline-docs-and-milestone-closure
**Mode:** assumptions
**Areas analyzed:** host plug contract, protected-resource nonce contract, milestone proof strategy, support-truth/docs posture

## Assumptions Presented

### Host plug contract

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Preserve the split `VerifyToken -> EnforceSenderConstraints -> RequireToken` pipeline with one strict HTTP boundary. | Confident | `lib/lockspire/plug/verify_token.ex`, `lib/lockspire/plug/enforce_sender_constraints.ex`, `lib/lockspire/plug/require_token.ex`, `.planning/phases/80-sender-constraining-integration/80-CONTEXT.md`, `.planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md` |

### Protected-resource nonce contract

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Host Phoenix routes should use the same `401` + `WWW-Authenticate: DPoP ... error=\"use_dpop_nonce\"` + `DPoP-Nonce` retry contract already used for `/userinfo`. | Confident | `lib/lockspire/protocol/protected_resource_dpop.ex`, `lib/lockspire/web/controllers/userinfo_controller.ex`, `lib/lockspire/plug/require_token.ex`, `test/lockspire/web/userinfo_controller_test.exs`, `test/lockspire/plug/require_token_test.exs`, `docs/protect-phoenix-api-routes.md` |
| Shared rendering/helper extraction is preferable to moving HTTP rendering into `EnforceSenderConstraints`. | Likely | `lib/lockspire/plug/enforce_sender_constraints.ex`, `lib/lockspire/plug/require_token.ex`, `lib/lockspire/web/controllers/userinfo_controller.ex` |

### Milestone proof strategy

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Generated-host E2E should be the main closure proof for the nonce-backed host-route claim, with local tests covering adapter gaps only. | Confident | `test/integration/phase81_generated_host_route_protection_e2e_test.exs`, `test/lockspire/plug/enforce_sender_constraints_test.exs`, `test/lockspire/plug/require_token_test.exs`, `test/lockspire/release_readiness_contract_test.exs`, `.planning/phases/83-lockspire-owned-dpop-endpoint-adoption/83-CONTEXT.md` |

### Support-truth and docs posture

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Public wording should stay anchored to `host Phoenix API routes protected by the shipped plug pipeline`, not broader resource-server middleware language. | Confident | `docs/supported-surface.md`, `docs/protect-phoenix-api-routes.md`, `docs/install-and-onboard.md`, `test/lockspire/release_readiness_contract_test.exs`, `prompts/lockspire-market-gap-and-positioning.md` |

## Corrections Made

No user corrections were required. The user explicitly requested deeper research and a one-shot coherent recommendation set, so the assumptions were expanded through parallel subagent research and then written as locked decisions.

## Research Inputs Used

- `gsd-advisor-researcher` on host plug contract shape
- `gsd-advisor-researcher` on protected-resource nonce semantics and rendering boundaries
- `gsd-advisor-researcher` on milestone proof strategy
- `gsd-advisor-researcher` on support-truth/docs posture
- Local review of prompt corpus:
  - `prompts/lockspire-oauth-oidc-implementation-playbook.md`
  - `prompts/lockspire-elixir-oss-library-practices.md`
  - `prompts/lockspire-host-app-integration-seam.md`
  - `prompts/lockspire-security-posture-and-threat-model.md`
  - `prompts/lockspire-phoenix-system-design.md`
  - `prompts/lockspire-release-readiness-and-conformance.md`
  - `prompts/lockspire-market-gap-and-positioning.md`

## Notes for Downstream Agents

- Treat the recommendations as a coherent bundle; do not optimize one area by violating another.
- The highest-risk regressions are support-boundary drift and `/userinfo` vs host-route challenge drift.
- Escalation threshold stays high for medium-impact implementation details in this phase.
