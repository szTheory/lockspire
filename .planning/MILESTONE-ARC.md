# Lockspire Milestone Arc

**Created:** 2026-05-23  
**Purpose:** Current milestone-selection source of truth for post-v1.21 planning. Use this file to choose what to build next without rediscovering the repo's adopter story from scratch.

## Current Product Judgment

Lockspire is **near-done for its stated scope** as an embedded OAuth/OIDC provider for Phoenix apps.

- **Rough done-ness:** `~94%`
- **Territory:** finish the last important wedges
- **Primary risk now:** overbuilding into adjacent protocol breadth that does not materially improve the embedded Phoenix adopter story

This judgment is based on current repo-local truth, especially:

- `docs/supported-surface.md`
- `docs/install-and-onboard.md`
- `docs/protect-phoenix-api-routes.md`
- `docs/private-key-jwt-host-guide.md`
- `docs/device-flow-host-guide.md`
- `docs/operator-admin.md`
- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs`
- `test/lockspire/release_readiness_contract_test.exs`

## What Is Already Strong

Lockspire already has a serious adopter story for Phoenix SaaS teams that want to become an OAuth/OIDC provider without standing up a separate auth service.

The shipped repo-proven story includes:

- generator-backed install via `mix lockspire.install`
- post-install diagnostics via `mix lockspire.verify`
- managed scaffolding upgrades via `mix lockspire.upgrade`
- host-owned login, consent, branding, policy, and `/verify` seams
- auth code + PKCE
- discovery, JWKS, userinfo, revocation, introspection, and refresh rotation
- PAR, JAR, JWE request-object decryption
- DCR and RFC 7592 management
- device authorization flow
- DPoP
- FAPI 2.0 security and message-signing tiers
- Token Exchange
- CIBA
- RAR and Resource Indicators
- `private_key_jwt`
- mTLS and certificate-bound tokens
- host Phoenix API route protection for Lockspire-issued tokens
- operator/admin surfaces for clients, consents, keys, tokens, policies, and logout propagation
- repo-native proof and release-truth discipline

## Current Adopter Gaps

The remaining gaps are **not foundational**. They are narrower trust or integrator-completion wedges.

### Highest-Leverage Gaps

1. **DCR logout propagation metadata**
   Logout propagation exists, but self-service clients still cannot manage the relevant metadata through DCR. That is practical adoption friction for partner-managed clients.

2. **`client_secret_jwt`**
   A useful direct-client auth addition, but lower leverage than DPoP nonce because Lockspire already ships `private_key_jwt` and mTLS for higher-trust clients.

3. **Advanced setup support burden**
   The remaining product risk is no longer foundational protocol coverage; it is support cost around advanced setup edges such as logout propagation, `jwks_uri` rotation, mTLS, and protected-route configuration.

### Useful But Secondary

- better operator/doctor coverage for advanced setup mistakes
- support-burden reduction around mTLS, `jwks_uri` rotation, logout propagation, and protected-route setup

## Candidate Milestones

Treat these as the default candidate set for the next `$gsd-new-milestone` run.

### Candidate 1

- **name:** `v1.22 DPoP Nonce Support`
- **status:** `shipped`
- **priority:** `completed`
- **recommendation:** archived milestone
- **why now:** closed the most obvious remaining trust gap in a surface Lockspire already positions as serious and production-worthy
- **target slice:**
  - nonce challenge and validation on the shipped DPoP surfaces that need it
  - truthful docs and discovery/support language
  - regression and negative-path proof in repo-native tests
- **non-goals:**
  - generic gateway or third-party issuer middleware
  - broader protected-resource product expansion

### Candidate 2

- **name:** `v1.23 DCR Logout Metadata`
- **status:** `candidate`
- **priority:** `highest`
- **recommendation:** leading next milestone candidate
- **why now:** turns an already-shipped operator-only logout propagation surface into a more partner-buildable self-service story
- **target slice:**
  - accept/store/validate logout propagation metadata in DCR and management updates
  - keep provenance and admin workflows truthful
  - update docs, discovery language where relevant, and proof
- **non-goals:**
  - full federation metadata ingestion
  - expanding beyond the current logout propagation truth model

### Candidate 3

- **name:** `v1.24 client_secret_jwt`
- **status:** `candidate`
- **priority:** `medium`
- **recommendation:** after DCR logout metadata unless adopter pull clearly says otherwise
- **why now:** fills a practical direct-client auth gap, but it is less leverage-heavy than the first two candidates
- **target slice:**
  - narrow shared verifier on Lockspire-owned direct-client endpoints
  - strict replay, audience, algorithm, and docs posture
  - support-truth and proof updates
- **non-goals:**
  - generic JWT client auth
  - broader federation-style trust expansion

## Stop Rules

Assume Lockspire should **probably stop soon** after one or two of the above wedges unless real adopter evidence suggests otherwise.

Do **not** default into more work just because a protocol feature is interesting.

Prefer to stop when:

- the remaining requests are mostly auth-method parity or certification theater
- the repo can already tell one coherent embedded Phoenix adoption story
- additional milestones would mostly broaden scope rather than remove serious adopter friction

## Diminishing-Returns Warnings

These are tempting, but currently look like lower-value or overbuild territory relative to Lockspire's stated scope:

- generic API gateway or service-mesh protected-resource middleware
- broad third-party issuer resource-server productization
- request-object-by-value support
- hosted-auth or control-plane expansion
- SAML / LDAP / workforce or CIAM platform expansion
- certification-breadth chasing beyond the repo-native support contract

## Selection Rules For Future Milestones

When choosing the next milestone:

1. Prefer wedges that remove real Phoenix SaaS adopter friction.
2. Prefer trust and install/support clarity over checklist protocol breadth.
3. Preserve the embedded-library shape and host-owned seams.
4. Treat `docs/supported-surface.md` and repo-native proof as more authoritative than older sequencing docs.
5. If a candidate does not materially improve the adopter story, do not build it by default.

## Confidence And Drift Notes

- Confidence is **high** in the done-ness assessment because the repo has unusually strong support-truth and proof surfaces.
- Confidence is **lower** in older strategic sequencing docs. `EPIC.md` was useful historical context, but it drifted behind shipped reality and should not be treated as the live next-milestone source of truth.
