# Phase 43: End-to-End FAPI 2.0 Validation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `43-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-05-02
**Phase:** 43-end-to-end-fapi-validation
**Mode:** assumptions
**Areas analyzed:** FAPI-05 redirect surface, FAPI-06 iss emission, FAPI-06 discovery metadata,
end-to-end proof lane and conformance task, generated host-seam tests

## Assumptions Presented

### FAPI-05 Surface Coverage and "What Counts as Exact"

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Don't change matching logic; existing exact-string `in` and `==` are canonical and single-sourced through `Lockspire.Clients.validate_redirect_uris/1` | Confident | `authorization_request.ex:236-247`, `token_exchange.ex:366-378`, `clients.ex:310-338`, `registration.ex:243-254`, `admin/clients.ex:229-234` |
| Keep `String.trim/1` at `end_session.ex:147` as documented behavior; pin with tests asserting only surrounding whitespace tolerated, no trailing-slash or query-drift tolerance | Likely | `end_session.ex:145-170` |

### FAPI-06 `iss` Parameter Emission Scope

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Append `iss` UNCONDITIONALLY at TWO redirect seams: `AuthorizationFlow.build_redirect/3` and `AuthorizeController.redirect_location/1` | Confident | `authorization_flow.ex:390-402`, `authorize_controller.ex:129-145`, RFC 9207 §2 |
| Phase 41 E2E test won't break (parses callback by query key, not full-URL equality); plan should still run a `mix test` regression sweep | Likely | `test/integration/phase41_fapi_2_0_e2e_test.exs:172-173` |

### FAPI-06 Discovery Metadata Strategy

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `authorization_response_iss_parameter_supported: true` UNCONDITIONAL; `require_pushed_authorization_requests: true` ONLY when global profile is `:fapi_2_0_security`; `dpop_signing_alg_values_supported` already published, no change; no mTLS / `signed_metadata` keys | Confident | `discovery.ex:74-94, 168-178`, `security_profile.ex:26-37`, `42-CONTEXT.md` D-11, `REQUIREMENTS.md:29` |

### End-to-End Proof Lane and Manual Conformance Gating

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add NEW `phase43_fapi_milestone_e2e_test.exs`; do NOT extend Phase 41 test; update `release_readiness_contract_test.exs` with FAPI-claim assertions | Confident | Per-phase `phase{N}_*_e2e_test.exs` precedent; `35-CONTEXT.md`, `36-CONTEXT.md` |
| Implement missing `mix lockspire.oidf_conformance` task; deterministic `--validate-env` shell-out around `fapi2-check.sh`; live OIDF Docker run remains documented manual step (not CI gate) | Confident | `docs/maintainer-conformance.md:53`, `.github/workflows/oidf-conformance.yml:66`, `release_readiness_contract_test.exs:481`, `42-CONTEXT.md` D-13/D-14/D-15 |

### Generated Host-Seam Tests Scope

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `install.ex` + `priv/templates/lockspire.install/` to emit ONE host-owned FAPI-aware integration test template (mirror Phase 41 E2E shape in host namespace); cap at one file unless >200 lines | Likely | `lib/lockspire/generators/install.ex:14`, install template listing, `release_readiness_contract_test.exs:291` |

## Corrections Made

No corrections — all assumptions confirmed by user ("Yes, proceed").

## External Research

- **OIDF FAPI 2.0 plan ID:** `fapi2-security-profile-final-test-plan` (Final, Feb 2025; ID1/ID2
  deprecated for new certs). Required variants for Lockspire: `fapi_profile=plain_fapi`,
  `client_auth_type=private_key_jwt`, `sender_constrain=dpop`, `fapi_request_method=unsigned`,
  `fapi_response_mode=plain_response`. Source: `FAPI2SPFinalTestPlan.java` line 18 in OIDF
  conformance-suite master
  (https://gitlab.com/openid/conformance-suite/-/raw/master/src/main/java/net/openid/conformance/fapi2spfinal/FAPI2SPFinalTestPlan.java).
  Resolves orphan placeholder in `docs/maintainer-conformance.md:96` to a verbatim, pinnable string.

- **RFC 9207 `iss` scope:** Strictly authorization-response only (success and error redirects from
  `/authorize`). RFC 9207 §2 explicitly does NOT extend `iss` to `/token`, `/revoke`, or
  `/introspect` responses. FAPI 2.0 Security Profile Final adds no such requirement. Keycloak's
  RFC 9207 implementation (#20621) similarly touched only the authorization-response surface.
  Source: https://www.rfc-editor.org/rfc/rfc9207.html §2. Confirms Phase 43's `iss` work stays
  bounded to the two authorization-redirect seams (D-04, D-05, D-06).
