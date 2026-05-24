---
phase: 65
slug: release-truth-support-contract-reconciliation
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 65 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/lockspire/release_readiness_contract_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~1 second measured in this workspace |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/release_readiness_contract_test.exs`
- **After every plan wave:** Run `mix ci`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 65-01-01 | 01 | 1 | TRUTH-01 | T-65-01-01 / T-65-01-03 | Version metadata, manifest, and changelog converge on one truthful release posture with explicit fallback handling | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 65-01-02 | 01 | 1 | TRUTH-01 | T-65-01-02 | Checked-in release workflow and release-please contract stay aligned with the same artifact posture | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 65-02-01 | 02 | 2 | TRUTH-02 | T-65-02-01 / T-65-02-03 | Canonical support contract stays narrow to repo-proven embedded surface | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 65-02-02 | 02 | 2 | TRUTH-02 | T-65-02-02 | README and SECURITY remain subordinate and non-broadening | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 65-03-01 | 03 | 3 | TRUTH-01, TRUTH-02 | T-65-03-01 | Maintainer guide stays operational and secondary to the canonical contract | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 65-03-02 | 03 | 3 | TRUTH-01, TRUTH-02 | T-65-03-02 / T-65-03-03 | Cross-file drift fence covers metadata, changelog, workflow/config, and doc hierarchy | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `65-01` Task 1 strengthens `test/lockspire/release_readiness_contract_test.exs` before artifact or public-doc posture changes begin
- [x] Per-task sampling uses the measured targeted contract test runtime
- [x] Early release-truth coverage exists for metadata plus workflow/config agreement before later doc-hierarchy tightening

*Existing infrastructure plus `65-01` Task 1 covers the required Wave 0 baseline.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Protected `hex-publish` environment settings still match maintainer guidance | TRUTH-01 | GitHub environment restrictions and secret placement live outside git | Verify branch restriction to `main`, intended bypass posture, and environment-scoped `HEX_API_KEY` in repository settings before cutting the authoritative `1.0.0` release |
| Public Hex artifact matches the merged repo version after release | TRUTH-01 | Publication happens outside local repo state | After release workflow completes, confirm `mix hex.info lockspire` reports the same version asserted by `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
