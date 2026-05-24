---
phase: 31
slug: host-owned-verification-ui-seam
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix controller and LiveView tests |
| **Config file** | `mix.exs` test aliases; no separate config file |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/protocol/device_verification_test.exs test/lockspire/web/controllers/lockspire_verification_controller_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/lockspire/protocol/device_verification_test.exs test/lockspire/web/controllers/lockspire_verification_controller_test.exs`
- **After every plan wave:** Run `MIX_ENV=test mix test`
- **Before `$gsd-verify-work`:** `mix ci` and `mix docs.verify` must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | DEV-04 | T-31-01 | Durable device-authorization records carry verification handles, lifecycle status, and terminal timestamps | integration | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs` | ✅ existing file, new assertions required | ⬜ pending |
| 31-01-02 | 01 | 1 | DEV-04 | T-31-02 | Repository lookup and transition callbacks are row-locked and reject stale terminal transitions | integration | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs` | ✅ existing file, expanded coverage required | ⬜ pending |
| 31-04-01 | 04 | 2 | DEV-04 | T-31-03 | Lookup and approve/deny APIs classify pending vs terminal states correctly and never mutate on raw `user_code` | unit/integration | `MIX_ENV=test mix test test/lockspire/protocol/device_verification_test.exs test/lockspire/protocol/device_authorization_test.exs test/lockspire/web/controllers/device_authorization_controller_test.exs` | ✅ planned in 31-04 | ⬜ pending |
| 31-02-01 | 02 | 3 | DEV-05 | T-31-04 | Prefilled `verification_uri_complete` never auto-submits, auto-looks-up, or auto-mutates on GET in the controller-first starter seam | controller contract | `MIX_ENV=test mix test test/integration/install_generator_test.exs test/lockspire/web/controllers/lockspire_verification_controller_test.exs` | ✅ planned in 31-02 | ⬜ pending |
| 31-03-01 | 03 | 2 | DEV-06 | T-31-07 | Device-flow host guide exists, rate-limit guidance is concrete, and docs wiring points to it | docs / contract | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs && mix docs.verify` | ✅ existing file, expanded assertions planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/lockspire/protocol/device_verification_test.exs` — planned in 31-04 for lookup classification, actor binding, and approve/deny outcomes
- [x] `test/lockspire/web/controllers/lockspire_verification_controller_test.exs` — planned in 31-02 for secure GET/prefill/review behavior in the controller-first path
- [x] `test/integration/install_generator_test.exs` assertions for generated `/verify` files and non-overwrite behavior — expanded in 31-02
- [x] `test/lockspire/release_readiness_contract_test.exs` updates covering the new device-flow host guide and onboarding links — planned in 31-03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host-specific rate limiter package choice (`Hammer`, `PlugAttack`, or custom Plug stack) | DEV-06 | Lockspire documents host-owned integration patterns but cannot execute host app middleware choices inside the library test suite | Review the new host guide example, confirm it covers trusted proxy IP handling, normalized `user_code` keys, IP and code buckets, and neutral 429 behavior |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
