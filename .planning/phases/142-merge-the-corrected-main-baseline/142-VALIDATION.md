---
phase: "142"
slug: "merge-the-corrected-main-baseline"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| **Estimated runtime** | About 36 minutes for `mix ci` on Elixir 1.19.5 / OTP 28 in this workspace |

---

## Sampling Rate

- **After 142-01-01:** Run the focused ExUnit command above, first red on the broken pointer and then green on the repair.
- **After 142-01-02:** Run the focused archived-path checks and complete `mix ci`; Phase 141 correction proof remains scoped to that earlier branch head.
- **At Wave 2 / 142-04-01:** Read back the live disabled auto-merge workflow, main-only environment branch rule, actual reviewer and self-review setting, zero active publication runs, and main protection including all seven CI contexts and the selected approval count. These hosted controls precede repository remediation.
- **After 142-04-02:** Run the exact portable `Release Hygiene Drift` Node command, including archived-root and child exit cases.
- **After 142-04-03:** Run the focused release-workflow ExUnit contract, then `mix ci`; verify both release variables remain unset/closed and the hosted hold is still effective.
- **At Wave 3:** Plan 02 pushes the remediation, verifies hosted required checks for the final PR head, proves the actual GitHub review policy is satisfied, repeats live release-state queries, then reaches the separate exact-head human merge decision.
- **At Wave 4:** Plan 03 repeats hosted controls and approval-policy checks immediately before the authorized merge. The maintained `--accept-sha` command reruns local `mix ci` and binds hosted CI and Release no-publish to the post-merge main SHA. Avoid a separate redundant `mix ci` run.
- **Before `$gsd-verify-work`:** Confirm the result record identifies the exact accepted source and the later record commit separately, and refresh main identity. Phase 143 revalidates current main before publication.
- **Max feedback latency:** Measure the focused command during execution; hosted CI and the helper's wait are bounded by the existing workflow and `--wait-seconds` controls.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 142-01-01 | 01 | 1 | TRUTH-06, CI-09 | T-142-01 | Resolve only repository-local links in the maintained release record; fail with the unresolved path. | contract | `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only release_train_links` | Yes | ✅ pass (one selected test) |
| 142-01-02 | 01 | 1 | CI-09 | T-142-02 | Repair current-source archive paths and exact-parent fixtures, then pass the full contributor gate. | automated | `mix ci` | Existing | ✅ pass (exit 0; integration suite: 102 tests, 0 failures) |
| 142-04-01 | 04 | 2 | TRUTH-06, CI-09 | T-142-09, T-142-11 | Host must disable old auto-merge, require explicit deployment approval, preserve main-only environment policy, verify zero active publish runs and enforce the seven CI contexts plus a real PR approval count. | hosted setting read-back | `gh api` workflow/environment/branch-protection GETs, including reviewer mode and approval-count join | Existing | ✅ pass — live settings and complete run inventory recorded in 142-04 and 142-02 summaries |
| 142-04-02 | 04 | 2 | CI-09 | T-142-12 | Archived-layout project roots route the portable finalizer without masking timeout, signal or child failures. | focused Node suite | `LOCKSPIRE_SKIP_BEAM_INTEGRATION=1 LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` | Existing; regression cases added in task | ✅ pass — 21 passed, 2 skipped, 0 failed |
| 142-04-03 | 04 | 2 | TRUTH-06, CI-09 | T-142-10 | Default-deny release guards require a fresh remote-main SHA equal to the authorized and previously verified SHA immediately before Hex upload; Phase 142 variables stay closed. | focused contract and contributor gate | `mix test test/lockspire/release_ci_evidence_contract_test.exs`; `mix ci`; paginated `gh api` variable read-back | Existing; contract extended in task | ✅ pass — contract, `mix ci`, absent variables and default-deny path recorded in 142-04 summary |
| 142-02-01 | 02 | 3 | TRUTH-06, CI-09 | T-142-03, T-142-11 | Update PR #112, require seven green hosted checks, prove the configured review count is met for its final head, and query live release timing and holds. | hosted checks | `gh pr checks --required`; `gh pr view 112 --json mergeable,reviewDecision,headRefOid`; paginated `gh api` PR and workflow queries | Existing | ✅ pass — exact head, seven checks, policy and timing rechecked before merge |
| 142-02-02 | 02 | 3 | TRUTH-06 | T-142-04 | Bind the separate human merge decision to one PR URL and full head SHA. | decision checkpoint | `gh pr checks --required` plus explicit authorization | Existing | ✅ pass — user authorization recorded for PR #112 at the full reviewed SHA |
| 142-03-01 | 03 | 4 | TRUTH-06 | T-142-05, T-142-08 | Recheck live timing, release holds, required checks and the actual GitHub review policy immediately before the approved PR merge, then capture its full merge SHA. | hosted merge | `gh pr view <approved PR URL> --json state,mergeCommit` | Existing | ✅ pass — squash merge source SHA `5e18d118091a47966bb29300de1fd453bb0880aa` |
| 142-03-02 | 03 | 4 | CI-09 | T-142-06, T-142-07 | Refresh local and remote main, then require the maintained helper's complete exact-SHA receipt including seven canonical jobs, no BLOCK and one disposition per WARN. | exact-SHA acceptance | `bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <post-merge-main-SHA> --format json` with actual WARN disposition arguments; `jq -e` on its successful receipt | Existing | ✅ pass — exact-SHA receipt has local CI pass, seven jobs, 0 BLOCK, 0 WARN, Release `no_publish` |
| 142-03-03 | 03 | 4 | TRUTH-06, CI-09 | T-142-07 | Record the accepted source, matching receipt, fresh public truth and Phase 143 boundary while main remains at the accepted source. | durable evidence | `git diff --cached --check`; refreshed `main == origin/main` | Result file added in task | ✅ pass — 142-RESULT.md identifies accepted source and separate record commit |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Wave 2 extends the existing Node and ExUnit contracts and GitHub workflow files; it adds no package or test framework.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|------------------|
| Explicit squash authorization for PR #112 at its reviewed full head SHA | TRUTH-06 | GitHub merge authority comes from a human decision, not a deterministic code test. | See 142-02-SUMMARY.md and 142-03-SUMMARY.md; authorization was conditional on all seven required checks remaining green. |
| Live branch protection, environment reviewer, release hold, authorization variables and active-run inventory | TRUTH-06, CI-09 | Hosted policy and run state can change and must be queried immediately before a consequential action. | See timestamped readbacks in 142-04-SUMMARY.md and 142-02-SUMMARY.md; protected publication actions remained held. |
| Public Hex and GitHub release truth | TRUTH-06 | Registry and release records are external, mutable facts rather than repository behavior. | Re-query the linked public APIs in 142-RESULT.md before future release decisions; the 2026-10-07 observation found 1.5.0 latest and no 1.5.1. |

All repeatable phase properties have automated verification. The only planned Phase 142 human checkpoint is exact PR review and merge authorization. The environment approval gate remains closed until Phase 143. A live timing conflict stops execution with the blocker named.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency remained bounded by focused tests and the exact-SHA helper's 1800-second CI wait; task-level durations and the bounded command are recorded in the plan summaries.
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-10-07

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 8 |
| Escalated | 0 |
