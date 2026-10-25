# Phase 176: Dedicated Verifier Custody & Compatible Runtime - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-25
**Phase:** 176-Dedicated Verifier Custody & Compatible Runtime
**Mode:** assumptions; text confirmation
**Areas analyzed:** custody/configuration, credential creation, lifetime compatibility, protocol/rollout
**Analysis execution:** Inline codebase analysis; no subagent or independent review is claimed for this discussion. Existing research and Phase 175 qualification supplied the frozen contract; no new external research was necessary to choose the recommendation bundle.

## Assumptions Presented

| Area | Assumption | Confidence | Evidence | If wrong |
|---|---|---|---|---|
| Custody/configuration | Implement the exact independent-key config and client-bound LSCV1 envelope, with redacted operation-local failures. | Confident | `175-CONTRACT.md`; `security/policy.ex`; `config.ex`; `application.ex`; signing `KeySet`. Source names are under `lib/lockspire/`. | Reopens frozen security/API contract or causes unrelated-auth outages. |
| Credential creation | Choose final identity before sealing for every writer; preserve coherent pairs, helpers and one-time handoff; decouple hash-only generation. | Confident | `lib/lockspire/clients.ex`; `lib/lockspire/protocol/registration.ex`; `lib/lockspire/admin/clients.ex`. | Missed writers can persist unusable or incorrectly bound material. |
| Lifetime compatibility | Use approved native configured-lifetime policy and preserve migrated original deadlines; unsupported legacy stays unchanged. | Confident | Phase 175 approved policy, qualification, metadata fixtures and persisted caller tests. | Migration could extend authority or break the approved upgrade policy. |
| Protocol/rollout | Preserve the five existing direct-client endpoint families, PAR/FAPI exclusions and replay/fingerprint behavior; stage readers before activating writes. | Confident, with wording clarification | Device/CIBA source opt-ins and positive direct-client tests; PAR negative tests; token-exchange fingerprint; frozen rollout contract. | Removing shipped support regresses clients; activating writes early strands old readers. |

## Corrections Made

No owner-requested correction to the recommendation bundle.

### Endpoint wording clarification
- **Ambiguity found:** The frozen Phase 175 ledger says “do not add JWT support to PAR/device/CIBA” while production device authorization/CIBA already explicitly support `client_secret_jwt` and have positive tests.
- **Recommendation presented:** Preserve existing token/introspection/revocation/device/CIBA support and PAR/FAPI exclusions; interpret the phrase as prohibiting expansion, not removing existing support.
- **Owner disposition:** “what do u rec? let's do that”. The full recommended bundle, including this clarification, is accepted.
- **Recording:** `176-CONTEXT.md` D-11 makes the endpoint matrix explicit. Historical Phase 175 evidence and frozen files remain unchanged.

## Methodology Applied

- Assumption-first and research-first recommendations: read qualification and runtime before presenting one cohesive bundle.
- Least-surprise host seam: explicit custody modes and local failures preserve host-owned configuration/authentication.
- High-threshold escalation: carry forward approved policy/API constraints; resolve routine module/test choices autonomously.

## Evidence Limits

This discussion records decisions for planning. It does not execute or certify the new runtime, deployment sequence, maintenance races, package journeys, fleet parity, final main acceptance or publication. No pending compatibility case is promoted to passing by context capture.
