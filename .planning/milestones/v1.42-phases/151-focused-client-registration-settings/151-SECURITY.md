---
phase: "151"
slug: "focused-client-registration-settings"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-15"
---

# Phase 151 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host application → AdminRouter | The host owns staff authentication, authorization, MFA, and tenant policy, and mounts Lockspire's admin router behind its guard. | Staff session (host-owned) |
| Staff browser → client registration LiveView | Submitted client metadata and filter query values are untrusted; the generated secret is sensitive output. | Client metadata, filter params; one-time client secret (high) |
| Staff browser → client settings LiveView | The selected client identifier and submitted settings arrive through browser-controlled routes and forms. | Client identifier, settings changes |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-151-01 | Spoofing | Admin route registration | medium | mitigate | `live("/clients/new", ...)` registered inside `Lockspire.Web.AdminRouter` (`lib/lockspire/web/admin_router.ex:17`), so it inherits the host guard; route resolution covered by `test/lockspire/web/admin_router_test.exs:24`. | closed |
| T-151-02 | Information Disclosure | Copy-once client creation result | high | mitigate | Plaintext lives only in LiveView assigns (`created_result`); `handle_params` resets it to `nil` on any route change and `hide_created_secret` hides it on acknowledgement (`clients_live/index.ex`); test "created client secret is cleared on acknowledgement and inventory filter change". | closed |
| T-151-03 | Tampering | Return-filter query | low | mitigate | `normalize_filters/1` allowlists status/provenance values; return links built only from `Lockspire.mount_path() <> "/admin/clients"` plus normalized filters (`clients_index_path/1`); no caller-supplied destination accepted. | closed |
| T-151-04 | Tampering | Client settings navigation and form | medium | mitigate | Identity and return links derived from the loaded client (`client_show_path/1`); Admin API authorization and validation unchanged; covered by `clients_live/show_test.exs` "each client task route names its task and keeps provenance reader-facing". | closed |
| T-151-05 | Elevation of Privilege | Destructive client task controls | medium | mitigate | Rotate and toggle handlers still require `"confirm" => "true"` and return a `confirm` error otherwise (`clients_live/show.ex:139-252`); test "client lifecycle changes require explicit confirmation". | closed |
| T-151-SC | Tampering | Package installation | low | accept | No package-manager or dependency changes in this phase. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-151-01 | T-151-SC | Phase 151 adds no packages or third-party dependencies; supply-chain surface unchanged. | Plan-time threat model (151-01, 151-02) | 2026-10-12 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-15 | 6 | 6 | 0 | secure-phase orchestrator (ASVS L1 grep-depth) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-15
