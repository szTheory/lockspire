---
gsd_state_version: "1.0"
milestone: v1.48
milestone_name: Client Authentication Key Isolation & Rotation
current_phase: 178
current_phase_name: Packaged Upgrade Proof & Delivery Handoff
current_plan: 11
status: executing
stopped_at: Plan 11 canonical source and lifetime passed; verifier and installed-host qualification executing
last_updated: "2026-10-28T22:01:00.177014+00:00"
last_activity: 2026-10-28
last_activity_desc: Corrected C50d canonical 2456/0 plus 2 properties and lifetime 47 checks/9 scenarios passed; verifier proof executing
state_head: 1757638a7770bb6f09c3b085f002fa7c8b7ed518
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 31
  completed_plans: 29
  percent: 75
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-10-25 after v1.48 selection)

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 178 Plan 11 has three accepted author reviews for corrected source `50d67751a7844dee2f5f595195a6ab455e313fc6` (1,079 selected inputs). Frozen execution checkout `1757638a7770bb6f09c3b085f002fa7c8b7ed518` passed canonical source CI: 2,456 tests, zero failures, two properties. The three lifetime tests passed, and native composition validated 47 checks across nine scenarios; parent independent checks reproduced the retained receipt bytes. The three earlier canonical failures remain unexplained, with their original identities retained and one failed-run journal pointer unavailable. VPROOF-02 remains reopened until locked/floor verifier and current/minimum installed-host qualification completes. PR #141 remains at `33db5483` with failed required hosted CI; no new remote action is authorized. Plan 11 incomplete; Plan 12 unstarted.

## Current Position

Phase: 178 (Packaged Upgrade Proof & Delivery Handoff) — EXECUTING
Current Plan: 11
Total Plans in Phase: 12
Plan: 11 of 12; 10/12 complete; Plan 12 not ready until Plan 11 completes
Status: Corrected source and lifetime proof passed; locked/floor verifier and installed-host proof executing. Required hosted candidate graph and main/delivery acceptance remain pending.
Last activity: 2026-10-28 — Canonical source and lifetime evidence independently verified; locked verifier partition running.

## Performance Metrics

v1.48: 18 approved requirements, 4 approved phases (175–178), 31 plans with 20 executed; 3/4 phases complete. Phase 177 corrected source `5e8cd65e` passed full `mix ci` (15 boundary, 2 properties and 2,138 fast tests, 261 integration tests; zero failures), independent security 29/29, clean source review across 32 files and prior regressions 188/0. Independent verification passed 47/47 truths, six requirements and all 23 decisions; no behavior override. Earlier failed attempts and two unclassified/three prohibition flags remain visible. Phase 176 corrected source `71627f27` passed full `mix ci` (2 properties, 2,102 fast tests and 231 integration tests; zero failures), focused security 26/0 and prior-phase regressions 30/0. Independent verification passed 28/28 truths; security closed 22/22 threats and source review found zero issues across 29 files. Four initial audit mechanisms were corrected; failed environmental attempts and three generic edge/three prohibition flags remain disclosed. Earlier Phase 175 candidate f3ef32a7 passed canonical mix ci: boundary 15/0, main 2,055/0 and integration 210/0, with recorded skips/exclusions. Source review has zero open findings.  Fresh pre-qualification exact-main acceptance and required tracer feedback both passed: 22 PASS, 2 WARN, 0 BLOCK, full local contributor gate, seven canonical CI jobs and no-publish Release at `173059a1`. The receipt's final ExUnit stage is 200 tests; the main stage separately passed 2,057 tests. Historical v1.47 remains 4 completed phases, 10 plans and 14 verified requirements; its old receipts are unchanged.
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
| Phase 175 P01 | 22min+ (from first controlled attempt) | 2 tasks | 3 files |
| Phase 175 P02 | 10min+ | 3 tasks | 6 files |
| Phase 176 P01 | 12 min | 2 tasks | 5 files |
| Phase 176 P02 | 12 min | 2 tasks | 7 files |
| Phase 176 P03 | 18 min | 2 tasks | 4 files |
| Phase 176 P04 | 8 min | 2 tasks | 4 files |
| Phase 176 P05 | 7 min | 2 tasks | 4 files |
| Phase 176 P06 | 6 min | 2 tasks | 2 files |
| Phase 176 P07 | 34min | 2 tasks | 7 files |
| Phase 177 P01 | 9min | 2 tasks | 6 files |
| Phase 177 P02 | 9min | 2 tasks | 6 files |
| Phase 177 P07 | 8min | 2 tasks | 7 files |
| Phase 177 P03 | 23min | 2 tasks | 7 files |
| Phase 177 P04 | 14min | 2 tasks | 8 files |
| Phase 177 P05 | 11 min | 2 tasks | 4 files |
| Phase 177 P06 | 6min | 2 tasks | 3 files |
| Phase 177 P08 | 10min | 2 tasks | 5 files |
| Phase 177 P09 | 35min | 2 tasks | 11 files |
| Phase 178 P01 | 36min | 2 tasks | 8 files |
| Phase 178 P02 | 33min | 2 tasks | 8 files |
| Phase 178 P03 | >=76m20s | 2 tasks | 4 files |
| Phase 178 P04 | 44m | 2 tasks | 9 files |
| Phase 178 P05 | 31min | 2 tasks | 7 files |
| Phase 178 P06 | 2h 26m | 2 tasks | 7 files |
| Phase 178 P07 | 95 min+ (elapsed from first Plan 07 commit; active time unavailable) | 2 tasks | 20 files |
| Phase 178 P08 | 96min | 2 tasks | 48 files |
| Phase 178 P9 | 15min | 2 tasks | 7 files |
| Phase 178 P10 | 75min | 3 tasks | 20 files |

## Accumulated Context

**Current decision posture:** The owner accepted the recommended SEC-01-first milestone selection with “follow ur recs” on 2026-10-25. Use the [standing guide](MILESTONE-GUIDE.txt), [rolling ranking](MILESTONE-ARC.md) and [v1.48 baseline](research/v1.48-client-auth-key-isolation/BASELINE.md). Focused research is complete and the owner approved all 18 requirements; the four-phase roadmap is approved. Preserve the UI proposal's Q1–Q10 and confirmed final summary; do not repeat its interview. Prefer existing vetted primitives and small, flat dependency trees.

**v1.48 entry limits:** This is a local planning branch preserving prior closeout/interview history, not fresh accepted main. Reconcile the retained delivery delta and obtain exact-main acceptance through the existing hygiene helper before product implementation. Preserve historical phases 142/143, old worktrees and demo resources; no blanket phase clearing. GSD's latest-completion parser sees only “Shipped” headings and reports v1.44 incorrectly; authoritative completed history ends at Phase 174. Phase 175 is the approved next phase.

**Historical v1.47 decision posture:** The following entry and phase records preserve their original execution context. Resolved v1.47 blockers below do not block or describe current v1.48 planning.

**Historical v1.47 entry limits:** Phase 171 could be planned before its fresh exact-main acceptance and finite qualification ledger. The [dated baseline](research/v1.47-core-hardening/BASELINE.md), [original machine-state bytes](research/v1.47-core-hardening/STATE-JSON-BEFORE.json) and [Phase 174 delivery](milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-DELIVERY.md) preserve the original sequence and eventual resolution. Full external suites remain supplemental/non-certifying.

**Phase 171 entry preflight (2026-10-24, after planning commit 322ae40f):** Independent checker passed all 3 plans; 4/4 requirements covered. Read-only GitHub API still reports main `a1e39a01aca258d0ac5f36414bf47c45686d92c1`; local main is `a1a55de0a931c641fbe176e5c3f9c4737aa62b9d`. The planning branch has 414 commits beyond observed origin/main and is not accepted main. All four registered worktrees are clean, but the three prior-agent worktrees retain the unresolved ownership/disposition recorded in BASELINE.md. Automatic advancement stops before acceptance, qualification or product edits; no plan is complete. Next owner: executing maintainer; next action: complete 171-01's reviewed cumulative-delivery and worktree/edit ownership reconciliation, preserving unknown work, before choosing an integration route and running exact-main acceptance. Runtime availability is not the blocker: process-local `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix --version` succeeds (Mix 1.19.5 / OTP 28), without changing toolchain files or installing anything. No acceptance/profile/test execution is claimed by this preflight.

v1.46 completed four phases, 16 plans and all 15 requirements. All four verification owners passed immediately before phase archival; [closeout projection](milestones/v1.46-CLOSEOUT.json) preserves that check. The [audit](milestones/v1.46-MILESTONE-AUDIT.md) records 14/14 integration boundaries, 6/6 flows, four Nyquist-compliant phases and 68/68 security threats closed. No phase-verification override or human UAT remains. Archived covered_files paths retain their original checkout meaning; reports are not restamped after relocation.

Closeout type: override_closeout. Known verification overrides: 1 newly acknowledged, 3 carried forward from a prior close (see STATE.md Deferred Items). The new acknowledgment covers only the existing duplicate record_trace/2 fixture warning; all four phase verification owners passed immediately before archival. Historical suppressed records retain their verdicts.

Local package/browser/runtime receipts retain exact source and package identities. Hosted CI, minimum CI BEAM and branch protection remain unobserved. Publication is separate; no remote refs were updated. Original unrelated state.json bytes remain preserved and excluded from commits. Older quick tasks remain in place. Detailed phase decisions and evidence remain in [pre-close state](milestones/v1.46-STATE.md), [phase archive](milestones/v1.46-phases/) and PROJECT.md.

### Pending Todos

- SEC-01 is selected for v1.48. UI quality is the next substantial candidate; its interview is complete. KEK-04, OPS-03, legacy-plaintext fixture maintenance and existing milestone debt retain their owners and triggers outside v1.48.
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

Last session: 2026-10-28T14:24:03Z
Stopped at: Resume context restored from structured handoff and checkpoint. Clean local bdbd6e5e and open PR #141 at 33db5483 reconfirmed; hosted CI still has four successes, two failures and coverage skipped. Ready for Plan 11 local corrections; no implementation or runtime started during restoration.
Resume file: .planning/phases/178-packaged-upgrade-proof-delivery-handoff/.continue-here.md
Structured handoff: Consumed on resume; original retained in commit bdbd6e5e and detailed phase checkpoint above.
Next: After clearing context, run `$gsd-execute-phase 178` with no wave filter. Read phase `continue.md`, the retained `.continue-here.md` and `178-11-APPROVED-UPDATE-OUTCOME.json` before execution. Resume Plan 11 local CI corrections and continue through remaining ready work automatically; the owner explicitly does not want to babysit individual waves or routine continuation prompts. Fix and verify routine scoped failures autonomously. Do not repeat the completed push/body update. Preserve redaction, authenticated source ownership, exact historical proof identities, and unresolved legacy/minimum causes. Local implementation/commits were previously authorized; further remote mutations require separate authorization after the corrected local SHA/body are concrete and reviewable. CI efficiency recommendations remain captured in the phase checkpoint and have not been implemented. Plan 11 and VDELIV-01/02 remain incomplete; Plan 12 has not started and remains dependent on Plan 11. Historical Phase 143 plans without summaries retain their existing disposition; no pending todo files, interrupted agent or async-job manifest was found. Resume bookkeeping changes are uncommitted and intentional; see phase `continue.md`.

### Blockers

- Current published CI run 40696973463 attempt 1 failed Integration and Minimum; coverage aggregation was skipped and required verifier pair artifacts are absent. Legacy inner failure and minimum VM-exit versus readiness-timeout remain unknown. See the retained phase checkpoint and committed approved-update outcome for exact evidence and correction scope.

## Decisions

- [Phase 178 execution resume]: After root explicitly asked whether to continue implementation and local commits, the owner replied “yes i authorize”. Resume Plan 01 from preserved edits/evidence; retain the earlier approval rejection. This authorization does not include merge or publication.

- [Phase 178 discussion]: Owner delegated subagent research and automatic adoption of coherent scoped recommendations. Use bounded installed journeys across both pairs and built-in/delegated PostgreSQL storage, independently attributed predecessor artifacts, actual contention/audit-INSERT witnesses and explicit pre/postmerge acceptance sequencing. See `178-CONTEXT.md`; no runtime or main-acceptance outcome is claimed.

- [Phase 177 discussion]: Owner delegated fan-out research and automatic adoption of coherent scoped recommendations. Preserve authenticated age metadata during dedicated custody rewrap, distinguish legitimate no-material clients, use selected authority with verifier-only atomic audit, require fresh complete local custody check, resolve bare-Mix configuration locally, and include existing disclosure paths. See 177-CONTEXT.md; runtime requirements remain pending.

- [Phase 176 discussion]: Owner accepted the recommended bundle with “what do u rec? let's do that”. Preserve dedicated custody/configuration, final-ID writer coherence, approved native/migrated lifetime policy, and reader-first activation. Preserve existing token/introspection/revocation/device/CIBA JWT support and PAR/FAPI exclusions; see 176-CONTEXT.md.

- [Phase 175 discussion]: Adopt the user-delegated coherent scoped recommendations in 175-CONTEXT.md. Preserve ciphertext-sensitive authority, explicit reader-first activation, narrow shared-PostgreSQL maintenance authority and existing-path disclosure proof. Fresh exact-main acceptance and actual-caller legacy qualification remain unperformed; native/migrated age policy must receive an explicit qualified disposition before Phase 176 planning.

- [v1.48 roadmap]: Owner explicitly approved Phases 175–178 on 2026-10-25 after approving all 18 requirements. Next action is Phase 175 discussion; no product implementation is complete.

- [v1.48 selection]: Follow the recommended SEC-01-first order; retain UI quality next with all ten interview decisions and final confirmation intact. Research, requirements and roadmap approvals are recorded; phase discussion/planning and implementation-entry gates remain.

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
- [Phase 175]: Use synchronized main at 173059a166e9ade0f5f57c9980b7b2400a98538c as the fresh pre-qualification baseline.
- [Phase 175]: Preserve historical and unknown-owner worktrees, databases, demo resources, and generated artifacts; do not clean or publish.
- [Phase 175]: Keep the VBASE-01 unclassified edge visibly flagged for the later compatibility work.
- [Phase 175]: Owner explicitly approved the recommended D-20 native age policy revision on 2026-10-25; native dedicated material follows configured client-secret lifetime and migrated rows retain their authenticated original finite deadline.
- [Phase 177]: Require exact agreement among declared maintenance participants and the selected client, transaction, and audit stores before access.
- [Phase 177]: Keep native verifier custody decoding internal and report changes only after the selected outer transaction commits.
- [Phase 177]: Use one internal authenticated envelope decoder for custody inspection and authentication, applying migrated expiry only to authentication.
- [Phase 177]: Promote legacy verifier material only through Legacy.authenticated_metadata/3, preserving its authenticated finite deadline and requiring hash agreement.
- [Phase 177]: Preserve RegistrationResult and rotation handoff shapes; redact stored credentials recursively without adding a wrapper struct.
- [Phase 177]: Apply the existing sensitive repository option to every full-client query/write so Logger and query telemetry are both suppressed.
- [Phase 177]: Map raw Postgrex and DBConnection failures to fixed reasons while preserving ordinary validation and lifetime outcomes.
- [Phase 177]: Use identical PostgreSQL COLLATE C expressions for exclusive cursor comparison and ordering after checking UTF8 server encoding.
- [Phase 177]: Only a complete nil-cursor check establishes current custody; apply reports committed progress and requires a separate fresh check.
- [Phase 177]: Return bounded encoded client identities, fixed next actions, and authenticated safe key IDs only.
- [Phase 177]: Bare verifier maintenance resolves a complete task-local context with freshly validated signing exclusions and never changes the serving-node startup snapshot.
- [Phase 177]: Reject a reporting rewrap when its selected Ecto repository is already in a transaction; retain the provisional low-level callback for caller-owned transactions.
- [Phase 177]: Treat an uncertain commit response as neither success nor rollback; reconcile with a fresh complete inventory.
- [Phase 177]: Use committed fixtures and exact pg_blocking_pids relationships to prove concurrency behavior.
- [Phase 177]: Real PostgreSQL maintenance between JWT authentication and the issuance guard proves obsolete identity rejection; restoration preserves the partner secret while authorized rotation replaces it.
- [Phase 177]: Preserve the existing one-time plaintext handoff and client/report shapes; no production change was needed after forced disclosure cases passed.
- [Phase 177]: Treat a successful fresh check as local store evidence; fleet parity, quiescence, backups, and rollback remain host-owned.
- [Phase 177]: Keep original-key restoration distinct from authorized partner-secret replacement and its one-time handoff.
- [Phase 178]: Keep installed candidate source revision separate from runner revision; source-bind clean checkout package inputs and leave unproven external source unavailable.
- [Phase 178]: Use dedicated verifier custody independently from endpoint and signing keys; keep group receipts partial and require exact positive tracer outcomes.
- [Phase 178]: Keep VPROOF-02 pending until remaining Phase 178 plans complete their assigned coverage.
- [Phase 178]: Keep delegated maintenance authority limited to the exact declared client, transaction, audit, and repository participants.
- [Phase 178]: Select optional verifier fixture files by fixed group ownership and fail when a selected input is missing.
- [Phase 178]: Keep these core receipts partial; VPROOF-02 remains pending until the remaining Phase 178 proof groups complete.
- [Phase 178]: One-off Mix commands keep runtime listeners disabled; only owned listener processes enable the endpoint server.
- [Phase 178]: Both old and candidate writers remain legacy through overlap; dedicated activation follows observed predecessor exit.
- [Phase 178]: Select rollout and legacy-control through separate explicit CLI entrypoints; legacy-control accepts locked/builtin only.
- [Phase 178]: Use the configured issuer string as client assertion audience on all five installed HTTP endpoints.
- [Phase 178]: Run the assembled release foreground command as an owned process group and bind the loaded maintenance beam to that release.
- [Phase 178]: Keep VPROOF-02 pending until the remaining Phase 178 proof groups complete their assigned coverage.
- [Phase 178]: Capture PostgreSQL backend IDs inside each selected transaction and require the exact observed pg_blocking_pids relation before a contention case passes.
- [Phase 178]: Provision pool capacity only in the generated transaction-proof host; treat it as headroom because the backend identity mismatch, not pool starvation, was the concrete observed blocker-witness cause.
- [Phase 178]: Keep VPROOF-02 pending until all remaining Phase 178 evidence owners pass.
- [Phase 178]: Keep all six group receipts partial; VPROOF-02 remains pending until the remaining Phase 178 evidence owners pass.
- [Phase 178]: Run issuance probes inside the owned host VM so mounted HTTP callbacks share the serving process and barrier state.
- [Phase 178]: Use fixed HTTP status and OAuth error enums and field-name-only failure summaries; never retain child diagnostics.
- [Phase 178]: Keep Plan 07 disclosure receipts partial and VPROOF-02 pending until all Phase 178 proof owners complete and independent review accepts the evidence.
- [Phase 178]: Run remaining database-backed source checks only through scripts/ci/run_owned_source_tests.py; preserve both wrong-target incidents without repair or cleanup.
- [Phase 178]: Retained receipt proof pins runner revision, candidate source owner, package archive/tree and current validator revision separately.
- [Phase 178]: Plan 10 owns fresh fixed-wrapper pair execution and strict composition of the exact 14 locked plus 12 floor receipts; no third all-scope producer is needed.
- [Phase 178]: Authenticated frozen archive/input ownership remains Plan 10 scope; Plan 08 accepts explicitly pinned checkout receipts.
- [Phase 178]: The install generator owns Phoenix integration scaffolding; verifier keys and their configuration remain host-owned.
- [Phase 178]: A mode-less maintenance task applies; preview, apply, and a separate fresh beginning-to-end check remain distinct.
- [Phase 178]: A local custody check does not authorize fleet retirement, and restored keys remain distinct from authorized partner-secret replacement.
- [Phase 178]: Retained package validation corroborates existing receipts only; fresh fixed-wrapper runs and frozen inputs remain Plan 10 work.
- [Phase 178]: Plan 10 completes VPROOF-02 with actual frozen-input package matrix and post-freeze canonical source CI; VDELIV-01 and VDELIV-02 remain pending hosted, audit, and main/delivery evidence.
- [Phase 178]: Plan 10 source and package evidence remains historical and valid for its exact 1,076-input frozen closure; after main-base synchronization, requalify the 1,077-input closure before marking VPROOF-02 complete.

## Operator Next Steps

- Resume Phase 178 Plan 11 from the latest execution checkpoint: preserve C50d/H175 canonical and lifetime evidence, finish native verifier pairs and six installed-admin journeys, then transfer validated owner/source/package records and prepare the exact final publication proposal. Keep all failed epochs, retractions, missing-token limitations, E-09/E-10 and generic/descriptorless flags visible. No additional push/body update/rerun/merge/release is authorized by the consumed `33db5483` approval.
- Preserve the immutable entry receipt, candidate CI/input hashes and retained custody; integrated-main acceptance remains Phase 178 work under the single milestone PR train. Merge and publication remain separately gated.

## 2026-10-28T14:00:27.096694+00:00 — Approved PR Update / Hosted Qualification

The user-authorized exact `33db5483` non-force push and approved `cb4b7c4d` PR #141 body update completed and were verified. Run 40696973463 attempt 1 is terminal: four required successes, Integration and Minimum failures, Complete Coverage skipped; Dependency Review succeeded. Six Integration headers and Minimum’s fixed startup witness are attributed in `178-11-APPROVED-UPDATE-OUTCOME.json`. No source change or local runtime followed the hosted failures. The old private lab/cache remain removed. Plan 11/Phase 178 and VDELIV-01/02 remain incomplete; no merge or further remote mutation is authorized. Subsequent tracking commits remain local and unpushed, distinct from published `33db5483`.
