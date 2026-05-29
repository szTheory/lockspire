---
phase: 102
slug: generated-host-scaffolding-telemetry-migration
status: draft
nyquist_compliant: false
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
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~varies (see RESEARCH.md Validation Architecture) |

---

## Sampling Rate

- **After every task commit:** Run the relevant focused test file (`mix test <file>`)
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** keep focused runs sub-minute

---

## Per-Task Verification Map

> Populated by gsd-planner / gsd-executor from RESEARCH.md `## Validation Architecture`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | — | — | SCAFFOLD-01 | — | uncomment-ready canonical block guard | unit | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| TBD | — | — | SCAFFOLD-02 | — | no-format-prompt refute guard | unit | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| TBD | — | — | TELEMETRY-01 | — | telemetry event emitted at both sites | unit | `mix test test/lockspire/plug/verify_token_test.exs` | ✅ | ⬜ pending |
| TBD | — | — | MIGRATE-01 | — | migration guide contract pins | unit | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| TBD | — | — | MIGRATE-02 | — | doctor token_format diagnostic | unit | `mix test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing ExUnit infrastructure covers all phase requirements — no new framework install needed.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification (regression guards, telemetry capture-handler tests, contract-test pins, doctor task test).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency reasonable
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
