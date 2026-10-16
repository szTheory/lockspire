---
phase: "152"
slug: "overview-queue-state-clarity"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-15"
---

# Phase 152 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host application → AdminRouter | The host owns staff authentication, authorization, MFA, and tenant policy, and mounts Lockspire's admin router behind its guard. | Staff session (host-owned) |
| Staff browser → queue LiveViews | The `status` query value on the sign-in request, device authorization, and app sign-out notice pages is browser-controlled. | Filter params |
| Storage → overview and queue rows | Rows and counts render records that contain account identifiers, device codes, and delivery failure detail. | Account handles, request references, failure context |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-152-01 | Tampering | Interactions status query | low | mitigate | `interaction_filter/1` matches only `"status" => "pending"` and falls back to `:all` (`interactions_live/index.ex:163-164`); tests "pending filter shows only requests waiting for sign-in or consent" and "unknown interaction status filters fall back to the full history". | closed |
| T-152-02 | Information Disclosure | Interaction row rendering | low | mitigate | Redaction helpers unchanged; test "interaction review keeps queue evidence redaction-safe and read-only". | closed |
| T-152-03 | Tampering | Device and logout status filters | low | mitigate | `device_authorization_filter/1` accepts only `"pending"` (`device_authorizations_live/index.ex:188-189`); `delivery_filter/1` accepts only `"needs_review"` and maps it to the fixed `status in [:retryable, :discarded]` predicate (`logout_deliveries_live/index.ex:162-166`); unknown values show full history (tests "unknown device status filters safely show the full history", "unknown logout status filters safely show the full history"). | closed |
| T-152-04 | Repudiation | Refresh-token reuse summary | medium | mitigate | Overview reads the `reuse_detected` count from the token store, whose rotation path records `reuse_detected_at` and returns `{:error, :reuse_detected}` (`token_store.ex:256-261`); copy says reuse "does not prove theft" and states "Related tokens revoked" only when the count is above zero (`overview_live/index.ex:34-47`); covered by "overview uses one title and concise, decision-focused copy". | closed |
| T-152-05 | Information Disclosure | Overview source observations | low | mitigate | Each source loads independently; test "overview starts in loading state and keeps each failed source independent". | closed |
| T-152-06 | Repudiation | Logout-delivery status copy | medium | mitigate | `delivery_pressure/1` derives copy from domain status, channel, HTTP status, and failure reason (`logout_deliveries_live/index.ex:258-267`); test "logout delivery review keeps incident evidence sanitized and read-only". | closed |
| T-152-07 | Information Disclosure | Device authorization rows | low | mitigate | Rows render `Redaction.handle(:account, ...)` and a redacted request reference (`device_authorizations_live/index.ex:135-136, 255-256`); test "device authorization review keeps queue evidence redaction-safe and read-only". | closed |
| T-152-SC | Tampering | Package installation | high | mitigate | No dependency changes: every 152 SUMMARY records that no dependency was introduced. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-15 | 8 | 8 | 0 | secure-phase orchestrator (ASVS L1 grep-depth) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-15
