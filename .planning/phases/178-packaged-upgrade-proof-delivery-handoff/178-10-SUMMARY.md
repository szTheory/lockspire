---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: 10
subsystem: acceptance-proof-and-delivery
tags: [package, upgrade, postgres, source-ci, delivery]
dependency-graph:
  requires: [178-09, 178-10-independent-reviews, 178-10-frozen-inputs]
  provides: [178-10-source-acceptance, 178-10-package-acceptance, 178-10-resource-custody]
  affects: [178-11-candidate-delivery, 178-12-main-handoff]
tech-stack:
  added: []
  patterns: [owned-source-ci, immutable-frozen-inputs, strict-pair-composition]
key-files:
  created:
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-OWNED-SOURCE-MANIFEST.json
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-SOURCE-ACCEPTANCE.json
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-PACKAGE-ACCEPTANCE.md
  modified:
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-EVIDENCE-RECONCILIATION.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
decisions:
  - Keep reviewed source, frozen runner, actual source-tested checkout, and package candidate identities distinct.
  - Preserve VDELIV-01 and VDELIV-02 as pending until hosted candidate CI, milestone audit, and main/delivery owners complete.
  - Mark VPROOF-02 complete from the actual source-bound package pair and contributor-gate evidence; this does not establish hosted or main acceptance.
metrics:
  duration: "multi-hour bounded execution"
  completed: 2026-10-27
  tasks: 3
  commits: 4
  plan_head_before: 5270f450655ea5335f15b1724e546ba907128349
  plan_head_after: bb116d4ab35a0b41abe89b99008485b376a5b23c
  status: complete
  requirements_completed: [VPROOF-02]
actuals:
  tokens: 785861
  tasks: 3
  commits: 4
---

# Phase 178 Plan 10: Frozen Package Proof and Local Source Acceptance

Fresh locked and floor package runs, strict composition, and post-freeze canonical source CI now bind to authenticated frozen inputs; hosted delivery and main acceptance remain pending.

## Completed Tasks

| Task | Result | Commit |
| --- | --- | --- |
| 178-10-01: Independent reviews and evidence validation | Three authored review lanes passed at reviewed source `5270f450`; historical review chain retained byte-exactly. | `a6f0c143`, `6910662b` |
| 178-10-02: Freeze final shipped and acceptance inputs | Fresh candidate archive/tree and canonical frozen manifest validated; failed prior attempt retained with exact custody journal. | `ccd8fe1e` |
| 178-10-03: Complete package and local source gates | Locked/floor wrappers, strict 26/64 package composition, post-freeze guarded canonical CI, source acceptance, and all final validators passed. | `bb116d4a` |

## Evidence and Identity

- Reviews: 1,076 selected inputs, scope SHA-256 `60639a42e77ae8d5339c5f986e924a000b581bd4930160e2bdf95034b47e7dd7`; source, security, and integration review validators passed. Historical review records and prior denial/incident material remain preserved. No review judgment was restamped.
- Candidate: Lockspire `1.6.1`, candidate source `5270f450655ea5335f15b1724e546ba907128349`, archive SHA-256 `f6f49878f81adb27493a3de4027b00e14995a13bb79b690b4bbf9c21e9d7423d`, extracted-tree SHA-256 `edef4f97132d62cefa7816ef9daeb8f826bc3a2b5c591e2a8c592a45e453b475`, owner SHA-256 `98b306c464f7204b4a6974dfb5f27e1673ab566fbe1bf2b88d76bface7325b14`.
- Frozen runner: `6910662b5b06cdb7ba27f3096c1193b42abf30a1`; canonical frozen manifest SHA-256 `fb57f70fe484a0666a2b73bf93040e587b4af2e870f76d212ca840fa25b95159`. The actual final validator/source checkout is `ccd8fe1e9668796a259857270b8ea34e4b42bb65`; covered inputs remained byte-identical.
- Locked wrapper: exit 0; 14 receipts / 33 cases / 0 failures. Native index SHA-256 `0daec3aa578e0c91720d21390a891461d8620f26c9222779d5569a524f568ccd`.
- Floor wrapper: exit 0; 12 receipts / 31 cases / 0 failures. Native index SHA-256 `949c27477b265e101abac8cb757c1bd743809ed6f3bdedf167b99730b8225717`.
- Strict package composition: exit 0; 26/26 receipts, 64/64 cases, 0 failures. `178-PACKAGE-ACCEPTANCE.md` SHA-256 `4220316e29a584e6e8157ab5390e7ddfaadb5fec5adda6d71f47d0b7939b40c1`.
- Post-freeze canonical guarded source CI: exit 0 at actual checkout `ccd8fe1e`; suite counts were 15/0, 2,140/0 with 2 property checks, and 261/0. Captured stdout was 721,467 bytes, SHA-256 `e2ac289c74f47847c2f31eb3c51eaea9ffa9ab93e993f1a56ea1d484cd01b4ea`; stderr was empty. The owned source manifest SHA-256 is `1f172998b372607cbf3c04194fe119cd23430b6c26557798fef13dea2167197f`.
- `178-SOURCE-ACCEPTANCE.json` SHA-256 `1e92a89dfebf5271107357234b876419b007b85e120c5098bf6a187754b8fbd3` binds tested source `ccd8fe1e`, frozen runner `6910662b`, candidate source `5270f450`, and the 26/64 package result. Frozen, review, source, and package validators all exited 0 with stderr empty.

## Resource Custody and Limitations

The locked and floor wrapper processes were independently absent after completion. On the explicitly selected private PostgreSQL port 64853, the exact created source-gate database was absent; bounded counts for `lockspire_owned_%`, `lockspire_clean_room_%`, and non-maintenance custom databases were zero. The root archive was restored to original SHA-256 `5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be`, 560,128 bytes, mode 0644. The original CI replacement archive and all protected backups remain retained and verified. The root-owned private PostgreSQL service remains running; no global process sweep, foreign-port action, or unowned cleanup was performed.

The locked native wrapper itself exited 0 with its authoritative 14-output inventory. Its outer supervising script separately exited 1 because a post-observation counted only filenames named `receipt.json` and missed the named `failure-receipt.json`; the complete finite inventory and native typed index reconciled to 14. This observer discrepancy remains disclosed; the package matrix was not rerun. No third all-scope package producer was run.

The earlier Python and source-gate qualification at source `5270f450` remains distinct from the post-freeze canonical CI at `ccd8fe1e`. Historical failed attempts, source database incidents, and Phase 177 E-09/E-10 remain unchanged and unwaived. This plan completes local source/package proof only. VDELIV-01 remains pending required candidate/hosted CI and milestone audit evidence; VDELIV-02 remains pending the dated main/delivery handoff and ranking refresh. No phase completion, merge, publication, or transition is claimed.

## Deviations from Plan

- An initial timestamp-format incompatibility in the source review record was corrected by the originating reviewer using a date-compatible authored report. The original timestamped review remains immutable; review scope and judgment were unchanged.
- The fixed wrapper output root was used with an exclusive new candidate root because the existing provision API does not accept an output-root argument. No provisioner or covered source changes were made.
- A post-freeze source CI run was added after the source-acceptance helper's ancestry and chronology contract showed that the earlier 5270 CI could not truthfully satisfy the final source record. The new run passed at unchanged frozen covered bytes and actual checkout `ccd8fe1e`.

## Self-Check: PASSED

All evidence files exist, the four plan commits (`a6f0c143`, `6910662b`, `ccd8fe1e`, `bb116d4a`) are ancestors of the measured plan-end HEAD, and frozen, review, source, and package validators passed at the actual package checkout `ccd8fe1e`. After the later metadata-only summary commit, frozen, review, and source CLIs pass again; the source validator revalidates package evidence using the recorded executed runner `ccd8fe1e` and passes 26/64. A standalone package CLI call at the later metadata HEAD returns the generic rejection because it defaults the expected executed runner to current HEAD, while the immutable package receipts correctly identify `ccd8fe1e`; the explicit pinned package validation passes. No source or covered input changed after the frozen evidence run.
