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
