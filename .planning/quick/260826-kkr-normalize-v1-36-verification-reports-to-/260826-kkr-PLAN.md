---
quick_id: 260826-kkr
slug: normalize-v1-36-verification-reports-to-
status: planned
created: 2026-08-26
description: Normalize v1.36 verification reports to canonical frontmatter and fix Phase 126 aggregate summary counting
---

# Quick Task 260826-kkr: Normalize v1.36 Verification Reports

## Objective

Make Phases 126–130 legible to GSD's canonical verification and progress projections without changing the already-established v1.36 verdict or its substantive evidence. Every phase must route as `passed`, and Phase 126 must report five plan summaries for five plans rather than counting the phase-level aggregate as a sixth plan summary.

## Contract Diagnosis

- `gsd-core/bin/lib/verification.cjs` accepts verification state only from a scalar `status` in YAML frontmatter anchored at byte zero; the body-only `**Status:** passed` in `126-VERIFICATION.md` therefore routes as `missing`.
- Phases 127–130 have no `*-VERIFICATION.md`, so they also route as `missing` even though `.planning/milestones/v1.36-VERIFICATION.md` independently verifies their outcomes and requirements.
- `gsd-core/bin/lib/plan-scan.cjs` returns every root `*-SUMMARY.md` in `summaryFiles`; `init.progress` reports that array's length. The unmatched aggregate `.planning/phases/126-trusted-release-path/126-SUMMARY.md` therefore yields `6/5`, although `roadmap.analyze` correctly uses matched PLAN-to-SUMMARY pairs and reports `5/5`.

## Tasks

<task type="auto">
  <name>Task 1: Canonicalize Phase 126 and retire its misleading aggregate summary</name>
  <files>.planning/phases/126-trusted-release-path/126-VERIFICATION.md, .planning/phases/126-trusted-release-path/126-SUMMARY.md</files>
  <action>Rewrite `126-VERIFICATION.md` as a canonical verification report beginning at byte zero with YAML frontmatter containing `phase: 126-trusted-release-path`, `verified: 2026-08-26T16:40:30Z`, `status: passed`, `score: "4/4 must-haves verified"`, and `behavior_unverified: 0`. Preserve the existing release-path proof text and focused command results, then fold in every substantive section from `126-SUMMARY.md`: Delivered, Verification, Commits, and Follow-up. Organize the report around the four Phase 126 roadmap success criteria and all six assigned requirements (`RELEASE-01`, `RELEASE-02`, `RELEASE-03`, `SUPPLY-01`, `SUPPLY-02`, `CI-01`), using `.planning/milestones/v1.36-VERIFICATION.md` and the five plan summaries as evidence sources; do not claim new test execution. After confirming all aggregate content is represented in the verification report, remove `126-SUMMARY.md` so only `126-01-SUMMARY.md` through `126-05-SUMMARY.md` retain the reserved plan-summary suffix. Do not edit `ROADMAP.md`.</action>
  <verify>
    <automated>test ! -e .planning/phases/126-trusted-release-path/126-SUMMARY.md &amp;&amp; test "$(node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query verification.status .planning/phases/126-trusted-release-path | jq -r '.status')" = passed &amp;&amp; node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query init.progress | jq -e '.phases[] | select(.number == "126") | .plan_count == 5 and .summary_count == 5 and .verification_status == "passed"'</automated>
  </verify>
  <done>Phase 126 retains its release, command, commit, and follow-up evidence in one canonical passing verification report; the obsolete aggregate summary is absent; and GSD reports exactly 5/5 plan summaries.</done>
</task>

<task type="auto">
  <name>Task 2: Create canonical passing verification reports for Phases 127–130</name>
  <files>.planning/phases/127-executable-quality-baselines/127-VERIFICATION.md, .planning/phases/128-runtime-dependency-truth/128-VERIFICATION.md, .planning/phases/129-token-endpoint-cohesion/129-VERIFICATION.md, .planning/phases/130-readable-code-sustainable-proof/130-VERIFICATION.md</files>
  <action>Create the four missing reports with byte-zero YAML frontmatter using each full phase slug, `verified: 2026-08-26T16:40:30Z`, `status: passed`, `behavior_unverified: 0`, and roadmap-derived scores of `"4/4 must-haves verified"` for Phases 127, 128, and 129 and `"5/5 must-haves verified"` for Phase 130. For each report, map every roadmap success criterion and every assigned requirement to the live evidence already recorded in `.planning/milestones/v1.36-VERIFICATION.md` and that phase's plan summaries: Phase 127 covers `STATIC-01`, `COVER-01`, `COMPAT-01`, `COMPAT-02`; Phase 128 covers `RUNTIME-01`, `RUNTIME-02`, `ARCH-01`, `ARCH-02`, `ARCH-03`; Phase 129 covers `RUNTIME-03`, `RUNTIME-04`, `ARCH-04`, `STATIC-02`; Phase 130 covers `TEST-01`, `TEST-02`, `CI-02`, `READ-01`, `READ-02`, `CLEAN-01`. Preserve warnings and caveats relevant to each phase, including Phase 130's closed READ-02 contradiction and the milestone's focused-test proof-noise warning. Present historical commands and counts as recorded evidence rather than rerunning or embellishing them. Do not alter the milestone verification, plan summaries, requirements, state, or `ROADMAP.md`.</action>
  <verify>
    <automated>for p in 127 128 129 130; do d=$(find .planning/phases -maxdepth 1 -type d -name "$p-*"); f="$d/$p-VERIFICATION.md"; test -f "$f" &amp;&amp; test "$(head -n 1 "$f")" = '---' &amp;&amp; grep -q '^verified: 2026-08-26T16:40:30Z$' "$f" &amp;&amp; grep -q '^behavior_unverified: 0$' "$f" &amp;&amp; test "$(node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query verification.status "$d" | jq -r '.status')" = passed || exit 1; done</automated>
  </verify>
  <done>Phases 127–130 each have one canonical `status: passed` verification report covering every assigned requirement and roadmap success criterion with the existing v1.36 evidence and caveats intact.</done>
</task>

## Verification

Run the task-level gates, then run:

```bash
node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query init.progress \
  | jq -e '[.phases[] | select(.number == "126" or .number == "127" or .number == "128" or .number == "129" or .number == "130") | {number, plan_count, summary_count, verification_status}] == [{"number":"126","plan_count":5,"summary_count":5,"verification_status":"passed"},{"number":"127","plan_count":3,"summary_count":3,"verification_status":"passed"},{"number":"128","plan_count":6,"summary_count":6,"verification_status":"passed"},{"number":"129","plan_count":8,"summary_count":8,"verification_status":"passed"},{"number":"130","plan_count":8,"summary_count":8,"verification_status":"passed"}]'
git diff --check -- .planning/phases/126-trusted-release-path .planning/phases/127-executable-quality-baselines .planning/phases/128-runtime-dependency-truth .planning/phases/129-token-endpoint-cohesion .planning/phases/130-readable-code-sustainable-proof
git diff --exit-code -- .planning/ROADMAP.md
```

## Source Coverage Audit

| Source | Item | Task | Status |
|---|---|---:|---|
| GOAL | Canonical v1.36 phase verification metadata | 1, 2 | COVERED |
| GOAL | Preserve substantive verification evidence | 1, 2 | COVERED |
| GOAL | Correct Phase 126 aggregate summary count | 1 | COVERED |
| REQ | Phase 126 assigned requirements | 1 | COVERED |
| REQ | Phase 127–130 assigned requirements | 2 | COVERED |
| RESEARCH | No research phase requested | — | EXCLUDED |
| CONTEXT | No CONTEXT.md or locked decisions supplied | — | EXCLUDED |

## Success Criteria

- `verification.status` returns `passed` for every phase from 126 through 130.
- `init.progress` reports the canonical per-plan counts `5/5`, `3/3`, `6/6`, `8/8`, and `8/8` for Phases 126–130.
- The v1.36 milestone verdict, requirement evidence, warnings, and Phase 126 aggregate evidence remain represented without inventing new execution evidence.
- `.planning/ROADMAP.md` is unchanged.
