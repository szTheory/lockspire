---
phase: "142"
slug: "merge-the-corrected-main-baseline"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-06"
---

# Phase 142 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only release_train_links` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | Not measured during planning |

---

## Sampling Rate

- **After the local-link contract task:** Run the focused ExUnit command above.
- **After every plan wave:** Run `mix ci`.
- **Before `$gsd-verify-work`:** Require the full contributor gate and exact-SHA hosted evidence to be green for the accepted source SHA.
- **Max feedback latency:** Measure the focused command during execution; keep it as the fast per-task check.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 142-01-01 | 01 | 1 | TRUTH-06, CI-09 | T-142-01 | Resolve only repository-local links in the maintained release record; fail with the unresolved path. | contract | `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only release_train_links` | Test home exists; add focused assertion | ⬜ pending |
| 142-02-01 | 02 | 2 | TRUTH-06, CI-09 | T-142-02 | Bind readiness to one refreshed full main SHA; stop on a missing or conflicting live release boundary. | exact-SHA acceptance | `bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <40-lowercase-hex-current-main-sha> --format json` | Existing | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The focused release-hygiene contract test is added in the implementation wave; no test framework, package, fixture, or new workflow is needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|------------------|

All repeatable phase properties have automated verification. Normal PR review and authorization for consequential GitHub actions are separate from verification and do not require manual UAT of the same properties.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency measured during execution
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
