# Lockspire Release Train

Lockspire is on a sustaining GA release train.

The default operating mode is not "find the next milestone." The default is: keep `main` green, keep release truth coherent, and let patch-eligible merged changes ride the maintained automated release lane. When future feature work is justified, use the milestone PR lane in `.planning/DEVELOPMENT-TRAIN.md`.

## Current Baseline

- Release Please version metadata: `1.5.1` <!-- x-release-please-version -->
- Release Please date metadata: `2026-09-26` <!-- x-release-please-date -->
- Latest public package: Hex `1.5.1`, published from source `0b56503859b69531ff86d8e4a465a0e75f963594` on 2026-10-08. Release Please metadata above is not publication proof.
- Artifact truth: protected release run [37795671282](https://github.com/szTheory/lockspire/actions/runs/37795671282) for source `0b56503859b69531ff86d8e4a465a0e75f963594` was backed by matching canonical push CI [37788996197](https://github.com/szTheory/lockspire/actions/runs/37788996197), whose seven required jobs passed on that exact SHA. The release run verified the public Hex checksum `c13dabddef307dcb5d89490642272571e91d12bdf3fd14756e820600121df0b3`, HexDocs, [lockspire-v1.5.1](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.1), and clean-room install. Its terminal receipt records `release_verified: true` with no blocker. The overall run failed only in bounded evidence retention; PR #120 fixed the receipt validator.
- Current-main truth: `main` is `ef6e33be2d8bc8ac438390495990b231b475466c`; canonical CI [37800419349](https://github.com/szTheory/lockspire/actions/runs/37800419349) and Release push [37800419385](https://github.com/szTheory/lockspire/actions/runs/37800419385) passed. PR #119 fixed the unsupported pinned GitHub App token input.
- Recovery history: the earlier protected run [37689835922](https://github.com/szTheory/lockspire/actions/runs/37689835922) failed before upload, and contemporaneous public queries correctly reported no 1.5.1. The later authorized run above published and verified 1.5.1. See the [historical Phase 143 result](milestones/v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md) for both outcomes.
- Previous release: source `5d10ce2219c2e687cf9573c8b280abfb118a47d8` passed canonical CI run `33141161205` and was published by protected run `33141484467`. Its package checksum was `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`; [lockspire-v1.5.0](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.0) was created on `2026-08-28` after Release Please auto-merged PR #93.
- Phase 141 planning completion and Phase 140's accepted source SHA do not represent a new package publication. See the [dated Phase 141 baseline](milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md) for observation times, same-SHA acceptance, links, and evidence boundaries.
- Release Please bookkeeping: the publish job now advances the merged release PR's `autorelease:` label itself (#78). Before that fix the label stayed `pending`, and Release Please aborted every later run with "There are untagged, merged release PRs outstanding", silently proposing no further releases. #79 was labelled `autorelease: tagged` automatically, confirming the fix end to end.

## Normal Train Rules

- `milestone: none` remains the default GSD state.
- Patch-eligible merged changes should flow to the next release through Release Please on `main`.
- The train is ready to move only when `main` is green and `./scripts/maintainer/repo_hygiene_check.sh` passes without `BLOCK`.
- `workflow_dispatch` is exact-ref only for release automation or recovery and must replay an exact immutable ref; it does not create a new release intent.
- Push-triggered Release Please manages release PRs only; it must not create GitHub releases directly because the exact-ref dispatch publish lane owns GitHub release/tag creation and Hex publish.
- `workflow_dispatch` validates and publishes one exact lowercase 40-hex commit equal to current `origin/main`, backed by its matching successful canonical CI run; a push never enters the protected publication jobs.
- Eligible Release Please PRs should auto-merge only after green `main` CI and only through the guarded Release Please branch/title/file allowlist.
- Exact-ref dispatch publishes the manifest-verified package to Hex before creating or validating the matching `lockspire-v<version>` GitHub release, then verifies public install truth from the same SHA-bound artifact.
- Before starting a new milestone or cutting a release, run the reusable hygiene checklist in `.planning/REPO-HYGIENE-CHECKLIST.md`.

## Patch-Eligible Change Classes

- Bug fixes on shipped behavior
- Docs or support-truth corrections that narrow drift without widening claims
- Release-hygiene, CI-drift, or maintainer-runbook hardening
- Narrow hardening on already-supported surfaces that does not expand the embedded-library contract

## Work That Requires A New Milestone

- New protocol families or endpoint surfaces
- Wider public support claims or topology claims
- Host seam expansion
- Material operator/admin breadth
- Anything that changes Lockspire's embedded-library scope instead of sustaining it

Feature milestones should run on `milestone/vNEXT-short-slug` branches and merge through one PR to `main` after GSD verification, milestone audit, `mix ci`, and GitHub PR checks pass. Do not create manual release branches for feature milestones; after merge, Release Please owns the normal release PR.

## Next Cut Condition

Cut the next patch release when there is at least one merged patch-eligible change on `main`, canonical CI is green for the exact current `origin/main` commit, the repo hygiene gate reports no `BLOCK`, and release truth still points to `docs/supported-surface.md` as the canonical contract.

## Current Main Readiness

At the 2026-10-08 observation, current `main` is `ef6e33be2d8bc8ac438390495990b231b475466c`; CI run `37800419349` and Release push run `37800419385` passed. The latest public release is 1.5.1 from source `0b56503859b69531ff86d8e4a465a0e75f963594`, independently verified by protected run `37795671282`. Earlier baseline evidence in the [Phase 141 baseline](milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md) remains historical.
