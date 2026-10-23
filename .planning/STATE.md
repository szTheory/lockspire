---
gsd_state_version: "1.0"
milestone: v1.46
milestone_name: Embedded Host Integration Reliability
current_phase: 169
current_phase_name: Install and Upgrade Convergence
current_plan: 5
status: executing
stopped_at: Phase 169 planned and independently checked; ready to execute five plans
last_updated: "2026-10-23T22:13:58.196Z"
last_activity: 2026-10-22
last_activity_desc: Phase 169 execution started
state_head: 0e25eb8937cf5f38b08433d7d66080e35c4e50de
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 11
  completed_plans: 10
  percent: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-10-22 for v1.46)

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 169 — Install and Upgrade Convergence

## Current Position

Phase: 169 (Install and Upgrade Convergence) — EXECUTING
Current Plan: 5
Total Plans in Phase: 5
Status: Ready to execute
Last activity: 2026-10-22 — Phase 169 execution started

## Accumulated Context

### Decisions

Phase 168 Plans 01–03 passed their focused runtime checks and the final `mix test.fast` selector. Coverage includes current host policy at HTTP, disconnected/connected entry, cached-response connected rejoin, public/consent cross-session entry, every admin destination and native params patches. All four HAUTH requirements are complete. Three unspecified probe assumptions remain flagged; both descriptor-less prohibitions have individual automated/source-evidence closure records. Browser/socket, packaged and exact-floor proof remains Phase 170; install/demo convergence remains Phase 169.

Phase 167 completed three plans: native host-expanded routes, required host pipelines/current-identity hooks, fixed :lockspire_admin session, mount alignment, 29-route parity and public/consent separation. Fresh verification passed 48 tests and all 22 truths; security closed 12/12 threats and code review found no issues. The two descriptor-less prohibition checkpoints were individually resolved through automated tests and delegated evidence review in 167-UAT.md. Canonical verification and the combined completion predicate passed; no override or human pass was assumed.

The user reaffirmed automation-first verification on 2026-10-22: shift checks left, reuse CI coverage, hand off only genuinely necessary human work, and record closures to prevent repeat UAT. Follow VERIFICATION-POLICY.md and PROJECT.md. Missing check descriptors require classification/evidence, not an automatic maintainer prompt. Full denial proof, install/upgrade convergence and transport/package/exact-floor proof retain their Phase 168–170 owners.

v1.46 scope and research are confirmed; all 15 requirements were approved on 2026-10-22. Approved phases 167–170 cover routing, host authorization, installation/upgrade convergence and packaged/runtime proof. The user approved the roadmap on 2026-10-22. Mechanical integration and automated acceptance only; no visual redesign, identity system or publication scope. Research was performed inline; no new subagents were spawned.

v1.45 decisions and validated requirements are recorded in PROJECT.md and the archived phases. Full pre-close context, performance metrics and historical concerns are preserved in [v1.45-STATE.md](milestones/v1.45-STATE.md). All five phase verification owners passed immediately before archival; their original fingerprint paths remain historical checkout paths and were not restamped after the move.
- [Phase 168]: Keep mutable host identity, session and staff policy in test-host authority; independently re-resolve it at HTTP and LiveView boundaries.
- [Phase 168]: Prove connected denial from a successful static response using live(conn) after host-policy withdrawal.
- [Phase 168]: Use public live(sent_conn) to prove a new server-side connected join checks current host authority; Phase 170 owns browser/socket transport proof.
- [Phase 168]: Re-resolve current host authority at every params transition through the existing on_mount seam; keep identity, roles, events, and logout policy host-owned.
- [Phase 168]: Model a cross-session redirect and fresh HTTP/live entry separately; do not claim browser transport proof.

### Blockers/Concerns

No active Phase 167 blocker. Its two original prohibition flags are closed in the UAT ledger; do not recreate them from historical plan/report text without a relevant change or contradictory evidence. A-167-MNT-02 remains an unclassified probe without an additional acceptance predicate; the written mount criteria are verified. Preserve evidence boundaries for Phases 168–170.

No active v1.45 implementation blocker. Its audit retains eight nonblocking debt entries and explicit undefined-probe/visual limits. [Audit](milestones/v1.45-MILESTONE-AUDIT.md). Latest verified public package remains 1.6.1; publication of the lifetime candidate is separate. Historical Phase 138/140/143 and visual exceptions are preserved in the archived pre-close state and the disclosure table below.

### Pending Todos

- Phase 138: UAT #100 remains pending an authorized live snapshot refresh; current inventory dispositions remain proposal-only until exact-target revalidation and action authority.
- Phase 140: WR-01 remains deferred with unknown cause; reopen only if the exact sealed Release Please relation rejection recurs, then capture stage-specific evidence.
- Future bounded conformance: supplemental OIDF/FAPI evidence remains redacted, supplemental, and non-certifying.

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

### v1.45 Accepted Debt

The audit’s eight entries are accepted for archival: Phase 163 wave0 bookkeeping; historical TDD classifier limits in 164-06 and 165-04; optional Phase 165 confirmation copy/rendered accessibility review; three undefined probes (A-EDGE-16/17/19); two descriptor-less prohibitions still flagged-unverified; eight missing historical SUMMARY completion fields; and the stale original REQUIREMENTS footer. The archived requirements footer is reconciled at closeout, while the original remains in git history. No historical RED evidence, passing probe or subjective review is invented.

Closeout type: verified_closeout. Known verification overrides: 0 newly acknowledged, 3 carried forward from a prior close. The pre-close artifact scan found zero open items; historical suppressed artifacts retain their own verdicts.

## Session Continuity

Last session: 2026-10-23T00:40:05.888Z
Stopped at: Phase 168 complete, ready to plan Phase 169
Resume file: None
Next: `$gsd-plan-phase 169` or `$gsd-discuss-phase 169`. Phase 168 verification passed with no human items; final focused checks passed 45 tests and the broad suite passed 1,977 checks. Preserve original unstaged state.json bytes. Phase 168 proves server-side authorization and navigation; browser/socket, packaged and exact-floor proof remains Phase 170. No Phase 169 implementation has begun.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 168 P01 | 8m | 2 tasks | 5 files |
| Phase 168 P02 | 8m | 2 tasks | 1 files |
| Phase 168 P03 | 18m | 2 tasks | 6 files |
