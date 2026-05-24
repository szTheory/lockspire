---
phase: 72
slug: jarm-encryption-and-metadata
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 72 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with `Phoenix.ConnTest`, `Req.Test`, and `Ecto.Adapters.SQL.Sandbox` |
| **Config file** | `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/jarm_test.exs test/lockspire/protocol/authorization_flow_test.exs test/lockspire/protocol/discovery_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/jarm_test.exs test/lockspire/protocol/authorization_flow_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/storage/ecto/client_record_test.exs` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** run the task-local `<automated>` command from the active plan
- **After every plan wave:** run that plan’s full verification command with `--warnings-as-errors`
- **Before `$gsd-verify-work`:** run the full Phase 72 suite above
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 1 | JARM-03 | T-72-01 / T-72-02 | Client persistence accepts only narrow encrypted-JARM metadata and preserves non-encrypted clients unchanged | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/storage/ecto/client_record_test.exs` | ✅ existing | ⬜ pending |
| 72-01-02 | 01 | 1 | JARM-03 | T-72-01 | DCR and RFC 7592 reject partial or incoherent encrypted-JARM metadata and persist coherent values | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs` | ✅ existing | ⬜ pending |
| 72-02-01 | 02 | 2 | JARM-03 | T-72-04 / T-72-05 | Recipient-key resolution uses inline `jwks` or guarded remote `jwks_uri` with one bounded refresh and no retry loops | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/jarm_test.exs` | ✅ existing | ⬜ pending |
| 72-02-02 | 02 | 2 | JARM-03 | T-72-03 / T-72-04 / T-72-05 | Nested sign-then-encrypt JARM stays fail-closed through protocol and browser-visible controller boundaries | integration | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/jarm_test.exs test/lockspire/protocol/authorization_flow_test.exs test/lockspire/web/authorize_controller_test.exs` | ✅ existing | ⬜ pending |
| 72-03-01 | 03 | 3 | JARM-03 | T-72-06 / T-72-07 | Discovery publishes one truthful authorization-response capability contract for signing and encryption at both helper and HTTP endpoint layers | integration | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ existing | ⬜ pending |
| 72-03-02 | 03 | 3 | JARM-03 | T-72-06 | Discovery coverage proves metadata is independent of transient client rows and remote JWKS health | integration | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ new*

---

## Wave 0 Requirements

- [x] Existing controller tests are part of the validation contract for browser-visible redirect and discovery publication behavior
- [x] No new test harness is required; all Phase 72 verification runs on current ExUnit / Phoenix.ConnTest / Req.Test infrastructure

---

## Manual-Only Verifications

All planned Phase 72 behaviors should be covered by automated tests.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all external-surface verification dependencies
- [x] No watch-mode flags
- [x] Feedback latency <= 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned
