# v1.3 Technical Validation Record: PAR Policy Controls

**Milestone:** v1.3  
**Release Readiness:** READY  
**Verification Date:** 2026-04-24

## Technical Status

The v1.3 milestone successfully transitioned from a PAR Foundation (v1.2) to a production-ready PAR Policy surface. The implementation enables operators to enforce PAR usage globally or on a per-client basis, providing the necessary controls for high-security environments.

### Core Components

- **Durable Policy Storage:** Server-wide PAR policy is stored in the `lockspire_server_policies` table, managed through `Lockspire.Admin`.
- **Client Configuration:** OAuth clients now include a `par_policy` field (`inherit`, `required`, `optional`) to allow for exemptions or stricter requirements than the global default.
- **Effective Resolution:** A dedicated `Lockspire.Protocol.PARPolicy` module resolves the effective policy for every authorization request, ensuring consistent enforcement logic between the runtime and the admin UI.
- **Enforcement Gate:** `Lockspire.Protocol.AuthorizationFlow` rejects direct authorization requests that do not present a valid `request_uri` when the effective policy is `required`.

## Performance Considerations

- **O(1) Resolution:** Policy resolution is integrated into the existing client lookup and server configuration fetch. There is no significant latency increase in the authorization path.
- **Efficient Storage:** PAR references (`request_uri`) remain short-lived and are stored by hash. The implementation includes automatic "burning" of references on use or failure, preventing replay and storage bloat.
- **Minimal DB Impact:** The `lockspire_server_policies` table is expected to be small (typically 1-2 records), making it a candidate for future caching if needed, though current performance is well within acceptable OIDC provider limits.

## Security Posture (STRIDE)

| Threat Category | Mitigation Strategy | Status |
|-----------------|---------------------|--------|
| **Spoofing** | PAR endpoint requires client authentication (if registered). PAR references are cryptographically strong and unguessable. | Verified |
| **Tampering** | PAR data is stored durably and verified upon `request_uri` resolution. Effective policy logic is immutable at runtime. | Verified |
| **Repudiation** | Audit events track PAR creation, PAR usage, and policy changes by operators. | Verified |
| **Information Disclosure** | Discovery metadata only advertises the supported PAR slice. PAR endpoint validates input before returning a reference. | Verified |
| **Denial of Service** | PAR references have a short TTL. Failed attempts at PAR-required paths are handled gracefully without heavy processing. | Verified |
| **Elevation of Privilege** | Policy enforcement is mandatory for all clients subject to a `required` policy. No bypass paths exist in the browser-based authorization flow. | Verified |

## Final Assessment

The PAR Policy implementation is technically sound, performant, and secure. It fulfills the v1.3 milestone goal without introducing scope drift into unsupported request-object behaviors.
