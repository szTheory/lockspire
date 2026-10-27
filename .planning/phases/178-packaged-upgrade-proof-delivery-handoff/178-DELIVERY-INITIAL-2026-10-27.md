# v1.48 Delivery Status — Preliminary, Pending Hosted Candidate Evidence

**Observed:** 2026-10-27 18:29 UTC
**Status:** Local milestone PR proposal prepared; no PR was created or updated. The milestone is not merge-ready.

## Proposed Delivery Route

The repository's development train calls for one milestone branch and one PR to `main`; the release train remains separate and is still owned by Release Please. Proposed repository is `szTheory/lockspire`, branch `milestone/v1.48-client-auth-key-isolation`, base `main`. The local branch is clean at the observation baseline `04272be23a03defec49704aeae2ec1488b165a4d`, has no upstream, and differs from observed `main` (`173059a166e9ade0f5f57c9980b7b2400a98538c`) by 531 branch-only commits and one main-only commit. The remote branch does not exist. Read-only PR search found no PR for this branch; open PR #139 is the unrelated Release Please PR.

The concrete title and complete proposed body are in [178-11-PR-PROPOSAL.md](178-11-PR-PROPOSAL.md). The body follows the recent milestone PR structure (`Summary`, `Evidence`, `Merge Danger`) and describes the cumulative v1.48 scope. This is a review draft, not evidence that a PR exists.

## Source and Package Evidence

These identities remain distinct:

| Evidence role | Identity |
| --- | --- |
| Independently reviewed candidate source | `5270f450655ea5335f15b1724e546ba907128349` |
| Frozen input runner | `6910662b5b06cdb7ba27f3096c1193b42abf30a1` |
| Actual post-freeze canonical source CI and package execution checkout | `ccd8fe1e9668796a259857270b8ea34e4b42bb65` |
| Observed current local metadata head before this proposal commit | `04272be23a03defec49704aeae2ec1488b165a4d` |
| Candidate source archive SHA-256 | `f6f49878f81adb27493a3de4027b00e14995a13bb79b690b4bbf9c21e9d7423d` |
| Candidate tree SHA-256 | `edef4f97132d62cefa7816ef9daeb8f826bc3a2b5c591e2a8c592a45e453b475` |
| Candidate owner SHA-256 | `98b306c464f7204b4a6974dfb5f27e1673ab566fbe1bf2b88d76bface7325b14` |
| Frozen manifest SHA-256 | `fb57f70fe484a0666a2b73bf93040e587b4af2e870f76d212ca840fa25b95159` |

The clean checkout matched all 1,076 frozen covered-input hashes when this proposal was prepared. No review or test identity is restamped to the current metadata head. Plan 10's actual locked/floor wrappers passed 14 receipts/33 cases and 12 receipts/31 cases; strict composition passed 26/26 receipts and 64/64 cases with zero failures. The post-freeze canonical guarded source CI passed all three suites at `ccd8fe1e`: 15 tests, 2,140 tests plus 2 property checks, and 261 tests, all with zero failures. The actual source manifest SHA-256 is `1f172998b372607cbf3c04194fe119cd23430b6c26557798fef13dea2167197f`. See [Plan 10 summary](178-10-SUMMARY.md) and [evidence reconciliation](178-EVIDENCE-RECONCILIATION.md).

## Preliminary Requirement Dispositions

Fifteen of the 18 approved requirements have local evidence recorded complete: VBASE-01/02, SEC-01–05, VUP-01–03, VOPS-01–04, and VPROOF-01. VPROOF-02 is pending requalification because the main-base sync expanded the selected source closure from 1,076 to 1,077 inputs. Its Plan 10 package and source-gate evidence remains valid for the original exact frozen closure only. VDELIV-01 remains pending a real candidate PR and a complete passing hosted contributor/CI gate graph plus the milestone audit. VDELIV-02 remains pending the dated main/delivery acceptance handoff and rolling-rank refresh. Phase 177 E-09/E-10 and prior flagged findings remain open and unwaived. These are preliminary dispositions, not the Plan 11 final requirement-evidence artifact.

## Hosted and Main Snapshot

At the observation time, remote `main` was `173059a166e9ade0f5f57c9980b7b2400a98538c`. Canonical push CI run [40198968774](https://github.com/szTheory/lockspire/actions/runs/40198968774) and Release workflow run [40198968751](https://github.com/szTheory/lockspire/actions/runs/40198968751) both completed successfully on that exact SHA. The CI run contained the seven required jobs: Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence, and Adoption Demo Smoke. The Release workflow's publish-related jobs were skipped, so this is not publication evidence.

Supplemental scheduled OIDF run [40455602937](https://github.com/szTheory/lockspire/actions/runs/40455602937) failed on the same main SHA; its two repo-native lanes failed and the hosted maintainer lane was skipped. This is separate from the canonical seven-job CI graph and must remain visible in review. The repository hygiene command was not run in this local preparation. Recheck the live main SHA, branch relationship, required status, hygiene result, and any repository open-time base policy immediately before a future PR open; this dated snapshot does not satisfy that future check.

No PR workflow run, PR synthetic merge SHA/tree/parents, candidate hosted job graph, candidate package artifact, integration approval, exact-main acceptance, merge, or publication was observed. The required seven candidate jobs are therefore pending, not passing.

## Resource Custody

Plan 10's owned pair processes and source-CI process groups were observed absent after completion. Its bounded private PostgreSQL catalog checks found no remaining owned test databases; root-owned PostgreSQL PID 3917/controller 81473 on port 64853 remains intentionally live. The original root archive and protected backups remain byte-verified, and the failed attempt/custody journals remain preserved. This delivery record makes no new cleanup or fleet-parity claim.

## Next Actions

1. Review the proposed full-milestone PR title/body and this dated readiness snapshot.
2. Before any PR open, obtain separate explicit authorization for that remote write, then recheck live `main`, branch ancestry, required statuses, repository hygiene, and any open-time base rule.
3. After a PR exists, observe the actual PR head and synthetic checkout graph, then the seven required jobs and both package artifacts from one compatible run/attempt. Preserve all failures and do not create `178-CANDIDATE.json`, `178-CANDIDATE-GATES.json`, or accepted requirement dispositions until authentic observations exist.
4. Keep merge, release, and publication as distinct later actions with their own authority and evidence.
