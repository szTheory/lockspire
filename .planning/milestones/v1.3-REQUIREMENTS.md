# Requirements: v1.3 PAR Policy Controls

**Milestone:** v1.3  
**Status:** Active  
**Last updated:** 2026-04-24

## Milestone Goal

Let operators require PAR safely at global and per-client scope while keeping discovery truth, admin UX, and automated proof aligned to the narrow embedded-provider surface.

## v1.3 Requirements

### PAR Policy Model

- [x] **PARPOL-01**: Operators can configure a global Lockspire policy that requires PAR for authorization requests.
- [x] **PARPOL-02**: Operators can configure per-client PAR requirements, and Lockspire resolves one effective PAR policy for each authorization request.

### Authorization Enforcement

- [x] **PARPOL-03**: OAuth clients that are subject to an effective PAR requirement can complete the existing authorization code + PKCE flow only by presenting a valid Lockspire-issued `request_uri`.

### Truthful Surface

- [x] **PARPOL-04**: Integrators and maintainers can discover the shipped PAR policy slice through truthful metadata and docs that do not imply JAR-by-value, generic external `request_uri`, dynamic client registration, device flow, or hosted-auth support.

### Operator Workflows

- [x] **PARPOL-05**: Operators can inspect and manage global and per-client PAR requirement state through the existing Lockspire admin surface without needing repo-internal changes.

### Verification

- [x] **PARPOL-06**: Maintainers have automated protocol, integration, and operator-surface proof for optional-PAR, required-PAR, and rejected-direct-request scenarios before the milestone can close.

## Requirement Notes

- `PARPOL-01` and `PARPOL-02` should share one effective-policy resolution path so runtime enforcement and admin UX cannot drift.
- `PARPOL-03` must preserve the existing auth-code + PKCE path for clients that are not subject to a PAR requirement.
- `PARPOL-04` should keep the current narrow discovery and support-truth posture unless the implementation introduces a repo-proven metadata change.
- `PARPOL-05` must preserve the embedded-library shape; host apps still own branding, accounts, and login UX.
- `PARPOL-06` should close with executable proof rather than narrative-only milestone claims.

## Future Requirements

- **JAR-01**: Clients can send signed or encrypted request objects by value or through richer PAR/JAR interoperability modes.
- **DCR-01**: Developers can self-register OAuth clients through dynamic client registration.
- **DEVICE-01**: Devices can complete OAuth authorization through the device authorization grant.
- **SCON-01**: Clients can use stronger sender-constrained token modes beyond the baseline bearer-token preview surface.
- **CONF-01**: Lockspire can support stronger conformance or certification profiles once the narrow embedded-provider surface is more mature.

## Out of Scope for v1.3

| Feature | Reason |
|---------|--------|
| JAR-by-value support in v1.3 | Broader request-object interoperability should follow PAR policy closure, not blur this milestone. |
| Generic external `request_uri` support in v1.3 | The shipped PAR slice still depends on Lockspire-issued references only. |
| Dynamic client registration in v1.3 | Opens a new developer-facing trust surface instead of tightening the existing request path. |
| Device flow in v1.3 | Introduces a separate interaction model rather than improving the existing browser flow. |
| Sender-constrained token modes in v1.3 | Valuable later, but not required to make the current preview request path more defensible. |

## Traceability

| Requirement | Assigned Phase | Status | Notes |
|-------------|----------------|--------|-------|
| PARPOL-01 | Phase 17 | Planned | Global PAR requirement model and durable configuration. |
| PARPOL-02 | Phase 17 | Planned | Per-client policy model and effective-policy resolution. |
| PARPOL-03 | Phase 18 | Planned | Authorization-path enforcement for required-PAR behavior. |
| PARPOL-04 | Phase 19 | Planned | Truthful discovery/support wording for the shipped PAR policy slice. |
| PARPOL-05 | Phase 19 | Planned | Operator/admin workflows for policy visibility and control. |
| PARPOL-06 | Phase 20 | Planned | End-to-end proof, traceability, and milestone closure evidence. |
