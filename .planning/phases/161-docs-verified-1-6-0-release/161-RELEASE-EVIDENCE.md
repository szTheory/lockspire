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
T: d1c9c0579cb615710e9bdef7f73c8d591fcb2619
- CI run: https://github.com/szTheory/lockspire/actions/runs/39469690927
- Dependency Review run: https://github.com/szTheory/lockspire/actions/runs/39469690774
- Remote main remained `038df080748c046829f9f98297da8403c47b4d89` after push.
- Passed so far: Release Hygiene Drift, dependency-review, Adoption Demo Smoke.
- Dialyzer failed: `lib/mix/tasks/lockspire.client.create.ex:54:11:call`; error tuple passed to a helper whose success typing contains only the successful tuple (the error clause only raises).
- Fast Checks, Integration Checks and Minimum Supported Elixir/OTP remain in progress; Complete Coverage Evidence depends on fast/integration.
- Scoped proposed fix: raise the same formatted domain error directly in the case branch and remove the raise-only helper clause. No code edits applied yet. Awaiting the plan's approval for a `lib/` CI fix; existing error-path tests cover the behavior.
- Local proposed patch: `/private/tmp/lockspire-132-proposed-dialyzer-fix.patch` (reconstruct from this note if unavailable).
- Plan 161-04 remains incomplete until all seven required checks and dependency-review pass. REL-01 / SAFE-02 / REL-02 remain unchecked.

## Release PR #121

(filled by plan 161-05)

## Publication

(filled by later plans)

## Independent verification

(filled by later plans)

## Variable lifecycle

(filled by later plans)
