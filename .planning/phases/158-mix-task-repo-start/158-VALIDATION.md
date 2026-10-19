---
phase: "158"
slug: "mix-task-repo-start"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-18"
---

# Phase 158 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (qa on Elixir 1.19.5-otp-28) + Python clean-room acceptance harness |
| **Config file** | `config/test.exs`, `test/test_helper.exs` (`:integration` excluded by default unless an explicit `.exs` path is given) |
| **Quick run command** | `MIX_ENV=test mix test <changed test file>.exs` |
| **Full suite command** | `MIX_ENV=test mix test.fast` ; then `mix test --only integration` and `python3 scripts/acceptance/clean_room_saas_journey.py --only happy_path` |
| **Env prefix** | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` |
| **Estimated runtime** | quick ~10 s; clean-room happy_path ~47 s (warm deps) |

---

## Sampling Rate

- **After every task commit:** Run the single new/changed test file via `MIX_ENV=test mix test <file>.exs`
- **After every plan wave:** `MIX_ENV=test mix test test/lockspire test/mix test/integration`, `mix format --check-formatted`, `mix compile --warnings-as-errors`
- **Before `/gsd-verify-work`:** `mix test.fast`, `mix test --only integration`, clean-room `--only happy_path` all green
- **Max feedback latency:** 60 seconds (excluding clean-room)

---

## Per-Task Verification Map

Task IDs are filled in by the planner; the requirement → command map below is binding.

| Requirement / SC | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|------------------|-----------------|-----------|-------------------|-------------|--------|
| TASK-01 / SC1 client.create cold | repo started and stopped by task | integration | `MIX_ENV=test mix test test/mix/tasks/lockspire_client_create_cold_test.exs` | ❌ W0 | ⬜ pending |
| TASK-01 / SC1 token_format cold | output names seeded client | integration | `MIX_ENV=test mix test test/mix/tasks/lockspire_doctor_token_format_cold_test.exs` | ❌ W0 | ⬜ pending |
| TASK-01 / SC1 remote_jwks cold | not_applicable, exit 0 | integration | `MIX_ENV=test mix test test/mix/tasks/lockspire_doctor_remote_jwks_cold_test.exs` | ❌ W0 | ⬜ pending |
| TASK-01 / SC1 clean room | reproduce then green, secret redacted | acceptance | `python3 scripts/acceptance/clean_room_saas_journey.py --only happy_path` | extend | ⬜ pending |
| TASK-03 / SC2 pool untouched | whereis pid, lookup_meta pid, no :DOWN, row visible | unit | `MIX_ENV=test mix test test/lockspire/install/repo_runner_test.exs` | extend | ⬜ pending |
| TASK-02 / SC3 real reason | fixed safe phrases, no "repo unavailable" for domain errors | unit | `MIX_ENV=test mix test test/lockspire/install/task_error_test.exs` | ❌ W0 | ⬜ pending |
| TASK-02 / SC3 secret once | secret printed once after write; Inspect hides secret | unit | `MIX_ENV=test mix test test/lockspire/clients_test.exs` | extend | ⬜ pending |
| SAFE-02 / SC4 log safety | no secret/hash/verifier in debug logs | integration | cold client.create module with `capture_log(level: :debug)` | ❌ W0 | ⬜ pending |
| SC4 doctor semantics | exit codes/output shape unchanged | unit | `MIX_ENV=test mix test test/mix/tasks/lockspire_doctor_token_format_test.exs test/mix/tasks/lockspire_doctor_remote_jwks_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/mix_repo_helpers.ex` — repo-stopped assertions, pool fingerprint, prefix cleanup, task runner
- [ ] Three cold `:integration` task test modules (client.create, token_format, remote_jwks)
- [ ] Classifier unit test for the shared task error helper
- [ ] Clean-room output-capturing `run_child_command` variant + three steps (reproduce-first commit)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Telemetry under `app.config` only (D-19) | TASK-01 | Observation recorded in SUMMARY, no code change | Inspect clean-room `client.create` run; record result |
| Reproduce-first evidence (failing command, redacted tail, SHA) | TASK-01 | Historical evidence of pre-fix state | Record in plan SUMMARY from the first clean-room run |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
