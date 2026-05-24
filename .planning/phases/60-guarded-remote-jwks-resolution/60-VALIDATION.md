---
phase: 60
slug: guarded-remote-jwks-resolution
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with `Req.Test` transport doubles |
| **Config file** | `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs test/lockspire/jwks_fetcher/target_safety_test.exs` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs`
- **After every plan wave:** Run `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs test/lockspire/jwks_fetcher/target_safety_test.exs`
- **Before `$gsd-verify-work`:** Full phase fetcher suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | JWKS-01 | T-60-01 / T-60-02 | `https`-only fetch path, redirects disabled, retries disabled, strict timeout/failure normalization | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs` | ✅ existing | ✅ green |
| 60-02-01 | 02 | 2 | JWKS-01, JWKS-02 | T-60-03 / T-60-04 | Unsafe resolved targets and oversized payloads fail closed before trust is widened | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs test/lockspire/jwks_fetcher/target_safety_test.exs` | ✅ existing | ✅ green |
| 60-03-01 | 03 | 3 | JWKS-03 | T-60-05 | Cached keys use explicit TTL semantics and one bounded forced-refresh path for ordinary rotation | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs test/lockspire/jwks_fetcher/target_safety_test.exs` | ✅ existing | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ new*

---

## Wave 0 Requirements

- [x] `test/lockspire/jwks_fetcher/target_safety_test.exs` — deterministic proof for unsafe-address classification and resolution error handling

---

## Manual-Only Verifications

All Phase 60 behaviors should be covered by automated ExUnit tests.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
