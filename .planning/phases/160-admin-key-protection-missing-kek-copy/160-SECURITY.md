---
phase: "160"
slug: "admin-key-protection-missing-kek-copy"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-19"
---

# Phase 160 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Storage/config → admin Keys page | Stored key rows and key-encryption config are summarised onto an operator-facing page | Protection state, tone, fixed copy, current key-encryption key id only |
| Exceptions → UI/logs | Errors raised during the status check could carry config text toward the page or logs | Nothing (rescued/caught to could-not-check; not logged) |
| Domain refusal → admin page | `{:error, :key_encryption_not_configured}` is turned into operator copy | Static strings only |
| Phase diff → shipped library | Unintended protocol, security-default, schema or dependency change | None (diff gate clean) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-160-01 | Information disclosure | `Protection.summarize/1` output and `key_protection` assign | high | mitigate | Summary type holds only `state`, `tone`, `value`, `detail`, `command` (protection.ex:19-23); current id is the only interpolated value; keys_live_test.exs asserts `test-2`, `gone-1` and the env var name are absent (8 refutes) | closed |
| T-160-02 | Information disclosure | `load_key_protection/0` rescue path and invalid-config message | high | mitigate | `summarize({:error, {:invalid_config, _message}})` discards the message (protection.ex:27); `rescue`/`catch :exit` in index.ex:192-198 map to could-not-check without logging; 0 Logger/telemetry hits in protection.ex and index.ex | closed |
| T-160-03 | Spoofing (false status) | A failed check rendered as healthy | high | mitigate | Catch-all `summarize(_other)` → `:could_not_check` with neutral tone and value "Unknown" (protection.ex:35, 125); DROP TABLE and injected-assign tests in keys_live_test.exs | closed |
| T-160-04 | Tampering / Elevation | A new control added to the line | medium | mitigate | `assert_protection_is_text_only/2` (keys_live_test.exs:905) rejects button, a, form, input and phx events in the section | closed |
| T-160-05 | Denial of service | Extra status read per page load | low | accept | One read per `assign_inventory` and per successful generate; no polling | closed |
| T-160-06 | Information disclosure | Missing-KEK refusal copy | medium | mitigate | Static strings in index.ex `{:error, :key_encryption_not_configured}` clause (index.ex:258); `assert_refusal/2` refutes the env var name and test-1 config material for both sig and enc | closed |
| T-160-07 | Tampering (security default) | A path that stores a private key unencrypted | high | mitigate | Domain refusal in `lib/lockspire/admin/keys.ex` unchanged vs dda81e8d; no fallback wording or new control; "repeated refusal stores nothing" test asserts row count unchanged | closed |
| T-160-08 | Tampering | Unintended protocol, schema, dependency or domain change | high | mitigate | `git diff --quiet dda81e8d -- mix.exs mix.lock priv lib/lockspire/protocol lib/lockspire/storage lib/lockspire/admin/keys.ex lib/lockspire/admin/keys lib/lockspire/config.ex lib/lockspire/application.ex lib/lockspire/web/components/admin_components.ex lib/lockspire/web/admin_css.ex` clean; changed files limited to the 6 planned | closed |
| T-160-SC | Tampering | package installs (npm/pip/cargo/hex) | high | accept | No packages installed; mix.exs/mix.lock unchanged (see AR-160-01) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-160-01 | T-160-SC | No dependencies added or changed (mix.exs and mix.lock unchanged vs phase base dda81e8d); no supply-chain surface introduced. Same disposition as AR-159-01. | plan-time threat model (160-01/02) | 2026-10-19 |
| AR-160-02 | T-160-05 | One extra read-only status query per Keys page load or successful generate; small table, no polling. | plan-time threat model (160-01) | 2026-10-19 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-19 | 9 | 9 | 0 | secure-phase orchestrator (L1 grep-depth, plan-time register) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-19
