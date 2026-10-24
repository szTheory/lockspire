# Lockspire Rolling Milestone Roadmap

**Reviewed:** 2026-10-24, after v1.46 archival and user approval of the core-hardening direction.
**Owner:** The agent starting or closing a milestone refreshes this document.
**Authority:** This is the live candidate ranking. [ROADMAP.md](ROADMAP.md) owns scheduled phases; [PROJECT.md](PROJECT.md) owns product scope; [MILESTONE-GUIDE.txt](MILESTONE-GUIDE.txt) owns standing decision posture. Current source, supported-surface contracts and fresh evidence outrank dated proposals.

## Direction

Improve the trustworthiness of the existing embedded Phoenix OAuth/OIDC provider. v1.45 delivered registration/credential lifetimes; v1.46 delivered native host integration and authorization. The next selected work concerns protocol interoperability. UI work is not the default. Keep accounts, login, consent presentation, branding and product policy host-owned.

The user approved this rolling-roadmap posture on 2026-10-24: research and adversarially examine consequential decisions upstream, synthesize a coherent recommendation, execute within the selected scope with little interruption, and leave a verifiable delivery handoff. Future candidates are adjustable hypotheses, not automatic execution authority.

## Ranked Milestone Sequence

| Order / handle | Outcome and bounded scope | Status / entry trigger | Exit evidence |
|---|---|---|---|
| Entry maintenance | Deliver or explicitly reconcile the accumulated v1.45/v1.46 branch delta; establish clean synchronized green main, owned worktrees and coherent GSD state | Satisfied for v1.47 implementation entry by PR #138 and original accepted-main receipt at fe38beee; historical work and current custody are preserved | Exact-main acceptance receipt, required CI, Release push no-publish shape, reviewed prior-delta disposition and safe worktree handoff |
| **v1.47 OAuth/OIDC Core Interoperability & Hardening** | Reproduce historical OIDC/FAPI findings; correct selected authorization-response and PAR/profile boundaries only where supported-surface evidence warrants it; prove fixes through a packaged host | **Selected and progressing.** Phase 171 qualified twelve cases; Phase 172 passed 11/11 after correcting A171-003. P171-005 is the next narrow correction in Phase 173; packaged/candidate delivery remains Phase 174 | Finding-to-standard-to-regression ledger; selected packaged HTTP cases; focused security review; full contributor/required CI gates; refreshed roadmap and clean delivery handoff |
| **v1.48 Client Authentication Key Isolation & Rotation** | SEC-01: dedicated-purpose rotatable encryption for client_secret_jwt verifier material, legacy reads/rewrap, mixed-version rollout, status and loss recovery | **Preferred next, provisional.** Re-rank at v1.47 close or sooner if an urgent supported-core issue appears | Existing clients survive documented upgrade/rotation; tampering/missing/retired keys fail closed; concurrent rewrite and secret rotation are safe; package upgrade and redaction proof |
| Next available version: Token Lifecycle Resilience | A narrow refresh/revocation/replay or selected-store transaction invariant | **Conditional.** Fresh deterministic counterexample or a material uncovered invariant; much of this is already implemented/tested | Reproducer plus actual PostgreSQL concurrency/rollback proof for the selected invariant; preserve family-wide reuse containment |
| Next available version: Key Maintenance at Scale | OPS-03: paged re-encryption dry-run and measured status-read improvements | **Conditional.** Measured memory/query/latency problem on realistic row counts | Bounded resource use, stable iteration, truthful partial progress/status, retry-safe and concurrent-update behavior |
| Next available version: Host Key Provider Integration | KEK-04: narrow host-controlled KMS/Vault provider seam | **Conditional.** Concrete adopter custody need with outage/latency/rotation requirements | Host-owned adapter and explicit failure contract; core library keeps a small dependency closure and embedded shape |
| Sustaining train | Focused fixes, dependency/security maintenance and truthful releases | Default between milestones or if no candidate has material value | Green exact main, coherent support/release truth, intentional clean workspaces |

Only v1.47 has scheduled phase numbers. Do not reserve later phase numbers or create detailed downstream plans until their evidence/entry decisions are settled. Provisional version handles may change. An urgent security finding can change this ordering.

## v1.47 Scope and Decision Gates

See [scope and decisions](research/v1.47-core-hardening/SCOPE.md), [research synthesis](research/v1.47-core-hardening/SUMMARY.md) and [requirements](REQUIREMENTS.md).

1. Phase 171 qualifies exact inputs, current failures and ownership; old suite_failure summaries are not proof of current bugs.
2. Authorization error/redirect/silent-auth cases are the first likely vertical slice. PAR/FAPI boundary cases follow only after transport/issuer/WebRunner attribution.
3. For each included case, specify the observable response, applicable standard, current support boundary, positive/negative proof and owner before implementation fans out.
4. If a candidate is already correct, reuse its evidence; do not manufacture a fix or duplicate a test. If no material findings remain, narrow/replan to an honest evidence/maintenance closeout.
5. Keep external-suite results supplemental and non-certifying. Overall full-FAPI success is not a new release gate. Selected repo-native acceptance remains mandatory.
6. SEC-01 storage migration, KMS, broad grant rewrites, new flows and UI redesign remain outside this milestone.

## Refresh at Every Boundary

At milestone start and close, compare this ranking against fresh branch/main/CI state, supported-surface docs, current code/tests, adopter evidence and retained findings. Mark candidates selected, shipped, deferred, obsolete or rejected with a reason and source/date. Carry unresolved owners and next triggers forward. Change stale proposals rather than restarting the discussion or inheriting their claims.

At each run stop, record base and head SHAs, owned edits/worktrees, validation commands/results, blockers, remaining cleanup, and the next exact action in STATE.md or its linked handoff. Planning completion, implementation completion, integration into green main and public publication are distinct states.

## Delivery Posture

Use the existing [development train](DEVELOPMENT-TRAIN.md), [release train](RELEASE-TRAIN.md) and [hygiene checklist](REPO-HYGIENE-CHECKLIST.md). Commit owned changes, preserve unknown edits and unique commits, retire owned temporary worktrees/resources once safely integrated, and re-observe main after merge. A retained workspace requires an explicit owner/purpose/next action; it is not a clean-baseline pass. Never force cleanup to make a status display green.

The [dated baseline](research/v1.47-core-hardening/BASELINE.md) retains the original pre-entry observations. Phase 171 subsequently established reviewed delivery and accepted main `fe38beee987b135e87c99e7aa7f2488b4c8613e8` through the unchanged [original receipt](phases/171-accepted-baseline-finding-qualification/171-MAIN-ACCEPTANCE.json). Its [passed qualification](phases/171-accepted-baseline-finding-qualification/171-VERIFICATION.md) authorizes the narrow downstream planning scope. The current milestone branch is distinct from accepted main; later candidate/main delivery and publication still need their own evidence.

## History and Stop Rule

Older ranking/guide content is preserved in [pre-v1.47 research history](research/archive/pre-v1.47/); completed milestone scope remains in [MILESTONES.md](MILESTONES.md). Do not re-open shipped DPoP nonce, DCR metadata, UI or host-integration milestones because an older strategic file still calls them candidates.

Stop broad research when additional perspectives no longer change a consequential decision, acceptance case, risk control or sequence. Prefer targeted reproduction over another ecosystem survey. Sustain or stop when the remaining candidates offer only speculative breadth.
