# Milestone v1.14 Requirements — Advanced Authorization & Resource Targetting

## Overview
This milestone focuses on raising real-client trust and providing high-leverage protocol features for complex domains (Fintech, Healthcare, etc.). By implementing **Rich Authorization Requests (RAR)** and **Resource Indicators**, Lockspire enables Phoenix teams to enforce the Principle of Least Privilege at both the resource and transaction levels.

## Requirements

### Resource Indicators (RFC 8707)
| ID | Requirement | Phase | Status |
|:---|:---|:---:|:---|
| RES-01 | Support `resource` parameter (absolute URIs) in Authorization and Token endpoints | 54 | Pending |
| RES-02 | Implement Audience Downscoping: Access Tokens must be restricted to the requested resource(s) in the `aud` claim | 54 | Pending |
| RES-03 | Support Refresh Token scope/resource intersection during targeted token exchange | 54 | Pending |

### Rich Authorization Requests (RAR - RFC 9396)
| ID | Requirement | Phase | Status |
|:---|:---|:---:|:---|
| RAR-01 | Support `authorization_details` parameter (JSON array) in PAR and Authorization requests | 55 | Pending |
| RAR-02 | Provide Ecto-based validation framework for host-defined RAR types | 56 | Pending |
| RAR-03 | Store approved RAR details in `Lockspire.Storage` and associate with minted tokens | 56 | Pending |
| RAR-04 | Expose RAR details in the `/introspection` response for Resource Servers | 57 | Pending |

### Discovery & Docs
| ID | Requirement | Phase | Status |
|:---|:---|:---:|:---|
| META-01 | Advertise `resource_indicators_supported: true` in Discovery | 58 | Pending |
| META-02 | Advertise `authorization_details_types_supported` based on host configuration in Discovery | 58 | Pending |
| DOC-01 | Provide executable documentation for implementing a custom RAR consent screen | 58 | Pending |

### Quality & Verification
| ID | Requirement | Phase | Status |
|:---|:---|:---:|:---|
| V-01 | Deliver e2e test suite for RAR-scoped consent and targeted token issuance | 57 | Pending |
| V-02 | Verify FAPI 2.0 compatibility when RAR is used (exact matching, PAR enforcement) | 57 | Pending |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| RES-01 | Phase 54 | Pending |
| RES-02 | Phase 54 | Pending |
| RES-03 | Phase 54 | Pending |
| RAR-01 | Phase 55 | Complete |
| RAR-02 | Phase 56 | Pending |
| RAR-03 | Phase 56 | Pending |
| RAR-04 | Phase 57 | Pending |
| META-01 | Phase 58 | Pending |
| META-02 | Phase 58 | Pending |
| DOC-01 | Phase 58 | Pending |
| V-01 | Phase 57 | Pending |
| V-02 | Phase 57 | Pending |
