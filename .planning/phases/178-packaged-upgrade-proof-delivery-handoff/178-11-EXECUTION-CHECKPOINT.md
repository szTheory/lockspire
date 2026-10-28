# Plan 178-11 Publication and Candidate-CI Checkpoint

**Observed:** 2026-10-28 02:25 UTC
**Plan:** 178-11, wave 7 of 8
**State:** Authorized push and normal PR creation completed. Candidate CI is not green; stop before any additional remote action.

## Authorized Publication Result

- Repository: `szTheory/lockspire`.
- Published PR head: `4d512ae2c6a042e2b4557750eca2d49e57fb7189` on `milestone/v1.48-client-auth-key-isolation`; post-push `ls-remote` confirmed exact SHA.
- PR: [#141](https://github.com/szTheory/lockspire/pull/141), open, normal non-draft, title `feat: isolate and rotate client authentication verifiers (v1.48)`, base `main` at `173059a166e9ade0f5f57c9980b7b2400a98538c`.
- Approved body path `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire178-plan11-pr-53bxxmy1/pr-body.md`; mode 0600, SHA-256 `b3bc7e601afea5fca177942f4933bac3ba214df7f1efc4ae06cff2aa6c8a4757`.
- The later local tracking commit is not part of PR #141 and remains unpushed absent new authorization.

## Actual PR Checkout and Triggered Runs

- GitHub reports synthetic merge commit `e5ea09406cbbf581a028dce0572ee4f594994ee0`, tree `20c69eacc567c87f6c16fc4251440573ae6b2854`; parents are main `173059a166e9ade0f5f57c9980b7b2400a98538c` and published head `4d512ae2c6a042e2b4557750eca2d49e57fb7189`. The workflow-job checkout identity was not separately proven from logs.
- PR CI run #40620643629, attempt 1: Release Hygiene Drift success; Integration Checks failure; Minimum Supported Elixir/OTP in progress; Fast Checks failure; Adoption Demo Smoke success; Dialyzer failure; Complete Coverage Evidence skipped.
- Dependency Review run #40620643727, attempt 1, completed successfully.
- These are automatic read-only observations. No logs, reruns, manual dispatch, fixes, comments, review requests, merge, or publication were performed.

## Proven Local Evidence and Limits

- Reviewed implementation `8a90a0a833a25d5a6b5f6af6525ba818e577df61`; review packet implementation revision `cd1630ccd1872436d13c0a029f0cb5fa07416a82`; selected scope 1,077, digest `f0b319d52ed30e640029ce983283d2fee4809aad9a3addacb1e7dac05aad5900`.
- Frozen runner `6b1fc33cec26560601628c6e44f8c41ac3aa064b`; manifest SHA-256 `0ca0a43d1d2bb6bc8b73cdcb0076b446e0e04c431c8d61c3d5330c3d08d973a4`.
- Actual local guarded source CI and package execution checkout `90d17f1741970287f6299eca6e6dc6865a64ae9c`; suites 15/0, 2,166/0 plus 2 properties, and 261/0.
- Local package profiles: locked 14/33/0, floor 12/31/0, strict composition 26/64/0. Local proof is independent from candidate CI.
- Pre-open bounded hygiene `--ci --skip-mix-ci`: exit 0, 18 PASS, 0 WARN, 0 BLOCK; it skipped `mix ci` and was not exact-main acceptance.
- Root custody SHA-256 `78f832ffe3e1459955684c323a5d420b39c4fc162704da3267e1cdd928ef8599` confirms PostgreSQL/cache closure; no more runtime actions are pending.

## Remaining Plan and Authorization Boundary

`VPROOF-02` is complete. `VDELIV-01` remains pending because the actual candidate graph has failures/pending/skipped jobs and no milestone audit. `VDELIV-02` remains pending. Phase 178/Plan 11 is incomplete; Plan 12 is not ready. The only remote actions authorized and completed were the exact SHA push and opening PR #141. Any branch update, retry, review/comment, merge, or publication requires separate authorization. Do not push this local tracking metadata commit.

The prior pre-publication snapshot remains byte-exact in [the initial checkpoint](178-11-EXECUTION-CHECKPOINT-INITIAL-2026-10-27.md); the dated current delivery summary is [178-DELIVERY.md](178-DELIVERY.md).

## 2026-10-28T13:18:02.124365+00:00 — Corrective Candidate Local Checkpoint

The earlier observation above remains historical at its original identities. Current local qualification has 1,078 selected inputs (scope `45d60561961df678ec1d4a4b81a1f128b5b89cf117db2a91fcff0b94f8331775`), reviewed source `fefe8a7d948252293d7ffac7b8b20748d070d5bb`, frozen runner `b99d6842c920a990de2c6df81123e43dc1a3bd2f`, and execution checkout `834b84d40a6059c308303658bea8b83d9fb0e412`. Actual post-freeze canonical CI passed 15/0, 2,170/0 plus two properties, and 261/0; locked/floor wrappers passed 14/33/0 and 12/31/0, with strict composition 26/64/0. Parent and root independently passed native review, frozen-owner, source, and explicitly pinned package validation. Generated source/package acceptance bytes remain unchanged.

All local DB/Mix/provider/profile work is complete. Root stopped and removed the owned replacement lab/cache; closure record `/private/tmp/lockspire178-pr141-root-closure-g8h938st/terminal.json`, SHA-256 `9ab2b3932c0c8ce00ba7f52b05fc843fdd9a8358fcb2176d013f56ecc06bdb06`. Historical unknown closures, reporter/collector failures, capacity retries, stale floor observations, incidents, and retractions remain preserved.

A fresh read-only job-metadata observation confirms old published head `4d512ae2c6a042e2b4557750eca2d49e57fb7189` attempt 1 is terminal with four failures (including Minimum Supported Elixir/OTP), two successes, and one skipped job. Minimum inner cause remains unknown. The new local source is not yet hosted-qualified. The prepared proposal requests a future non-force push of the exact SHA in the separate private publication plan and the exact prepared PR #141 body update, with read-only verification before and after the push. Neither action has occurred or is authorized by the old exact-4d approval. Plan 11 and Phase 178 remain incomplete; Plan 12 is not started, VDELIV-01/02 pending.

Orchestrator post-local qualification gates exited 0: schema drift unblocked, codebase drift skipped because no structure map exists (no action), UI safety unblocked. Their measured results are in `178-POST-LOCAL-QUALIFICATION-GATES.json`. The final publish SHA is deliberately kept outside this committed checkpoint to avoid a self-reference.

## 2026-10-28T14:00:27.096694+00:00 — Approved Update Completed; Hosted Blockers

Published head `33db5483bc5aa06b4a51d2742e90fb8616cad7c2` and exact PR body `cb4b7c4d8dee3d09ada103dce2b486f11b0548e4c54163a3e65ca457e99f3a38` were explicitly authorized and verified. New CI run 40696973463 attempt 1 failed Integration and Minimum; four other required jobs succeeded and Complete Coverage was skipped. Dependency Review succeeded. Required verifier pair artifacts are absent. See `178-11-APPROVED-UPDATE-OUTCOME.json` and the latest delivery section for exact test IDs, finite observations, and source leads. No next push/rerun/dispatch/body update/merge/release is authorized. Local proof at execution `834b84d4` remains attributable and unchanged, while VDELIV-01/02 and Plan 11/12 remain incomplete. No local runtime or source change occurred during attribution; replacement lab resources must be owned and provisioned before any future DB-backed check.
