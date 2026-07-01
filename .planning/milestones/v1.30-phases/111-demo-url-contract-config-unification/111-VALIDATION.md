---
phase: 111
slug: demo-url-contract-config-unification
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 111 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus Python stdlib smoke |
| **Config file** | Root `mix.exs`, `test/test_helper.exs`; adoption demo has no separate `examples/adoption_demo/test` directory |
| **Quick run command** | `mix format --check-formatted examples/adoption_demo/config/config.exs examples/adoption_demo/priv/repo/seeds.exs examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex && cd examples/adoption_demo && mix compile --warnings-as-errors` |
| **Full suite command** | `cd examples/adoption_demo && mix ecto.setup`, run `mix phx.server`, then from repo root run `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` |
| **Estimated runtime** | ~90-180 seconds, depending on local PostgreSQL and dependency state |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/adoption_demo && mix compile --warnings-as-errors` plus the targeted `rg` command for hard-coded URL drift when URL-bearing files changed.
- **After every plan wave:** Run `mix format --check-formatted` for touched Elixir files, adoption demo compile, `mix ecto.setup`, server startup, and the adoption smoke.
- **Before `$gsd-verify-work`:** The full adoption demo smoke must be green with `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100`.
- **Max feedback latency:** 180 seconds for quick checks; full smoke may exceed this when starting the demo app and database.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 111-01-task-1 | 01 | 1 | URL-01, URL-02 | T-111-01 / T-111-02 | Endpoint URL and issuer derive from one normalized browser-visible base URL | compile + static | `cd examples/adoption_demo && mix compile --warnings-as-errors` | yes | pending |
| 111-01-task-2 | 01 | 1 | URL-05 | T-111-03 / T-111-04 | Public URL does not control bind IP; default bind remains loopback and Docker opts into `0.0.0.0` | compile + compose | `cd examples/adoption_demo && LOCKSPIRE_DEMO_BIND_IP=0.0.0.0 mix compile --warnings-as-errors` | yes | pending |
| 111-02-task-1 | 02 | 2 | URL-01, URL-03 | T-111-05 / T-111-06 | Exact local redirect, registration, interaction, logout, and printed callback URLs derive from the same base URL while external fixtures stay external | static + setup | `cd examples/adoption_demo && mix ecto.setup` | yes | pending |
| 111-02-task-2 | 02 | 2 | URL-01, URL-03 | T-111-05 | Developer copy and authorize params match the seeded local callback URL | compile + static | `cd examples/adoption_demo && mix compile --warnings-as-errors` | yes | pending |
| 111-02-task-3 | 02 | 2 | URL-02, URL-04 | T-111-07 / T-111-08 | Smoke remains base-URL driven and reports expected/actual issuer, endpoint, redirect, and verification URI drift | py_compile + smoke | `python3 -m py_compile scripts/demo/adoption_smoke.py` | yes | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

- [x] `scripts/demo/adoption_smoke.py` exists and is the black-box drift fence for URL-02, URL-03, and URL-04.
- [x] `mix compile --warnings-as-errors` exists for adoption-demo compile checks.
- [x] `mix ecto.setup` exists for repeatable local seed setup.
- [x] No new test framework or package install is required for this phase.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Docker bind env is wired without adding the Phase 112 default app-plus-DB topology | URL-05 | Phase 111 should not broaden Docker topology; compose config review is enough before Phase 112 consumes it | Run `cd examples/adoption_demo && LOCKSPIRE_DEMO_BIND_IP=0.0.0.0 mix compile --warnings-as-errors`; optionally run `docker compose config` from `examples/adoption_demo` and confirm the web service sets the bind env only |
| External partner fixture URLs remain external | URL-03 | This is a seed-content intent check, not a dynamic behavior | Inspect `examples/adoption_demo/priv/repo/seeds.exs` and confirm Northstar, legacy, and other external partner fixture URLs are not rewritten to `LOCKSPIRE_DEMO_BASE_URL` |

---

## Validation Sign-Off

- [x] All planned task shapes have automated verify commands or existing Wave 0 coverage.
- [x] Sampling continuity: no 3 consecutive tasks should proceed without compile, static grep, setup, or smoke proof.
- [x] Wave 0 covers all missing references without adding new framework infrastructure.
- [x] No watch-mode flags.
- [x] Feedback latency target is defined.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
