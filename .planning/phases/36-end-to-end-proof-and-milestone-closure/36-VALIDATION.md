---
phase: 36
slug: end-to-end-proof-and-milestone-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix on Elixir `1.19.5` |
| **Config file** | `mix.exs` aliases and `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs -x` |
| **Full suite command** | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest task-local command from the per-task verification map; default smoke command is `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs -x`
- **After every wave:** Run `MIX_ENV=test mix test.setup && MIX_ENV=test mix test --include integration test/integration/phase36_auth_code_dpop_e2e_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/release_readiness_contract_test.exs -x`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | DPoP-12 | T-36-01 | Browser auth-code DPoP issuance succeeds only with a valid proof through the real hosted interaction seam | integration | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test --include integration test/integration/phase36_auth_code_dpop_e2e_test.exs -x` | ❌ Wave 0 | ⬜ pending |
| 36-01-02 | 01 | 1 | DPoP-12 | T-36-02 | Browser-issued bound token succeeds on owned `userinfo` only with DPoP auth scheme and matching proof; misuse stays standards-shaped | integration | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test --include integration test/integration/phase36_auth_code_dpop_e2e_test.exs -x` | ❌ Wave 0 | ⬜ pending |
| 36-02-01 | 02 | 1 | DPoP-13 | T-36-04 | Active introspection exposes persisted `cnf` while bearer responses omit it and inactive responses still collapse | protocol + controller | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs -x` | ✅ | ⬜ pending |
| 36-02-02 | 02 | 1 | DPoP-12, DPoP-13 | T-36-05 | Generated-host device DPoP proof issues a bound token and HTTP introspection returns `active: true` plus `cnf.jkt` | integration | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test --include integration test/integration/phase32_device_flow_token_exchange_e2e_test.exs -x` | ✅ | ⬜ pending |
| 36-03-01 | 03 | 2 | DPoP-14 | T-36-07 | Supported-surface docs and release contract pin the final narrow DPoP claim set including introspection visibility only | contract | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs -x` | ✅ | ⬜ pending |
| 36-03-02 | 03 | 2 | DPoP-14 | T-36-08 | Verification, live planning truth, and explicit archival handoff close only after proof and docs agree | docs + repo checks | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs -x && rg -n 'DPoP-12|DPoP-13|DPoP-14' .planning/REQUIREMENTS.md .planning/phases/36-end-to-end-proof-and-milestone-closure/36-VERIFICATION.md && rg -n 'v1\\.7|Phase 36|DPoP|\\$gsd-complete-milestone' .planning/PROJECT.md .planning/ROADMAP.md .planning/STATE.md .planning/EPIC.md .planning/MILESTONES.md .planning/phases/36-end-to-end-proof-and-milestone-closure/36-VERIFICATION.md` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/integration/phase36_auth_code_dpop_e2e_test.exs` — dedicated browser auth-code DPoP proof through `/authorize`, consent, `/token`, and owned `userinfo`.
- [ ] `.planning/phases/36-end-to-end-proof-and-milestone-closure/36-VERIFICATION.md` — final Phase 36 verification record grounded in the completed proof and contract updates.
- [ ] `36-VERIFICATION.md` explicitly records the immediate follow-on `$gsd-complete-milestone` handoff for archive snapshot creation.

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
