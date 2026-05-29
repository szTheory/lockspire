---
phase: 102
slug: generated-host-scaffolding-telemetry-migration
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-29
---

# Phase 102 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/lockspire/release_readiness_contract_test.exs` |
| **Full suite command** | `mix ci` (canonical gate) or `mix test` |
| **Estimated runtime** | sub-minute for focused files; full suite varies |

---

## Sampling Rate

- **After every task commit:** Run the relevant focused test file (`mix test <file>`)
- **After every plan wave:** Run `mix test` (watch for telemetry-attach handler leaks across async tests — always `detach` in `on_exit`)
- **Before `/gsd-verify-work`:** `mix ci` green (full canonical gate)
- **Max feedback latency:** keep focused runs sub-minute

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 102-01-T1 | 102-01 | 1 | SCAFFOLD-02 | T-102-01 | no-format-prompt refute over task + generator source | unit (contract) | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 102-01-T2 | 102-01 | 1 | SCAFFOLD-01 | T-102-02, T-102-03 | uncomment-ready RAW-bytes canonical-block guard | unit (contract) | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 102-02-T1 | 102-02 | 1 | TELEMETRY-01 | T-102-04, T-102-06 | telemetry capture test (both sites + literal atom), RED first | unit (plug) | `mix test test/lockspire/plug/verify_token_telemetry_test.exs` | ❌ new | ⬜ pending |
| 102-02-T2 | 102-02 | 1 | TELEMETRY-01 | T-102-05, T-102-07 | direct :telemetry.execute at two sites, no emit/4 | unit (plug) | `mix test test/lockspire/plug/verify_token_telemetry_test.exs test/lockspire/plug/verify_token_test.exs` | ✅ | ⬜ pending |
| 102-03-T1 | 102-03 | 2 | MIGRATE-01 | T-102-08 | honest runtime opt-out doc, no phantom config key | doc + grep | `test -f docs/upgrading/v1.27.md && grep -q "put_access_token_format(:opaque)" docs/upgrading/v1.27.md` | ❌ new | ⬜ pending |
| 102-03-T2 | 102-03 | 2 | MIGRATE-01 | T-102-09 | migration-guide contract pins (opt-out + nil-inherit + refute config key) | unit (contract) | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 102-04-T1 | 102-04 | 1 | MIGRATE-02 | T-102-10, T-102-11, T-102-13 | read-only doctor subtask, reproduced precedence, no raise, dispatcher+help | compile + unit | `mix compile --warnings-as-errors` | ❌ new | ⬜ pending |
| 102-04-T2 | 102-04 | 1 | MIGRATE-02 | T-102-10, T-102-11 | diagnostic report + nil-only flag + precedence parity + help | unit (mix task) | `mix test test/mix/tasks/lockspire_doctor_token_format_test.exs` | ❌ new | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing ExUnit infrastructure covers all phase requirements — no new framework install needed.* The three net-new test files (`verify_token_telemetry_test.exs`, `lockspire_doctor_token_format_test.exs`) and the new contract-test constants/clauses ARE the deliverables; each is created within its own plan rather than a separate Wave 0 plan, because each test pairs directly with the production change it fences (telemetry test ↔ emit sites; doctor test ↔ subtask; contract clauses ↔ scaffolding/migration source).

---

## Manual-Only Verifications

*None.* All phase behaviors have automated verification (regression guards, telemetry capture-handler tests, contract-test pins, doctor task test).

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (net-new test files created in their owning plans)
- [x] No watch-mode flags
- [x] Feedback latency reasonable
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (planned)
