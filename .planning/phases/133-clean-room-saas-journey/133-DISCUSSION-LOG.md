# Phase 133: Clean-Room SaaS Journey - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `133-CONTEXT.md`; this log preserves the autonomous analysis.

**Date:** 2026-08-26
**Phase:** 133-clean-room-saas-journey
**Mode:** assumptions (`--auto`)
**Areas analyzed:** Acceptance Harness, Confidential-Client Security, OIDC Validation, Lifecycle Truth, Negative Matrix, Durable DPoP Proof

## Assumptions Presented

| Area | Assumption | Confidence | Evidence |
|------|------------|------------|----------|
| Harness | Use separately booted provider/resource and confidential-client Phoenix apps on distinct origins over real HTTP. | Confident | E2E-01/02 and the roadmap require clean installation and origin separation; the existing adoption demo is same-origin and public-client shaped. |
| Package boundary | Consume only packaged/generated public seams; reserve exact published artifact proof for Phase 137. | Confident | E2E-01 forbids internal modules and replacement routes; Phase 137 owns exact artifact/publish proof. |
| Client transaction | Persist random state, nonce, and S256 verifier server-side and consume the transaction on terminal callback outcomes. | Confident | E2E-02 requires persistence and mismatch rejection; current smoke values are fixed/in-memory. |
| OIDC validation | Validate discovery, JWKS, signature, issuer, audience, expiry, nonce, and userinfo subject equality before API use. | Confident | E2E-03 explicitly names this contract and existing focused tests prove provider behavior. |
| Lifecycle | Prove refresh rotation/reuse containment, introspection, revocation, and truthful offline JWT lifetime semantics. | Confident | E2E-04 and milestone non-goals distinguish server state from offline JWT validity. |
| Negative and DPoP | Exercise wire-level redirect/code/token/audience/scope/nonce/replay failures using the configured Ecto replay repository. | Confident | E2E-05/06, Phase 81 nonce proof, and Phase 132 durable replay proof establish the intended behavior. |

## Corrections Made

No corrections — autonomous mode accepted all confident, repository-backed assumptions.

## Auto-Resolved

- Selected a separate small confidential-client fixture instead of widening the same-origin adoption demo.
- Kept the protected API in the generated provider host so the phase proves the embedded provider/resource-server boundary without inventing a third service.
- Selected headless HTTP orchestration rather than browser automation because the requirements concern protocol and callback behavior, not UI rendering.

## External Research

No external research is required for phase scoping. Formal OIDF/conformance tooling remains Phase 137.
