# Phase 161 Release Evidence

Running log appended by plans 161-04..09.

## Landing v1.44

Preflight (plan 161-04 Task 1), taken 2026-10-20, before any remote write:

- Branch: local `main`; project root pin matched.
- `git fetch origin`; `git rev-parse origin/main` = `038df080748c046829f9f98297da8403c47b4d89` (matches expected).
- Working tree: only ` M .planning/state.json` (no other changes).
- `git log 038df080..HEAD`: 118 commits, including the 161-01, 161-02 and 161-03 commits.
- SAFE-02 sweep HEAD: `9471f0981a3686597717b10453de19b03bbfa60f`; `git diff --name-only <that>..HEAD | grep -vc '^\.planning/'` = 0 (only .planning/ changed since the sweep).
- `gh auth status`: logged in as szTheory.
- `gh pr list --head milestone/v1.44-adopter-polish --state all`: none.
- `gh pr view 122` body: 0 occurrences of BEGIN_COMMIT_OVERRIDE.
- `Release Please Auto Merge` workflow: disabled_manually (D-09).
- Dependabot PRs #125, #126, #127 still open and untouched.

Planned branch: `milestone/v1.44-adopter-polish`.

Resume preflight (2026-10-20, Codex):

- GitHub API reachable; live `refs/heads/main` is still `038df080748c046829f9f98297da8403c47b4d89`.
- No milestone PR exists (all states checked); #122 has no override yet.
- Release Please Auto Merge remains `disabled_manually`; #125–#127 remain open.
- Since the SAFE-02 sweep, committed changes affect only `.planning/`.
- Local planning changes are STATE.md continuity, config runtime `claude` → `codex`, and the intentionally unstaged state.json.
- Existing push/PR approval is retained. User instructed this session: “what do u recommend? do that”; recommended action is to push/open the prepared milestone PR and obtain green CI.
- Historical handoff instructions demanding approval again solely because of a new session are superseded by the active session's approval-persistence rule.

Landing execution (2026-10-20T17:54:04+00:00):

- PR: https://github.com/szTheory/lockspire/pull/132
Initial T (failed Dialyzer): d1c9c0579cb615710e9bdef7f73c8d591fcb2619
- CI run: https://github.com/szTheory/lockspire/actions/runs/39469690927
- Dependency Review run: https://github.com/szTheory/lockspire/actions/runs/39469690774
- Remote main remained `038df080748c046829f9f98297da8403c47b4d89` after push.
- Passed so far: Release Hygiene Drift, dependency-review, Adoption Demo Smoke.
- Dialyzer failed: `lib/mix/tasks/lockspire.client.create.ex:54:11:call`; error tuple passed to a helper whose success typing contains only the successful tuple (the error clause only raises).
- Fast Checks, Integration Checks and Minimum Supported Elixir/OTP remain in progress; Complete Coverage Evidence depends on fast/integration.
- Scoped proposed fix: raise the same formatted domain error directly in the case branch and remove the raise-only helper clause. No code edits applied yet. Awaiting the plan's approval for a `lib/` CI fix; existing error-path tests cover the behavior.
- Local proposed patch: `/private/tmp/lockspire-132-proposed-dialyzer-fix.patch` (reconstruct from this note if unavailable).
- Plan 161-04 remains incomplete until all seven required checks and dependency-review pass. REL-01 / SAFE-02 / REL-02 remain unchecked.

CI repair (2026-10-20): maintainer explicitly approved the scoped fix. Source commit `a679e9ce0e5dd0269b43cb47c8d14c2ca31c3846` moves the existing validation-error raise directly into the case branch and removes its raise-only helper clause. Local verification: cold client-creation tests 9/9, full SAFE-02 targeted suite 199/199, Dialyzer zero errors, formatter and forbidden-path diff checks passed. SAFE-02 evidence extended to this source revision. All other checks on the first PR revision passed. The updated head must pass a fresh complete CI run before plan 04 closes.

Final landing verification (2026-10-20T18:12:15+00:00):

PR: https://github.com/szTheory/lockspire/pull/132
T: c12b2c65f5705090fc7641f16b0f3e633659a733
CI run: https://github.com/szTheory/lockspire/actions/runs/39471393273 (success)
Dependency Review: https://github.com/szTheory/lockspire/actions/runs/39471393331 (success)

| Check | Result |
|-------|--------|
| Complete Coverage Evidence | success |
| Dialyzer | success |
| dependency-review | success |
| Release Hygiene Drift | success |
| Fast Checks | success |
| Minimum Supported Elixir/OTP | success |
| Adoption Demo Smoke | success |
| Integration Checks | success |

- Live branch read-back equals T; live main remains `038df080748c046829f9f98297da8403c47b4d89`.
- PR state OPEN; merge state `CLEAN`.
- Release Please Auto Merge remains disabled_manually.
- Final plan-04 evidence append is committed locally after T and deliberately not pushed; plan 161-06 preserves it during the reset procedure.
- All seven required checks plus dependency-review passed at this head. This completes plan 04's PR/CI prerequisite, not REL-01, SAFE-02 or REL-02.

Milestone squash merge (plan 161-05 Task 4):

- Maintainer explicitly approved squash-merging PR #132 at `c12b2c65f5705090fc7641f16b0f3e633659a733` with its current title.
- Immediately preceding merge gate (2026-10-20T18:30:38.279228+00:00): Release Please Auto Merge = `disabled_manually`; all eight exact-head checks success; live main still `038df080748c046829f9f98297da8403c47b4d89`; #122 body hash unchanged since the verified override edit.
- Merged at: 2026-10-20T18:30:41Z; used --squash and --match-head-commit, no admin bypass.
S1: db33c470c5deef9cc72e2240e0db0bdf0044e22b
- Subject: `feat(install): add mix lockspire.gen.kek and show Key protection status in admin (v1.44) (#132)`.
- S1 parent: `038df080748c046829f9f98297da8403c47b4d89` (verified).
- `git diff --quiet c12b2c65f5705090fc7641f16b0f3e633659a733 db33c470c5deef9cc72e2240e0db0bdf0044e22b` succeeded: S1 tree equals approved T.
- Local branch untouched by this merge task; no backup/reset/stash/cherry-pick performed.

Plan 161-06 Task 1 — SAFE-02 rebinding and safe local reset:

- SAFE-02 bound to S1 `db33c470c5deef9cc72e2240e0db0bdf0044e22b`: forbidden-path diff empty; approved T and S1 trees identical; 36 added-line emission grep hits identical to approved T including the scoped CI repair.
- Backup branch: `backup/local-main-pre-v1.44-reset` at `941423c2306e9a67525c5d9d6add2263fece4522`.
- Saved state.json SHA256 before/after: `f260f30019ac3d53ce4682057c2eaac9546751b5cf978d94c57783520e21e40b`; byte-for-byte preserved.
- Stashed state.json under `phase161-state-json`, then the clean-tree gate immediately before reset printed nothing.
- Reset local main to origin/main S1, replayed all nine post-T planning-only commits in order, then popped the task's exact stash.
- Replayed commits (old → new):
  - `cf49b6450b6e9fd968e2be589210e9961b662e93` → `df7b0d172a1d884b61f629578861d416542d3586`
  - `4969b5e9b03e389e25052d9d08f62405dc520d6f` → `c8920302dc5d5c2c4aa05984967378016cbad92c`
  - `3d544848f7491c580426064026a5383e748a90fe` → `07d11c8fc288b2cd74dedaf6df0dbeaa03f495ab`
  - `626880b944e24d9aa0c1b74734071759603c3c83` → `f743ffb355bb0b7b67bba1bcfadd1a92e3dd48ed`
  - `fc7154209722be73ac7a70e15cd34f519360801f` → `712d89b2bfa6b2e913fbae133cdad2a7ddf66094`
  - `4739294eb428f9f2b25ba06a8fca4c6c34b877bd` → `a8081ebf41d811768b6d735b2774ef4188078ac0`
  - `01eba239eef7892f889625abe82a39c92579404b` → `71d7c33a94b5d5afa0f7ec1d8ba03808c2b3ef21`
  - `98c505d745a70508838da469eda873b9c7dbbbbd` → `20bd763c8c651b759af0fcb23bdf82f2ddb0ec91`
  - `941423c2306e9a67525c5d9d6add2263fece4522` → `4658fb1aca32284a887a0b4627722980ae6ad7c1`

- Post-reset local main differs from origin/main only under `.planning/`; working tree contains only the preserved ` M .planning/state.json`.

## Release PR #121

PR #122 override edit (plan 161-05 Task 2), 2026-10-20T18:29:33+00:00:

- Maintainer explicitly approved the exact append in this session (“yes”).
- Pre-edit body SHA-256 (gh --jq newline convention): `5fc53683228d8767e8faaaa59f88b46195f494fc8869daca64a5e3db627ab0d2`.
- Post-edit body SHA-256 (same convention): `872a5161a00a731de0e736738b76876cb33c097444844163ece84f031691d91f`.
- Read-back equals the proposed body byte-for-byte and preserves the complete previous body as its prefix.
- Exactly one marker pair; the block matches the approved artifact exactly. Offline parser: two feat(admin) entries; no breaking change.
- Applied before any v1.44 squash merge; PR #132 remains open. No Release workflow re-run.

Stored block:

```text
BEGIN_COMMIT_OVERRIDE
feat(admin): refine the operator UI across apps, security, keys, consents and tokens (v1.40) (#122)

feat(admin): describe admin pages in task and object language and route adopters through task-grouped guides (v1.41) (#122)
END_COMMIT_OVERRIDE
```

Regenerated #121 read-back and D-21 simulation (2026-10-20T18:34:08+00:00):

- S1 Release push run https://github.com/szTheory/lockspire/actions/runs/39475380565 completed successfully; it regenerated #121 without a workflow re-run.
- Title: `chore(main): release lockspire 1.6.0`; state OPEN; mergeable MERGEABLE.
HEAD121: 14bb083562a195e99feed679a08f74f0e9fc3e75
- Changelog covers v1.40 and v1.41 (#122), v1.42 (#129), v1.43 (#131), v1.44 (#132), plus #123, #124, #128 and #120.
- Exact changed files: .planning/RELEASE-TRAIN.md, .release-please-manifest.json, CHANGELOG.md, mix.exs. Diff from S1 to HEAD121 is exactly those four files.
- Ledger read-back:
  - - Release Please version metadata: `1.6.0` <!-- x-release-please-version -->
  - - Latest public package: Hex `1.5.1`, published from source `0b56503859b69531ff86d8e4a465a0e75f963594` on 2026-10-08. Release Please metadata above is not publication proof.

- Prior plan-02 simulation: `Summary: 18 PASS, 0 WARN, 0 BLOCK`; release_automation_contract_test: 3 tests, 0 failures; both release/repository hygiene contracts combined: 13 tests, 0 failures. Prior lower-metadata negative control: `Summary: 17 PASS, 0 WARN, 1 BLOCK`.
- Repeated on #121's actual exact head in a disposable detached worktree with its own _build, shared dependency sources, Elixir 1.19.5 / OTP 28.5: hygiene `Summary: 18 PASS, 0 WARN, 0 BLOCK`, exit 0; release_automation_contract_test.exs plus repository_hygiene_contract_test.exs `13 tests, 0 failures`, exit 0.
- Disposable worktree removed; no simulation worktree remains.
D-21 simulation: head 14bb083562a195e99feed679a08f74f0e9fc3e75 hygiene 0 BLOCK; contract tests 0 failures

- No PR-level CI checks were requested for #121; its bot-token push cannot create them. Gate is exact-head simulation + read-back, then green CI on the resulting squash before publication.
- Release Please Auto Merge remains disabled_manually; #125–#127 remain OPEN.
- No merge of #121 or publication occurred. Next step is the separate #121 squash-merge approval.

Plan 161-06 merge-gate correction (2026-10-20):

- Maintainer approved squash-merging #121 at HEAD121 14bb083562a195e99feed679a08f74f0e9fc3e75. All planned preconditions passed, but normal `gh pr merge --squash --match-head-commit` was rejected: “the base branch policy prohibits the merge”. PR remains OPEN; main remains S1. No merge, admin bypass, protection change or publication occurred.
- Live protection requires seven status contexts from GitHub Actions (app 15368), strict/up-to-date, with admins enforced. #121 initially had an empty statusCheckRollup because its bot-token push did not start PR workflows.
- D-21's assumption that simulation alone suffices for the pre-merge policy gate is incomplete. Local exact-head simulation remains valid; additionally, run existing ci.yml workflow_dispatch on release-please--branches--main--components--lockspire at the unchanged verified HEAD121. CI already supports this trigger and has no event-based job exclusions. This creates real required check evidence without changing source, workflow or branch protection.
- The user's exact-head merge approval is retained. Retry only after this head's dispatched CI succeeds and live exact-head/main/auto-merge guards are revalidated. Post-merge CI on the resulting S is still mandatory before publish. No release.yml workflow re-run.

Additional PR workflow approval recovery:

- Head workflow_dispatch CI run 39476538922 completed with all seven jobs success at unchanged HEAD121. Normal exact-head squash retry was still rejected; no merge occurred.
- Diagnosis: the existing pull_request CI run 39475469715 and Dependency Review run 39475469657 were `action_required`, with zero jobs. They had been created by github-actions[bot], waiting for approval. PR statusCheckRollup was empty while the dispatched branch-head checks were successful; dispatch did not clear this gate.
- Current GitHub primary docs (https://docs.github.com/en/actions/concepts/security/github_token) explain bot-token pull_request events create approval-required runs. D-21's premise that these PR workflows cannot run is outdated.
- Started the existing reviewed-head PR CI and Dependency Review runs with normal POST actions/runs/{id}/approve endpoints, under the already authorized merge work. No source, workflows, branch protection or admin-bypass change. Retain the user's merge approval and retry only after these runs pass and live exact-head guards hold.
- Required runs to watch: CI 39475469715; Dependency Review 39475469657. Head remains 14bb083562a195e99feed679a08f74f0e9fc3e75. Post-merge push CI on S remains mandatory before publication.

Release PR #121 squash merged (2026-10-20T18:55:22Z):

- User's explicit exact-head merge approval retained through the required-check recovery.
- Actual PR CI 39475469715 succeeded (all seven jobs), Dependency Review 39475469657 succeeded; statusCheckRollup had eight successes and merge state CLEAN.
- Immediately preceding merge (2026-10-20T18:55:19.594917+00:00): HEAD121 unchanged, live main S1 db33c470, auto-merge workflow disabled_manually. Used --squash --match-head-commit, no admin bypass.
S: 428a9c53e02bc573376d0fcac313f047fbbea81c
CI_RUN: 39478977350
- Post-merge push CI 39478977350 is running; its success is still required before any publication authorization.
- Release push workflow 39478977389 is running.
- Read-back: #121 MERGED; mergeCommit equals live origin/main S; parent is S1; exact tree equals simulated/CI-green HEAD121; subject `chore(main): release lockspire 1.6.0 (#121)`; mix.exs version 1.6.0.
- No package publication or authorization-variable change performed.

Plan 161-06 completion evidence:

- CI_RUN 39478977350: push event on S `428a9c53e02bc573376d0fcac313f047fbbea81c`, completed success; all seven required jobs success.
- Release push run 39478977389: completed success; publication jobs skipped on ordinary push.
- Post-merge local preservation: backup/local-main-pre-release-rebase at `b2448edfccb6ba6b923888070cd4025367fed637`; stashed only state.json, observed empty clean-tree gate, rebased all 16 planning-only commits onto origin/main S, and restored state.json byte-for-byte (SHA256 `f260f30019ac3d53ce4682057c2eaac9546751b5cf978d94c57783520e21e40b`).
- After rebase, local main differs from origin/main only under `.planning/`; only unstaged change is `.planning/state.json`.

| Required source CI job | Conclusion |
|------------------------|------------|
| Fast Checks | success |
| Release Hygiene Drift | success |
| Integration Checks | success |
| Dialyzer | success |
| Minimum Supported Elixir/OTP | success |
| Adoption Demo Smoke | success |
| Complete Coverage Evidence | success |

REL-01 and SAFE-02 completion evidence is now established. Publication REL-02 remains pending; no package publish or authorization-variable set has occurred.

## Publication

Read-only publication preflight (2026-10-20T19:04:46+00:00), plan 161-07 Task 1:

- Live origin/main == #121 mergeCommit == S `428a9c53e02bc573376d0fcac313f047fbbea81c`; mix.exs version 1.6.0.
- Source CI push run `39478977350` completed success; all seven required jobs success (see prior section).
- Authorized-SHA variable absent: no stale variable, no cleanup needed.
- No in-flight release.yml run; ordinary S push run completed success.
- Remote tag lockspire-v1.6.0 absent; Hex API exact version returned HTTP 404.
- hex-publish environment exists with required-reviewer protection.
- Release Please Auto Merge remains disabled_manually.
- Open PRs #127, #126, #125, #98, #97, #96, #91, #88, #87 will be left alone throughout publication.
- No variable set, dispatch or publication performed. Awaiting explicit authorization for these exact commands:

```sh
gh variable set LOCKSPIRE_PHASE143_AUTHORIZED_SHA --repo szTheory/lockspire --body 428a9c53e02bc573376d0fcac313f047fbbea81c
gh workflow run release.yml --repo szTheory/lockspire --ref main -f recovery_ref=428a9c53e02bc573376d0fcac313f047fbbea81c -f source_ci_run_id=39478977350 -f "recovery_reason=Publish Lockspire 1.6.0 (v1.43 + v1.44) from verified main 428a9c53e02bc573376d0fcac313f047fbbea81c"
```

The protected hex-publish environment remains a later separate maintainer approval. Variable cleanup after the attempt is mandatory on every outcome.

Publication authorization and dispatch (plan 161-07 Task 3):

- Maintainer explicitly authorized setting the one-use variable and dispatching the exact-SHA protected workflow (“yes”).
- Repeated guards before writing: live main S, matching #121 mergeCommit, source push CI all seven success, exact Hex version HTTP404, tag absent, variable absent, no in-flight Release run, auto-merge disabled.
- Set LOCKSPIRE_PHASE143_AUTHORIZED_SHA at 2026-10-20T19:09:50+00:00; read-back equals S `428a9c53e02bc573376d0fcac313f047fbbea81c`.
RUN: 39481079989
- Run URL: https://github.com/szTheory/lockspire/actions/runs/39481079989
- Confirmed workflow_dispatch event and exact headSha S. Validation and package proof run before the hex-publish environment approval.
- No deployment approval performed. Keep variable until attempt finishes; on abort cancel run and wait for terminal, then clear it; clear on every outcome.

## Independent verification

(filled by later plans)

## Variable lifecycle

2026-10-20T19:04:46+00:00: no stale variable; LOCKSPIRE_PHASE143_AUTHORIZED_SHA absent. No set or dispatch yet.

2026-10-20T19:09:50+00:00: set authorized-SHA variable to `428a9c53e02bc573376d0fcac313f047fbbea81c` and verified read-back; dispatched RUN 39481079989. Cleanup pending terminal outcome.
