# Roadmap

## Phases

- [x] **Phase 41: FAPI 2.0 Profile Configuration and Strict Enforcement**
- [x] **Phase 42: FAPI 2.0 Advanced Cryptography and OIDF Test Suite Prep**
- [ ] **Phase 43: End-to-End FAPI 2.0 Validation and Release Posture**

## Phase Details

### Phase 41: FAPI 2.0 Profile Configuration and Strict Enforcement
**Goal:** Introduce `security_profile: :fapi_2_0_security` option, durable global+per-client config, boundary FAPI20EnforcerPlug, and Admin LiveViews. PAR + DPoP boundary enforcement; algorithm enforcement deferred to Phase 42.
**Requirements:** FAPI-01, FAPI-02, FAPI-03
**Success:** When the FAPI 2.0 profile is enabled, requests without PAR, requests missing DPoP, and non-S256 PKCE are aggressively rejected at the Plug boundary, operators can manage the profile globally and per-client, and the end-to-end enforcement path is proven by targeted integration coverage.
**Plans:** 4 plans
Plans:
- [x] 41-01-PLAN.md — Domain + storage + admin command boundary for security_profile (FAPI-01)
- [x] 41-02-PLAN.md — FAPI20EnforcerPlug + router pipeline (FAPI-02, FAPI-03)
- [x] 41-03-PLAN.md — Admin LiveViews for global + per-client security_profile (FAPI-01)
- [x] 41-04-PLAN.md — End-to-end integration test + conformance script + maintainer doc (FAPI-01, FAPI-02, FAPI-03)

### Phase 42: FAPI 2.0 Advanced Cryptography and OIDF Test Suite Prep
**Goal:** Ensure the cryptosystem correctly supports ES256/PS256 exclusively and limits allowed algorithms per FAPI 2.0.
**Requirements:** FAPI-04
**Success:** Key storage and signing logic enforce strict algorithm whitelisting when the FAPI profile is active. OIDF conformance container harness is documented.
**Plans:** 7 plans
Plans:
- [ ] 42-01-PLAN.md — Canonical algorithm truth source plus key/admin/storage fail-fast enforcement (FAPI-04)
- [ ] 42-02-PLAN.md — Runtime signer/verifier alignment for JAR and ID token enforcement (FAPI-04)
- [ ] 42-03-PLAN.md — Server-policy and admin client readiness gates for mixed-mode FAPI opt-in (FAPI-04)
- [ ] 42-04-PLAN.md — OIDF harness prep, executable maintainer docs, CI truth, and release-contract coverage (FAPI-04)
- [ ] 42-05-PLAN.md — Discovery, JWKS, and DPoP publication truth aligned to runtime policy (FAPI-04)
- [ ] 42-06-PLAN.md — DCR and registration-management rejection/remediation wiring over the Phase 42 readiness contract (FAPI-04)
- [x] 42-07-PLAN.md — Logout, end-session, and DPoP runtime cleanup aligned to the canonical FAPI policy (FAPI-04)

### Phase 43: End-to-End FAPI 2.0 Validation and Release Posture
**Goal:** Complete the implementation with generated host-seam tests and documentation.
**Requirements:** FAPI-05, FAPI-06
**Success:** The `v1.10` milestone can be archived with proven repo-truth that Lockspire protects applications against the FAPI 2.0 threat model.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| Phase 41 | 4/4 | complete | 2026-05-01 |
| Phase 42 | 7/7 | complete | 2026-05-02 |
| Phase 43 | 0 | upcoming | | 
