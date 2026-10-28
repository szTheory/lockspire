# v1.48 Delivery Status — Open PR, Candidate Checks Incomplete

**Observed:** 2026-10-28T13:16:52.002548+00:00
**Status:** The user-authorized normal milestone PR is open. Candidate checks have produced failures and remain incomplete. No merge or publication occurred.

## Pull Request

- Repository: `szTheory/lockspire`; PR [#141](https://github.com/szTheory/lockspire/pull/141), title `feat: isolate and rotate client authentication verifiers (v1.48)`, normal non-draft.
- Source branch: `milestone/v1.48-client-auth-key-isolation`; immutable published head `4d512ae2c6a042e2b4557750eca2d49e57fb7189`.
- Base: protected `main` at `173059a166e9ade0f5f57c9980b7b2400a98538c` when opened.
- Submitted body at original publication: SHA-256 `b3bc7e601afea5fca177942f4933bac3ba214df7f1efc4ae06cff2aa6c8a4757`. A corrected local-only replacement is prepared at `/private/tmp/lockspire178-pr141-final-local-delivery/pr-body.md`; its digest and exact final metadata HEAD are in the private publication plan. The remote PR body remains unchanged pending separate authorization.
- GitHub reports PR synthetic merge commit `e5ea09406cbbf581a028dce0572ee4f594994ee0`, tree `20c69eacc567c87f6c16fc4251440573ae6b2854`, parents `173059a166e9ade0f5f57c9980b7b2400a98538c` and `4d512ae2c6a042e2b4557750eca2d49e57fb7189`. This records the PR merge object; no job-log checkout assertion or package artifact was inspected.

## Automatically Triggered Checks

Read-only observation of PR run #40620643629, attempt 1, shows:

| Required job | Observed status | Conclusion |
| --- | --- | --- |
| Dialyzer | completed | failure |
| Release Hygiene Drift | completed | success |
| Fast Checks | completed | failure |
| Minimum Supported Elixir/OTP | completed | failure |
| Integration Checks | completed | failure |
| Complete Coverage Evidence | completed | skipped |
| Adoption Demo Smoke | completed | success |

Dependency Review run #40620643727, attempt 1, completed successfully. The old-head graph is terminal and not green: four required jobs failed, two succeeded, and one was skipped. This fresh job-metadata refresh read no logs and issued no rerun or workflow dispatch. Earlier bounded diagnostic observations remain separately attributable; no passing candidate acceptance is claimed. The terminal observation is recorded in `178-11-ATTEMPT1-TERMINAL-OBSERVATION.json`.

## Historical 1,077-Input Source and Package Evidence

| Evidence role | Identity |
| --- | --- |
| Reviewed implementation | `8a90a0a833a25d5a6b5f6af6525ba818e577df61` |
| Review packet implementation revision | `cd1630ccd1872436d13c0a029f0cb5fa07416a82` |
| Frozen runner | `6b1fc33cec26560601628c6e44f8c41ac3aa064b` |
| Actual local tested execution checkout | `90d17f1741970287f6299eca6e6dc6865a64ae9c` |
| Frozen manifest SHA-256 | `0ca0a43d1d2bb6bc8b73cdcb0076b446e0e04c431c8d61c3d5330c3d08d973a4` |
| Selected inputs | 1,077; digest `f0b319d52ed30e640029ce983283d2fee4809aad9a3addacb1e7dac05aad5900` |
| Candidate source | `8a90a0a833a25d5a6b5f6af6525ba818e577df61` |
| Candidate archive / tree / owner SHA-256 | `f6f49878f81adb27493a3de4027b00e14995a13bb79b690b4bbf9c21e9d7423d` / `edef4f97132d62cefa7816ef9daeb8f826bc3a2b5c591e2a8c592a45e453b475` / `b5dc88de4fa124c8b42f198bfa7a92dab43ba66f660b09945acd06c4588a8f39` |

Native guarded source CI passed at execution checkout 90d17: 15/0, 2,166/0 with 2 properties, and 261/0. Fresh locked/floor package profiles passed 14 receipts/33 cases and 12 receipts/31 cases; strict composition passed 26 receipts/64 cases with zero failures. This is local evidence, separate from the failed/pending candidate jobs. This 1,077-input proof remains historical at its original identities; current 1,078-input acceptance is summarized below.

## Main, Hygiene, and Custody

At the pre-open read-only observation on 2026-10-28, live `main` and `origin/main` were `173059a166e9ade0f5f57c9980b7b2400a98538c`; main was an ancestor of the approved branch. A read-only refresh at 13:02 UTC reconfirmed remote `main` at the same SHA; local `origin/main` matched, remained an ancestor of local HEAD `834b84d40a6059c308303658bea8b83d9fb0e412`, and the remote milestone branch remained at the published PR head `4d512ae2c6a042e2b4557750eca2d49e57fb7189`. The bounded repo-owned hygiene command `bash scripts/maintainer/repo_hygiene_check.sh --ci --skip-mix-ci` exited 0 with 18 PASS, 0 WARN, 0 BLOCK; it skipped `mix ci` and is not exact-main acceptance. The latest observed main CI #40198968774 and Release #40198968751 succeeded on that SHA on 2026-10-25; Release publication jobs were skipped. Supplemental OIDF run #40455602937 failed separately on that main SHA. No full hygiene/Mix command was rerun during this local metadata pass.

The original root archive and protected backup SHA-256 `5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be` remain verified. The root-owned PostgreSQL service and private cache were closed and removed; custody is recorded at `/private/tmp/lockspire178-root-closure-e6b82laq/terminal.json`, SHA-256 `78f832ffe3e1459955684c323a5d420b39c4fc162704da3267e1cdd928ef8599`. No further DB/package runtime action is pending or available.

## Requirement Status and Boundary

`VPROOF-02` is complete for the current 1,078-input source-bound local proof, summarized in [the current Plan 10 addendum](178-10-SUMMARY.md#2026-10-28-local-delivery-reconciliation--current-1078-input-closure). `VDELIV-01` remains pending a passing compatible seven-job candidate graph, complete coverage evidence, and milestone audit. `VDELIV-02` remains pending the dated main/delivery acceptance handoff and ranking refresh. E-09/E-10 and existing flags remain open and unwaived.

Authorization covered only pushing exact SHA `4d512ae2c6a042e2b4557750eca2d49e57fb7189` and opening this normal PR. Subsequent local tracking updates are unpushed; no branch update, rerun, review request/comment, merge, or publication is authorized by this record. The local checkpoint is [178-11-EXECUTION-CHECKPOINT.md](178-11-EXECUTION-CHECKPOINT.md). The exact pre-publication proposal, delivery, and checkpoint remain preserved under `*-INITIAL-2026-10-27.md`.

## 2026-10-28 Local Body and Checkpoint Preparation

The corrected proposal is [178-11-PR-PROPOSAL.md](178-11-PR-PROPOSAL.md). It proposes a future non-force push of the exact final local metadata SHA to the existing milestone branch, followed by an update to PR #141's body only after verifying the remote branch and PR head both equal that SHA. The currently observed failed/succeeded/skipped hosted jobs apply to old published head `4d512ae2c6a042e2b4557750eca2d49e57fb7189`; they do not qualify the proposed local candidate. The private body and publication plan record separate source, frozen-runner, execution, and proposed-publication identities. No remote update was made. Plan 11 is not complete; Plan 12 has not started; Phase 178 remains in progress.

## Current Local Custody and Terminal Hosted Observation

The current 1,078-input proof remains bound to execution `834b84d40a6059c308303658bea8b83d9fb0e412`, frozen runner `b99d6842c920a990de2c6df81123e43dc1a3bd2f`, and reviewed source `fefe8a7d948252293d7ffac7b8b20748d070d5bb`. Root independently validated reviews, frozen ownership, source, and pinned package composition (26/64/0), then closed the replacement private lab. Current closure: `/private/tmp/lockspire178-pr141-root-closure-g8h938st/terminal.json`, SHA-256 `9ab2b3932c0c8ce00ba7f52b05fc843fdd9a8358fcb2176d013f56ecc06bdb06`. Port 54547, controller/process group 1307, credentials, and the owned Hex cache are absent; no further local runtime is required or authorized in this checkpoint. Historical resource custody above remains unchanged for its own epoch.

The refreshed old-head graph has four failures, including Minimum Supported Elixir/OTP; its inner minimum failure remains unknown. New local proof does not establish hosted or main acceptance. The updated body is prepared for the corrective candidate, with the exact future push SHA and body hash kept in the separate private publication plan. No new remote action has occurred.
