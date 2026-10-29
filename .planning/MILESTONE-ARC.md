# Lockspire Rolling Milestone Roadmap

**Reviewed:** 2026-10-25, at v1.48 milestone selection after v1.47 closeout and the completed UI quality interview.
**Owner:** The agent starting or closing a milestone refreshes this document.
**Authority:** This is the live candidate ranking. [ROADMAP.md](ROADMAP.md) owns scheduled phases; [PROJECT.md](PROJECT.md) owns product scope; [MILESTONE-GUIDE.txt](MILESTONE-GUIDE.txt) owns standing decision posture. Current source, supported-surface contracts and fresh evidence outrank dated proposals.

## Direction

Improve the trustworthiness of the existing embedded Phoenix OAuth/OIDC provider. v1.45 delivered registration/credential lifetimes; v1.46 delivered native host integration and authorization. v1.47 delivered the selected protocol interoperability corrections. The owner accepted the recommended SEC-01-first order at the v1.48 selection gate; UI quality follows as the next substantial candidate. Keep accounts, login, consent presentation, branding and product policy host-owned.

The user approved this rolling-roadmap posture on 2026-10-24: research and adversarially examine consequential decisions upstream, synthesize a coherent recommendation, execute within the selected scope with little interruption, and leave a verifiable delivery handoff. Future candidates are adjustable hypotheses, not automatic execution authority.

## 2026-10-29 delivery checkpoint

E7AD local source passed 2,463 tests/zero failures plus two properties; fresh locked/floor verifier proof composed 26 receipts/64 passing cases with zero failures. Its archive/tree match EC92 byte-for-byte, so prior EC92 lifetime/SaaS/96host proof keeps its original execution attribution. Local metadata assembly, preservation/promotion and ROOT semantic checks passed. Published PR #141 remains f962fce4; CI40927824424 ended cancelled (five passed, Integration cancelled, Coverage skipped). Fresh exact push/body approval and a successful new hosted graph/artifact pair are still required. Plan11 is incomplete, Plan12 is not ready, 16/18 requirements are complete, and security remains OPEN_THREATS4. Integration/main acceptance are pending. This outcome does not change the UI-next ranking or authorize its implementation. Q1–Q10/final confirmation and OPS-03/KEK-04/token evidence triggers remain intact.

## Ranked Milestone Sequence

| Order / handle | Outcome and bounded scope | Status / entry trigger | Exit evidence |
|---|---|---|---|
| Entry maintenance | Deliver or explicitly reconcile the accumulated v1.45/v1.46 branch delta; establish clean synchronized green main, owned worktrees and coherent GSD state | Satisfied for v1.47 implementation entry by PR #138 and original accepted-main receipt at fe38beee; historical work and current custody are preserved | Exact-main acceptance receipt, required CI, Release push no-publish shape, reviewed prior-delta disposition and safe worktree handoff |
| **v1.47 OAuth/OIDC Core Interoperability & Hardening** | Reproduce historical OIDC/FAPI findings; correct selected authorization-response and PAR/profile boundaries only where supported-surface evidence warrants it; prove fixes through a packaged host | **Completed and archived2026-10-25.** Twelve qualified cases, two corrections, package12/12 and all14 requirements verified. PR140 merged reviewedhead6f10fcc7 as accepted main173059a1; fresh local acceptance, seven canonical push jobs and no-publish Release passed. Phase171–174 judgment flags remain non-authoritative; no public package was published. | Finding-to-standard-to-regression ledger; selected packaged HTTP cases; focused security review; full contributor/required CI gates; refreshed roadmap and clean delivery handoff |
| **v1.48 Client Authentication Key Isolation & Rotation** | SEC-01: dedicated-purpose rotatable encryption for client_secret_jwt verifier material, legacy reads/rewrap, mixed-version rollout, status and loss recovery | **Selected 2026-10-25.** Owner accepted the recommendation; focused research is complete and 18 requirements approved; the four-phase roadmap is approved. Phases 175–177 are independently verified (15/18 requirements) as of 2026-10-26; Phase 178 package proof and final delivery/main acceptance remain pending. Original implementation entry was accepted in Phase 175; current source acceptance is distinct from integrated main. | Existing clients survive documented upgrade/rotation; tampering/missing/retired keys fail closed; concurrent rewrite and secret rotation are safe; package upgrade and redaction proof |
| **Next available version: UI Stories & Continuous Quality** | Whole-UI inventory and complete layered coverage for Apps setup/configuration and Tokens/Consents investigation; maintainer-only phoenix_storybook, observed shared fixes and reliable mechanical regression checks | **Next substantial candidate after SEC-01.** Q1–Q10 and final summary confirmed; design interview complete. Preserve [proposal](research/ui-quality-engine/MILESTONE-PROPOSAL.md) and [recommendations](research/ui-quality-engine/RECOMMENDATIONS.md). Re-rank for urgent security/adopter evidence; no version or phases reserved. | Both jobs are inspectable from shared primitives through complete pages/jobs; coherent scenarios reject impossible states; real improvements have before/after evidence; reliable checks block new confirmed regressions within measured or explicitly revised budgets; same-PR maintenance is documented. |
| Next available version: Token Lifecycle Resilience | A narrow refresh/revocation/replay or selected-store transaction invariant | **Conditional.** Fresh deterministic counterexample or a material uncovered invariant; much of this is already implemented/tested | Reproducer plus actual PostgreSQL concurrency/rollback proof for the selected invariant; preserve family-wide reuse containment |
| Next available version: Key Maintenance at Scale | OPS-03: paged re-encryption dry-run and measured status-read improvements | **Conditional.** Measured memory/query/latency problem on realistic row counts | Bounded resource use, stable iteration, truthful partial progress/status, retry-safe and concurrent-update behavior |
| Next available version: Host Key Provider Integration | KEK-04: narrow host-controlled KMS/Vault provider seam | **Conditional.** Concrete adopter custody need with outage/latency/rotation requirements | Host-owned adapter and explicit failure contract; core library keeps a small dependency closure and embedded shape |
| Sustaining train | Focused fixes, dependency/security maintenance and truthful releases | Default between milestones or if no candidate has material value | Green exact main, coherent support/release truth, intentional clean workspaces |

v1.47 phases171–174 are archived. v1.48 schedules approved Phases 175–178; no later candidate has scheduled phases or a reserved version. Do not create detailed downstream plans until their evidence/entry decisions are settled. An urgent security finding can change this ordering.

## 2026-10-25 v1.48 selection reassessment

The owner said “follow ur recs” after the milestone selection checkpoint: retain SEC-01 first, then UI quality. Source inspection and v1.47 closeout supply a concrete verifier-key custody concern; no new token-concurrency counterexample, maintenance-scale problem or KMS custody requirement was supplied. The UI interview settles its future scope but does not establish a fresh observed usability defect or displace security work. Preserve its accepted decisions without restarting discovery. [v1.48 planning baseline](research/v1.48-client-auth-key-isolation/BASELINE.md) records exact entry identity, 27 PASS / 6 WARN / 0 BLOCK planning preflight and the separate fresh-main implementation-entry gate. No fresh protocol, runtime, visual or accessibility acceptance is claimed by selection.

## 2026-10-25 closeout reassessment

Accepted main is `173059a166e9ade0f5f57c9980b7b2400a98538c`; fresh receipt SHA-256 `f50652c307019bbe57ad2f4a2a24bbefbc830bfd6f00010431b68971b4c095dd`. Main CI40198968774 passed7/7; Release40198968751 passed no-publish. Final selected package proof is source73bb4681, receipt9ec9de15…; candidate9b8cf54d and reviewed PRhead6f10fcc7 retain distinct identities. The [archived handoff](milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-DELIVERY.md) records exact hashes and retained resource custody. No new supported-core counterexample, scale evidence or adopter custody need changed the ranking: SEC-01 remains preferred provisional next scope. Start `$gsd-new-milestone` before requirements/design; no future implementation is selected.

## Historical 2026-10-25 Phase174 Plan03 checkpoint

The fresh local Lockspire 1.6.1 package run at source revision
`a348bf71285cb0ffe9eeba0da94a6c2d46faa477` executed A171-001–006 and
P171-001–006: 12 passed, 0 failed, 0 skipped. Receipt SHA-256 is
`751ef1398bfe9ca902d60fc03a6ab673c9fee6b23def3356e6ebf52b79803de1`;
archive SHA-256 is
`89baff6aaf0549cee541ec9b381798fe502c8be33c71ff894440ec85563598cc`.
Cleanup, evidence scanning, and redaction checks passed. This is local
package-to-loopback-host evidence; it does not establish candidate CI, a new
accepted-main result, publication, or external profile reachability.

At this checkpoint the implementation branch is
`milestone/v1.47-core-hardening` at `a348bf71285cb0ffe9eeba0da94a6c2d46faa477`;
the local `main` and `origin/main` refs both remain at
`fe38beee987b135e87c99e7aa7f2488b4c8613e8`. GitHub's latest observed `CI` and
`Release` workflow runs on that main SHA succeeded on 2026-10-24. No workflow
run was listed for the milestone branch, so its candidate gates remain pending.
The original exact-main receipt remains the accepted-base evidence; no branch
merge, release tag, publication, or next-milestone authorization is claimed.

## v1.47 Scope and Decision Gates

See [scope and decisions](research/v1.47-core-hardening/SCOPE.md), [research synthesis](research/v1.47-core-hardening/SUMMARY.md) and [archived requirements](milestones/v1.47-REQUIREMENTS.md).

1. Phase 171 qualifies exact inputs, current failures and ownership; old suite_failure summaries are not proof of current bugs.
2. Authorization error/redirect/silent-auth cases are the first likely vertical slice. PAR/FAPI boundary cases follow only after transport/issuer/WebRunner attribution.
3. For each included case, specify the observable response, applicable standard, current support boundary, positive/negative proof and owner before implementation fans out.
4. If a candidate is already correct, reuse its evidence; do not manufacture a fix or duplicate a test. If no material findings remain, narrow/replan to an honest evidence/maintenance closeout.
5. Keep external-suite results supplemental and non-certifying. Overall full-FAPI success is not a new release gate. Selected repo-native acceptance remains mandatory.
6. SEC-01 storage migration, KMS, broad grant rewrites, new flows and UI redesign remain outside this milestone.

## Refresh at Every Boundary

At milestone start and close, compare this ranking against fresh branch/main/CI state, supported-surface docs, current code/tests, adopter evidence and retained findings. Mark candidates selected, shipped, deferred, obsolete or rejected with a reason and source/date. Carry unresolved owners and next triggers forward. Change stale proposals rather than restarting the discussion or inheriting their claims.

At each run stop, record base and head SHAs, owned edits/worktrees, validation commands/results, blockers, remaining cleanup, and the next exact action in STATE.md or its linked handoff. Planning completion, implementation completion, integration into green main and public publication are distinct states.

## 2026-10-29 Phase 178 delivery checkpoint

The EC92 source-bound local package and host qualification is recorded with its actual identities in [the Phase 178 correction evidence](phases/178-packaged-upgrade-proof-delivery-handoff/178-11-CI-CORRECTION-EVIDENCE-ec92cca0.json). The single milestone PR #141 is at reviewed head `f962fce47d97a78ae67522301aa65104d42a8b2d`; run `40927824424` attempt 1 is still in progress at the latest owner observation. Dialyzer, Release Hygiene Drift and Adoption Demo Smoke passed; Fast Checks and Integration Checks were running; the Minimum job's fast and floor-host steps passed but the job was not terminal; Complete Coverage Evidence had no terminal result. Candidate gates and matching hosted package artifacts are therefore pending; integration and accepted main remain pending. Do not start the next implementation or infer merge/publication authority from the local proof.

UI Stories & Continuous Quality remains the next substantial candidate after the security milestone's delivery/main gates are actually satisfied. Keep its accepted Q1–Q10 and final summary intact; no version or phase numbers are reserved. Retain the original proposal, recommendations, OPS-03/KEK-04/token-lifecycle triggers and all existing conditional ranking criteria. This checkpoint does not restart the UI interview or claim UI implementation/acceptance.

## Delivery Posture

Use the existing [development train](DEVELOPMENT-TRAIN.md), [release train](RELEASE-TRAIN.md) and [hygiene checklist](REPO-HYGIENE-CHECKLIST.md). Commit owned changes, preserve unknown edits and unique commits, retire owned temporary worktrees/resources once safely integrated, and re-observe main after merge. A retained workspace requires an explicit owner/purpose/next action; it is not a clean-baseline pass. Never force cleanup to make a status display green.

The [dated baseline](research/v1.47-core-hardening/BASELINE.md) retains the original pre-entry observations. Phase 171 subsequently established reviewed delivery and accepted main `fe38beee987b135e87c99e7aa7f2488b4c8613e8` through the unchanged [original receipt](milestones/v1.47-phases/171-accepted-baseline-finding-qualification/171-MAIN-ACCEPTANCE.json). Its [passed qualification](milestones/v1.47-phases/171-accepted-baseline-finding-qualification/171-VERIFICATION.md) authorizes the narrow downstream planning scope. The retained evidence branch is distinct from accepted main173059a1. Later candidate/main delivery was completed with its own exact identities in the archived Phase174 receipt; publication remains unselected.

## History and Stop Rule

Older ranking/guide content is preserved in [pre-v1.47 research history](research/archive/pre-v1.47/); completed milestone scope remains in [MILESTONES.md](MILESTONES.md). Do not re-open shipped DPoP nonce, DCR metadata, UI or host-integration milestones because an older strategic file still calls them candidates.

Stop broad research when additional perspectives no longer change a consequential decision, acceptance case, risk control or sequence. Prefer targeted reproduction over another ecosystem survey. Sustain or stop when the remaining candidates offer only speculative breadth.
