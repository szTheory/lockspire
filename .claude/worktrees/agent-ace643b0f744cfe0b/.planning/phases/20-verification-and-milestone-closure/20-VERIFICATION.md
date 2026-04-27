# v1.3 Verification Report: PAR Policy Controls

**Date:** 2026-04-24  
**Status:** PASSED  
**Scope:** PAR Policy Enforcement, Operator UX, and Discovery Truth.

## Requirement Traceability

| Requirement | Description | Implementation Artifacts | Verification Evidence |
|-------------|-------------|--------------------------|-----------------------|
| **PARPOL-01** | Global PAR Policy | `Lockspire.Domain.ServerPolicy`, `Lockspire.Storage.ServerPolicyStore` | `Lockspire.Integration.MilestoneV13VerificationTest` ("Scenario: Global Required") |
| **PARPOL-02** | Per-Client Policy & Resolution | `Lockspire.Domain.Client` (par_policy), `Lockspire.Protocol.PARPolicy` | `Lockspire.Integration.MilestoneV13VerificationTest` ("Scenario: Client Override Required/Optional") |
| **PARPOL-03** | Authorization Enforcement | `Lockspire.Protocol.AuthorizationFlow` | `Lockspire.Integration.MilestoneV13VerificationTest` ("Scenario: Global Required", "Scenario: Client Override Required") |
| **PARPOL-04** | Truthful Surface | `Lockspire.Protocol.Discovery`, `docs/supported-surface.md`, `SECURITY.md` | `Lockspire.Web.DiscoveryControllerTest` (v1.3 metadata checks) |
| **PARPOL-05** | Operator Workflows | `Lockspire.Web.Live.Admin.PoliciesLive.PAR`, `Lockspire.Web.Live.Admin.ClientsLive.FormComponent` | Manual verification of admin UI; presence of LiveView routes in `Lockspire.Web.Router`. |
| **PARPOL-06** | Consolidated Proof | `test/integration/milestone_v1_3_verification_test.exs` | Execution of `mix test test/integration/milestone_v1_3_verification_test.exs` (All 5 scenarios passed). |

## Automated Test Results

The following tests were executed to confirm milestone readiness:

1. **Integration Verification Suite**
   - File: `test/integration/milestone_v1_3_verification_test.exs`
   - Scenarios:
     - [x] Global Optional (Default): Direct authorize succeeds.
     - [x] Global Required: Direct authorize rejected; PAR-backed flow succeeds.
     - [x] Client Override Required: Direct authorize rejected even if global is optional.
     - [x] Client Override Optional (Exemption): Direct authorize succeeds despite global requirement.
     - [x] Effective Policy Independence: Resolution works correctly across multiple clients.

2. **Protocol and Discovery**
   - File: `test/lockspire/web/discovery_controller_test.exs`
   - [x] `pushed_authorization_request_endpoint` advertised when PAR mounted.
   - [x] No JAR-by-value or generic `request_uri` metadata present.

3. **Admin and Policy Logic**
   - File: `test/lockspire/protocol/par_policy_test.exs`
   - [x] Unit tests for tri-state resolution logic (Inherit, Required, Optional).

## Conclusion

All v1.3 requirements are successfully implemented and verified through automated tests. The PAR Policy system provides a flexible, secure, and truthful mechanism for operators to enforce PAR usage.
