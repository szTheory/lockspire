---
status: resolved
trigger: "Diagnose Phase 138 UAT gap G-138-96: determine why 138-34-SUMMARY.md says plan_head_before=5490b0b21c9846045b29af839c126500749958e8 and commits=4 while git rev-list --count 5490b0b21c9846045b29af839c126500749958e8..HEAD is now 78; distinguish a bad summary claim from a measurement-scope issue caused by later commits."
created: 2026-09-24T12:28:15Z
updated: 2026-10-05T22:23:58Z
---

## Current Focus

hypothesis: Confirmed historical false mismatch — the old verifier used an evolving HEAD for a plan-local commit claim, and later descendants entered that unbounded count.
test: Inspect the exact Phase 138 summary and the installed #4670 reconciliation rule; confirm the original task and summary commit boundaries in Git.
expecting: Satisfied — this summary lacks `plan_head_after`, so the current verifier reports the unbounded count as a WARNING and never a commit_claim_mismatch BLOCKER.
next_action: none
bug_class: bohrbug
known_pattern_candidate: none (Phase 0: MemPalace CLI and durable knowledge base are both absent; keyword fallback unavailable)
phase_1_25: skipped; this is a deterministic Git-history measurement with no failing/passing test spectrum or per-test coverage.
candidate_causes:
  - "code: the historical verify-work reconciliation evaluated `BASE..HEAD` at verification time although `commits` recorded the count when the plan completed."
  - "data: at diagnosis time the repository had 75 descendants after the summary-add commit, including later plan, phase, and UAT bookkeeping commits."
and_gate: "yes — the false mismatch requires both the unbounded current-HEAD endpoint and post-summary descendants; at summary creation the measurement was 4 before the summary commit and 5 after it, which the contract accepts."

## Symptoms

expected: Reconciliation should accept the summary's claimed commit count if its measurement scope and recorded head match the contract.
actual: 138-34-SUMMARY.md claims plan_head_before=5490b0b21c9846045b29af839c126500749958e8 and commits=4, but `git rev-list --count 5490b0b21c9846045b29af839c126500749958e8..HEAD` currently returns 78. First commits after the base are 8a1c3402, a3cb8c53, 31a131ac, 2beab2df, apparently the four plan commits; later phase and unrelated commits follow. Installed verify-work reconciliation contract measures base..current HEAD and treats anything other than claimed or claimed+1 as blocker.
errors: UAT gap G-138-96 reports a claimed-versus-observed commit-count mismatch; no runtime error supplied.
reproduction: Run `git rev-list --count 5490b0b21c9846045b29af839c126500749958e8..HEAD` in the repository and compare the result with `commits=4` in `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-34-SUMMARY.md`.
started: The summary was produced during Phase 138; the mismatch is observed at current HEAD during Phase 139 UAT reconciliation. Exact introduction time is under investigation.

## Eliminated

- hypothesis: The summary's `commits: 4` is a bad or narrated plan count.
  evidence: `git rev-list --count BASE..2beab2df` and `BASE..b09beccd^` both return 4; the four descendants are exactly the four Task Commits in the summary. The summary itself was added by `b09beccd`, making `BASE..b09beccd` equal 5, which the installed contract explicitly accepts as the summary commit.
  timestamp: 2026-09-24T12:33:49Z

## Evidence

- timestamp: 2026-09-24T12:28:15Z
  checked: Phase-0 debug knowledge recall and exact UAT issue
  found: `mempalace` is not installed and `.planning/debug/knowledge-base.md` is absent. UAT Test 96 / G-138-96 states the required measurement is `git rev-list` from `plan_head_before` to current HEAD and reports 78 versus claimed 4.
  implication: No prior debug resolution is available; the UAT's present contract explicitly uses current HEAD, so the next test must establish whether the summary's 4 was accurate at its creation boundary.

- timestamp: 2026-09-24T12:28:15Z
  checked: `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-34-SUMMARY.md`
  found: Summary frontmatter declares `plan_head_before` as `5490b0b21c9846045b29af839c126500749958e8`, `commits: 4`, and lists exactly four task/deviation commits: `8a1c3402`, `a3cb8c53`, `31a131ac`, `2beab2df`.
  implication: The claim is internally aligned with four named plan commits, but Git ancestry/count at the summary-time endpoint remains to be checked.

- timestamp: 2026-09-24T12:30:13Z
  checked: Git ancestry and counts from the declared base
  found: `git rev-list --count BASE..2beab2df` is 4; `BASE..HEAD` is 80 at HEAD `e08c1661f2789051ddc19b83f55704ec752b7f06`; `2beab2df..HEAD` is 76. The first four descendants of BASE are exactly the four commit IDs listed as plan task commits in the summary. The reverse-chronological listing shows Phase 138 closeout, Phase 139, and later UAT commits after them.
  implication: `commits: 4` matches the plan's first four task commits at the plan-local boundary. The current repository count is now 80 (not 78), so the UAT's 78 was observed at an earlier HEAD; its precise endpoint and the summary-file addition boundary remain to be confirmed.

- timestamp: 2026-09-24T12:30:13Z
  checked: Installed verify-work and executor commit-metadata contract; summary file history
  found: `/Users/jon/.codex/gsd-core/workflows/verify-work.md` defines `ACTUAL=$(git rev-list --count "${BASE}"..HEAD)` and accepts only `ACTUAL == CLAIMED` or `CLAIMED + 1`, describing the +1 as the summary/metadata commit. The executor spec says `commits` is measured from a per-plan ledger to HEAD at SUMMARY write. Git history shows `138-34-SUMMARY.md` was added by `b09beccd` after the four listed task commits.
  implication: The summary's field represents the plan's measured task commits; the verifier's later run includes every subsequent descendant because it reuses the old base with today's HEAD. Need verify the exact counts at summary addition and at the UAT's previously reported measurement endpoint before confirming this as root cause.

- timestamp: 2026-09-24T12:33:49Z
  checked: Git count at the summary and UAT receipt boundaries, plus the repository state at diagnosis time
  found: `BASE..b09beccd^`=4 and `BASE..b09beccd`=5; `BASE..c95e4eee^`=78, `BASE..c95e4eee`=79, and current `BASE..e08c1661`=80. `b09beccd..HEAD`=75. Commit `c95e4eee` is the Phase 138 UAT receipt commit and `e08c1661` adds the mismatch report; the reported 78 matches HEAD immediately before `c95e4eee`, while current HEAD includes both later commits.
  implication: The claim was correct at plan-task completion, and its own metadata commit is the one allowed extra commit. The observed 78 is a prior HEAD snapshot; current is 80. Verification of the historical summary becomes time-dependent because all 75 post-summary descendants are included in the same base..current-HEAD range.

- timestamp: 2026-10-05T22:23:58Z
  checked: Exact `138-34-SUMMARY.md` frontmatter, installed `/Users/jon/.codex/gsd-core/workflows/verify-work.md` reconciliation contract, and Git commit boundaries
  found: The summary still has `plan_head_before: 5490b0b21c9846045b29af839c126500749958e8` and `commits: 4`, but no `plan_head_after`. The installed #4670 contract bounds modern summaries to `BASE..AFTER` and classifies older summaries with a base but no `plan_head_after` as WARNING; it explicitly forbids a BLOCKER from the unbounded `BASE..HEAD` count. `BASE..2beab2df` remains 4 and `BASE..b09beccd` remains 5, with `b09beccd` adding the summary.
  implication: The historical claim is accurate and the current verifier no longer makes G-138-96 a blocking commit-claim mismatch. Preserve the original summary and commit history.

## Resolution

root_cause: "The historical verifier compared a plan-local `commits: 4` claim with an unbounded `plan_head_before..HEAD` count after later commits had landed. The four task commits were real; the later descendants made the old check report a false mismatch."
fix: "The installed #4670 verifier now uses `plan_head_after` to bound modern summaries and reports legacy summaries like 138-34, which lack that field, as WARNING rather than BLOCKER. No source or historical-summary edit was needed."
verification: "The exact summary has no `plan_head_after`; the installed verifier explicitly applies legacy WARNING behavior and forbids a BLOCKER from the unbounded count. Git counts remain 4 at the last task commit and 5 at the summary commit."
files_changed: []

## Prevention

- Why not caught earlier: The original reconciliation contract did not record the plan's terminal commit and used the repository's evolving HEAD, so its count changed after unrelated work.
- Recurrence guard: Installed verify-work reconciliation #4670 records and checks `plan_head_after` for modern summaries; older summaries without that boundary produce a WARNING for manual review.
