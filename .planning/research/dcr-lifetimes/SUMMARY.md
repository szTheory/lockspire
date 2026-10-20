# Project Research Summary

**Project:** Lockspire v1.45 DCR Lifetime Enforcement
**Researched:** 2026-10-20
**Confidence:** HIGH on standards/current gaps; MEDIUM on design until Phase 162 decisions are selected.
**Execution:** Inline research in the current agent, not four independent specialist reviews. This milestone-specific directory preserves prior milestone research at the parent path.

## Executive Summary

Reuse the completed Phase 153 audit: app and management-token lifetimes are not enforced; secret expiry metadata does not control authentication and is stale after operator rotation. Focused current-source checks confirm the named storage and protocol seams still require coordinated changes. No new dependency is indicated.

The main risk is activating enforcement against deployed credentials whose stored expiry was never meaningful. Resolve semantics and compatibility first; then implement complete lifecycle slices with deterministic boundary, concurrency and host-upgrade tests. Research does not select a new timeout, automatic backfill or rejection policy.

## Key Findings

- [Stack](STACK.md): use existing protocol/storage/generator/test infrastructure; no dependency upgrade is needed for scope.
- [Features](FEATURES.md): expiry metadata and authentication must agree. RFC 7591 wire zero means no secret expiry; policy-duration zero is a separate product decision.
- [Architecture](ARCHITECTURE.md): share request-time eligibility, atomically persist credential and expiry changes, and specify legacy/custom-storage behavior before implementation.
- [Pitfalls](PITFALLS.md): management timeout can strand registration access; stale pre-lock authorization and legacy timestamps need explicit handling.

## Implications for Roadmap

1. **Phase 162: Lifetime Semantics and Upgrade Contract.** Resolve the decision matrix, standards/error mappings, endpoint inventory, custom-storage strategy and rollout/rollback rules. Produce acceptance examples that implementation plans consume. This is a prerequisite, not an implementation phase.
2. **Subsequent lifecycle slices:** implement the chosen storage/issuance/enforcement behavior for registrations, shared secrets and management tokens, including rotation/recovery. Carry scoped tests in every slice.
3. **Final host and security proof:** existing-host upgrade, fresh packaged clean-room journey, custom-store conformance, redaction and scoped security review, then truthful docs/UI. Package publication remains separate.

Exact phase grouping follows approved requirements. No implementation plan may guess an unresolved Phase 162 decision.

## Confidence Assessment

| Area | Confidence | Remaining validation |
|---|---|---|
| Existing gaps and seams | High | Complete endpoint/consumer inventory in Phase 162 |
| Standards constraints | High | Map selected behavior to errors and wire responses |
| Legacy/custom-store deployment | Medium | Choose supported rollout and prove representative fixtures |
| Concurrency behavior | Medium | Decide linearization, then real PostgreSQL races |

## Gaps to Address

Phase 162 must choose unset/zero/positive behavior for all three lifetimes; prospective versus retroactive policy; expired-app effects on issued tokens and management; optional management expiry and recovery; legacy date treatment; rotation policy timing; precision and equality boundary; custom-store and mixed-node compatibility. These remain open product/design decisions.

## Sources

- [Phase 153 source audit](../../milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md) and [approved scope](SCOPE.md).
- [RFC 7591 section 3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1): secret expiry wire metadata.
- [RFC 7592 sections 2 and 5](https://www.rfc-editor.org/rfc/rfc7592.html#section-5): management lifecycle, errors, rotation and lockout risk (Experimental).
- [RFC 7662 section 4](https://www.rfc-editor.org/rfc/rfc7662.html#section-4): introspection validation and cache limits.
- [RFC 7009 section 3](https://www.rfc-editor.org/rfc/rfc7009.html#section-3): revocation deployment limits.

Research complete for requirements scoping; requirement confirmation and roadmap approval remain pending.
