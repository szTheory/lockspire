# Phase 74: FAPI 2.0 Message Signing Strict Mode - Research

**Researched:** 2026-05-08  
**Domain:** Strict FAPI 2.0 Message Signing enforcement across security-profile resolution, authorization validation, introspection delivery, and operator/admin visibility in Lockspire.  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-02 through D-07:** Add `:fapi_2_0_message_signing` as a new durable tier inside the existing `security_profile` plane, preserving inheritance and the explicit `:none` escape hatch.
- **D-08 through D-14:** Under the new tier, `/authorize` must require explicit JARM without silent upgrade, while already-requested encrypted JARM must remain fail-closed.
- **D-15 through D-21:** Under the new tier, `/introspect` must require positive negotiation of `application/token-introspection+jwt`; JSON fallback is not allowed for successful strict-mode callers.
- **D-22 through D-26:** Admin UI must expose effective strict posture plus readiness/remediation using canonical runtime logic rather than UI-only heuristics.
- **D-27 through D-29:** Compatibility-first behavior outside the new tier must remain unchanged, and docs/telemetry must describe this as strict enforcement for the shipped message-signing slice only.

### Deferred / Out of Scope

- Redefining `:fapi_2_0_security`
- A second compliance toggle or policy plane
- Mandatory JARM encryption
- Hosted auth, broader CIAM posture, or resource-server product expansion
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENF-01 | Add strict profile enforcement for Message Signing. | The repo can support this truthfully by extending the existing `security_profile` model, enforcing JARM in `AuthorizationRequest`, enforcing JWT introspection representation in `IntrospectionController` plus protocol seams, and surfacing readiness/remediation through the current admin policy/client LiveViews. |
</phase_requirements>

## Summary

Phase 74 is an enforcement-and-operator-clarity layer on top of already shipped optional JARM and RFC 9701 support. The codebase already has the right baseline pieces: `SecurityProfile.resolve_effective_profile/2` for one canonical policy plane, `AuthorizationRequest` for redirect-safe request validation, `IntrospectionController` plus `IntrospectionJwt` for negotiated JWT introspection delivery, and admin LiveViews that already render global/client effective security posture. The strongest implementation shape is therefore additive rather than architectural: extend the existing profile tier, route strictness into the protocol/controller seams that already own the relevant truth, and keep the Phase 41 boundary plug limited to coarse FAPI checks. [VERIFIED: repo read]

The most important architectural decision is placement. Strict JARM belongs in `AuthorizationRequest`, not `FAPI20EnforcerPlug`, because the decision depends on validated client state, parsed `response_mode`, redirect-safe OAuth error behavior, and the already-established request-object/PAR flow. Strict JWT introspection belongs in `IntrospectionController` plus a small protocol-owned caller-policy seam, not in the plug, because the decision depends on authenticated caller identity, negotiated `Accept` semantics, and representation-specific fallback behavior. [VERIFIED: repo read]

The admin side should follow the current repo pattern of normalize -> validate -> persist at the command boundary, with list-shaped field errors rendered by LiveView. The existing `validate_fapi_signing_readiness/0` helper in `Repository`, plus the current global/client security-profile surfaces, are the clearest analogs for a new message-signing readiness helper that proves the issuer has compliant signing keys and that the effective profile can be explained truthfully to operators. The UI should consume canonical derived state instead of duplicating enforcement rules. [VERIFIED: repo read]

**Primary recommendation:** Plan Phase 74 as four execution slices: `profile-tier plumbing and readiness`, `authorize strict-JARM enforcement`, `strict JWT-introspection enforcement`, and `operator visibility + support-truth + end-to-end proof`. This keeps file ownership coherent, matches existing repo seams, and gives later plans concrete dependencies instead of one large mixed-scope change. [VERIFIED: repo read]

## Recommended Plan Split

1. **Plan 74-01: Add the `:fapi_2_0_message_signing` tier and readiness plumbing.** Extend domain/storage/admin/registration normalization and validation, add monotonic resolver semantics plus any new convenience flags, and introduce canonical readiness helpers for entering the strict tier.
2. **Plan 74-02: Enforce explicit JARM under strict mode at `/authorize`.** Add strict-mode response-mode validation in `AuthorizationRequest` and preserve fail-closed encrypted-JARM behavior without silent upgrade.
3. **Plan 74-03: Enforce strict JWT introspection representation and caller policy.** Require positive negotiation of `application/token-introspection+jwt`, reject downgrade cases for strict-mode callers, and add the smallest truthful caller-entitlement seam that fits the current direct-client auth shape.
4. **Plan 74-04: Surface operator readiness/remediation and pin the support story.** Extend the current security-profile LiveViews and client detail surfaces with canonical readiness state, then add integration/liveview/release-truth proof that Phase 74 is described narrowly and truthfully.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Resolve effective message-signing profile | API / Backend | Database / Storage | `SecurityProfile`, `ServerPolicy`, and client records already define the single policy plane. |
| Validate entry into strict tier | Database / Storage | API / Backend | Readiness is driven by repo-owned signing-key posture and persisted client/server policy changes. |
| Reject non-JARM `/authorize` requests | API / Backend | Frontend Server (redirect adapter) | `AuthorizationRequest` already owns redirect-safe request validation and parsed response-mode truth. |
| Reject non-JWT strict-mode introspection success paths | Frontend Server (controller) | API / Backend | `IntrospectionController` owns `Accept` negotiation and representation selection over protocol truth. |
| Expose readiness/remediation to operators | Frontend Server (LiveView) | API / Backend | LiveViews already present effective profile information and render list-shaped validation errors. |
| Preserve public support truth | Docs / Tests | API / Backend | The repo already pins support wording through `docs/supported-surface.md` and release-readiness tests. |

## Existing Repo Insights

### Reusable Assets

- `lib/lockspire/protocol/security_profile.ex` already centralizes inheritance, effective profile resolution, and algorithm policy. It should become the single source of truth for the stricter tier.
- `lib/lockspire/admin/server_policy.ex` and `lib/lockspire/admin/clients.ex` already implement normalize -> readiness-check -> persist for `security_profile`.
- `lib/lockspire/protocol/authorization_request.ex` already resolves effective profile, validates `response_mode`, and returns browser-safe or redirect-safe errors.
- `lib/lockspire/web/controllers/introspection_controller.ex` already parses `Accept`, chooses JWT vs JSON, and maps signer failures to JSON `server_error`.
- `lib/lockspire/protocol/introspection.ex` and `lib/lockspire/protocol/introspection_jwt.ex` already separate introspection payload truth from JWT packaging.
- `lib/lockspire/web/live/admin/policies_live/security_profile.ex`, `clients_live/show.ex`, and `clients_live/form_component.ex` already expose global, client, and effective security-profile state in the operator UI.

### Important Gaps Phase 74 Must Close

- `SecurityProfile`, `Domain.ServerPolicy`, `Domain.Client`, and the Ecto records only know about `:none` and `:fapi_2_0_security`.
- Current readiness validation is issuer-signing-key-only; it does not explain message-signing-specific prerequisites or operator remediation.
- `AuthorizationRequest` currently accepts raw `query`, `fragment`, and `form_post` under all profiles.
- `IntrospectionController` currently preserves JSON fallback when JWT is absent or not selected; strict mode needs explicit rejection for those successful caller paths.
- The admin UI can show effective profile, but it does not yet distinguish “strict message-signing enforced” from “optional JARM/JWT features available”.

## Recommended Implementation Patterns

### Pattern 1: Monotonic profile extension

Extend the existing effective-profile resolver and boolean helpers so `:fapi_2_0_message_signing` implies Phase 41 behavior plus stricter authorization/introspection semantics. Preserve the explicit client `:none` escape hatch under stricter global policy because the repo already treats mixed mode as intentional operator-controlled behavior. [VERIFIED: repo read]

### Pattern 2: Redirect-safe JARM enforcement in `AuthorizationRequest`

Reuse the current request validation pipeline after effective-profile resolution and after `response_mode` parsing. Reject missing/raw response modes with explicit redirect-safe `invalid_request` errors. Do not silently rewrite `response_mode`, and do not move this logic into `FAPI20EnforcerPlug`. [VERIFIED: repo read]

### Pattern 3: Strict-mode success gating in `IntrospectionController`

Keep the Phase 73 separation of concerns: protocol code returns authenticated caller + payload truth; the controller negotiates representation. Under the new tier, missing/malformed/non-selecting `Accept` headers should produce an OAuth JSON error for strict-mode callers before a JSON success response is emitted. Successful strict-mode callers should always receive the JWT representation. [VERIFIED: repo read]

### Pattern 4: Canonical readiness/remediation helper consumed by admin and validation

Follow the repo’s “one truth source” posture. The same helper that blocks moving into `:fapi_2_0_message_signing` should also drive operator-facing readiness/remediation copy, so the UI cannot drift from runtime enforcement. `Repository.validate_fapi_signing_readiness/0` is the clearest existing analog. [VERIFIED: repo read]

### Pattern 5: Phase-proof test layering

Use the repo’s existing split:
- protocol tests for resolver and authorization validation
- controller tests for introspection wire behavior
- liveview tests for operator surfaces
- integration tests for whole-profile behavior and mixed-mode escape hatches
- release-readiness tests for public support wording

## Standards and Ecosystem Notes

- FAPI Message Signing treats signed authorization responses and signed introspection responses as stronger non-repudiation/integrity posture, which supports the decision to model this as a stricter profile tier rather than a silent baseline mutation. [CITED: https://openid.net/specs/fapi-message-signing-2_0-final.html]
- JARM defines `jwt`, `query.jwt`, `fragment.jwt`, and `form_post.jwt`, supporting the plan to require explicit JWT response modes rather than silently upgrading raw modes. [CITED: https://openid.net/specs/oauth-v2-jarm-final.html]
- RFC 9701 defines `application/token-introspection+jwt` as the JWT introspection media type, supporting strict positive negotiation and no JSON success fallback once the strict profile is active. [CITED: https://www.rfc-editor.org/rfc/rfc9701]
- Mature provider implementations separate “supported” from “required” posture, which matches the repo’s compatibility-first baseline outside the new strict tier. [CITED: https://docs.duendesoftware.com/identityserver/tokens/fapi-2-0-specification/]

## Risks and Mitigations

| Risk | Why it matters | Mitigation |
|------|----------------|------------|
| Silent behavior mutation on `/authorize` | Relying parties may not notice they are no longer receiving raw parameters. | Reject invalid strict-mode requests explicitly instead of auto-upgrading them. |
| Plug-level overreach | Coarse plug enforcement cannot safely decide negotiated response-mode or caller negotiation truth. | Keep JARM logic in `AuthorizationRequest` and introspection strictness in controller/protocol seams. |
| UI/runtime drift | Operators may see badges that do not match actual enforcement or readiness. | Drive readiness/remediation from one canonical helper shared by validation and LiveView surfaces. |
| Overclaiming support | Public docs could imply broader FAPI Message Signing coverage than the repo proves. | Pin narrow wording in `docs/supported-surface.md` and release-readiness tests. |

## Verification Expectations

- Security-profile resolver tests prove monotonic semantics and mixed-mode escape hatch behavior for the new tier.
- Storage/admin/registration tests prove the new enum can be normalized, persisted, and validated globally and per-client.
- Authorization-request tests prove strict mode rejects missing/raw `response_mode` while preserving accepted JARM modes and fail-closed encrypted-JARM behavior.
- Introspection controller tests prove strict-mode callers cannot fall back to JSON success and that JWT success remains the only successful strict representation.
- LiveView tests prove operator surfaces distinguish effective message-signing posture and show remediation from canonical readiness state.
- Integration tests prove global strict mode, per-client strict mode, and per-client `:none` override under stricter global profile.

## Conclusion

Phase 74 should be planned as a narrow enforcement profile, not a new subsystem. The repo already contains the right abstractions; the work is to extend them coherently, place strictness at the seams that already own protocol truth, and make the operator story explicit without widening Lockspire’s product boundary.
