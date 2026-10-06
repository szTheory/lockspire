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

- **After 142-01-01:** Run the focused ExUnit command above, first red on the broken pointer and then green on the repair.
- **After Wave 1:** Run `mix ci` once on the corrected PR branch and inspect required PR checks.
- **At Wave 2:** Query current PR, Release Please and Release workflow state; obtain explicit review/merge authorization. These are action gates, not manual UAT.
- **At Wave 3:** The maintained `--accept-sha` command reruns local `mix ci` and binds hosted CI and Release no-publish to the post-merge main SHA. Avoid a separate redundant `mix ci` run.
- **Before `$gsd-verify-work`:** Confirm the result record identifies the exact accepted source and the later record commit separately, and refresh main identity. Phase 143 revalidates current main before publication.
- **Max feedback latency:** Measure the focused command during execution; hosted CI and the helper's wait are bounded by the existing workflow and `--wait-seconds` controls.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 142-01-01 | 01 | 1 | TRUTH-06, CI-09 | T-142-01 | Resolve only repository-local links in the maintained release record; fail with the unresolved path. | contract | `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only release_train_links` | Test home exists; add focused assertion | ⬜ pending |
| 142-01-02 | 01 | 1 | TRUTH-06, CI-09 | T-142-02 | Publish the correction and contract as one reviewable PR head after the contributor gate. | contributor/PR | `mix ci`; `gh pr view --json state,baseRefName,headRefOid,url` | Existing | ⬜ pending |
| 142-02-01 | 02 | 2 | TRUTH-06, CI-09 | T-142-03 | Query live Release Please PR and workflow timing plus required PR checks; halt on missing or unsafe evidence. | hosted read-only | `gh pr checks --required`; `gh pr list`; `gh run list` | Existing | ⬜ pending |
| 142-02-02 | 02 | 2 | TRUTH-06 | T-142-04 | Bind human review and merge authorization to one PR URL and full head SHA. | decision checkpoint | `gh pr checks --required` plus explicit authorization | Existing | ⬜ pending |
| 142-03-01 | 03 | 3 | TRUTH-06 | T-142-05, T-142-08 | Recheck live timing immediately before the approved PR merge, then capture its full merge SHA. | hosted merge | `gh pr view <approved PR URL> --json state,mergeCommit` | Existing | ⬜ pending |
| 142-03-02 | 03 | 3 | CI-09 | T-142-06, T-142-07 | Refresh local and remote main, then require the maintained helper's complete exact-SHA receipt including seven canonical jobs, no BLOCK and one disposition per WARN. | exact-SHA acceptance | `bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <post-merge-main-SHA> --format json` with actual WARN disposition arguments; `jq -e` on its successful receipt | Existing | ⬜ pending |
| 142-03-03 | 03 | 3 | TRUTH-06, CI-09 | T-142-07 | Record the accepted source, matching receipt, fresh public truth and Phase 143 boundary while main remains at the accepted source. | durable evidence | `git diff --cached --check`; refreshed `main == origin/main` | Result file added in task | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The focused release-hygiene contract test is added in the implementation wave; no test framework, package, fixture, or new workflow is needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|------------------|

All repeatable phase properties have automated verification. The only planned human checkpoint is exact PR review and merge authorization. A concrete live timing conflict also stops execution, with the blocker named. Neither is manual UAT of CI or hygiene.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency measured during execution
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
