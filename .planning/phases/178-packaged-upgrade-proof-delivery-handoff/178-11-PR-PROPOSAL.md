# Proposed v1.48 Milestone Pull Request Update

**Title:** `feat: isolate and rotate client authentication verifiers (v1.48)`

**Repository:** `szTheory/lockspire`

**PR:** [#141](https://github.com/szTheory/lockspire/pull/141), open, normal, non-draft

**Target:** `main`

**Source branch:** `milestone/v1.48-client-auth-key-isolation`

**Published PR head:** `4d512ae2c6a042e2b4557750eca2d49e57fb7189` (unchanged)

**Local preparation HEAD before metadata commits:** `834b84d40a6059c308303658bea8b83d9fb0e412`

**Observed current `main`:** `173059a166e9ade0f5f57c9980b7b2400a98538c`, observed locally and with read-only remote ref query at 2026-10-28 13:02 UTC; it is an ancestor of the local preparation HEAD.

**Final metadata publication HEAD:** Exact value recorded in the private publication plan after the last local metadata commit; the plan is outside the repository to avoid self-reference.
**Readiness:** Local PR-body replacement prepared for review. No remote body update, push, rerun, review, comment, merge, or publication occurred. VDELIV-01/02 remain pending.

## Prepared PR Body

### Summary

Deliver the cumulative v1.48 client authentication key isolation and rotation milestone from Phases 175–178. Client-secret-JWT verifier material has dedicated rotatable encryption-key custody, independent of endpoint/session secrets and signing-key KEKs, with explicit read/write key selection, authenticated envelopes, and fail-closed behavior.

The milestone also provides a reader-first legacy upgrade path, deliberate writer activation and legacy rejection, retry-safe rewrap and rotation, status and recovery tooling, and source-bound package proof across the existing supported dependency pairs. It preserves client secret hashes and lifetimes, one-time secret delivery, supported direct-client security behavior, and the host-owned account/login/policy seam.

### Local proof and identities

- **Current selected source:** The 1,078 selected inputs have scope SHA-256 `45d60561961df678ec1d4a4b81a1f128b5b89cf117db2a91fcff0b94f8331775`. Candidate source reviewed by three accepted lanes is `fefe8a7d948252293d7ffac7b8b20748d070d5bb`; review packet SHA-256 `e28b8c2b6d27617c898d216fe0c425a60485516099ce9603d6ece77507d2d322`. Corrected source, security, and integration lanes are `497c6860`, `b217a486`, and `e3adc839` respectively.
- **Frozen package:** Lockspire 1.6.1 was frozen with runner `b99d6842c920a990de2c6df81123e43dc1a3bd2f`, manifest SHA-256 `905319d54428d7c7c18f9a48057cfe7652c445431400e20ddeebd85b5d860e3d`, archive SHA-256 `527353b93cb5796fdf7a1878dc629966eed7417c1223b6fd6248040fa85491c4`, extracted-tree SHA-256 `2c3900f7d7a21876341ee39593216d528f71432dc3948efc00b492cfb1a897a4`, and owner SHA-256 `5b63c4582c53af39cf40aaabee66f4e803117dfb1638b8a0607bc41a6c52c752`.
- **Actual local execution:** Post-freeze guarded source CI passed at execution checkout `834b84d40a6059c308303658bea8b83d9fb0e412`: architecture 15/0, Fast 2,170/0 with two property checks, and Integration 261/0. The locked package profile passed 14 receipts/33 cases; the floor profile passed 12 receipts/31 cases; strict composition passed 26 receipts/64 cases with zero failures. The executed checkout, reviewed candidate source, frozen runner, archive, and extracted tree are separate identities. `VPROOF-02` is complete for this local 1,078-input proof.
- **Source acceptance:** `178-SOURCE-ACCEPTANCE.json` binds the actual execution checkout, current owned source manifest SHA-256 `b517c3fc7453ac0945cd0e63878e3a445c799b30079415ad7471040099378595`, and package acceptance SHA-256 `b13214ca5395658a43306ae95cc276a24100efa67cf74e143ad41ccf18799e4b`. Locked native index SHA-256 `c647ddf51591a342feec6337af78368864a8206875c807fb838c67cc5814dc28`; floor native index SHA-256 `c688e23f267e01a3bd63e17f146efabee82fa8dc43c489e2d708e8a26581d743`.
- **Current local source relationship:** The PR remains published at `4d512ae2c6a042e2b4557750eca2d49e57fb7189`. Local metadata/proof commits are unpushed and are not presented as that PR head. The source acceptance execution is the earlier exact `834b84d4` checkout; no evidence is retargeted to later metadata commits.
- **Main snapshot:** A read-only refresh at 2026-10-28 13:02 UTC observed both `origin/main` and remote `main` at `173059a166e9ade0f5f57c9980b7b2400a98538c`. This is a ref observation only, not exact-main acceptance. Earlier main CI #40198968774 and Release #40198968751 succeeded on this SHA on 2026-10-25; release publication jobs were skipped. Supplemental scheduled OIDF run #40455602937 failed on that SHA and remains separately disclosed.
- **Details:** See [current Plan 10 evidence](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-10-SUMMARY.md), [source acceptance](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-SOURCE-ACCEPTANCE.json), [package acceptance](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-PACKAGE-ACCEPTANCE.md), [frozen inputs](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-FROZEN-INPUTS.json), and [delivery reconciliation](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-DELIVERY.md).

### Candidate CI and merge status

This PR is not merge-ready. Read-only observation of PR run `40620643629`, attempt 1, showed Dialyzer failed; Release Hygiene Drift succeeded; Fast Checks failed; Minimum Supported Elixir/OTP remained in progress; Integration Checks failed; Complete Coverage Evidence was skipped; and Adoption Demo Smoke succeeded. Dependency Review run `40620643727`, attempt 1, succeeded. These observations do not form a passing canonical candidate graph. Logs were not read, no rerun or workflow dispatch occurred, and no hosted package artifacts were inspected. The reason the minimum job remained in progress is unknown; the local typed-transport diagnostic correction is not claimed to fix that hosted job.

The PR merge object reported by GitHub is `e5ea09406cbbf581a028dce0572ee4f594994ee0`, tree `20c69eacc567c87f6c16fc4251440573ae6b2854`, with parents `173059a166e9ade0f5f57c9980b7b2400a98538c` and `4d512ae2c6a042e2b4557750eca2d49e57fb7189`. No job-log checkout assertion or package artifact was inspected. Do not conflate this object with reviewed source, frozen runner, actual tested checkout, or PR head.

`VDELIV-01` remains pending a compatible passing seven-job candidate graph, complete coverage evidence, and milestone audit. `VDELIV-02` remains pending the dated main/delivery acceptance handoff and ranking refresh. Phase 178 Plan 11 is incomplete; Plan 12 has not started. E-09/E-10, historical database incidents, prior failures, and existing generic/descriptorless flags remain preserved and unwaived.

### Authorization boundary

The exact push of published SHA `4d512ae2c6a042e2b4557750eca2d49e57fb7189` and normal PR #141 creation were authorized and completed. All later commits are local and unpushed. Updating the remote PR body, pushing, rerunning jobs, requesting/submitting reviews, commenting, merging, or publishing requires separate authorization. Release Please remains the release-intent path after future authorized integration.

## Private prepared body and publication record

**Private PR body:** `/private/tmp/lockspire178-pr141-final-local-delivery/pr-body.md`

**Body SHA-256:** Recorded in the private publication plan beside the exact final metadata HEAD and read-only ref snapshot.

**Private publication plan:** `/private/tmp/lockspire178-pr141-final-local-delivery/publication-plan.json`

The private plan records the exact commit to which this preparation applies and the next authorization boundary. The body is a local draft; no GitHub mutation is proposed as already done.
