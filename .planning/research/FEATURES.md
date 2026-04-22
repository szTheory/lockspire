# Feature Research

**Domain:** Embedded OAuth/OIDC authorization server library for Phoenix/Elixir
**Researched:** 2026-04-22
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Authorization code flow with PKCE | Modern provider-side OAuth starts here; without it the library is not credible | HIGH | Must be strict by default and work inside an existing Phoenix app. |
| OIDC discovery, JWKS, and userinfo | Third-party developers expect standard OIDC metadata and key discovery | MEDIUM | Needed for "sign in with my app" and interoperable client libraries. |
| Access and refresh token lifecycle | Teams expect issuance, rotation, revocation, and inspection | HIGH | Refresh rotation with reuse detection is part of the trust story. |
| Client registration and management | Providers need a clear way to onboard third-party developers | MEDIUM | v1 can be operator-managed; dynamic client registration can wait. |
| Consent grant UX and consent revocation | End-users and operators both need visibility and control | MEDIUM | Must fit host branding and session rules. |
| Key lifecycle and rotation | OAuth/OIDC providers need publish, activate, retire, and inspect key state | HIGH | Rotation must be an operator workflow, not hidden maintenance. |
| Telemetry, audit, and incident visibility | Auth infrastructure must be observable and defensible | HIGH | Core product requirement, not an afterthought. |
| Install generator and onboarding path | OSS adoption depends on fast install DX | MEDIUM | The host should reach a real issued token in a short setup path. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| LiveView-native admin and consent surfaces | Makes Lockspire feel embedded instead of bolted-on | MEDIUM | Strong operator UX is a market wedge against heavy foreign consoles. |
| Narrow host seam with generated, editable code | Keeps hosts in control without forcing a specific auth stack | MEDIUM | This is central to adoption across Sigra, `phx.gen.auth`, Ash Auth, and Pow users. |
| Calm operator workflows for token lineage, secret rotation, and incidents | Moves the product beyond endpoint coverage into real operability | HIGH | Particularly important for Auth0-exit and B2B SaaS teams. |
| Executable docs and release hygiene as product features | Builds trust in a security-sensitive library | MEDIUM | Strong docs and CI discipline materially affect adoption and safety. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| SAML IdP and enterprise federation in v1 | Teams conflate "identity" with every enterprise protocol | Explodes scope, support burden, and attack surface | Stay focused on OAuth/OIDC provider use cases first |
| Standalone service requirement | Some systems treat auth as a separate deployment by default | Breaks the embedded-Phoenix value proposition and raises activation cost | Keep the library embedded; revisit headless later only if demand is real |
| Full theming engine | People expect auth products to ship branded templates | Creates a maintenance sink and foreign-UI problem | Generate editable host-owned LiveView code and layout hooks |
| "Keycloak for Elixir" feature breadth | Broad auth suites sound safer on paper | Destroys the narrow wedge and slows v1 credibility | Build a focused provider library with explicit non-goals |
| Dynamic client registration in the first milestone | Sounds like a standards completeness win | Adds complexity before the manual client-management path is proven | Support operator-driven client registration first; plan DCR later |

## Feature Dependencies

```text
Authorization code + PKCE
    └──requires──> host seam + interaction handling
                         └──requires──> generated host glue

OIDC discovery/JWKS/userinfo
    └──requires──> key lifecycle + issuer model

Refresh rotation + revocation + introspection
    └──requires──> durable token records + audit events

Operator token inspection
    └──requires──> token lineage + telemetry + admin UI

Install DX
    └──enhances──> every other feature

SAML / CIAM suite
    └──conflicts──> narrow, shippable v1
```

### Dependency Notes

- **Authorization code + PKCE requires host seam + interaction handling:** the flow must hand login and consent back to the host app without Lockspire owning accounts.
- **OIDC discovery/JWKS/userinfo requires key lifecycle + issuer model:** metadata only becomes trustworthy when signing and issuer rules are coherent.
- **Refresh rotation + revocation + introspection requires durable token records + audit:** operator-grade lifecycle management depends on durable truth, not only stateless JWT issuance.
- **Operator token inspection requires token lineage + telemetry + admin UI:** otherwise the admin surface becomes superficial and incident response remains CLI-only.
- **Install DX enhances every other feature:** a hard install path suppresses adoption even if the protocol implementation is strong.
- **SAML / CIAM scope conflicts with the narrow v1:** this is a product focus constraint, not just a resourcing constraint.

## MVP Definition

### Launch With (v1)

- [ ] Install generator that wires Lockspire into a host Phoenix app with editable glue
- [ ] Authorization code + PKCE flow and access token issuance
- [ ] OIDC discovery, JWKS, userinfo, and ID token correctness
- [ ] Rotating refresh tokens with reuse detection
- [ ] Revocation and introspection
- [ ] Client registration and management through admin/operator workflows
- [ ] Consent grant UX and consent revocation
- [ ] Key lifecycle and rotation
- [ ] Telemetry, audit events, and token inspection
- [ ] Strong negative-path tests, executable docs, and release readiness

### Add After Validation (v1.x)

- [ ] PAR — add when teams need higher-assurance front-channel handling
- [ ] Dynamic client registration — add when manual client management becomes an adoption bottleneck
- [ ] Device flow — add when specific integrator environments require it

### Future Consideration (v2+)

- [ ] Stronger sender-constrained token modes — defer until a concrete customer or compliance need exists
- [ ] Stronger conformance and certification profiles — defer until the baseline provider path is proven
- [ ] Expanded adapter story beyond the default Ecto/Postgres path — defer until actual host diversity demands it

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Install generator and canonical onboarding | HIGH | MEDIUM | P1 |
| Authorization code + PKCE | HIGH | HIGH | P1 |
| OIDC discovery/JWKS/userinfo | HIGH | MEDIUM | P1 |
| Refresh rotation and reuse detection | HIGH | HIGH | P1 |
| Revocation and introspection | HIGH | MEDIUM | P1 |
| Admin client management | HIGH | MEDIUM | P1 |
| Consent UX and revocation | HIGH | MEDIUM | P1 |
| Key rotation workflows | HIGH | HIGH | P1 |
| Telemetry, audit, and token inspection | HIGH | HIGH | P1 |
| PAR | MEDIUM | HIGH | P2 |
| Dynamic client registration | MEDIUM | HIGH | P2 |
| Device flow | MEDIUM | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Competitor A | Competitor B | Our Approach |
|---------|--------------|--------------|--------------|
| Install DX | Doorkeeper is strong on setup speed | Hydra is stronger on headless purity than onboarding | Match Doorkeeper-style generator speed inside Phoenix |
| Protocol extensibility | node-oidc-provider is strong and explicit | OpenIddict is strong through package/event separation | Borrow explicit seams without losing Phoenix-native ergonomics |
| Operator UX | Keycloak is broad but heavy and foreign | Managed providers are polished but expensive or external | Ship calm, embedded LiveView operator workflows |
| Host integration seam | Doorkeeper and node-oidc-provider both keep user ownership outside the library | Heavy auth suites often take over too much | Keep Lockspire narrow and host-owned at the account boundary |

## Sources

- `lockspire-idea.md`
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md`
- `prompts/Oauth server jtbd and domain.md`
- `prompts/lockspire-oauth-oidc-implementation-playbook.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-operator-admin-ia-and-workflows.md`
- `prompts/lockspire-security-posture-and-threat-model.md`

---
*Feature research for: Embedded OAuth/OIDC authorization server library for Phoenix/Elixir*
*Researched: 2026-04-22*
