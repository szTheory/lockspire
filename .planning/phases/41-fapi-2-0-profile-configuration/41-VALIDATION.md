---
phase: 41
slug: fapi-2-0-profile-configuration
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-01
---

# Phase 41 — Validation Status

> Phase 41 targeted validation is complete for the shipped code path. Manual live-server conformance remains available as a maintainer follow-up.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | FAPI-01 | — | Schema accepts `:fapi_2_0_security` on ServerPolicy and Client | unit | `mix test test/lockspire/protocol/security_profile_test.exs test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs` | ✅ | ✅ green |
| 41-02-01 | 02 | 2 | FAPI-02 | T-41-01 (param injection) | Plug halts non-PAR requests when profile active | unit | `mix test test/lockspire/protocol/fapi20_enforcer_plug_test.exs` | ✅ | ✅ green |
| 41-02-02 | 02 | 2 | FAPI-03 | T-41-02 (token replay) | Plug halts token/userinfo requests without DPoP/mTLS when profile active | unit | `mix test test/lockspire/protocol/fapi20_enforcer_plug_test.exs` | ✅ | ✅ green |
| 41-03-01 | 03 | 2 | FAPI-01 | — | Admin LiveViews expose global and per-client security profile controls plus mixed-mode warning UI | liveview | `mix test test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ | ✅ green |
| 41-04-01 | 04 | 3 | FAPI-01,02,03 | T-41-03, T-41-07, T-41-16, T-41-17 | End-to-end FAPI flow proves boundary enforcement and in-protocol defense-in-depth for global and per-client modes | integration | `mix test test/integration/phase41_fapi_2_0_e2e_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/lockspire/protocol/fapi20_enforcer_plug_test.exs` — unit tests for FAPI-02, FAPI-03 enforcement at the Plug boundary

*Existing infrastructure (ExUnit, LiveView tests, integration coverage, and the conformance script at `scripts/conformance/fapi2-check.sh`) covers all other phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Admin LiveView UX for setting `security_profile` on ServerPolicy and per-Client | FAPI-01 (config UX) | `Phoenix.LiveViewTest` now covers the functional behavior. Manual review is still useful for operator ergonomics and visual layout, but it is not a blocker for phase truth. | 1. `mix phx.server` 2. Visit `/admin/policies/security-profile` 3. Toggle global profile 4. Visit a client's edit page 5. Toggle per-client override 6. Confirm value persists across reloads |
| Conformance script exits 0 | FAPI-01, FAPI-02, FAPI-03 | Requires running Lockspire with a FAPI client provisioned; the script's exit-0 promise is verifiable only against a live HTTP endpoint, not from ExUnit. The cross-tier defense-in-depth integration tests in Plan 04 Task 1 are the automated guarantee for FAPI 2.0 boundary correctness; this script is the maintainer ergonomics layer. | 1. Boot `mix phx.server` with `ServerPolicy.security_profile = :fapi_2_0_security` and at least one registered client whose `security_profile = :fapi_2_0_security` (or `:inherit`); 2. Run `LOCKSPIRE_CLIENT_ID=<client-id> LOCKSPIRE_BASE_URL=http://localhost:4000 ./scripts/conformance/fapi2-check.sh`; 3. Confirm the script exits 0; 4. Confirm the three probes report PASS — 302 redirect with `error=invalid_request` for non-PAR /authorize, 400 with `invalid_dpop_proof` for /token without DPoP, 401 with `invalid_token` for /userinfo with Bearer auth. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** targeted validation complete; manual live-server conformance probe still pending
