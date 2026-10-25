# Phase 174: Packaged Proof & Delivery Handoff — Context

**Gathered:** 2026-10-24
**Status:** Ready for planning
**Mode:** Assumptions, automatic continuation under delegated user authority

<domain>
## Phase Boundary

Deliver source-bound selected-case proof through a packaged embedded Phoenix host, current milestone/security/candidate evidence and an exact resumable delivery handoff through the existing train. The twelve-case selection is frozen; A171-003 and P171-005 are corrected. Phase 173 passed six behavioral truths with two prominent non-authoritative judgment flags; three generic edge assumptions remain unresolved. This phase proves and delivers selected work, without another protocol feature project or publication.
</domain>

<decisions>
## Implementation Decisions

### Selected proof and packaged host

- **D-01:** Keep the canonical twelve-case selection authoritative. Reuse the ten existing proof owners and link the two actual corrections to their recorded normative RED/GREEN regressions. Preserve original case/source/observation identities, receipts/probes and frozen IDs. Use existing IDs in any source/package evidence index rather than inventing another qualification matrix.
- **D-02:** Demonstrate applicable selected authorization/PAR outcomes through a package-clean embedded Phoenix host using real HTTP and recorded source/archive/tree/vendor/resolved/compiled identities. Reuse `clean_room_saas_journey.py` and `clean_room/package_input.py` machinery. Prefer a bounded scenario group in the existing journey; a thin sibling may share those helpers only if existing lifetime receipt coupling materially obstructs a clean extension. Do not clone the acceptance framework or add a dependency.
- **D-03:** Add only the synthetic host-fixture capabilities required by the selected cases: appropriate `openid`/`email` scopes and host-supplied authentication-time proof. The current fixture resolves accounts without auth_time and omits email from known scopes, so ordinary happy-path login is insufficient. Keep account/session/login/claims/consent policy host-owned; do not change Lockspire's product seam or add a public debug surface to manufacture proof.
- **D-04:** Require actual response/status/headers and safe persisted projections as appropriate, including valid neighboring controls and exact callback/consent boundaries. Source-host discovery or loopback package HTTP does not prove public TLS/proxy/browser reachability. Preserve external profiles as unavailable, unlaunched, supplemental and non-certifying; no implied full-suite release gate.

### Identity, freshness and gates

- **D-05:** Freeze final shipped source/harness/guidance inputs before expensive package/candidate runs. Keep source/package/candidate/main identities distinct, use existing binding checks, and regenerate affected evidence when actual covered bytes change. Do not restamp a result at another revision. Later planning-only metadata must be explicitly reconciled rather than presented as new runtime execution.
- **D-06:** Repair prior verification-owner freshness through scoped reassessment and relevant current GREEN proof after covered inputs settle. Phase 171/172 reports legitimately cover changed protocol/tests/ledger and planning documents; leave original historical observations intact and let verifier owners regenerate. Never rerun the old deliberate-RED qualification probe as a green gate or reconstruct the original main receipt. Phase 174 roadmap edits outside the frozen Phase 172–173 selector do not justify refreshing that selector or unowned ledger entries.
- **D-07:** Use focused checks during implementation, then complete local `mix ci` and the existing seven required hosted CI jobs at the exact candidate head. Local success does not establish hosted Dialyzer, exact-floor, coverage or demo results. Keep guidance/support boundaries synchronized with delivered behavior and retain the exact legacy-floor advisory/isolation caveat; no floor or platform upgrade is selected.

### Delivery, retained resources and limits

- **D-08:** Use the existing development/release/hygiene train for reviewed integration and fresh synchronized-main acceptance when delivery reaches main. A read-only GitHub observation at discussion time still finds protected main `fe38beee987b135e87c99e7aa7f2488b4c8613e8`; it accepts the earlier base, not this milestone branch. Record exact candidate, CI, PR/integration and main status or concrete remaining blockers. An honest blocked handoff is not a green-main claim and does not authorize the next milestone's product execution.
- **D-09:** Own and clean only this run's temporary hosts, ports, databases, containers and files, using existing cleanup/redaction controls. Persistent source-test DB `lockspire_171_main_20261024b` remains owned while work continues. Preserve historical Phase 142/143 material, three retained prior-agent worktrees/unique commits, unknown edits and retained adoption-demo data under recorded custody, purpose and next review action. Do not delete them to make status look clean.
- **D-10:** Keep the embedded-library shape and existing security defaults. No new dependency/framework, flow, product API, schema/migration, host product policy, admin redesign, external profile install/run, manual tag, Hex publication or release dispatch. `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED` remains false pending its recorded owner review. Refresh the rolling ranking with actual evidence; SEC-01 stays provisional, not automatic next-milestone execution authority.

### Autonomous judgment lifecycle

- **D-11:** Preserve original automatic prohibition provenance, then record an actual resolved/judgment lifecycle after scoped review evidence exists. In autonomous mode retain prominent non-authoritative `unverified-prohibition — human review recommended` flags under the documented soft-gate. Do not invent mechanical enforcement or human confirmation, suppress flags, or block solely because a completed judgment was left in an unresolved enum. Actual behavioral gaps and genuinely required human actions still block. Record exact flag counts in final handoff and keep generic unclassified/concurrency limits honest.

### the agent's Discretion

Assumptions were Confident except the package-harness shape, which was Likely. Auto mode selected the recommended existing-journey extension with a narrowly bounded shared-helper fallback. Routine source/harness/gate sequencing and scoped maintainer judgments are delegated by the user's explicit unblock/follow-recommendations/keep-going instruction. This is agent judgment, not fabricated user confirmation. A newly required product/API/security/support expansion must be explicitly resolved; none is selected here.

### Folded Todos

No new todo scope selected. Existing historical debts retain their owners/triggers.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` Phase 174; `.planning/REQUIREMENTS.md` CPROOF-01/02 and DELIV-01/02.
- `.planning/DEVELOPMENT-TRAIN.md`, `.planning/RELEASE-TRAIN.md`, `.planning/REPO-HYGIENE-CHECKLIST.md`, `.planning/MILESTONE-ARC.md`, `AGENTS.md`, `.planning/METHODOLOGY.md`, `docs/supported-surface.md`.
- Phase 171 canonical qualification/decisions/DELIVERY and unchanged `171-MAIN-ACCEPTANCE.json`; Phase 172/173 source-bound summaries, learnings and verification. The original accepted-main receipt SHA-256 remains `be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39`.
- Existing clean-room SaaS journey and `clean_room/package_input.py`, `clean_room/build_provider.py`; prior Phase 170 package evidence supplies mechanics, not new protocol success.
- `.github/workflows/ci.yml`, `mix.exs`, current maintainer gate scripts and package/source binding owners.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- SaaS journey has real HTTP/cookies, run-owned random DB/ports/temp directories, redaction and cleanup.
- Package input helper binds archive/tree/vendor/resolved dependency/compiled state. Keep this actual package boundary instead of running checkout code in a host.
- Generated synthetic provider is the right place for host-owned authentication-time and scope fixtures; existing source owners define the twelve exact projections.

### Established Patterns

- Phase 172 valid control precedes unsupported-mode candidate; Phase 173 uses independent real PAR references, exact relative consent and persisted interaction equality.
- Media-type checks separate parameters and compare the base value exactly.
- Selective manifest audits preserve old/new/source/reason chains; verifier owners regenerate covered digests after actual changes.

### Integration Points

The existing package-clean provider and candidate CI train are the acceptance seams. Keep local package HTTP, hosted CI, accepted main and publication separate. No new external API/service integration is introduced.
</code_context>

<specifics>
## Specific Ideas

Prefer small auditable glue and existing primitives. Stop research when another perspective no longer changes a consequential case, control or sequence. A dated handoff must state base/head, exact proof identities, judgment flags, blockers, owned cleanup/retention and next action without relabeling historical or unavailable evidence.
</specifics>

<deferred>
## Deferred Ideas

Public publication, external profile preparation/certification, general overlap/interruption guarantees, SEC-01 migration, KMS/Vault and unrelated storage/UI work. Historical ownership and retained data review remain separate from owned cleanup.

### Reviewed Todos (not folded)

No additional todo is promoted by this discussion.
</deferred>
