# Roadmap

## Phases

- [ ] **Phase 41: FAPI 2.0 Profile Configuration and Strict Enforcement**
- [ ] **Phase 42: FAPI 2.0 Advanced Cryptography and OIDF Test Suite Prep**
- [ ] **Phase 43: End-to-End FAPI 2.0 Validation and Release Posture**

## Phase Details

### Phase 41: FAPI 2.0 Profile Configuration and Strict Enforcement
**Goal:** Introduce `security_profile: :fapi_2_0_security` option, durable global+per-client config, boundary FAPI20EnforcerPlug, and Admin LiveViews. PAR + DPoP boundary enforcement; algorithm enforcement deferred to Phase 42.
**Requirements:** FAPI-01, FAPI-02, FAPI-03
**Success:** When the FAPI 2.0 profile is enabled, requests without PAR, requests missing DPoP, and non-S256 PKCE are aggressively rejected at the Plug boundary.
**Plans:** 4 plans
Plans:
- [ ] 41-01-PLAN.md — Domain + storage + admin command boundary for security_profile (FAPI-01)
- [ ] 41-02-PLAN.md — FAPI20EnforcerPlug + router pipeline (FAPI-02, FAPI-03)
- [ ] 41-03-PLAN.md — Admin LiveViews for global + per-client security_profile (FAPI-01)
- [ ] 41-04-PLAN.md — End-to-end integration test + conformance script + maintainer doc (FAPI-01, FAPI-02, FAPI-03)

### Phase 42: FAPI 2.0 Advanced Cryptography and OIDF Test Suite Prep
**Goal:** Ensure the cryptosystem correctly supports ES256/PS256 exclusively and limits allowed algorithms per FAPI 2.0.
**Requirements:** FAPI-04
**Success:** Key storage and signing logic enforce strict algorithm whitelisting when the FAPI profile is active. OIDF conformance container harness is documented.

### Phase 43: End-to-End FAPI 2.0 Validation and Release Posture
**Goal:** Complete the implementation with generated host-seam tests and documentation.
**Requirements:** FAPI-05, FAPI-06
**Success:** The `v1.10` milestone can be archived with proven repo-truth that Lockspire protects applications against the FAPI 2.0 threat model.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| Phase 41 | 4 | in-progress | |
| Phase 42 | 1 | in-progress | |
| Phase 43 | 0 | upcoming | |