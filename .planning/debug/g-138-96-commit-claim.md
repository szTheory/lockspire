---
status: diagnosed
trigger: "Diagnose Phase 138 UAT gap G-138-96: determine why 138-34-SUMMARY.md says plan_head_before=5490b0b21c9846045b29af839c126500749958e8 and commits=4 while git rev-list --count 5490b0b21c9846045b29af839c126500749958e8..HEAD is now 78; distinguish a bad summary claim from a measurement-scope issue caused by later commits."
created: 2026-09-24T12:28:15Z
updated: 2026-09-24T12:33:49Z
---

## Current Focus

hypothesis: The blocker requires two conditions: verify-work compares the summary's historical plan base against evolving current HEAD, and later descendants after the plan are present; their combination counts unrelated later commits as if they belonged to the plan.
test: Compare direct `git rev-list` counts at task completion, summary addition, the UAT measurement's matching historical endpoint, and current HEAD; inspect the installed verifier endpoint definition.
expecting: The plan-task boundary should count 4, summary addition should count 5 (the contract's allowed +1), and later descendants should explain the UAT's historical 78 and current 80.
next_action: Return the root-cause-only diagnosis to the orchestrator; no code or planning changes are requested.
bug_class: bohrbug
known_pattern_candidate: none (Phase 0: MemPalace CLI and durable knowledge base are both absent; keyword fallback unavailable)
phase_1_25: skipped; this is a deterministic Git-history measurement with no failing/passing test spectrum or per-test coverage.
candidate_causes:
  - "code: installed verify-work reconciliation evaluates `BASE..HEAD` at verification time although `commits` records the count when the plan completed."
  - "data: the repository has 75 descendants after the summary-add commit, so current HEAD includes later plan, phase, and UAT bookkeeping commits."
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

## Resolution

root_cause: "Two contributing conditions: (1) the installed verify-work contract uses the old plan_head_before as BASE but measures through the evolving current HEAD, although the summary's commits field is measured at plan completion; (2) 75 commits landed after 138-34-SUMMARY.md, so later Phase 138/139 and UAT history is counted as plan 138-34 work. Their conjunction creates a false commit_claim_mismatch. The summary's commits=4 is accurate; BASE..the four task commits is 4, and the summary metadata commit makes it 5, the explicitly accepted +1."
fix: diagnosis-only; no code or planning fix applied
verification: "Direct Git range counts were run at plan-task completion, summary addition, pre-UAT receipt, UAT receipt, and current HEAD; each matched the commit ancestry. The installed verify-work contract was read and confirms it measures BASE..current HEAD."
files_changed: []
