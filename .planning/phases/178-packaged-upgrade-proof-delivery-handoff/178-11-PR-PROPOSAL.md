# Proposed v1.48 Milestone Pull Request

**Title:** `feat: isolate and rotate client authentication verifiers (v1.48)`

**Repository:** `szTheory/lockspire`
**Target:** `main`
**Source branch:** `milestone/v1.48-client-auth-key-isolation`
**Preparation snapshot HEAD:** `26269bb9068a48c5354df79371d1ed7a0941d420`
**Remote snapshot:** 2026-10-27; `origin/main` and live protected GitHub `main` were both `173059a166e9ade0f5f57c9980b7b2400a98538c`. No remote milestone branch or PR matching this branch/title was found.
**Final metadata publication HEAD:** Recorded in the private publication plan after the final local commit; it is not a self-reference in this tracked proposal.
**Readiness:** Review draft only. No PR, candidate synthetic checkout, or candidate hosted graph exists. VDELIV-01/02 remain pending.

## Proposed PR Body

## Summary

Deliver the cumulative v1.48 client authentication key isolation and rotation milestone from Phases 175–178. Client-secret-JWT verifier material now has dedicated rotatable encryption-key custody, independent of endpoint/session secrets and signing-key KEKs, with explicit read/write key selection, authenticated envelopes, and fail-closed behavior.

The milestone also provides a reader-first legacy upgrade path, deliberate writer activation and legacy rejection, retry-safe rewrap and rotation, status and recovery tooling, and source-bound package proof across the existing supported dependency pairs. It preserves client secret hashes and lifetimes, one-time secret delivery, supported direct-client security behavior, and the current host-owned account/login/policy seam.

## Evidence

- **Current selected source:** All 1,077 frozen inputs (scope SHA-256 `f0b319d52ed30e640029ce983283d2fee4809aad9a3addacb1e7dac05aad5900`) were reviewed. The implementation reviewed for the equivalent-case change is `8a90a0a833a25d5a6b5f6af6525ba818e577df61`; its authored source, security, and integration review lanes passed. The review packet SHA-256 is `d88b0214f474106291ed67a6a0a50f41876b5e21c66e071f83112b849360686f`.
- **Frozen package:** Lockspire 1.6.1 was frozen with runner `6b1fc33cec26560601628c6e44f8c41ac3aa064b`, manifest SHA-256 `0ca0a43d1d2bb6bc8b73cdcb0076b446e0e04c431c8d61c3d5330c3d08d973a4`, candidate archive SHA-256 `f6f49878f81adb27493a3de4027b00e14995a13bb79b690b4bbf9c21e9d7423d`, extracted-tree SHA-256 `edef4f97132d62cefa7816ef9daeb8f826bc3a2b5c591e2a8c592a45e453b475`, and owner SHA-256 `b5dc88de4fa124c8b42f198bfa7a92dab43ba66f660b09945acd06c4588a8f39`.
- **Actual local execution:** Canonical guarded source CI passed at execution checkout `90d17f1741970287f6299eca6e6dc6865a64ae9c`: 15/0, 2,166/0 with 2 property checks, and 261/0. The fresh locked package profile passed 14 receipts/33 cases; the floor profile passed 12 receipts/31 cases; strict composition passed 26 receipts/64 cases with zero failures. The source acceptance record binds the actual execution checkout, reviewed source, frozen runner, and package identities separately.
- **Current metadata applicability:** The proposal preparation head was `26269bb9068a48c5354df79371d1ed7a0941d420`. The current local tree and `90d17f1741970287f6299eca6e6dc6865a64ae9c` each match all 1,077 frozen selected-input hashes. The final metadata commit that carries this proposal will be recorded in the private publication plan after that commit; review and test identities are not retargeted to it.
- **Main snapshot:** On 2026-10-27, remote `main` was `173059a166e9ade0f5f57c9980b7b2400a98538c`, protected, and an ancestor of the proposal branch. The latest observed canonical CI run (#40198968774) and Release workflow run (#40198968751) both succeeded on that exact SHA on 2026-10-25; Release publication jobs were skipped. Supplemental scheduled OIDF run #40455602937 failed on that main SHA and remains separately disclosed.
- **Details:** See the [Plan 10 evidence summary](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-10-SUMMARY.md), [source acceptance](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-SOURCE-ACCEPTANCE.json), [package acceptance](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-PACKAGE-ACCEPTANCE.md), [frozen inputs](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-FROZEN-INPUTS.json), [review packet](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-INDEPENDENT-REVIEWS.json), and [evidence reconciliation](.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-EVIDENCE-RECONCILIATION.md).

## Merge Danger

This proposal is not merge-ready. Read-only checks found no remote milestone branch or PR matching this branch/title. Consequently there is no PR head, synthetic merge checkout, or candidate hosted workflow graph. The required seven hosted jobs—Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence, and Adoption Demo Smoke—remain unobserved and pending. VDELIV-01 also awaits the milestone audit. VDELIV-02 awaits the dated main/delivery handoff and ranking refresh. Phase 177 E-09/E-10 and existing flagged findings remain unwaived.

The 18 local repo-owned hygiene checks passed with 0 warnings and 0 blockers; this bounded check skipped `mix ci` and did not establish exact-main acceptance. The branch is clean, remote `main` is an ancestor (0 main-only and 550 branch-only commits at observation), and all 1,077 frozen selected bytes match. Before opening the PR, refresh the live `main` SHA and required status, branch ancestry, full open-time hygiene conditions, and any repository base condition. The recorded observations are dated and do not guarantee future green status. Do not merge or publish from this PR without their separate authorization and gates. Release Please remains the only release-intent path after a future milestone merge.

## Proposed Remote Actions — Not Executed

**Private PR body file:** `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire178-plan11-pr-53bxxmy1/pr-body.md`; SHA-256 `b3bc7e601afea5fca177942f4933bac3ba214df7f1efc4ae06cff2aa6c8a4757`.


After separate explicit authorization and a fresh open-time check, the proposed sequence is:

```sh
git push --set-upstream origin milestone/v1.48-client-auth-key-isolation
gh pr create --repo szTheory/lockspire --base main --head milestone/v1.48-client-auth-key-isolation --title "feat: isolate and rotate client authentication verifiers (v1.48)" --body-file /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire178-plan11-pr-53bxxmy1/pr-body.md
```

The proposed PR is a normal (non-draft) milestone PR. These commands are recorded for review only; neither was run. Merge, publication, comments, reviews, and workflow dispatch remain separate actions and are not authorized by this proposal.
