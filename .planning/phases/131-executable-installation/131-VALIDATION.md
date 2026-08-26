---
phase: 131
slug: executable-installation
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-26
---

# Phase 131 — Validation Strategy

> Per-phase validation contract for executable installation feedback during implementation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Mix 1.19.5 with Phoenix 1.8 and LiveView 1.1+ |
| **Config file** | `mix.exs`, `test/test_helper.exs`, and `test/support/fixtures/generated_host_app` |
| **Quick run command** | `mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` |
| **Full suite command** | `mix test.fast && mix test.integration && mix qa && mix docs.verify` |
| **Estimated runtime** | Quick feedback under 90 seconds; full gate under 10 minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest affected ExUnit file plus the quick installation suite.
- **After every plan wave:** Run `mix test.fast` and the generated-host integration tests.
- **Before `$gsd-verify-work`:** `mix test.fast && mix test.integration && mix qa && mix docs.verify` must be green.
- **Max feedback latency:** 90 seconds for task-level checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 131-01-T1 | 131-01 | 1 | INST-01 | T-131-01 | Guarded admin routes precede public forwarding and actual generated route AST is compiled. | compile + integration | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| 131-03-T1/T2 | 131-03 | 2 | INST-02 | T-131-09, T-131-10, T-131-11 | The installer renders the consent template; emitted bytes equal the executable fixture; that module compiles, is selected by the compiled router, binds the current subject, is visited/submitted, and never exposes sensitive protocol state. | template compile + LiveView + HTTP integration | `mix test test/integration/install_generator_test.exs && mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` | ✅ generator file / ❌ W0 behavior | ⬜ pending |
| 131-07-T1/T2 | 131-07 | 5 | INST-02 | T-131-25, T-131-26, T-131-27 | The exact installer-rendered consent LiveView first shows a control-free semantic loading status, then asynchronously resolves authoritative state into populated/empty/error/terminal behavior while preserving supported submission and redaction. | template parity + LiveView async + HTTP integration | `mix test test/integration/install_generator_test.exs && mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` | ✅ existing files / ❌ loading behavior | ⬜ pending |
| 131-02-T1/T2 then 131-04-T1/T2 | 131-02 then 131-04 | 1 then 2 | INST-03 | T-131-05, T-131-06, T-131-14, T-131-15, T-131-16 | One immutable operation plan validates all migration and managed destinations; fresh managed or migration collision leaves both artifact classes, directories, and manifest unchanged through the public install/upgrade entry points. | filesystem + public-orchestration integration | `mix test test/lockspire/install/migrations_test.exs test/integration/install_upgrade_test.exs` | ❌ W0 | ⬜ pending |
| 131-06-T1 | 131-06 | 4 | INST-04 | T-131-23 | Every missing host seam is reported independently with actionable remediation. | unit + Mix task | `mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` | ✅ | ⬜ pending |
| 131-05-T1/T2 | 131-05 | 3 | INST-05 | T-131-18 | Default-profile proof succeeds without weakening defaults; FAPI proof remains explicit opt-in. | generated-host integration | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| 131-01-T2 | 131-01 | 1 | INST-06 | T-131-03 | Rendered claims resolver compiles against the real `%Lockspire.Host.Claims{}` contract. | template compile | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Planner replaces TBD task/plan/wave identifiers when plans are authored.*

---

## Wave 0 Requirements

- [ ] Compile a generated host router fixture that imports the rendered macro rather than spelling routes independently.
- [ ] Render the consent template through public installation, assert byte parity with the committed executable fixture, compile the emitted module unchanged, confirm `Phoenix.Router.routes/1` selects it, and exercise its LiveView visit/submission against a stored interaction.
- [ ] Add a bounded `with_test_source_root/2` package migration fixture seam that is process-scoped, test-environment-only, restored in `after`, absent from CLI switches, and used around the real public install/upgrade entry points.
- [ ] Add immutable all-artifact operation-plan proof: fresh managed collision and fresh migration identity/content collision each preserve a complete pre/post tree snapshot with no new directories, managed files, migration files, or manifest.
- [ ] Compile rendered resolver, consent LiveView, router macro, config, and default-smoke templates.
- [ ] Separate default-profile generated smoke from explicitly selected FAPI proof.

---

## ASVS L1 Control-to-Automated-Test Gate

Every high-severity threat in Plans 131-01 through 131-06 is blocking. The corresponding command must be green before that plan may write its SUMMARY; an unresolved high-severity threat blocks Phase 131 completion regardless of other requirement tests.

| ASVS L1 area | High-severity threats | Named automated evidence |
|---|---|---|
| V4 Access Control — guarded admin route ordering | T-131-01, T-131-22 | `mix test test/integration/install_generator_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` |
| V5 Validation — generated router structure and migration/file identity | T-131-02, T-131-05, T-131-06, T-131-14, T-131-16 | `mix test test/integration/install_generator_test.exs test/lockspire/install/migrations_test.exs test/integration/install_upgrade_test.exs` |
| V4 Access Control — consent subject/state binding | T-131-09, T-131-10 | `mix test test/lockspire/web/consent_context_test.exs test/lockspire/web/live/consent_live_test.exs && mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` |
| V4 Access Control — generated consent remains non-interactive before authoritative resolution | T-131-25, T-131-27 | `mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` |
| V7 Error Handling — consent/verification redaction | T-131-11, T-131-24 | `mix test test/integration/install_generator_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs && mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` |
| V7 Error Handling — deferred consent failures remain redaction-safe | T-131-26 | `mix test test/integration/install_generator_test.exs && mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` |
| V4 Access Control — manifest metadata is audit-only | T-131-15 | `mix test test/integration/install_upgrade_test.exs` |
| V6 Cryptography and V14 Configuration — default/FAPI proof boundary | T-131-18, T-131-19, T-131-20 | `mix test test/integration/install_generator_test.exs` |
| V14 Configuration — independent fail-closed verification | T-131-23 | `mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` |

---

## Manual-Only Verifications

All Phase 131 behaviors have automated verification. Host-specific branding is constrained by the UI contract and is not visually redesigned in this phase.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Task feedback latency remains under 90 seconds.
- [ ] Every high-severity threat has green named ASVS L1 automated evidence; unresolved high-severity threats block plan and phase completion.
- [ ] `nyquist_compliant: true` set in frontmatter after implementation evidence exists.

**Approval:** pending
