---
phase: 110
slug: demo-state-screenshots-docs-and-regression-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 110 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveView tests |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90 seconds for focused admin checks, longer for full suite |

---

## Sampling Rate

- **After every task commit:** Run the task's focused test command.
- **After every plan wave:** Run `mix test test/lockspire/web/live/admin --max-failures 1`.
- **Before `$gsd-verify-work`:** `MIX_ENV=test mix compile --warnings-as-errors`, `git diff --check`, `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`, `mix test test/lockspire/web/live/admin --max-failures 1`, and `mix test` must pass or record explicit environment blockers.
- **Max feedback latency:** 90 seconds for focused checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 110-01-01 | 01 | 1 | CONFIG-03 | T-110-01 | Demo seeds remain artificial and redaction-safe | source/test | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 110-01-02 | 01 | 1 | CONFIG-03 | T-110-01 | Copy-once states are represented without persisting later plaintext | source/test | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 110-02-01 | 02 | 1 | PROOF-01 | T-110-02 | Operator docs preserve host-owned boundary | source/test | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 110-02-02 | 02 | 1 | PROOF-02 | T-110-03 | Screenshot/browser inventories do not become runtime dependencies | source/test | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 110-03-01 | 03 | 2 | PROOF-03 | T-110-03 | Deterministic tests fail on missing route/inventory/docs proof | source/test | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 110-03-02 | 03 | 2 | PROOF-03 | T-110-01 | Deterministic tests fence redaction and copy-once proof | source/test | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 110-04-01 | 04 | 3 | PROOF-02 | T-110-03 | Desktop/mobile evidence is route-complete or explicitly gapped | browser/manual plus source/test | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 110-04-02 | 04 | 3 | PROOF-04 | T-110-04 | Final compile/test/diff/browser proof is recorded | CLI/browser | `MIX_ENV=test mix compile --warnings-as-errors && git diff --check && mix test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser screenshot capture for every route | PROOF-02 | The repo has screenshot evidence but no established browser screenshot runner in source | Start the adoption demo with seeded state, capture desktop and 390px mobile screenshots for every route in `110-SCREENSHOTS.md`, and record path/browser note or `Not captured - <reason>` |
| Mobile no-page-overflow proof at 390px | PROOF-04 | Requires browser viewport inspection | Visit each route in the inventory at 390px width and record pass/gap notes in `110-BROWSER-EVIDENCE.md` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for focused checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
