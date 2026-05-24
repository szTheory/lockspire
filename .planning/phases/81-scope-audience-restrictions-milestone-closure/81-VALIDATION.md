---
phase: 81
slug: scope-audience-restrictions-milestone-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 81 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.ConnTest / Plug.Test |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs test/lockspire/plug/require_token_test.exs --warnings-as-errors` |
| **Full suite command** | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration && mix docs --warnings-as-errors` |
| **Estimated runtime** | ~90 seconds for targeted Phase 81 proof, longer for full suite |

---

## Sampling Rate

- **After every task commit:** Run the narrowest relevant unit or integration command for the touched file set
- **After every plan wave:** Run the Phase 81 targeted proof slice for that wave
- **Before `$gsd-verify-work`:** Run the full targeted Phase 81 proof suite plus docs/release-readiness checks
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 81-01-01 | 01 | 1 | VAL-PLUG-04 | T-81-01 / T-81-03 | `VerifyToken.init/1` rejects ambiguous or malformed `scopes:` / `audience:` / `audiences:` config before request handling | unit | `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 81-01-02 | 01 | 1 | VAL-PLUG-04 / VAL-DX-01 / VAL-DX-03 | T-81-01 / T-81-02 / T-81-04 | Verified tokens keep the `%AccessToken{}` assigns contract; malformed/mismatched audience and insufficient-scope outcomes become structured failures with differentiated developer-facing logs and no secret leakage | unit | `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 81-02-01 | 02 | 2 | VAL-DX-02 | T-81-05 / T-81-06 | `RequireToken` preserves `401 invalid_token` for token/audience/sender failures and `403 insufficient_scope` for scope-only denials with correct challenge semantics | unit | `MIX_ENV=test mix test test/lockspire/plug/require_token_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 81-02-02 | 02 | 2 | VAL-PLUG-01 / VAL-DX-01 / VAL-BIND-03 | T-81-07 / T-81-08 | Real generated-host routes prove 200 success, 401 missing token, 401 audience mismatch, 403 insufficient scope, and sender-constrained restricted-route behavior | integration | `MIX_ENV=test mix test test/integration/phase81_generated_host_route_protection_e2e_test.exs --include integration --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 81-03-01 | 03 | 3 | VAL-PLUG-01 / VAL-DX-02 | T-81-09 / T-81-10 | Public docs and support-surface wording match the narrow shipped Phoenix API protection claim and are pinned by release-readiness contract tests | docs + unit | `mix docs --warnings-as-errors && MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs --warnings-as-errors` | ✅ existing test / ❌ guide W0 | ⬜ pending |
| 81-03-02 | 03 | 3 | milestone closure | T-81-11 | Verification report cites actual unit, integration, generated-host, and docs-contract evidence before claiming closure | integration + docs | `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs test/lockspire/plug/require_token_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/lockspire/release_readiness_contract_test.exs --include integration --warnings-as-errors` | ❌ W0 for integration/report | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/integration/phase81_generated_host_route_protection_e2e_test.exs` - generated-host routed proof for scope, audience, and sender-constraint semantics
- [ ] `docs/protect-phoenix-api-routes.md` - executable guide aligned to the tested route snippets
- [ ] `.planning/phases/81-scope-audience-restrictions-milestone-closure/81-VERIFICATION.md` - milestone-closing verification artifact

---

## Manual-Only Verifications

All Phase 81 deliverables are expected to have automated proof. No human-only checks should be required for closure.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or explicit Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers missing integration/doc/report artifacts
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 gaps are closed

**Approval:** pending
