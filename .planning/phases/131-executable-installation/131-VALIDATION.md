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
| 131-TBD-01 | TBD | TBD | INST-01 | T-131-01 | Guarded admin routes precede public forwarding and actual generated route AST is compiled. | compile + integration | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| 131-TBD-02 | TBD | TBD | INST-02 | Consent context binds the current subject and never exposes sensitive protocol state. | LiveView + HTTP integration | `mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` | ❌ W0 | ⬜ pending |
| 131-TBD-03 | TBD | TBD | INST-03 | Migration delivery is atomic, byte-identical, idempotent, and never overwrites host files. | filesystem integration | `mix test test/integration/install_upgrade_test.exs` | ❌ W0 | ⬜ pending |
| 131-TBD-04 | TBD | TBD | INST-04 | Every missing host seam is reported independently with actionable remediation. | unit + Mix task | `mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` | ✅ | ⬜ pending |
| 131-TBD-05 | TBD | TBD | INST-05 | Default-profile proof succeeds without weakening defaults; FAPI proof remains explicit opt-in. | generated-host integration | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| 131-TBD-06 | TBD | TBD | INST-06 | Rendered claims resolver compiles against the real `%Lockspire.Host.Claims{}` contract. | template compile | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Planner replaces TBD task/plan/wave identifiers when plans are authored.*

---

## Wave 0 Requirements

- [ ] Compile a generated host router fixture that imports the rendered macro rather than spelling routes independently.
- [ ] Add a generated-host consent route test covering returned context and the supported completion URL.
- [ ] Add an isolated migration package/host fixture for fresh, repeat, upgrade, and collision cases.
- [ ] Compile rendered resolver, consent LiveView, router macro, config, and default-smoke templates.
- [ ] Separate default-profile generated smoke from explicitly selected FAPI proof.

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
- [ ] `nyquist_compliant: true` set in frontmatter after implementation evidence exists.

**Approval:** pending
