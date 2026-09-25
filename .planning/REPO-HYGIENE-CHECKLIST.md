# Repo Hygiene Checklist

Use this before starting a new milestone, before merging a milestone PR, and before cutting a release. The goal is a clean, boring repo state: local work committed, worktrees intentional, GitHub PRs/issues triaged, `main` green, GSD state current, and release truth coherent.

## Local Git

- Refresh refs: `git fetch --prune --tags origin`.
- Confirm branch state: `git status --short --branch` should show clean `main...origin/main`.
- Confirm worktrees: `git worktree list --porcelain`; every listed worktree must be intentional and clean.
- Prune local branches whose upstream is gone after confirming their work is obsolete.
- Keep intentional WIP/snapshot branches only when their purpose is known.

## GitHub

- Check open PRs: `gh pr list -R szTheory/lockspire --state open`.
- Check open issues: `gh issue list -R szTheory/lockspire --state open`.
- Close, merge, or explicitly defer open PRs before new milestone work starts.
- For exact acceptance of synchronized `main`, run `bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <40-lowercase-hex-current-main-sha> --format json`; the supplied commit must equal `HEAD`, local `main`, and refreshed `origin/main` before and after the local gates.
- Confirm canonical CI and the push-triggered Release no-publish outcome both belong to that exact SHA. Recency alone is not acceptance evidence.
- Every `WARN` requires one explicit `--warn-disposition CODE=DISPOSITION`. When there are no warnings, the acceptance receipt must retain the explicit empty list `"warn_dispositions": []` rather than omit the field.
- OIDF/FAPI evidence remains redacted, supplemental, non-certifying, and not a release gate; a retained supplemental result neither satisfies nor blocks required acceptance.

## Local Gates

- Run `mix ci`.
- Run `bash ./scripts/maintainer/repo_hygiene_check.sh`.
- If either fails, fix the issue before starting milestone work or release work.

## GSD State

- Run `/gsd-progress`.
- Confirm there is no active phase unless intentionally mid-milestone.
- Confirm `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` say v1.38 and Phase 140 are the current planning truth, with Phase 140 planning gated on the Phase 139 exact-SHA receipt.
- Confirm `.planning/MILESTONES.md` and `.planning/RELEASE-TRAIN.md` say v1.37 and Lockspire 1.5.0 remain the latest shipped truth. Active planning and latest-shipped history are coherent precisely because they describe different states.
- Confirm pending todos, debug sessions, and handoff/checkpoint files are either clear or explicitly documented.

## Release Readiness

- Do not manually bump `mix.exs`, `.release-please-manifest.json`, or `CHANGELOG.md` unless the release process explicitly calls for it.
- For a release-prep pass, draft user-facing notes first and let Release Please own the checked-in changelog/version PR.
- Publish to Hex only through the protected trusted release lane.
