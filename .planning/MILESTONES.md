# Milestones

## v1.16 Embedded Adoption Hardening & Sigra Golden Path (Shipped + archived: 2026-05-07)

**Phases completed:** **4** (**63-66**), **13** plans, **11** requirements closed.

**Package posture:** `lockspire 1.0.0` now has one coherent repo-truth story across package metadata, changelog posture, protected release wiring, supported-surface docs, and release-readiness contract tests.

**Key accomplishments:**
- Added one canonical embedded install path with explicit Lockspire-managed versus host-owned seams, plus a manifest-backed `mix lockspire.upgrade`.
- Added `mix lockspire.verify` so host teams can catch router wiring, seam, config, and migration mistakes before runtime drift becomes support debt.
- Proved the Sigra companion path end to end through generated-host code, including unauthenticated `/authorize`, login bounce, interaction resume, consent, token exchange, and JWKS.
- Reconciled README, SECURITY, maintainer docs, changelog posture, package metadata, and release workflow wording around a single 1.0.0 support story.
- Retired the old external-suite conformance lane as historical non-claim audit context and anchored current trust claims to repo-native strictness and release-readiness proof.

**Pre-close audit:** `audit-open` had 2 acknowledged deferred items: historical `Phase 37: 37-VERIFICATION.md [gaps_found]` preserved as non-authoritative audit context, and seed `SEED-001-cut-next-real-release [dormant]` kept for the next milestone decision. Formal milestone audit: [`.planning/milestones/v1.16-MILESTONE-AUDIT.md`](milestones/v1.16-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.16-ROADMAP.md`, `milestones/v1.16-REQUIREMENTS.md`, `milestones/v1.16-MILESTONE-AUDIT.md` · **Git tag:** `v1.16`

---

## v1.14 Advanced Authorization & Resource Targetting (Shipped + archived: 2026-05-06)

**Phases completed:** **5** (**54-58**), **12** plans, **12** requirements closed.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes OAuth 2.0 Resource Indicators (RFC 8707) and Rich Authorization Requests (RFC 9396).

**Key accomplishments:**
- Added Resource Indicators validation and audience downscoping across authorization-code and refresh-token exchanges.
- Added `authorization_details` intake on `/par` and `/authorize`, including durable PAR and interaction persistence.
- Added host-owned RAR validator behaviors, normalization, fingerprinting, durable consent-grant storage, and token-to-grant linkage.
- Added grant-backed RAR introspection, structural consent-surface proof, and narrow FAPI/PAR regression coverage.
- Published truthful discovery metadata and an executable host-owned RAR consent guide pinned by release-contract tests.

**Pre-close audit:** `audit-open` had 1 acknowledged deferred verification gap (`Phase 37: 37-VERIFICATION.md [gaps_found]`, recorded in `STATE.md`). Formal milestone audit: [`.planning/milestones/v1.14-MILESTONE-AUDIT.md`](milestones/v1.14-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.14-ROADMAP.md`, `milestones/v1.14-REQUIREMENTS.md`, `milestones/v1.14-MILESTONE-AUDIT.md` · **Git tag:** `v1.14`

---

## v1.13 OpenID Connect CIBA (Shipped + archived: 2026-05-05)

**Phases completed:** **3** (**51-53**), **8** plans, **7** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now includes full support for the OpenID Connect Client-Initiated Backchannel Authentication Flow (CIBA).

**Key accomplishments:**
- Implemented the `/bc-authorize` endpoint with robust validation and discovery metadata.
- Added the CIBA token grant type to `/token` with durable polling state enforcement.
- Support for Poll, Ping, and Push delivery modes using Oban for reliable, retriable webhook delivery.
- Established the `Lockspire.Host` Behaviour for delegating out-of-band notifications and user consent to the host application.
- Verified all flows with a comprehensive integration test suite covering asynchronous lifecycle events and background delivery.

**Pre-close audit:** Handled by `$gsd-complete-milestone`.

**Archives:** `milestones/v1.13-ROADMAP.md`, `milestones/v1.13-REQUIREMENTS.md` · **Git tag:** `milestone/v1.13`

---

## v1.12 Token Exchange (RFC 8693) (Shipped + archived: 2026-05-05)

**Phases completed:** **3** (**48-50**), **7** plans, **5** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now includes OAuth 2.0 Token Exchange for microservice patterns (Delegation and Impersonation).

**Key accomplishments:**
- Added parsing and durable storage of RFC 8693 Token Exchange requests, tracking token lineage via `grant_id`.
- Introduced the `Lockspire.TokenExchangeValidator` behaviour to give host apps explicit policy control over which clients and actors are allowed to perform exchanges.
- Enforced domain-specific delegation boundaries via `max_delegation_depth` configuration to prevent arbitrary recursive token bloat.
- Generated and verified `act` claims for nested delegation chains when `actor_token` is present.

**Pre-close audit:** Handled by `$gsd-complete-milestone`.

**Archives:** `milestones/v1.12-ROADMAP.md`, `milestones/v1.12-REQUIREMENTS.md` · **Git tag:** `v1.12`

---

## v1.11 1.0 GA Release — The Stabilization Epoch (Shipped + archived: 2026-05-05)

**Phases completed:** **4** (**44-47**), **6** requirements closed.

**Package posture:** Lockspire transitions from preview to 1.0 GA release. `release-please` is configured to publish `1.0.0`.

**Key accomplishments:**

- Fixed Dialyzer and strict typing constraints across the codebase.
- Standardized operator telemetry and LiveView seams.
- Completed comprehensive ExDoc `@moduledoc` and `@doc` coverage.
- Configured 1.0.0 GA posture in Release Please and scrubbed preview documentation.
- Project CI passes all `credo`, `dialyzer`, and `sobelow` checks.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.11-MILESTONE-AUDIT.md`](milestones/v1.11-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.11-ROADMAP.md`, `milestones/v1.11-REQUIREMENTS.md`, `milestones/v1.11-MILESTONE-AUDIT.md` · **Git tag:** `v1.11`

---

## v1.10 FAPI 2.0 Security Profile (Shipped + archived: 2026-05-03)

**Phases completed:** **3** (**41-43**), **18** plans, **6** requirements closed.

**Package posture:** `lockspire` now includes a FAPI 2.0 strict mode. When enabled, requests without PAR, without DPoP, or lacking compliant cryptography are strictly rejected.

**Key accomplishments:**

- Added `security_profile: :fapi_2_0_security` operator option (global and per-client).
- Implemented `FAPI20EnforcerPlug` boundary for zero-tolerance PAR and DPoP checking.
- Locked down cryptography to strictly `ES256` and `PS256` under the FAPI profile.
- Strict RFC 9207 `iss` emission on all authorization responses.
- Truthful discovery and security documentation reflecting the FAPI 2.0 claims.
- Provided `mix lockspire.oidf_conformance` preflight tooling for formal conformance suite execution.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.10-MILESTONE-AUDIT.md`](milestones/v1.10-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.10-ROADMAP.md`, `milestones/v1.10-REQUIREMENTS.md`, `milestones/v1.10-MILESTONE-AUDIT.md` · **Git tag:** `v1.10`

---

## v1.9 JAR Decryption (JWE Support) (Shipped + archived: 2026-04-29)

**Phases completed:** **1** (**40**), **0** plans, **2** requirements closed.

**Package posture:** `lockspire 0.2.0` remains preview. The shipped surface now includes nested JWE support for request objects.

**Key accomplishments:**

- Added RSA/EC encryption keypairs (`enc`) to `Storage.KeyStore` and JWKS endpoints.
- Implemented nested JWT validation (Sign-then-Encrypt) in `Protocol.Jar` using `JOSE.JWE` and `JOSE.JWS`.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.9-MILESTONE-AUDIT.md`](milestones/v1.9-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.9-ROADMAP.md`, `milestones/v1.9-REQUIREMENTS.md`, `milestones/v1.9-MILESTONE-AUDIT.md` · **Git tag:** `v1.9`

---

## v1.8 Session Management & Conformance (Shipped + archived: 2026-04-29)

**Phases completed:** **3** (**37-39**), **14** plans, **8** requirements closed (CONF-04 deferred).

**Package posture:** `lockspire 0.2.0` remains preview. The shipped surface now includes full RP-Initiated logout, automated back-channel and front-channel logout propagation, and strict protocol validation for auth_time and max_age.

**Key accomplishments:**

- Added strict protocol validation for integers and URL match exactness.
- EndSession endpoint implementation with generated host seams for RP-initiated logout.
- Back-channel logout implementation using Oban and HTTP request propagation.
- Front-channel logout rendering of invisible iframes based on relying party registration metadata.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.8-MILESTONE-AUDIT.md`](milestones/v1.8-MILESTONE-AUDIT.md) (`passed` with CONF-04 deferred).

**Archives:** `milestones/v1.8-ROADMAP.md`, `milestones/v1.8-REQUIREMENTS.md`, `milestones/v1.8-MILESTONE-AUDIT.md` · **Git tag:** `v1.8`

---

## v1.7 DPoP Core for Public and CLI Clients (Shipped: 2026-04-28)

**Phases completed:** **4** (**33-36**), **12** plans, **14** requirements closed.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the full repo-proven DPoP core on top of the earlier device-flow, PAR, JAR, and DCR work.

**Key accomplishments:**

- Added DPoP proof validation, replay protection, and thumbprint derivation for token binding.
- Implemented DPoP-aware authorization-code, refresh-token, and device-code exchanges without breaking the bearer default.
- Added DPoP enforcement on the Lockspire-owned `userinfo` endpoint and aligned discovery, docs, and operator/DCR configurations to the shipped slice.
- End-to-end proof and introspection behavior validate the truthful support claim.

**Pre-close audit:** Formal milestone archive handoff handled by `$gsd-complete-milestone`.

**Archives:** `milestones/v1.7-ROADMAP.md`, `milestones/v1.7-REQUIREMENTS.md` · **Git tag:** `v1.7`

---

## v1.6 Device Authorization Grant (Shipped + archived: 2026-04-28)

**Phases completed:** **3** (**30-32**), **10** plans, **9** requirements closed.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the full repo-proven Device Authorization Grant wedge on top of the earlier PAR, JAR, and DCR work.

**Key accomplishments:**

- Added the full Device Authorization Grant flow: mounted `POST /device/code`, durable hashed storage, Base20 user codes, and strict TTLs.
- Generated and documented the host-owned `/verify` seam with explicit anti-phishing behavior, CSRF-protected forms, and rate-limit guidance that stays on the host side.
- Added durable poll pacing, RFC 8628 continuation outcomes on `/token`, truthful discovery metadata, and generated-host end-to-end proof for `/device/code -> /verify -> /token`.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md) (`passed` with no requirement, integration, flow, or Nyquist gaps).

**Archives:** `milestones/v1.6-ROADMAP.md`, `milestones/v1.6-REQUIREMENTS.md`, `milestones/v1.6-MILESTONE-AUDIT.md` · **Git tag:** `v1.6`

---

## v1.5 Dynamic Client Registration (Shipped + archived: 2026-04-27)

**Phases completed:** **5** (**25-29**), **27** requirements mapped and closed.

**Key accomplishments:**

- Added full RFC 7591/7592 dynamic client registration lifecycle.
- Implemented operator policy controls and Initial Access Tokens.
- Truthful discovery and security documentation.

## v1.4 JAR and Request Objects (Shipped + archived: 2026-04-26)

**Phases completed:** **4** (**21-24**), **18** plans, **5** shipped requirements (**JAR-01**, **JAR-02**, **JAR-03**, **JAR-05**, **JAR-06**); **JAR-04** remains deferred.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the verified JAR request-object slice on top of the earlier PAR and PAR-policy work.

**Key accomplishments:**

- Added signed JAR request-object support with client-key signature validation and RFC 9101 claim checks.
- Integrated request objects into the existing authorization-code, PAR, and browser-boundary flow without widening the embedded-library shape.
- Published truthful JAR discovery and operator policy controls for the shipped request-object slice.
- Closed the milestone with explicit verification, validation, and traceability evidence while preserving JAR-04 as deferred.

**Pre-close audit:** `audit-open` clear. Formal milestone validation: [`.planning/phases/24-verification-and-milestone-closure/24-VALIDATION.md`](phases/24-verification-and-milestone-closure/24-VALIDATION.md) (`passed` with JAR-04 deferred and no boundary drift).

**Archives:** `milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md` · **Git tag:** `v1.4`

---

## v1.2 PAR Foundation (Shipped + archived: 2026-04-24)

**Phases completed:** **3** (**14-16**), **8** plans, **5** requirements (**PAR-01**-**PAR-04**, **RELS-04**)

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the narrow PAR wedge and a checked-in Release Please path on a supported runtime.

**Key accomplishments:**

- Added durable hash-only PAR intake plus a mounted `POST /par` endpoint that reuses existing client-auth and validation seams.
- Extended `/authorize` to consume Lockspire-issued PAR references with expiry, client binding, replay resistance, and unchanged auth-code + PKCE semantics.
- Locked discovery, docs, SECURITY wording, and repo-truth contract tests to the exact shipped PAR slice.
- Closed `PAR-04` traceability and removed the deferred Release Please Node 20 runtime warning by moving to a repo-controlled Node 24 composite action.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md) (`passed` with no requirement, integration, flow, or Nyquist gaps).

**Automation note:** `gsd-sdk query milestone.complete` remains unreliable, so the close again used manual `milestones/v1.2-*` artifacts, `ROADMAP.md` collapse, and `git rm .planning/REQUIREMENTS.md`.

**Archives:** `milestones/v1.2-ROADMAP.md`, `milestones/v1.2-REQUIREMENTS.md`, `milestones/v1.2-MILESTONE-AUDIT.md` · **Git tag:** `v1.2`

---

## v1.1 Release Hardening (Shipped + archived: 2026-04-24)

**Phases completed:** **7** (**07-13**), **15** plans, **9** requirements (**GATE-01**-**GATE-03**, **RELS-01**-**RELS-03**, **POST-01**-**POST-03**)

**Package posture:** `lockspire 0.2.0` exists at archive time; planning milestone complete, but public product posture remains preview rather than `1.0`.

**Key accomplishments:**

- Repo-truth QA and contributor gate recovery closed the maintained `mix qa`/`mix ci` drift and backfilled formal gate verification.
- Trusted release hardening locked the checked-in publish policy, maintainer guide, protected environment proof, and approved canonical run evidence.
- Preview-support docs and contract tests now keep public claims bounded to the implemented embedded-provider wedge while leaving PAR as the next milestone candidate only.
- Final verification and ledger-reconciliation phases closed the remaining audit handoff gaps without reopening release implementation.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md) (`tech_debt` for Nyquist completeness gaps and the `release-please-action` Node.js 20 warning only).

**Automation note:** `gsd-sdk query milestone.complete` failed again (`version required for phases archive`), so the close used manual `milestones/v1.1-*` artifacts, `ROADMAP.md` collapse, and `git rm .planning/REQUIREMENTS.md`.

**Archives:** `milestones/v1.1-ROADMAP.md`, `milestones/v1.1-REQUIREMENTS.md`, `milestones/v1.1-MILESTONE-AUDIT.md` · **Git tag:** `v1.1`

---

## v1.0 Embedded OAuth/OIDC Provider Foundation (Shipped + archived: 2026-04-23)

**Phases completed:** **6** (**01-06**), **25** plans

**Archives:** `milestones/v1.0-ROADMAP.md`, `milestones/v1.0-REQUIREMENTS.md` · **Git tag:** `milestone/v1.0`
