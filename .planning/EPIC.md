# Lockspire Epic Arc

**Created:** 2026-04-28
**Purpose:** Persist the longer-range project gameplan so milestone selection compounds from repo truth instead of restarting from scratch each cycle.

## Current Position

Lockspire already has a substantial embedded-provider preview surface:

- Authorization code + PKCE
- OIDC discovery and JWKS
- Userinfo, revocation, introspection, and refresh rotation
- PAR and PAR policy controls
- JAR request-object support (with decryption deferred)
- Dynamic Client Registration (RFC 7591/7592)
- Device Authorization Grant
- Generated host seams and Phoenix-native operator workflows
- Repo-truth release, support, and preview-posture discipline

That means the next milestones should optimize for **real integrator readiness**, not raw spec breadth.

## Strategic Priority

Move Lockspire from a serious, truthful preview into a preview that real Phoenix teams can adopt for third-party integrations with fewer trust gaps.

The priority order is:

1. Raise real-client trust on the surfaces already shipped.
2. Keep public claims narrow and repo-verifiable.
3. Preserve the embedded-library shape and host-owned seams.
4. Delay broader CIAM, hosted-auth, federation, and enterprise-platform scope unless the product thesis itself changes.

## Planned Arc

### 1. v1.7 — DPoP Core for Public and CLI Clients

Why next:
- Highest leverage security/trust wedge for the already-shipped browser, DCR, and device/CLI paths.
- Better fit than mTLS for the current product shape.
- Improves actual adoption readiness without requiring hosted infrastructure or enterprise PKI.

Scope:
- Proof validation
- Replay protection
- Token binding via `cnf`
- DPoP-aware auth-code, refresh, and device-code exchanges
- DPoP-aware `userinfo`
- Truthful discovery/docs
- Explicit operator/DCR rollout controls

### 2. Adoption-Hardening Milestone

Why likely next:
- Once DPoP lands, the biggest remaining gap may be not another RFC, but making the release/support/onboarding story boring enough to trust repeatedly.

Likely scope:
- Repeated green release proof
- Support/runbook hardening
- Compatibility/onboarding clarity
- Doc/install truth over time
- Sharper 1.0 gate definition

### 3. Next Protocol-Depth Milestone

Choose based on real demand after v1.7:

- **JAR decryption** if partner interoperability pressure centers on request-object completeness.
- **SSRF-guarded `jwks_uri` fetch** if DCR adoption pressure centers on easier client key management.

Selection rule:
- Pick the wedge that most improves real integration outcomes for the supported embedded Phoenix path.

### 4. Post-1.0 / Advanced Security and Conformance

Only after the core adoption story is stable:

- mTLS-bound tokens
- Broader sender-constrained modes
- Stronger conformance/certification profiles
- Additional logout/session-management families if they still fit the embedded-library thesis

## Milestone Selection Rules

Use these rules when choosing what comes next:

1. Prefer real integrator leverage over checklist spec breadth.
2. Do not widen into hosted auth, generic CIAM, or account-system ownership.
3. Keep Lockspire-owned protocol state separate from host-owned login/session/branding policy.
4. Ship only what the repo can prove end to end.
5. Favor wedges that compound on already-shipped surfaces instead of opening unrelated product families.

## Explicit Non-Goals

These are not the intended arc unless the product thesis changes:

- Becoming a standalone hosted identity provider
- Becoming a full workforce identity or enterprise federation suite
- Taking over the host app's account, session, or login UX model
- Chasing certification breadth before the Phoenix embedded path is boring and trustworthy

## How to Use This File

- Update it at every milestone boundary if the priority arc changes.
- Use it with `.planning/PROJECT.md`:
  - `PROJECT.md` = current milestone and current validated state
  - `EPIC.md` = longer-range sequence and selection logic
- Use it to justify why a candidate milestone is next, not just what it would build.
