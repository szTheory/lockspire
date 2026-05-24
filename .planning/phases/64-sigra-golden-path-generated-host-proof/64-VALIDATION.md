---
phase: 64
slug: sigra-golden-path-generated-host-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 64 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` / `config/test.exs` |
| **Quick run command** | `mix test test/integration/phase6_onboarding_e2e_test.exs` |
| **Full suite command** | `mix test test/integration/phase6_onboarding_e2e_test.exs test/integration/phase31_generated_host_verification_e2e_test.exs test/integration/phase37_protocol_strictness_e2e_test.exs test/integration/install_generator_test.exs test/lockspire/host/claims_test.exs test/lockspire/release_readiness_contract_test.exs` |
| **Estimated runtime** | ~75 seconds |

## Sampling Rate

- After every task commit: run the task-local `mix test ...` command from the plan.
- After every plan wave: run the full suite command above.
- Before `$gsd-verify-work`: the full suite command must be green.
- Max feedback latency: 75 seconds.

## Wave Plan

| Wave | Plans | Validation focus |
|------|-------|------------------|
| 1 | `64-01` | generated-host `current_scope` seam, login resume preservation, and browser-flow regressions |
| 2 | `64-02` | canonical auth-code onboarding proof plus generator and claims guidance alignment |
| 3 | `64-03` | doc-truth and release-contract drift fences |

## Per-Plan Verification Map

| Plan | Requirement | Automated command |
|------|-------------|-------------------|
| `64-01` | `SIGRA-02` | `mix test test/integration/phase31_generated_host_verification_e2e_test.exs test/integration/phase37_protocol_strictness_e2e_test.exs` |
| `64-02` | `SIGRA-01`, `SIGRA-02` | `mix test test/integration/phase6_onboarding_e2e_test.exs test/integration/install_generator_test.exs test/lockspire/host/claims_test.exs` |
| `64-03` | `SIGRA-03` | `mix test test/lockspire/release_readiness_contract_test.exs` |

## Source Audit

| Source item | Covered by |
|-------------|------------|
| unauthenticated authorize redirects through the host login seam | `64-01`, `64-02` |
| `return_to` and `interaction_id` survive host login resume | `64-01`, `64-02` |
| account resolution derives from `current_scope.user` | `64-01`, `64-02` |
| canonical claims stay narrow and host-owned | `64-02`, `64-03` |
| one topology and no compile-time Lockspire-to-Sigra dependency | `64-02`, `64-03` |
| companion docs match executable generated-host proof | `64-03` |

## Manual-Only Verifications

All planned Phase 64 behavior should have automated verification. No manual-only verification is expected.

## Acceptance Checklist

- [ ] The generated-host fixture models a Sigra-shaped `current_scope` seam before Lockspire routes execute.
- [ ] Host login bounce preserves both `return_to` and `interaction_id` safely.
- [ ] The canonical onboarding proof starts unauthenticated and completes through the generated host seam.
- [ ] Generated Sigra resolver guidance matches the proof and keeps canonical claim examples narrow.
- [ ] Docs and release-contract tests describe one truthful companion path with no compile-time coupling.
