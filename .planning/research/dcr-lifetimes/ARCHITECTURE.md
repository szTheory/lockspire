# Architecture Research

**Milestone:** v1.45 DCR Lifetime Enforcement
**Researched:** 2026-10-20
**Confidence:** HIGH for inspected seams; MEDIUM for proposed structure.

## System Overview

Host policy → resolved policy → registration/rotation → domain client and storage → protocol eligibility → endpoint response. Operator surfaces describe the same persisted/effective state. Host account and login seams stay unchanged.

## Integration Points

| Existing seam | Required integration |
|---|---|
| protocol/dcr_policy.ex and client_metadata.ex | Define issuance-time effective policy and metadata |
| domain/client.ex and storage/ecto/client_record.ex | Represent distinguishable lifetime states and migrate safely |
| storage/client_store.ex | Version or adapt the contract for custom implementations |
| storage/ecto/repository/client_store.ex | Credential and expiry updates in one transaction; revalidate current state under the lock |
| protocol/client_auth.ex and client_auth/client_secret_jwt.ex | Check shared-secret expiry consistently while retaining JWT assertion timing and replay checks |
| protocol/registration_management.ex and admin/clients.ex | Management eligibility, replacement expiry and recovery permissions |
| install/migrations.ex and priv/repo/migrations | Fresh install and existing host migration support |
| Registration JSON and admin presenters | Match stored/effective dates after proof |

## Architectural Patterns

Recommend a pure eligibility/effective-expiry calculation using one captured request clock. Exact name/API is a Phase 162 design choice. Enforce at request paths rather than relying on eventual worker cleanup. Trace all direct credential and client consumers before coding; public clients and non-secret methods need app eligibility even when secret expiry is inapplicable.

Existing rotation writes already use row locks, but locking alone does not prove authorization is rechecked against the current record. A management request can authenticate before a concurrent rotation. Define the transaction linearization point and stale-hash comparison/conditional update semantics; use the established lifecycle transaction boundary rather than adding an uncoordinated second write.

## Upgrade Compatibility

Separate absent lifetime state, explicit unlimited state and known finite expiry if the chosen policy needs that distinction. Legacy secret dates were advertised without enforcement and may equal creation time or be stale after rotation. Do not infer safe rejection/backfill solely from those dates. Inventory available provenance, choose explicit legacy treatment and document any operator activation step.

Decide migration ordering, mixed-version deployment support, rollback limits and custom-store capability negotiation before implementation. Test fresh install and upgrade from representative existing data. Do not silently ignore missing expiry support in a store that claims enforcement.

## Issued Token Boundary

App expiry effects must be specified for authorization, code redemption, refresh, token exchange and other existing grant consumers, management, introspection, userinfo and already-issued access tokens. Trace applicable consumers in Phase 162. Offline JWT verification by host/resource servers cannot learn a new server-side state without an appropriate validation mechanism; document that limit rather than promise instant universal revocation. See [RFC 7662 section 4](https://www.rfc-editor.org/rfc/rfc7662.html#section-4) for introspection validation and cache implications and [RFC 7009 section 3](https://www.rfc-editor.org/rfc/rfc7009.html#section-3) for revocation deployment limits.

## Build Order

Phase 162 produces the selected decision matrix, compatibility contract, endpoint inventory and executable acceptance scenarios before implementation plans. Subsequent phases deliver vertical lifecycle slices and final packaged host/security proof; exact phase count awaits requirements and roadmap approval.

## Sources

[Phase 153 audit](../../milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md), current named source seams, and the primary RFCs linked above. Proposed architecture is an inference from these seams, not runtime verification.
