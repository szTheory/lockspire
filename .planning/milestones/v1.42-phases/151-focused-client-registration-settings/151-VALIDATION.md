---
phase: "151"
slug: "focused-client-registration-settings"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-15"
---

# Phase 151 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Reconstructed after execution from the 151 PLAN and SUMMARY artifacts.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest |
| **Config file** | `test/test_helper.exs`, `test/support/endpoint.ex` (host route mirror) |
| **Quick run command** | `HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 mix test test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` |
| **Full suite command** | `HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 mix test.fast` |
| **Estimated runtime** | ~2 seconds (quick run, 55 tests) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Run the full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 151-01-01 | 01 | 1 | UI-04 | — | Static `/clients/new` resolves before `/clients/:client_id`; return path built only from normalized filters | router + LiveView | `mix test test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/clients_live_test.exs` | ✅ | ✅ green |
| 151-01-02 | 01 | 1 | UI-04, UI-05 | — | Validation errors keep safe input; created secret shown once and cleared on acknowledgement/navigation; create is primary, return is secondary | LiveView | `mix test test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/clients_live_test.exs` | ✅ | ✅ green |
| 151-02-01 | 02 | 1 | UI-04 | — | Client task routes name the client and task without rendering the full workspace | LiveView | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ | ✅ green |
| 151-02-02 | 02 | 1 | UI-04, UI-05 | — | Destructive lifecycle changes keep explicit confirmation; navigation/save/destructive styles follow the documented rule | LiveView | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Key test cases on HEAD:

- `clients_live_test.exs` — "clients index links to a focused registration route that preserves normalized filters", "rejected client creation retains safe input and associates actionable field errors", "created client secret is cleared on acknowledgement and inventory filter change", "client registration reserves primary styling for creation and keeps return navigation secondary"
- `clients_live/show_test.exs` — "each client task route names its task and keeps provenance reader-facing", "client lifecycle changes require explicit confirmation"
- `admin_router_test.exs` — `/clients/new` route resolution

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-15

## Validation Audit

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
