# Lockspire Maintenance Baseline — 2026-10-05

**Observed:** 2026-10-05 19:38 UTC
**Planning status:** Phase 140 terminal acceptance established; Phase 141 baseline and GSD reconciliation are documentation work in progress.
**Latest evidenced public package:** Lockspire 1.5.0.

## Accepted source and observation boundary

Phase 140's post-summary terminal receipt accepts source tree `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`. At receipt time, `HEAD`, local `main`, fetched and advertised `origin/main` all matched that full SHA; the worktree and exact binary diff were clean. The matching read-only closure result marks CI-06 and CI-07 `pass`. The Phase 140 owner handoff corroborates that closure.

This acceptance applies only to that source tree. The Phase 141 branch and commits containing this report or later planning records are documentation commits outside the receipt. A later source-acceptance claim needs evidence for its own exact SHA. The immutable commit that first contains this report is recorded separately in `141-01-SUMMARY.md`.

## Local CI and hygiene at the accepted source SHA

| Check | Status | Evidence |
| --- | --- | --- |
| Local `mix ci` | Pass; receipt reports 102 ExUnit tests | Private Phase 140 acceptance receipt |
| Exact-SHA repository hygiene | Pass: 24 PASS, 0 WARN, 0 BLOCK; no WARN dispositions were needed | Private Phase 140 acceptance receipt |
| Synchronized refs and clean worktree | Pass for `877a0f758aa0bbd5433cbe3d70f1476fa0e12223` | Private Phase 140 terminal closure result |

## Canonical CI and Release no-publish proof

Required canonical [CI run 37354878786](https://github.com/szTheory/lockspire/actions/runs/37354878786) completed successfully on `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`. All seven required jobs passed: Adoption Demo Smoke, Complete Coverage Evidence, Dialyzer, Fast Checks, Integration Checks, Minimum Supported Elixir/OTP, and Release Hygiene Drift.

The canonical [Release run 37354878693](https://github.com/szTheory/lockspire/actions/runs/37354878693) also completed successfully on that same SHA with outcome `no_publish`. Maintain Release Please PR passed; Validate exact main head and CI evidence, Prove exact package before publication, Publish verified release to Hex, and Verify public install truth were skipped. This run did not publish a package.

## Separately published package chain

Closure-time read-only queries at 2026-10-05 19:38 UTC found Hex `latest_version` and `latest_stable_version` both `1.5.0`; the release list contained no `1.5.1`, and the exact Hex API request for 1.5.1 returned HTTP 404. The 1.5.0 release record reports checksum `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`.

GitHub's public [1.5.0 release](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.0) and tag both identify source `5d10ce2219c2e687cf9573c8b280abfb118a47d8`. Canonical [CI run 33141161205](https://github.com/szTheory/lockspire/actions/runs/33141161205) succeeded on that SHA. Protected [Release run 33141484467](https://github.com/szTheory/lockspire/actions/runs/33141484467) succeeded via `workflow_dispatch` on the same SHA, publishing and verifying the package. This historical publication chain is independent of Phase 140's accepted source SHA and Phase 141 planning completion.

## Phase 140 dispositions and retained deferrals

The source-linked [Phase 140 disposition register](../140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md) remains authoritative for finding identities, evidence, and recheck triggers. In summary:

- **Already resolved:** specific current test, formatter, fixture, and recovery findings have terminal scoped evidence in the register. Their historical evidence and identities remain distinct.
- **Retain historical:** released tags and named historical evidence remain preserved; unavailable historical test identities are not inferred from grouped counts.
- **Deferred with trigger:** current refs, worktrees, PRs, and selected maintained records remain proposal-only until exact identity, ownership, ancestry, recovery, worktree safety, and authority are revalidated before action. WR-01 remains deferred with unknown cause; reopen only if the exact sealed Release Please relation rejection recurs, then capture stage-specific evidence. Phase 138 UAT #100 remains pending an authorized live snapshot refresh.
- **Out of scope:** no cleanup, PR or issue action, ref mutation, or release action is authorized by this baseline.

Supplemental OIDF/FAPI evidence remains redacted, supplemental, and non-certifying. It is not a release gate and supports no certification claim; any future conformance work belongs to a separately bounded effort.

## Next supported sustaining-train condition

The next supported check is to evaluate whether `main` contains a merged patch-eligible change. Before the release owner acts, require canonical CI for the exact current `main` SHA, repository hygiene with no `BLOCK`, and supported-surface truth against `docs/supported-surface.md`. Phase 141 completion is planning completion; it does not direct a release cut or package publication. See [the existing release-train rules](../../RELEASE-TRAIN.md).

## Evidence sources

| Source | Status and identity | Link |
| --- | --- | --- |
| Phase 140 owner-only acceptance receipt | Pass; accepted SHA `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`; receipt SHA-256 `c54edd4006ede7f7495adf27843605e6ce0b5085f8b0317a641c9c7a20b4b051`; file mode 0600 | `/private/tmp/lockspire-140-plan/140-18-final-acceptance.877a0f758aa0bbd5433cbe3d70f1476fa0e12223.json` |
| Phase 140 owner-only terminal verifier | Pass; CI-06/CI-07 pass; receipt digest matches; verifier SHA-256 `8a0e13500e5da75c880809d8be5318ff71e334a5126fa472411323a97cecce24`; file mode 0600 | `/private/tmp/lockspire-140-plan/140-18-read-only-closure.877a0f758aa0bbd5433cbe3d70f1476fa0e12223.json` |
| Phase 140 owner corroboration | Confirms post-summary terminal closure and evidence identities | `/private/tmp/lockspire-140-plan/140-18-next-command-handoff.877a0f758aa0bbd5433cbe3d70f1476fa0e12223.txt` |
| Phase 140 tracked acceptance and verification | Historical planning snapshot still showed CI-06/CI-07 pending before the private post-summary terminal result | [140-ACCEPTANCE.md](../140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md), [140-VERIFICATION.md](../140-bounded-operational-loose-end-triage/140-VERIFICATION.md) |
| Current accepted-source required CI | Pass on `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`; run `37354878786` | [GitHub run](https://github.com/szTheory/lockspire/actions/runs/37354878786) |
| Current accepted-source Release | Pass, `no_publish`, on the same SHA; run `37354878693` | [GitHub run](https://github.com/szTheory/lockspire/actions/runs/37354878693) |
| Current public Hex package list | Latest stable 1.5.0; exact 1.5.1 query returned 404 | [Hex package API](https://hex.pm/api/packages/lockspire), [Hex 1.5.0 record](https://hex.pm/api/packages/lockspire/releases/1.5.0), [Hex 1.5.1 query](https://hex.pm/api/packages/lockspire/releases/1.5.1) |
| Published GitHub release and tag | 1.5.0; source `5d10ce2219c2e687cf9573c8b280abfb118a47d8` | [Release](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.0), [tag API](https://api.github.com/repos/szTheory/lockspire/git/ref/tags/lockspire-v1.5.0) |
| Published package CI and protected run | Both pass on published source SHA; runs `33141161205` and `33141484467` | [CI](https://github.com/szTheory/lockspire/actions/runs/33141161205), [Release](https://github.com/szTheory/lockspire/actions/runs/33141484467) |

---

Observation completeness is limited to the exact local receipt and the listed official public records queried at the stated UTC time. Mutable refs and hosted records require fresh checks before future actions. Detailed logs and raw supplemental conformance results are intentionally not copied here.
