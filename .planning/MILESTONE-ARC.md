# Lockspire Milestone Arc

**Created:** 2026-05-23  
**Purpose:** Current milestone-selection source of truth for post-v1.21 planning. Use this file to choose what to build next without rediscovering the repo's adopter story from scratch.

## Current Product Judgment

Lockspire is **strong-to-near-done for its stated scope** as an embedded OAuth/OIDC provider for Phoenix apps.

- **Rough done-ness:** `~88-92%`
- **Territory:** finish the last important wedges
- **Primary risk now:** treating patch-truth drift or adoption/operator seams as either "nothing to do" or as an excuse for adjacent protocol breadth

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
- `test/lockspire/workers/backchannel_logout_delivery_worker_test.exs`
- `test/integration/phase54_resource_indicators_e2e_test.exs`
- `test/integration/phase55_rar_intake_e2e_test.exs`

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

There is **no broad protocol gap** after `v1.25`, but repo inspection found a practical maintenance-first sequence before the next milestone decision.

### Highest-Leverage Gaps

- Restore green `main` after PR #31 by fixing test application-env leakage around root-mount integration suites and back-channel logout worker issuer validation.
- Close patch-truth drift before feature work: CIBA discovery/runtime support, JAR/request-object docs versus shipped by-value behavior, and JTBD wording that still reads older than the shipped protected-route story.
- If opening a feature milestone, make it adoption/operator hardening rather than protocol breadth: host account/claims recipes, client bootstrap ergonomics, admin-route boundary clarity, and diagnostic/operator docs.

### Useful But Secondary

- release or maintenance work that keeps the already-shipped support contract trustworthy
- narrowly scoped follow-ons only when repeated adopter evidence shows a concrete embedded-library friction wedge
- broader doctor/support console expansion after the adoption/operator boundary work proves the remaining support gaps are real

## Candidate Milestones

Treat these as historical context plus the current ordering rule for the next `$gsd-new-milestone` run.

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
- **status:** `shipped`
- **priority:** `completed`
- **recommendation:** archived milestone
- **why now:** turned an already-shipped operator-only logout propagation surface into a more partner-buildable self-service story
- **target slice:**
  - accept/store/validate logout propagation metadata in DCR and management updates
  - keep provenance and admin workflows truthful
  - update docs, discovery language where relevant, and proof
- **non-goals:**
  - full federation metadata ingestion
  - expanding beyond the current logout propagation truth model

### Candidate 3

- **name:** `v1.24 client_secret_jwt`
- **status:** `shipped`
- **priority:** `completed`
- **recommendation:** archived milestone
- **why now:** DCR logout metadata was shipped, leaving `client_secret_jwt` as the most practical remaining direct-client auth gap
- **target slice:**
  - narrow shared verifier on Lockspire-owned direct-client endpoints
  - strict replay, audience, algorithm, and docs posture
  - support-truth and proof updates
- **non-goals:**
  - generic JWT client auth
  - broader federation-style trust expansion
  - any new claim that shared-secret JWT auth satisfies Lockspire's higher-trust FAPI or mTLS posture

### Candidate 4

- **name:** `Support-Burden Reduction`
- **status:** `shipped`
- **priority:** `completed`
- **recommendation:** archived milestone
- **why now:** the remaining repo risk is support cost and advanced setup ambiguity, not missing foundational protocol coverage
- **target slice:**
  - better diagnostics and docs truth for `jwks_uri` rotation
  - clearer operator guidance for mTLS, logout propagation, and protected-route setup
  - repo-native proof for the highest-friction support paths that still generate ambiguity
- **non-goals:**
  - broad new protocol families
  - generic CIAM or hosted-auth expansion
  - auth-method parity work that does not materially reduce adopter friction
- **activated:** `2026-05-25`
- **version:** `v1.25`
- **shipped:** `2026-05-26`

### Candidate 5

- **name:** `Green-Main Patch`
- **status:** `active patch`
- **priority:** `immediate`
- **recommendation:** merge before any roadmap or release work
- **why now:** main CI failed after PR #31 because integration tests leaked root-mount application env into later worker tests, undermining the release-train premise
- **target slice:**
  - isolate/restore `:issuer`, `:mount_path`, and adjacent Lockspire app env in the leaking integration tests
  - pin the back-channel logout worker test to its own issuer/mount config
  - prove with the worker test, `mix test.integration`, `mix ci`, and repo hygiene
- **non-goals:**
  - changing runtime issuer validation
  - broad test-suite refactors unrelated to the leak

### Candidate 6

- **name:** `Support-Truth Patch Train`
- **status:** `recommended next patch`
- **priority:** `next`
- **recommendation:** do before feature milestone planning
- **why now:** the repo is mostly strong, but several public-truth seams lag shipped behavior and are exactly the kind of friction that hurts a mature auth library
- **target slice:**
  - align CIBA discovery with shipped Poll/Ping/Push support or explicitly document why discovery remains narrower
  - align JAR/request-object docs with actual by-value request object support
  - refresh adopter JTBD wording where older docs still understate shipped protected-route and onboarding proof
- **non-goals:**
  - new protocol features
  - certification breadth
  - changing support scope without runtime proof

### Candidate 7

- **name:** `v1.26 Host Integration & Operator Boundary Hardening`
- **status:** `candidate`
- **priority:** `first feature milestone candidate`
- **recommendation:** open only after green-main and support-truth patch work
- **why now:** the most adopter-facing friction is no longer missing OAuth/OIDC machinery; it is making the host seam, client bootstrap, and admin/operator boundary feel obvious to a Phoenix SaaS team
- **target slice:**
  - account resolver and claims recipes that demonstrate realistic SaaS integration patterns
  - client bootstrap guidance or generator ergonomics for first real partner client setup
  - explicit admin-route authorization boundary in generated host examples/docs
  - sharper operator docs for common client, consent, token, and key support workflows
- **non-goals:**
  - hosted auth/control plane
  - SAML/LDAP/CIAM expansion
  - generic gateway/service-mesh productization
  - auth-method parity that does not reduce adopter friction

## Stop Rules

Assume Lockspire should **probably stop soon** after the patch-truth cleanup and, at most, one adoption/operator-hardening milestone unless real adopter evidence suggests otherwise.

Do **not** default into more work just because a protocol feature is interesting.

Prefer to stop when:

- the remaining requests are mostly auth-method parity or certification theater
- the repo can already tell one coherent embedded Phoenix adoption story
- additional milestones would mostly broaden scope rather than remove serious adopter friction

## Diminishing-Returns Warnings

These are tempting, but currently look like lower-value or overbuild territory relative to Lockspire's stated scope:

- generic API gateway or service-mesh protected-resource middleware
- broad third-party issuer resource-server productization
- more JAR/request-object expansion beyond the shipped support-truth cleanup
- hosted-auth or control-plane expansion
- SAML / LDAP / workforce or CIAM platform expansion
- certification-breadth chasing beyond the repo-native support contract

## Recommended Ordering

1. Restore green `main` with the env-isolation patch.
2. Run the support-truth patch train for CIBA discovery, JAR docs/runtime truth, and JTBD wording.
3. If feature work is still justified, open `v1.26 Host Integration & Operator Boundary Hardening` on `milestone/v1.26-host-integration-operator-boundary`.
4. Consider doctor/support-console expansion only after v1.26 reveals concrete residual support drag.

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
