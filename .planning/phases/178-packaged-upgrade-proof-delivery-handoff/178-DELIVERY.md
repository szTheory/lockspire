# v1.48 Delivery Status — Approved Update Published, Hosted Gates Failed

**Observed:** 2026-10-28T13:16:52.002548+00:00
**Status:** PR #141 is open at approved update `33db5483bc5aa06b4a51d2742e90fb8616cad7c2`; its approved body update is verified. The new candidate run is terminal with failed required gates. No merge, release, rerun, dispatch, review, or comment occurred.

## Original Publication and Preserved History

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

## 2026-10-28T14:00:27.096694+00:00 — Approved 33db Update and Terminal Hosted Result

The user explicitly authorized both actions: non-force push of exactly `33db5483bc5aa06b4a51d2742e90fb8616cad7c2` to the existing milestone branch, then replacement of only PR #141’s body with approved SHA-256 `cb4b7c4d8dee3d09ada103dce2b486f11b0548e4c54163a3e65ca457e99f3a38`. Both completed and were independently verified against the remote branch and GitHub PR readback. The PR remains open/non-draft, based on `main` at `173059a166e9ade0f5f57c9980b7b2400a98538c`. The new synthetic merge object observed in PR metadata is `70afa2a31df5d85549678008dbfeb106993126ec`; that metadata alone is not claimed as an observed job checkout.

Automatically triggered CI [run 40696973463](https://github.com/szTheory/lockspire/actions/runs/40696973463), attempt 1, event `pull_request`, is terminal with failure. Fast Checks, Dialyzer, Release Hygiene Drift, and Adoption Demo Smoke succeeded; Integration and Minimum Supported Elixir/OTP failed; Complete Coverage Evidence was skipped. Dependency Review run 40696973443 succeeded. No expected locked/floor verifier-upgrade pair artifacts were present, and no artifact archives were downloaded. The complete safe observation and attribution references are in `178-11-APPROVED-UPDATE-OUTCOME.json`.

Integration produced 565 tests/3 failures (seed 36080) and a packaged suite of 3 tests/3 failures (seed 632735). The first three tests expect SQL or raw PostgreSQL details suppressed by deliberate security controls; corrections must preserve cold persistence/no-ambient-key behavior, forced rollback state/audit invariants, and one-winner race semantics. Fresh/custom packaged paths have a source-level tar-plus-SHA ownership gap; authenticated Git/frozen ownership must be wired without weakening authority. Legacy exposes only `runner_failure/PackageInputError` at `legacy_upgrade/selected`; a narrower inner cause is unobserved. Minimum’s closed producer witness is `host_startup/host_startup_failed`, command native exit 1, cleanup stopped. This is not a VM exit status; VM exit versus readiness timeout remains unexposed, and the missing listener opt-in is only a source candidate. No source edits, local runtime, or new resources were introduced during attribution.

The local source/package proof at `834b84d4` and its generated records remain unchanged for their actual inputs. Current hosted candidate qualification has not passed. Plan 11 and Phase 178 remain incomplete, Plan 12 is not started, and VDELIV-01/02 remain pending. Further local correction needs an owned-resource plan before any runtime; the prior PostgreSQL/credentials/cache remain removed. Any later tracking commit is local and unpushed; the exact approved published head remains `33db5483`. No further remote mutation is authorized.


## 2026-10-28T23:51:51.514347+00:00 — Corrected local package and host proof qualified

Reviewed package source C50 (`50d67751a7844dee2f5f595195a6ab455e313fc6`) and execution/frozen runner H175 (`1757638a7770bb6f09c3b085f002fa7c8b7ed518`) retain distinct identities from the future metadata publication head. All 1,079 selected inputs remain byte-identical. Existing canonical source proof is 2,456 tests/zero failures/two properties; lifetime composition is 47 checks across nine scenarios. Fresh verifier pairs passed locked 14/33 and floor 12/31; native strict composition passed 26 receipts/64 cases with zero failures. Installed hosts passed all 16 required scenarios at each of three mounts on both actual Elixir1.19.5/OTP28.5 and Elixir1.18.4/OTP27.3.4.15: 96 scenarios total. These are local installed proofs; hosted-current/minimum owner profile names do not mean GitHub execution.

The minimum retry (root exec9307) has a durable typed terminal record, SHA-256 `da8be24fed86e85804b10505648f68673585071dcd003ed38bc46c9e6b5462c9`, with 37 events, no invalid metadata, confirmed original child groups, dependent cleanup, PG shutdown/root removal and collector-owned coordinator closure. Parent native receipt/owner audits passed 48 current and 48 minimum scenarios; each run has 39 original inner process pairs and 14 outer command pairs. Current84579 journal pointers were uniquely joined from existing original records by the security author; no identity was reconstructed. Its PG shutdown/root removal remain attributed terminal facts because the exact outer PG identity and complete durable terminal event were not retained. This audit-retention limit remains unwaived. Run71794 has three passing native receipts but lost its final terminal metadata; its final PG/root status remains UNKNOWN, and it is not promoted as an accepted run.

Root transfer preserved five earlier artifact directories by rename and retained the old four native records before promotion. Transfer record SHA-256 `6d280bad9d43b176ab4fc93b55cb1be7e5c325b49d00d6c66c3c70c700af24c9` binds 454 byte-identical copies, with no raw output files copied. Native root review, frozen-owner, source and pair validation passed under explicit Python3.14/Elixir1.19.5/OTP28.5 and private tool homes. Its 79 original process pairs all stopped; 73 wrapped result summaries plus six direct native owner captures explain the counter difference. The protected user tar remains regular, one link,0644,560128 bytes and SHA-256 `5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be`.

The complete record is [178-11-CORRECTED-NATIVE-PACKAGE-HOST-EVIDENCE-50d6775.json](178-11-CORRECTED-NATIVE-PACKAGE-HOST-EVIDENCE-50d6775.json). It retains authored runtime-helper rejections/acceptance, original journals, toolchain correction, the source/lifetime evidence link, every earlier incident and all E-09/E-10/generic/descriptorless flags. No old proof is restamped, unexplained canonical failure diagnosed, or unknown resource inspected/cleaned. VPROOF-02 is locally qualified; VDELIV-01/02 remain pending. PR #141 is still at published `33db5483` with Integration and Minimum failed and Coverage skipped. The forthcoming exact non-force push/body proposal is a new authorization boundary, not a remote action already performed. Plan11 remains incomplete, Plan12 unstarted, Phase178 in progress.


## 2026-10-29T00:12Z — Authorized corrected update published; new candidate CI blocker

The owner approved the exact publication request with “yes”. Non-force push of `cc61cffc563fc8df141313c26442186c0b4645a3` succeeded; independent read-only checks confirmed both the remote milestone branch and PR #141 at that exact SHA. The approved PR body was replaced through the GitHub connector, then independently fetched and compared byte-for-byte: SHA-256 `eaf0ad6a6f6d8b6733356af2ec799da59a8506e743296bbd0f2acd8c4fa90fe3`. Main/base remain `173059a166e9ade0f5f57c9980b7b2400a98538c`; the PR remains open, non-draft and unmerged. GitHub reports synthetic merge metadata `49e561c4f34590c51ccf6275735d82d3ce091294`; that metadata alone does not prove a job checkout. Both specifically approved remote actions are complete.

Automatic CI run [40792440885](https://github.com/szTheory/lockspire/actions/runs/40792440885) is in progress at the recorded observation. Dialyzer job 123180682056 failed with exit 2 and `pattern_match_cov` at `lib/lockspire/security/client_secret_verifier/operation_context.ex:95`: its pattern is already covered. Checkout, toolchain and cache steps succeeded. Logs were read only in memory; only finite classifications, validated source location and counts were retained. Release Hygiene and Adoption Demo Smoke passed; Fast, Integration and Minimum were still running, and the complete required seven-job graph was not yet observed. Automatic Dependency Review run 40792440963 passed. No passing candidate graph is claimed.

Exact observations and approval scope are in [178-11-APPROVED-CORRECTED-UPDATE-OUTCOME.json](178-11-APPROVED-CORRECTED-UPDATE-OUTCOME.json), SHA-256 `7462702c38752836859564793f7d9310e5ca80b2f3e912de0031ae116045de4e`. Local proof retains reviewed source C50, execution runner H175 and its original outcomes; publication does not restamp those results. All earlier failures, unknown closures, retention limits, E-09/E-10 and generic/descriptorless flags remain unwaived. VPROOF-02 stays locally qualified; VDELIV-01/02, Plan 11 and Phase 178 remain incomplete; Plan 12 is unstarted. No rerun, dispatch, comment, review, merge, release or package publication occurred. The exact push/body approval is consumed; any later remote mutation requires new authorization. Any local tracking commit after the published SHA is not part of the authorized push.

## 2026-10-29 UTC — e13 local CI correction and active proof requalification

Corrected source is `e13a71976f216c8953e060729825b821a3e6eba5`; independent source/security/integration judgments are bound to its complete 1,079-input closure, with metadata at `998d68cb`. The old C50/H175 evidence remains its own immutable epoch. The correction fixes candidate-source versus synthetic-checkout selection, source binding for explicitly owned local host tar inputs, and the unreachable private Dialyzer fallback. An independent review also found and closed a tracked-deletion omission bypass in the initial correction; clean tracked-source guards run before/after Mix package observation.

Exact e13 canonical CI passed 2,456 tests, zero failures and two properties through a fresh owned PostgreSQL runner; its database is independently absent and original captured groups are stopped. Python acceptance289/0 and clean-room56/0 passed final working-tree bytes; Git HEAD at those Python invocations was not separately captured. Their identity limit is explicit in `178-11-CI-CORRECTION-EVIDENCE-e13a7197.json`.

Current and minimum installed hosts each passed 48 scenarios across three mounts with native receipts, paired original journals, PG shutdown and retained data. Current archive/tree are `ef8b944fb6666e718ac52d3bff60acbf5724cb7314b90c1f1c6880ce353b7250` / `a0503351b9529b9c7f7728b9d96a0808c58e8ac1328db199ae7f38083c42a464`; minimum archive/tree are `e610e7fba89d1ab9e25cee9bb4d6410a41c4ddc5c74379aa6b77662b12249e27` / `acb61fb460e72f92ff87d753c63341fce7404fa13872c8b0b1f5be58e6c42259`. Direct comparison found only `hex_metadata.config` bytes differ; do not collapse these two archive identities or claim independent generated-metadata derivation from the tar source check.

Native frozen provisioning passed for e13/e13. Lifetime qualification passed three ExUnit tests, 47 checks across nine scenarios, zero failures/skips, and byte-identical independent native recomposition. The first locked verifier attempt retained two core receipts and failed rollout with `ReceiptError`; its rejected predicate is still UNKNOWN. The original outer and PG groups stopped, dependent cleanup remains unconfirmed, and its private data is retained. New passive diagnosis is being prepared; floor pair is unstarted. No full current verifier matrix/package acceptance is claimed yet.

The two earlier installed first-mount failures still have unknown DB-cleanup causes despite later successful isolated runs. Diagnostic 0349/MIX_DEBUG run had four fast-test failures with no retained individual rejection witnesses. Every such failed epoch remains visible. The root archive overwrite and exact restoration remain disclosed in `178-11-LOCAL-INCIDENT.md`; the protected archive still matches its original SHA.

Read-only GitHub observation confirms PR141 remains open/unmerged at `cc61cffc563fc8df141313c26442186c0b4645a3`, base `173059a166e9ade0f5f57c9980b7b2400a98538c`, and unchanged approved body SHA `eaf0ad6a6f6d8b6733356af2ec799da59a8506e743296bbd0f2acd8c4fa90fe3`. CI40792440885 remains failed, Dependency Review40792440963 passed. Synthetic merge metadata is not proof of actual job checkout. No push, PR edit, rerun/dispatch, comment, merge or publication was performed. Plan11 remains incomplete and Plan12 stays unready. Finish scoped local qualification and a concrete exact SHA/body proposal before seeking any new remote authorization.
