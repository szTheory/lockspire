# Phase 132: Public API and Resource-Server Truth - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `132-CONTEXT.md`; this log preserves the autonomous analysis.

**Date:** 2026-08-26
**Phase:** 132-public-api-and-resource-server-truth
**Mode:** assumptions (`--auto`)
**Areas analyzed:** Public Access-Token Contract, Registration Shape Coherence, DPoP Replay-Store Boundary, Documentation and Compatibility Boundary

## Assumptions Presented

### Public Access-Token Contract

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add normalized accessors while preserving the current struct and raw claims. | Confident | `lib/lockspire/access_token.ex`, `lib/lockspire/plug/verify_token.ex`, `docs/protect-phoenix-api-routes.md`, and their tests show the guide advertises nonexistent direct fields while internal normalization already exists. |

### Registration Shape Coherence

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Registration must be capability-aware for OIDC, redirect flows, device-only clients, and `private_key_jwt`. | Confident | `lib/lockspire/clients.ex` rejects `openid` and requires redirects unconditionally, while authorization, discovery, DCR, device-flow code, and docs advertise the corresponding supported behaviors. |

### DPoP Replay-Store Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The configured Ecto repository is the durable default; the behavior remains the custom injection seam. | Confident | `protected_resource_dpop.ex`, `storage/ecto/repository.ex`, the replay behavior, migration, and repository tests already implement this path; the resource-server guide presents only a custom store. |

### Documentation and Compatibility Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Correct supported docs and generated guidance additively, retain host business authorization, and leave the black-box SaaS journey to Phase 133. | Confident | Phase 131 context, the Phase 132/133 roadmap boundary, supported-surface docs, generated router template, and the canonical route-protection guide. |

## Corrections Made

No corrections — autonomous mode accepted all four confident, evidence-backed assumptions.

## Auto-Resolved

No unclear assumptions required a default selection.

## External Research

No external research was required; the repository and existing shipped standards behavior fully established the Phase 132 decision boundary.
