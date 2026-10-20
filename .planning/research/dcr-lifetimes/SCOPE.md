# Proposed next milestone: DCR Lifetime Enforcement

Status: activated as v1.45 on 2026-10-20; requirements and Phases 162–166 approved. Implementation has not started. Originally recorded under the approved sequence: close v1.44, finish the bounded keys.reencrypt follow-up, then scope DCR lifetimes separately. No protocol behavior is changed by this brief.

## Outcome

A Phoenix host can rely on documented registration and credential lifetime policy: advertised expiry matches actual authentication and management behavior, operators can rotate credentials without misleading dates, and upgrading existing clients has an explicit compatibility path.

## Existing evidence

Reuse the completed [Phase153 source trace](../../milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md) and [pending protocol todo](../../todos/pending/2026-10-13-audit-dcr-default-lifetime-semantics.md). The audit is already done; the next milestone must decide and implement behavior rather than repeat it. Source spot-checks during closeout found the same policy assignments, metadata serialization, hash-only management token lookup and absence of credential-expiry checks in the named auth paths. These are built-in implementation limits; custom hosts may impose their own policy.

| Concept | Current built-in behavior | Required milestone decision |
|---|---|---|
| App lifetime | Stored/resolved policy; no client expiry or automatic enforcement | Define whether and how registrations expire, including the effect on existing issued tokens and management |
| App-management token lifetime | Stored/resolved policy; hash replacement and client state govern access, with no expiry | Choose an explicit lifecycle and recovery path before enforcing timeout |
| Client-secret lifetime | Sets reported date for new secret-bearing registrations, but auth does not enforce it and operator rotation does not renew it | Align issuance, secret auth, rotation and response metadata |

## In scope

- Exact unset, zero, positive and boundary-time semantics for each policy; distinguish durations from serialized expiry metadata.
- One documented effective policy contract shared by registration, credential authentication, management and rotation.
- Existing rows, existing reported dates, custom storage implementations and host migration compatibility.
- Secret-bearing authentication variants, registration management token lifecycle, disabled clients and relevant token use after client expiry.
- Truthful configuration/storage documentation, operator guidance and regression evidence after behavior is proven.

## Out of scope

KMS/Vault integration, external federation, hosted auth, account ownership changes, unrelated token grants, an admin redesign, and broad dependency upgrades. Do not turn Lockspire into a standalone service or weaken PKCE, redirect matching, hashed secrets, code single-use, refresh reuse revocation or redaction.

## Decisions to resolve before implementation planning

1. What does unset mean for existing hosts? What does zero mean for each duration? Which policy changes affect existing registrations versus only future issuance?
2. Is app expiry a request-time eligibility check, a persisted lifecycle transition, or both? How do management access, token issuance, refresh and existing resource tokens behave after expiry?
3. Should management tokens expire by default, optionally, or be rotated without automatic expiry? How does a host regain access without stranding a registration?
4. How are current rows with ambiguous secret-expiry metadata migrated without silently invalidating deployed clients? What changes are required in the storage contract and generator migrations?
5. When secrets rotate, which policy and clock establish the replacement expiry? How are concurrent requests/rotations and old credentials handled?
6. Which standards clauses govern response/error behavior? Re-read the primary registration and management specifications during research; do not infer policy-duration semantics from a wire timestamp value.

The next discuss/research phase should resolve these as a coherent compatibility design. No new global timeout, automatic backfill or expiry rejection is approved merely by this scoping document.

## Acceptance scenarios

- New registrations with unset/zero/positive policy have matching stored, advertised and effective behavior for every supported credential type.
- Each credential is usable immediately before its defined expiry and rejected at/after it, with deterministic time control and safe protocol errors.
- Basic/post and secret-JWT authentication consistently enforce credential policy while preserving independent assertion timing and replay rules.
- Management reads, updates, deletes and token/secret rotation obey the chosen lifecycle, including disabled/expired clients and the documented recovery path.
- Existing clients upgrade under an executable migration/compatibility proof; a fresh generated host and a host with custom storage have explicit supported behavior.
- Failed and concurrent operations preserve the established transaction, hash-at-rest and redaction guarantees.
- Automated unit, real PostgreSQL integration and packaged clean-room journey tests cover the full issuance → use → expiry/rotation path. Required CI and a scoped security review pass before merge.

## Completion boundary

v1.45 is initialized with approved requirements and Phases 162–166. Implementation remains pending and the protocol todo stays open. Start Phase 162 to resolve the decision matrix and upgrade contract before planning implementation slices. Phase 166 owns final proof; package release is a separate verified step after implementation.
