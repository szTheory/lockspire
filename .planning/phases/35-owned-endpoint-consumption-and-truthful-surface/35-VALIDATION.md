---
phase: 35
slug: owned-endpoint-consumption-and-truthful-surface
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-28
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix on Elixir `1.19.5` |
| **Config file** | `mix.exs` aliases and `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/web/userinfo_controller_test.exs -x` |
| **Full suite command** | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` |
| **Estimated runtime** | ~35 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest task-local command from the per-task verification map; default smoke command is `MIX_ENV=test mix test test/lockspire/web/userinfo_controller_test.exs -x`
- **After every plan wave:** Run `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/web/userinfo_controller_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/web/registration_json_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs -x`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 35 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | DPoP-09 | T-35-01 | Protocol-owned protected-resource DPoP validation enforces `Authorization: DPoP`, `ath`, durable `cnf.jkt`, and replay recording for bound tokens | protocol seam | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/protected_resource_dpop_test.exs -x` | ❌ Wave 0 | ⬜ pending |
| 35-01-02 | 01 | 1 | DPoP-09 | T-35-03 | `userinfo` preserves bearer clients, rejects bearer downgrade for bound tokens, and returns standards-shaped DPoP-aware challenges | controller + protocol | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/web/userinfo_controller_test.exs -x` | ✅ | ⬜ pending |
| 35-03-01 | 03 | 1 | DPoP-11 | T-35-07 | DCR create/read/update round-trips `dpop_bound_access_tokens` through durable `client.dpop_policy` | protocol + JSON | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/web/registration_json_test.exs -x` | ✅ | ⬜ pending |
| 35-03-02 | 03 | 1 | DPoP-11 | T-35-08 | Admin global/client workflows expose explicit DPoP policy without widening beyond existing LiveView patterns | liveview | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/clients_live_test.exs -x` | ❌ Wave 0 | ⬜ pending |
| 35-02-01 | 02 | 2 | DPoP-10 | T-35-04 | Discovery publishes `dpop_signing_alg_values_supported` only when the owned DPoP slice is really mounted and uses the validator allowlist | protocol + controller | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs -x` | ✅ | ⬜ pending |
| 35-02-02 | 02 | 2 | DPoP-10 | T-35-05 | Supported-surface docs and release contract tests pin the narrow DPoP claim set and reject generic host protected-resource support claims | contract | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs -x` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/protocol/protected_resource_dpop_test.exs` — protocol-owned proof for `ath`, durable `cnf.jkt`, replay, and DPoP auth-scheme enforcement in the new protected-resource helper.
- [ ] `test/lockspire/web/live/admin/policies_live/dpop_test.exs` — global DPoP policy page route and persistence proof mirroring the PAR admin pattern.

---

## Manual-Only Verifications

- All phase behaviors are expected to have automated proof; no manual-only acceptance is planned.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
