# Project Research Summary

**Project:** Lockspire
**Domain:** Embedded OAuth/OIDC authorization server library for Phoenix/Elixir
**Researched:** 2026-04-22
**Confidence:** HIGH

## Executive Summary

Lockspire is best positioned as a narrow, embedded Phoenix/Elixir library that lets a host SaaS app become an OAuth/OIDC provider for third-party developers. The project corpus is unusually consistent on the central trade-off: win on install DX, protocol correctness, host-owned seams, and operator workflows, but explicitly avoid drifting into hosted auth, SAML, or a "Keycloak for Elixir" breadth play.

The recommended approach is an embedded library with a strong protocol core, Ecto/Postgres durable truth, LiveView-native admin and consent surfaces, generated host glue, and explicit behaviours for account and claim resolution. That architecture matches Phoenix team expectations and preserves the project's main value proposition: no separate auth service, no foreign console, and no need for the host to invent dangerous protocol logic.

The biggest risks are predictable and manageable. Scope creep, weak host boundaries, over-reliance on process state, shallow operator UX, and late release hardening are the main ways this project could miss its product thesis. The roadmap should therefore sequence foundation and seams first, then core protocol flow, then OIDC lifecycle and operator surfaces, followed by hardening and release readiness.

## Key Findings

### Recommended Stack

Lockspire should stay on the standard Phoenix/Elixir path rather than introducing a custom frontend or service topology. Phoenix `1.8.5`, LiveView `1.1.28`, Ecto SQL `3.13.5`, Bandit `1.6.1`, PostgreSQL `14+`, Oban `2.21.x`, and OpenTelemetry `1.6.0` form a coherent baseline for a modern embedded library. These choices are aligned with the target host environment and preserve a small operational surface.

**Core technologies:**
- Phoenix: router and endpoint integration — current Phoenix-native install surface
- Phoenix LiveView: admin and consent UX — keeps the product embedded and editable
- Ecto/Postgres: durable protocol truth — best fit for auditability and operational clarity
- Oban: lifecycle and cleanup jobs — supports key rotation and maintenance safely
- OpenTelemetry plus `:telemetry`: observability foundation — supports real operator workflows

### Expected Features

Research strongly separates table stakes from later protocol expansion. The launch set is auth code + PKCE, OIDC metadata/JWKS/userinfo, token lifecycle management, client management, consent UX, key lifecycle, telemetry/audit, and install DX. These are the minimum features that make the library credible to Phoenix SaaS teams.

**Must have (table stakes):**
- Authorization code + PKCE — users expect a modern secure provider baseline
- OIDC discovery, JWKS, and userinfo — required for interoperability
- Token lifecycle management — issuance, refresh rotation, revocation, introspection
- Client registration and management — the provider must onboard developer clients
- Consent UX and revocation — the product must handle real end-user grants
- Key lifecycle and telemetry/audit — trust and operability depend on them

**Should have (competitive):**
- LiveView-native operator/admin workflows — a strong differentiator against heavyweight auth consoles
- Generated editable host glue — reduces lock-in and supports real Phoenix integration
- Release-quality docs and onboarding — materially affects adoption for a security-sensitive library

**Defer (v2+):**
- PAR
- Dynamic client registration
- Device flow
- Stronger sender-constrained token modes and stronger certification profiles

### Architecture Approach

The architecture should be a layered embedded library: Phoenix delivery at the edge, protocol services in the middle, explicit storage and host behaviours underneath, and runtime services for jobs and observability alongside. That split lets Lockspire keep a small public API while remaining strict about protocol correctness and flexible at the host boundary.

**Major components:**
1. Protocol core — authorize, token, consent, metadata, lifecycle, and validation rules
2. Storage and adapters — durable records for clients, grants, tokens, keys, and audit
3. Host seam — account resolution, claims, login redirects, and host policy hooks
4. Web/admin layer — endpoints, LiveView admin, consent UI, and generated glue

### Critical Pitfalls

1. **Scope creep into a full identity suite** — keep non-goals explicit and protect the wedge
2. **Weak host boundary** — never let the library absorb account ownership or login UX
3. **Process state as source of truth** — keep durable auth truth in Postgres
4. **Operator UX treated as optional** — plan real incident workflows, not just endpoints
5. **Release readiness arriving too late** — reserve explicit hardening and release phases

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation and Host Seam
**Rationale:** the product fails if it cannot integrate cleanly into a host Phoenix app.
**Delivers:** library skeleton, public API boundaries, storage seams, and generated host integration path.
**Addresses:** install DX and host-ownership requirements.
**Avoids:** weak host boundary and early scope drift.

### Phase 2: Authorization Core
**Rationale:** auth code + PKCE is the main protocol credibility bar.
**Delivers:** client validation, authorization interactions, code issuance, and access token exchange.
**Uses:** Phoenix, Ecto/Postgres, and explicit protocol services.
**Implements:** protocol core and durable interaction/code records.

### Phase 3: OIDC and Token Lifecycle
**Rationale:** interoperability and secure token lifecycle complete the core provider path.
**Delivers:** discovery, JWKS, userinfo, refresh rotation, revocation, and introspection.

### Phase 4: Operator and Consent Product
**Rationale:** Lockspire differentiates on in-app operability, not only endpoint coverage.
**Delivers:** client management, consent workflows, token inspection, and key visibility.

### Phase 5: Security, Telemetry, and Hardening
**Rationale:** secure defaults and observability must be enforced before release-readiness work.
**Delivers:** threat-driven tests, telemetry/audit surfaces, redaction guarantees, and lifecycle hardening.

### Phase 6: Install DX and Release Readiness
**Rationale:** trust in an auth library depends on docs, CI, onboarding, and release discipline.
**Delivers:** polished generators, canonical onboarding, CI/CD, changelog/release flow, and conformance prep.

### Phase Ordering Rationale

- Foundation and seams must precede protocol implementation or the library will calcify around the wrong ownership model.
- Token lifecycle and OIDC metadata depend on key and storage design, which depend on the earlier protocol/domain foundation.
- Operator UX should land before final hardening so the underlying domain model supports real workflows instead of bolted-on screens.
- Release readiness is safest as a dedicated final phase so it cannot be silently squeezed out by feature work.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** OIDC and token lifecycle details will need spec-level edge-case review during implementation planning.
- **Phase 5:** Security, telemetry, and threat handling will need a deliberate negative-path and advisory process plan.
- **Phase 6:** Conformance and release workflow details may need targeted research against current tooling and certification expectations.

Phases with standard patterns (skip research-phase):
- **Phase 1:** host seam and library structure are well-supported by the current corpus.
- **Phase 2:** authorization core patterns are clear from the prep docs and product framing.
- **Phase 4:** operator IA is already well-defined in the corpus.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official docs verify the recommended Phoenix/Ecto/Oban/OpenTelemetry baseline. |
| Features | HIGH | The idea brief and prompt corpus strongly agree on the v1 target and later candidates. |
| Architecture | HIGH | The corpus is explicit about embedded library boundaries and host seam design. |
| Pitfalls | HIGH | Security, scope, and operator risks are repeatedly documented in the prep materials. |

**Overall confidence:** HIGH

### Gaps to Address

- OIDC conformance profile targeting should be finalized when planning the release-readiness phase.
- Sender-constrained token modes and DCR/PAR should remain intentionally deferred unless a concrete milestone calls for them.
- The exact generator shape should be tested against a fresh Phoenix host app before Phase 6 is considered complete.

## Sources

### Primary (HIGH confidence)
- `lockspire-idea.md`
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md`
- `prompts/Oauth server jtbd and domain.md`
- `prompts/lockspire-oauth-oidc-implementation-playbook.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-operator-admin-ia-and-workflows.md`
- `prompts/lockspire-security-posture-and-threat-model.md`

### Secondary (MEDIUM confidence)
- Official Phoenix docs — current package versions and stack fit
- Official Oban, Bandit, and OpenTelemetry docs — operational baseline

---
*Research completed: 2026-04-22*
*Ready for roadmap: yes*
