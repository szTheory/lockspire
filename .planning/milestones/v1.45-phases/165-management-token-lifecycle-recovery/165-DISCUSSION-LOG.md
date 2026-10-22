# Phase 165: Management-Token Lifecycle & Recovery - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the discussion.

**Date:** 2026-10-21
**Phase:** 165-management-token-lifecycle-recovery
**Mode:** assumptions; inline source analysis, no subagent dispatched
**Areas analyzed:** lifetime and response metadata; management access; recovery and atomic rotation; proof and guidance

## Assumptions Presented

| Area | Assumption | Confidence | Evidence | Consequence if wrong |
|------|------------|------------|----------|----------------------|
| Lifetime and response metadata | Nil/zero unlimited; positive duration snapshots issuance/replacement policy; GET never renews; add both selected server-owned lifecycle fields. | Confident | Phase 162 contract; lib/lockspire/client_metadata.ex; lib/lockspire/web/registration_json.ex | Advertised deadlines and enforced authority would disagree. |
| Management access | Check current token identity/deadline, URL binding and app state; expired-enabled apps permit valid-token GET/DELETE but reject PUT; disabled apps reject self-management; complete selected PUT field validation. | Confident | lib/lockspire/protocol/registration_management.ex; lib/lockspire/web/controllers/registration_controller.ex; RFC 7592 section 2.2 | Stale credentials or client-controlled deadlines could gain authority. |
| Recovery and atomic rotation | Reuse host-authorized rotation and one-time plaintext; atomically replace hash/deadline/legacy state/audit after locking; preserve app/secret deadlines and disabled state; keep existing stale-snapshot rejection for competing replacements. | Confident; preserve existing concurrency behavior | lib/lockspire/client_lifecycle.ex; lib/lockspire/storage/ecto/repository/client_store.ex; lib/lockspire/web/live/admin/clients_live/show.ex | A stale operation could revive invalid authority or deliver credentials after transaction failure. |
| Proof and guidance | Include boundary/policy/legacy/race/rollback/permission/redaction checks, correct recovery attribution and affected guidance; reuse existing storage/transactions; keep final proof and umbrella closure in Phase 166. | Confident | Existing management, PostgreSQL concurrency and DCR redaction tests; pending lifetime todo | Lifecycle claims could lack executable evidence or the umbrella could close prematurely. |

## User Confirmation

The offered choices were “1. Proceed with this bundle” and “2. Correct specific items.” The user replied “1.” All four areas were explicitly confirmed. No corrections or new capabilities were requested.

## Corrections Made

No corrections — all assumptions confirmed. Existing Phase 162 semantics remain locked. The stale-snapshot policy above applies to management-token replacements; Phase 164's separate serialized shared-secret rotation behavior remains unchanged.

## External Research

- [RFC 7592 section 2.2](https://www.rfc-editor.org/rfc/rfc7592.html#section-2.2): rechecked full metadata replacement, unchanged body client_id, prohibited server-owned fields and optional current-secret matching. Confirms the previously selected request contract.
- [RFC 7592 section 5](https://www.rfc-editor.org/rfc/rfc7592.html#section-5): rechecked management-expiry lockout guidance. Unlimited default plus explicit finite policy and authorized host recovery remains the selected Phase 162 choice.
- [RFC 6750 section 3](https://www.rfc-editor.org/rfc/rfc6750.html#section-3): consulted for Bearer challenge/error handling; no new semantic decision selected.

## Methodology and Scope

Applied the project's assumption-first, least-surprise host seam, research-first defaults, high-threshold escalation and one-shot bundle lenses. No dependency, schema, host account system, app renewal or admin redesign was added. The matching lifetime todo remains pending with resolves_phase: 166.

This invocation captures discussion only, following the session handoff's explicit “Discuss Phase 165 only” boundary. The project auto_advance preference does not authorize overriding that bounded handoff. Planning and execution require the next instruction; no PLAN.md or runtime work is included here.
