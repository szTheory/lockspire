---
gsd_state_version: "1.0"
milestone: v1.47
milestone_name: OAuth/OIDC Core Interoperability & Hardening
current_phase: 174
status: All phases complete; accepted main 173059a1
stopped_at: "PR #140 merged; fresh exact-main acceptance passed; v1.47 delivery complete"
last_updated: "2026-10-25T14:24:55.814Z"
last_activity: 2026-10-25
last_activity_desc: "PR #140 merged; fresh main acceptance passed and receipt saved"
state_head: 077326a2f6250c18111b947b9ab7b6059a9f8875
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 10
  completed_plans: 10
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-10-25 after Phase 174 verification)

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** PR #140 is merged as 173059a166e9ade0f5f57c9980b7b2400a98538c. Exact-main local acceptance, seven push CI jobs and no-publish Release passed; the byte-preserved receipt and custody records are on the retained milestone evidence branch.

## Current Position

Phase: 174
Plan: Not started
Status: All phases complete; accepted main 173059a1
Last activity: 2026-10-25 — PR #140 merged; fresh main acceptance passed and receipt saved

Progress: [██████████] 100% — 4/4 phases, 10/10 plans complete; all 14 requirements verified; protected delivery and exact-main acceptance complete.

## Performance Metrics

v1.47: 4 completed phases, 10 completed plans and 14 verified requirements. Phase 174 passed 23/23; package 12/12; accepted main 173059a1 passed local CI, seven hosted jobs and no-publish Release. Milestone audit passes; next product milestone remains provisional.
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 171 P01 | 17 min | 2 tasks | 3 files |
| Phase 171 P02 | 14min | 2 tasks | 2 files |
| Phase 171 P03 | 31min | 3 tasks | 7 files |
| Phase 171 P04 | 6 min | 2 tasks | 8 files |
| Phase 172 P01 | 6min | 2 tasks | 5 files |
| Phase 173 P01 | 5 min | 2 tasks | 4 files |
| Phase 174 P01 | 84 min | 2 tasks | 7 files |
| Phase 174 P02 | 28min | 2 tasks | 8 files |
| Phase 174 P03 | 19min | 3 tasks | 15 files |
| Phase 174 P04 | 56min | 2 tasks | 11 files |

## Accumulated Context

**Current decision posture:** The user selected v1.47 and delegated upstream research, adversarial synthesis and routine scoped decisions. Use the [standing guide](MILESTONE-GUIDE.txt), [rolling ranking](MILESTONE-ARC.md), [scope](research/v1.47-core-hardening/SCOPE.md) and [research](research/v1.47-core-hardening/SUMMARY.md); prefer small, flat dependencies and existing vetted primitives, refresh future candidates at each boundary, and preserve honest green-main/clean-workspace handoffs.

**Entry limits:** Phase 171 may be planned here; this feature checkout is not accepted main. Before product implementation, reconcile cumulative prior delivery and edit/worktree ownership, then obtain fresh exact-main acceptance through the existing [hygiene checklist](REPO-HYGIENE-CHECKLIST.md). Freeze the finite ledger before dependent plans; replan invalidated slices and reuse already-correct evidence. The [dated baseline](research/v1.47-core-hardening/BASELINE.md) records unqualified historical findings and delivery limits; [original machine-state bytes](research/v1.47-core-hardening/STATE-JSON-BEFORE.json) remain preserved, while the SDK owns the new v1.47 projection. Do not clear historical phase directories 142/143. Selected behavior is mandatory; full external suites remain supplemental/non-certifying.

**Phase 171 entry preflight (2026-10-24, after planning commit 322ae40f):** Independent checker passed all 3 plans; 4/4 requirements covered. Read-only GitHub API still reports main `a1e39a01aca258d0ac5f36414bf47c45686d92c1`; local main is `a1a55de0a931c641fbe176e5c3f9c4737aa62b9d`. The planning branch has 414 commits beyond observed origin/main and is not accepted main. All four registered worktrees are clean, but the three prior-agent worktrees retain the unresolved ownership/disposition recorded in BASELINE.md. Automatic advancement stops before acceptance, qualification or product edits; no plan is complete. Next owner: executing maintainer; next action: complete 171-01's reviewed cumulative-delivery and worktree/edit ownership reconciliation, preserving unknown work, before choosing an integration route and running exact-main acceptance. Runtime availability is not the blocker: process-local `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix --version` succeeds (Mix 1.19.5 / OTP 28), without changing toolchain files or installing anything. No acceptance/profile/test execution is claimed by this preflight.

v1.46 completed four phases, 16 plans and all 15 requirements. All four verification owners passed immediately before phase archival; [closeout projection](milestones/v1.46-CLOSEOUT.json) preserves that check. The [audit](milestones/v1.46-MILESTONE-AUDIT.md) records 14/14 integration boundaries, 6/6 flows, four Nyquist-compliant phases and 68/68 security threats closed. No phase-verification override or human UAT remains. Archived covered_files paths retain their original checkout meaning; reports are not restamped after relocation.

Closeout type: override_closeout. Known verification overrides: 1 newly acknowledged, 3 carried forward from a prior close (see STATE.md Deferred Items). The new acknowledgment covers only the existing duplicate record_trace/2 fixture warning; all four phase verification owners passed immediately before archival. Historical suppressed records retain their verdicts.

Local package/browser/runtime receipts retain exact source and package identities. Hosted CI, minimum CI BEAM and branch protection remain unobserved. Publication is separate; no remote refs were updated. Original unrelated state.json bytes remain preserved and excluded from commits. Older quick tasks remain in place. Detailed phase decisions and evidence remain in [pre-close state](milestones/v1.46-STATE.md), [phase archive](milestones/v1.46-phases/) and PROJECT.md.

### Pending Todos

- SEC-01 remains preferred provisional v1.48; KEK-04, OPS-03, legacy-plaintext fixture maintenance and existing milestone debt retain their owners and triggers outside selected v1.47.
- Phase 138 UAT #100 remains pending an authorized live snapshot refresh; inventory dispositions remain proposal-only.
- Phase 140 WR-01 stays deferred unless the exact sealed Release Please relation rejection recurs.
- Supplemental OIDF/FAPI evidence remains bounded, redacted and non-certifying.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 20261020-keys-reencrypt | Route keys.reencrypt through TaskError/RepoRunner;171tests/0failures; implemented in PR135 | 2026-10-20 | 170428a7 | [summary](./quick/20261020-keys-reencrypt-repo-runner/SUMMARY.md) |
| 260924-mhp | Classify active UAT lifecycle records from structured status and document shape | 2026-09-24 | 37a1d62c | [260924-mhp-classify-active-uat-records-in-the-phase](./quick/260924-mhp-classify-active-uat-records-in-the-phase/) |
| 2 | 260925-x8y: classify structurally valid status: testing UAT as active evidence | 2026-09-26 | f0270d2d | — |
| 260926-c7l | Refresh Phase 139 verification across all 13 plans | 2026-09-26 | 285c6c62 | [260926-c7l-refresh-phase-139-s-canonical-verificati](./quick/260926-c7l-refresh-phase-139-s-canonical-verificati/) |

## Deferred Items

Items acknowledged and deferred at milestone close; acknowledgment preserves the source report's status and is not a pass.

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| Conformance | Supplemental OIDF/FAPI findings | Future bounded conformance milestone; non-certifying | v1.38 start | v1.38 |
| Repository automation | Additional drift checks | Only if a repeatable repository-owned gap is demonstrated | v1.38 start | v1.38 |
| Quick task | 260925-t6x — repair Phase 139's stale verification report | Halted; acknowledged at v1.38 closeout | 2026-10-06 | v1.38 |
| Verification gap | Phase 139 verification report | gaps_found; acknowledged at v1.38 closeout | 2026-10-06 | v1.38 |
| Verification gap | Phase 140 verification report | gaps_found; acknowledged at v1.38 closeout | 2026-10-06 | v1.38 |
| Verification gap | Phase 143 PR #119 exact-head merge authorization | gaps_found (16/18); acknowledged as non-blocking for forward development; report remains unchanged | 2026-10-09 | v1.39 |
| Phoenix integration | Public forwarded `Lockspire.Web.AdminRouter` LiveView joins with an inner-router signed path while the browser requests the full host mount path; Phase 144 adoption demo uses guarded direct mounts with route parity. Public forwarded integration remains unverified and needs a separate library-level fix. | Deferred; no public router/API repair in Phase 144 Plan 02 | 2026-10-09 | v1.40 |
| Security | CR-01: private signing-key JWK material is persisted as plaintext JSON despite the `private_jwk_encrypted` field name | Critical, pre-existing, unresolved; deferred and not accepted or closed. Requires a dedicated encryption design before key persistence is release-ready. Resolved in v1.43 (envelope encryption at rest, 2026-10-16). | Phase 145 code review | v1.40 |
| seeds | SEED-261010-zzo — inset operator theme-select caret | dormant | 2026-10-10 | v1.40 |
| verification_gaps | 145/145-VERIFICATION.md | human_needed | 2026-10-10 | v1.40 |
| verification_gaps | 146/146-VERIFICATION.md | human_needed | 2026-10-10 | v1.40 |
| deferred_items | 145/deferred-items.md: Phase 145 Plan 02's existing compiler/type warnings outside its ownership | acknowledged | 2026-10-10 | v1.40 |
| deferred_items | 148/deferred-items.md: Existing compiler/type warnings outside Phase 148's copy-only scope | acknowledged; no change claimed | 2026-10-11 | v1.41 |
| todos | 2026-10-13-audit-dcr-default-lifetime-semantics.md | (presence-only) | 2026-10-15 | v1.42 |
| todos | 2026-10-14-bump-bandit-in-demo-and-clean-room-hosts.md | (presence-only) | 2026-10-15 | v1.42 |
| todos | 2026-10-16-mix-tasks-start-repo.md | (presence-only) | 2026-10-16 | v1.43 |
| verification_override | 155/155-VERIFICATION.md | passed at execution; stale after in-milestone 156/157 edits; override_closeout | 2026-10-16 | v1.43 |
| verification_override | 156/156-VERIFICATION.md | passed at execution; stale after in-milestone 157 edits; override_closeout | 2026-10-16 | v1.43 |

| todos | 2026-10-19-keys-reencrypt-via-repo-runner.md | Deferred follow-up after approved v1.44 closeout; not resolved | 2026-10-20 | v1.44 |

| deferred_items | 168/deferred-items.md: The test-host fixture has duplicate `record_trace/2` clauses and emits compiler warnings. status: open **Found:** Present before Phase 168 edits; unrelated to the authorization behavior. **Scope:** Deferred to a fixture cleanup task if warning cleanup is needed. | acknowledged for archival; warning unresolved | 2026-10-24 | v1.46 |

### v1.45 Accepted Debt

The audit’s eight entries are accepted for archival: Phase 163 wave0 bookkeeping; historical TDD classifier limits in 164-06 and 165-04; optional Phase 165 confirmation copy/rendered accessibility review; three undefined probes (A-EDGE-16/17/19); two descriptor-less prohibitions still flagged-unverified; eight missing historical SUMMARY completion fields; and the stale original REQUIREMENTS footer. The archived requirements footer is reconciled at closeout, while the original remains in git history. No historical RED evidence, passing probe or subjective review is invented.

Closeout type: verified_closeout. Known verification overrides: 0 newly acknowledged, 3 carried forward from a prior close. The pre-close artifact scan found zero open items; historical suppressed artifacts retain their own verdicts.

## Session Continuity

Last session: 2026-10-25T14:24:55.698Z
Stopped at: PR #140 merged; fresh exact-main acceptance passed; v1.47 delivery complete
Resume file: .planning/phases/174-packaged-proof-delivery-handoff/174-DELIVERY.md
Next: v1.47 delivery is accepted on main 173059a166e9ade0f5f57c9980b7b2400a98538c. Preserve evidence/custody and use milestone closeout before selecting the provisional SEC-01 direction; publication remains unselected.

### Blockers

None

## Decisions

- [Phase 171]: Maintainer delegated delivery reconciliation; current run owns preservation decisions. Retain historical worktrees and original local main; deliver completed v1.45/v1.46 separately from unfinished v1.47 planning. — Preserve unique history without inferring old ownership; fresh protected checks and exact-main acceptance remain required.
- [Phase 171]: Preserve and reuse the original accepted-main receipt; do not rerun the exact-main authority after ledger edits.
- [Phase 171]: Keep source-host, package, and external-suite evidence distinct; explicitly mark package and suite evidence not applicable for A171-001.
- [Phase 171]: Observed and expected outcomes may be equal when each is separately attributed in the evidence.
- [Phase 171]: Unlaunched OIDF profiles retain null wrapper exits/classifications and no receipts; environment readiness is not protocol acceptance.
- [Phase 171]: A171-003 unsupported response_mode and P171-005 pushed/front-channel scope conflict remain explicit required proof/policy gaps for Plan 03.
- [Phase 171]: External issuer/TLS/proxy/browser reachability is supplemental unavailable evidence, not a selected product defect.
- [Phase 171]: A171-003 requires HTTP 400 without OAuth Error Response parameters for unsupported response_mode; the controlled request reproduced the contrary redirect.
- [Phase 171]: For P171-005, the valid pushed scope is authoritative over the conflicting outer scope under the documented RFC 9126 to RFC 9101 clause chain; plain form PAR remains supported.
- [Phase 171]: Retain only the two reproduced correction scopes, reuse existing proof for the other ten cases, and keep unavailable optional external profiles supplemental.
- [Phase 171]: Limit current optional-profile claims to the sequential operator procedure; automatic overlap, interruption and cleanup remain UNVERIFIED because both wrappers were not launched.
- [Phase 171]: Select no optional profile retry; retain the existing unavailable owner and exact-environment actions.
- [Phase 171]: Leave Phase 171 requirements and phase-passed status for independent re-verification after this gap closure.
- [Phase 172]: Classify unsupported binary response_mode as the existing browser_error/3 disposition; retain supported modes, strict-signing behavior, and host login ownership.
- [Phase 173]: Removed the blanket outer-parameter rejection at the existing resolver; stored pushed values remain authoritative and the distinct request plus request_uri collision guard remains.
- [Phase 173]: Used independent real PAR references and asserted the exact relative consent route plus persisted client, scopes, state and nonce.
- [Phase 173]: External provider-origin, TLS, proxy and browser profiles remain supplemental and unlaunched; Phase 174 owns packaging and delivery.
- [Phase 174]: Selected receipts bind exact source, archive, package tree, vendor tree, resolution, and compiled candidate identities.
- [Phase 174]: Synthetic auth_time is host-supplied in the clean-room host; Lockspire account and policy ownership remain unchanged.
- [Phase 174]: The six authorization cases remain explicitly partial evidence; PAR expansion and final twelve-case acceptance belong to later plans.
- [Phase 174]: P171-001 and P171-004 share a required-PAR/S256 lifecycle run while retaining independent executed assertion rows.
- [Phase 174]: PAR fixtures and persisted projections remain on the private run-owned child-command seam; public behavior is observed over mounted HTTP.
- [Phase 174]: Lockspire 1.6.1 remains the package version; this plan adds proof and does not bump or publish it.
- [Phase 174]: Only two Phase 174 prohibitions move to resolved/judgment after scoped review; both retain non-authoritative flags and Phase 173 history remains unchanged.
- [Phase 174]: Freeze shipped inputs and bind existing source owners to one fresh complete package run.
- [Phase 174]: Keep DELIV-01 and DELIV-02 pending until candidate gates and delivery work are observed in Plan 04.
- [Phase 174]: Resolve the five reviewed prior prohibitions at the judgment tier while retaining non-authoritative human-review flags.
- [Phase 174]: Keep package source f01b6ef77889d38b032944eb37069d6d4b3b3171 distinct from immutable candidate ec6361d9840f2adfda85116d72fec0efe9065c6c.
- [Phase 174]: Preserve the first failed hosted CI attempt and evaluate exactly seven jobs from the successful latest attempt on the unchanged candidate SHA.
- [Phase 174]: Leave the new main receipt absent while PR #140 remains open; record the concrete main-acceptance blocker and parent-owned next action.
