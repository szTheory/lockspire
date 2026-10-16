---
phase: "153"
slug: "configure-support-page-refinement"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-12"
---

# Phase 153 — Validation Strategy

> Run regression checks with each task; keep rendered route review separate from source assertions.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest and AdminProof contracts |
| **Config file** | `mix.exs` |
| **Quick run command** | `HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 mix test <changed route test(s)> --max-failures 1` |
| **Full suite command** | `HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 mix test.fast` |
| **Expected feedback** | Focused LiveView and CSS tests complete in seconds after Mix has compiled the project. |

## Sampling Rate

- Run the owning test module and relevant route/CSS contract after each task.
- At each wave boundary, run all changed Configure/Support modules plus the route and CSS contracts.
- Before Phase 153 verification, run formatting, `git diff --check`, all affected route tests, and `mix test.fast`; report a slow or interrupted run as incomplete.
- Phase 154 performs the final current-source browser review, screenshot comparison, responsive/theme/zoom/keyboard proof, and sensitive-value check.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 153-00-01 | 00 | 0 | UI-01/UI-02/UI-06 | Rendered screenshot baseline | Manual: verify all 30 route images and redaction checks in `153-BASELINE-SCREENSHOTS.md` | ✅ | ✅ passed |
| 153-01-01 | 01 | 1 | UI-01/UI-02/UI-06 | LiveView render | `mix test test/lockspire/web/live/admin/policies_live/index_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-01-02 | 01 | 1 | UI-06 | CSS contract | `mix test test/lockspire/web/live/admin/design_system/css_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-02-01 | 02 | 2 | UI-01/UI-02/UI-06 | LiveView integration | `mix test test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-02-02 | 02 | 2 | UI-01/UI-02/UI-06 | LiveView integration | `mix test test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-03-01 | 03 | 2 | UI-01/UI-02/UI-06/SAFE-01 | LiveView integration | `mix test test/lockspire/web/live/admin/keys_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-03-02 | 03 | 2 | UI-01/UI-02/UI-06/SAFE-01 | LiveView integration | `mix test test/lockspire/web/live/admin/dcr_live_test.exs test/lockspire/web/live/admin/iat_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-04-01 | 04 | 2 | UI-01/UI-02/UI-06/SAFE-01 | LiveView integration | `mix test test/lockspire/web/live/admin/consents_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-04-02 | 04 | 2 | UI-01/UI-02/UI-06/SAFE-01 | LiveView integration | `mix test test/lockspire/web/live/admin/tokens_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-05-01 | 05 | 3 | UI-01/UI-02/UI-06/SAFE-01 | LiveView integration | `mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-05-02 | 05 | 3 | UI-01/UI-02/UI-06/SAFE-01 | LiveView integration | `mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-05-03 | 05 | 3 | UI-01/UI-02/UI-06/SAFE-01 | Route contract | `mix test test/lockspire/web/live/admin/design_system/route_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-06-01 | 06 | 4 | UI-01/UI-02 | Route matrix contract | `mix test test/lockspire/web/live/admin/design_system/route_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 153-06-02 | 06 | 4 | UI-01/UI-02 | Route matrix contract | `mix test test/lockspire/web/live/admin/design_system/route_contract_test.exs --max-failures 1` | ✅ | ✅ green |

The command examples in this table omit the environment prefix for legibility. In this workspace use the full quick-run command above; `.hex` cannot write its default user-home cache here.

## Manual Rendered Verifications

- Open all 30 current paths against the same rebuilt demo source as the Phase 153 code and review the page title, first decision-relevant content, remaining issue or no-change rationale, and protected Phase 151/152 behavior.
- Keep interactions read-only. Do not submit forms, create or rotate credentials, revoke records, or display user/device codes/private key material.
- Plan 00 captures redaction-safe baseline evidence for all 30 paths before any Phase 153 source edit. Use a full-page screenshot when readable; otherwise capture each meaningful section, and record actual image paths plus sensitivity checks in `153-BASELINE-SCREENSHOTS.md`. Phase 154 captures the same route/section set after the cleanup and runs the viewport/theme/keyboard checks.
- Inspect screenshots for credential or sensitive-value leakage before adding them to the project.

## Validation Sign-Off

- [x] Every plan task has an automated verification or a documented manual-only reason
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Existing focused test and route-proof infrastructure covers the planned checks
- [x] No watch-mode flags
- [x] Feedback latency confirmed by execution (17 mapped modules, 219 tests, 2.9s after compile)
- [x] `nyquist_compliant: true` after verification

**Approval:** validated 2026-10-15 (retroactive audit at HEAD cff6ae4e; all mapped commands green)

## Validation Audit 2026-10-16

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
