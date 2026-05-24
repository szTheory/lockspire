---
phase: 63
slug: canonical-install-path-host-diagnostics
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 63 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` / `config/test.exs` |
| **Quick run command** | `mix test test/integration/install_generator_test.exs` |
| **Full suite command** | `mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/integration/phase6_onboarding_e2e_test.exs test/lockspire/application_test.exs test/lockspire/config_test.exs test/mix/tasks/lockspire_verify_test.exs test/lockspire/install/verify_test.exs` |
| **Estimated runtime** | ~90 seconds |

## Sampling Rate

- After every task commit: run the task-local `mix test ...` command from the plan.
- After every plan wave: run the full suite command above.
- Before `$gsd-verify-work`: the full suite command must be green.
- Max feedback latency: 90 seconds.

## Wave Plan

| Wave | Plans | Validation focus |
|------|-------|------------------|
| 1 | `63-01`, `63-02` | generator/bootstrap safety plus verify-command negative/positive diagnostics |
| 2 | `63-03` | manifest creation, dry-run output, managed-file upgrade, host-owned refusal |
| 3 | `63-04` | docs truth plus generated-host router proof |

## Per-Plan Verification Map

| Plan | Requirement | Automated command |
|------|-------------|-------------------|
| `63-01` | `HOST-01`, `HOST-03` | `mix test test/integration/install_generator_test.exs` |
| `63-02` | `HOST-02` | `mix test test/mix/tasks/lockspire_verify_test.exs test/lockspire/install/verify_test.exs test/lockspire/application_test.exs test/lockspire/config_test.exs` |
| `63-03` | `HOST-03` | `mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs` |
| `63-04` | `HOST-01`, `HOST-02`, `HOST-03` | `mix test test/integration/install_generator_test.exs test/integration/phase6_onboarding_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` |

## Source Audit

| Source item | Covered by |
|-------------|------------|
| one canonical generic install path, Sigra as recommended companion only | `63-01`, `63-04` |
| early detection of router, seam, migration, and runtime config mistakes | `63-02`, `63-04` |
| explicit managed-vs-host-owned ownership boundaries and upgrade path | `63-01`, `63-03`, `63-04` |
| truthful generated-host proof for router mount wiring | `63-04` |

## Manual-Only Verifications

All planned phase behaviors should have automated verification. No manual-only behavior is expected for this phase.

## Acceptance Checklist

- [ ] Generated install path no longer depends on pre-existing Lockspire runtime config.
- [ ] Generated files carry explicit ownership classification.
- [ ] `mix lockspire.verify` reports actionable failures for missing wiring, seams, config, and migrations.
- [ ] `mix lockspire.upgrade` updates only unchanged managed files and refuses risky host-owned or drifted edits.
- [ ] Canonical docs and generated smoke proof describe and exercise the same embedded install shape.
