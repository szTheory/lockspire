# Phase 164: Client-Secret Expiry & Atomic Rotation - Discussion Log

> Audit trail only. Do not use as planning, research or execution input. Decisions are in 164-CONTEXT.md.

**Date:** 2026-10-20
**Mode:** assumptions
**Analysis:** Typed gsd-assumptions-analyzer; current source and verified Phase 162/163 contracts. Applied project methodology: assumption-first recommendations, narrow host seam, research-first defaults, high-threshold escalation and one coherent bundle.

## Assumptions Presented

| Area | Recommendation | Confidence | Evidence |
| --- | --- | --- | --- |
| Issuance | nil/zero unlimited, finite issuance snapshot, current DCR policy only for self-registered replacements | Confident | client_metadata.ex; dcr_policy.ex; Phase 162 contract |
| Metadata | Effective current deadline, v0 zero, omit for non-secret methods | Confident | registration_json.ex; registration.ex; clients.ex |
| Authority | Shared Basic/post/secret-JWT gate plus final post-lock check; independent assertion controls | Confident | client_auth.ex; client_secret_jwt.ex; grant_persistence.ex; refresh_exchange.ex |
| Legacy/storage | Extend current adapter; locked canonicalization on explicit replacement | Confident | domain/client.ex; storage/client_lifetime.ex; repository/client_store.ex |
| Rotation | Atomic material/verifier/deadline/audit using post-lock time | Confident | admin/clients.ex; client_lifecycle.ex; transaction_store.ex |
| Operator concurrency | Preserve serialized host-authorized replacement, latest committed secret current | Likely | Current operator command and row-lock callback; no new CAS guarantee selected |

## Corrections and Adoption

No separate confirmation response is claimed. Recommendations were adopted under the user's standing explicit direction to synthesize and automatically follow coherent recommendations. This invocation did not revoke it. No Phase 162 semantics or new public operator behavior was introduced. Parent presented the bundle and bounded configured auto-advance to Phase 164 only.

## External Research

The analyzer reported no unresolved external-research gap. Reuse the verified Phase 162 standards contract. Exact normative source checks belong to planning research where needed; this log does not claim a fresh web search.

## Todo Disposition

Matched lifetime audit todo is already approved milestone scope; retain pending resolves_phase: 166. No duplicate audit or new capability added.
