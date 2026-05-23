# v1.21 Resource Server (API Protection) Roadmap

## Overview
This milestone delivers a first-class validation Plug (`Lockspire.Plug.VerifyToken`) to protect host Phoenix API routes. Having established Lockspire as a highly secure token issuer with DPoP, MTLS, and FAPI 2.0 capabilities, this milestone closes the loop by providing developers an idiomatic, out-of-the-box way to easily validate those complex tokens on their resource servers. 

## Architecture & Sequencing
The implementation will start with the core JWT validation primitives (signature, expiration, scope), followed by the integration of our advanced sender-constraining proofs (DPoP and MTLS bindings), and wrap up with documentation and developer experience improvements.

## Phases

### Phase 79: Core Validation Plug
**Goal**: Establish the `Lockspire.Plug.VerifyToken` Plug with basic JWT validation.

**Plans:** 3 plans
- [ ] 79-01-PLAN.md — Build the core data structure (AccessToken) and high-speed ETS cache for signing keys (KeyCache)
- [ ] 79-02-PLAN.md — Implement the Lockspire.Plug.VerifyToken plug
- [ ] 79-03-PLAN.md — Implement the Lockspire.Plug.RequireToken plug

### Phase 80: Sender-Constraining Integration (DPoP & MTLS)
**Goal**: Transparently enforce `cnf` (confirmation) claims for high-security tokens.
- **Plans:** 2/3 plans executed
- [x] 80-01-PLAN.md — Normalize sender-binding metadata and extract shared MTLS token-binding helpers
- [x] 80-02-PLAN.md — Generalize protected-resource DPoP validation and add `EnforceSenderConstraints`
- [ ] 80-03-PLAN.md — Complete MTLS enforcement and DPoP-aware `RequireToken` challenges
- **Tasks**:
  - Detect `cnf` claims in the validated access token.
  - If `jkt` is present, validate the incoming `DPoP` proof header against the request URL, method, and token thumbprint.
  - If `x5t#S256` is present, utilize the configured `Lockspire.MTLS.Extractor` to hash the client certificate and verify the match.
  - Emit correct `WWW-Authenticate: DPoP` error headers if DPoP proofs are missing or invalid.

### Phase 81: Scope/Audience Restrictions & Milestone Closure
**Goal**: Provide granular route protection options and verify end-to-end DX.
- **Tasks**:
  - Add support for required scopes (e.g., `plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"]`).
  - Add support for Audience (`aud`) validation.
  - Add an executable documentation guide for protecting Phoenix API routes.
  - Verify end-to-end integration and close the milestone.
