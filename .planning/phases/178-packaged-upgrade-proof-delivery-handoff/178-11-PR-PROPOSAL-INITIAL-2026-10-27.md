# Proposed v1.48 Milestone Pull Request

**Title:** `feat: isolate and rotate client authentication verifiers (v1.48)`

**Target:** `szTheory/lockspire:main`
**Source branch:** `milestone/v1.48-client-auth-key-isolation`
**Current local head at proposal start:** `04272be23a03defec49704aeae2ec1488b165a4d`
**Remote PR state:** No PR exists for this branch in the read-only observation.
**Readiness:** Proposal only; required candidate hosted jobs and milestone audit remain pending.

## Proposed PR Body

## Summary

Deliver the cumulative v1.48 client authentication key isolation and rotation milestone from Phases 175–178. Client-secret-JWT verifier material now has dedicated rotatable encryption-key custody, independent of endpoint/session secrets and signing-key KEKs, with explicit read/write key selection, authenticated envelopes, and fail-closed behavior.

The milestone also provides a reader-first legacy upgrade path, deliberate writer activation and legacy rejection, retry-safe rewrap and rotation, status and recovery tooling, and source-bound package proof across the existing supported dependency pairs. It preserves client secret hashes and lifetimes, one-time secret delivery, supported direct-client security behavior, and the current host-owned account/login/policy seam.

The approved requirements currently have 16 local evidence-backed completions. VDELIV-01 and VDELIV-02 remain pending; this draft does not claim a green hosted candidate graph, completed milestone audit, accepted main integration, merge, or publication.

## Evidence

- **Source and review:** The independent source, security, and integration lanes cover 1,076 selected inputs at reviewed source `5270f450655ea5335f15b1724e546ba907128349`. Current proposed content preserves all 1,076 frozen covered-input hashes. The frozen runner is `6910662b5b06cdb7ba27f3096c1193b42abf30a1`; the actual post-freeze source-gate and package execution checkout is `ccd8fe1e9668796a259857270b8ea34e4b42bb65`. These identities are intentionally distinct.
- **Package proof:** Actual locked wrapper passed 14 receipts/33 cases; floor wrapper passed 12 receipts/31 cases; strict composition passed 26 receipts/64 cases with zero failures. Candidate source is `5270f450655ea5335f15b1724e546ba907128349`, archive SHA-256 `f6f49878f81adb27493a3de4027b00e14995a13bb79b690b4bbf9c21e9d7423d`, and tree SHA-256 `edef4f97132d62cefa7816ef9daeb8f826bc3a2b5c591e2a8c592a45e453b475`.
- **Local contributor gate:** Post-freeze canonical guarded CI passed at `ccd8fe1e`: 15 architecture tests, 2,140 fast tests plus 2 property checks, and 261 integration tests, all with zero failures. It is local source evidence and does not substitute for candidate-hosted CI.
- **Main snapshot:** At 2026-10-27 18:29 UTC, `main` was `173059a166e9ade0f5f57c9980b7b2400a98538c`. Canonical push CI [40198968774](https://github.com/szTheory/lockspire/actions/runs/40198968774) passed its seven jobs on that SHA. Release workflow [40198968751](https://github.com/szTheory/lockspire/actions/runs/40198968751) succeeded on the same SHA with publication jobs skipped. Supplemental scheduled OIDF run [40455602937](https://github.com/szTheory/lockspire/actions/runs/40455602937) failed on that SHA; retain this result for review.
- **Details:** See [Plan 10 evidence summary](178-10-SUMMARY.md), [source acceptance](178-SOURCE-ACCEPTANCE.json), [package acceptance](178-PACKAGE-ACCEPTANCE.md), [frozen inputs](178-FROZEN-INPUTS.json), [review packet](178-INDEPENDENT-REVIEWS.json), and [evidence reconciliation](178-EVIDENCE-RECONCILIATION.md).

## Merge Danger

This proposal is not merge-ready. No milestone PR or candidate workflow run exists, so the required seven hosted jobs—Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence, and Adoption Demo Smoke—have not passed on a candidate head and compatible synthetic checkout. VDELIV-01 also awaits the milestone audit. VDELIV-02 awaits the dated main/delivery handoff and ranking refresh. Phase 177 E-09/E-10 and existing flagged findings remain unwaived.

Before opening the PR, recheck the live `main` SHA and required status, current branch ancestry, repository hygiene, and any open-time base condition. The recorded main snapshot is dated and does not guarantee future green status. Do not merge or publish from this PR without their separate authorization and gates. Release Please remains the only release-intent path after a future milestone merge.
