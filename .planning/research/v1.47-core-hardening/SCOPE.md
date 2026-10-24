# v1.47 Scope and Upstream Decisions

**Selected:** 2026-10-24, user approved OAuth/OIDC Core Interoperability & Hardening and delegated research, synthesis and routine decisions within that direction.
**Goal:** Clients using Lockspire's supported embedded Phoenix surface receive standards-grounded, secure authorization and PAR/profile behavior, with reproducible evidence for each selected correction.
**State:** Planning. Product execution is gated on repository delivery readiness and finding qualification.

## Scope

Start with the retained Phase 37 authorization-error findings and FAPI PAR/TLS/WebRunner summaries. They are historical pointers, not current defect reports. Qualify the exact selected module/condition and applicable standard against today's supported surface and package before selecting a repair.

Likely slices are authorization-response disposition (valid versus unsafe callback, state, supported response mode), prompt=none/authentication freshness, and PAR reference/profile boundaries. These are investigation categories, not pre-decided behavior changes. Phase 171 produces the finite case inventory and matrix. Do not expand to all discovery, JWKS, userinfo, refresh, device, CIBA, exchange, JAR or profile combinations merely because they exist.

For a case already proven correct, cite/reuse the current automated owner. For a material unproven case, add the smallest meaningful check. For a confirmed defect, obtain a deterministic failing regression before changing behavior. Source inspection is not new runtime proof.

## Decisions

| Decision | Adopted recommendation | Alternative / tradeoff |
|---|---|---|
| Work sequence | Repository entry maintenance, exact-input attribution, authorization slice, conditional PAR/profile slice, packaged proof and delivery | A broad protocol sweep obscures causality and creates unnecessary downstream plans |
| Evidence hierarchy | Current supported contract + normative clause + fresh reproducer; historical receipts retain original meaning | Suite output alone may reflect harness, proxy, TLS or browser setup |
| Input identity | Use existing immutable lock for comparable reproduction; if unavailable/obsolete, record that and make a separately reviewed exact lock update before comparing results | Opportunistic suite upgrades mix source and test semantic changes |
| Failure taxonomy | Protocol assertion; harness/origin/TLS/browser; infrastructure; unsupported profile; already-correct/not reproduced | The runner's suite_failure category does not identify the underlying owner |
| Acceptance | All selected supported cases have deterministic owners and required checks; full external suite stays supplemental | Neither an overall supplemental failure nor an unavailable container may be relabeled a protocol pass |
| Regression economics | Reuse current tests and harnesses; focused iteration, then complete required candidate checks | Do not repeat all slow matrices after every local edit or add a permanent job for an unproven recurring risk |
| Dependencies | Existing OTP/Plug/Phoenix/Ecto/JOSE and pinned suite tooling; small auditable local glue preferred | No general conformance framework, secrets framework or second browser stack absent a demonstrated gap; never copy crypto primitives |
| Migration separation | SEC-01 is provisional v1.48 with its own purpose separation and upgrade/rotation proof | Combining encryption persistence changes with protocol corrections increases review and rollback ambiguity |
| Uncertainty | Phase 171 settles downstream cases; unresolved security/API/support choices block dependent implementation | Do not fan out implementations against mutually incompatible assumptions |
| Stop | Reduce/replan when cases are already correct or unsupported; unresolved external boundaries retain precise blockers | No quota for product code or milestone count; do not manufacture defects to fill phases |

## Qualification Ledger Contract

Phase 171 creates one bounded ledger. For each case retain: stable ID; source/date and historical identity; selected provider/package SHA and checksum; suite commit/image/helper/plan identity when applicable; supported mount/profile/auth mode; safe module/condition identifier; normative section; observed versus expected behavior; classification; affected owner; deterministic reproduction command; regression owner; disposition and verification identity. Never retain provider config, raw keys, tokens, personal data, raw exception dumps or browser logs.

Enumerate the chosen cases, not every possible OAuth extension. An unavailable historical artifact must be recorded as unavailable; recreate a new dated repro rather than fabricating an old result. Current versus historical suite comparisons name both identities.

## Gates

- **Before product execution:** reconcile the accumulated prior delivery branch with reviewed main history; resolve/hand off unknown work; establish the existing exact-main acceptance gate on a fresh synchronized base; branch according to the development train. This planning commit is portable; it is not proof that prior milestones reached main.
- **Before dependent plans:** ledger selection and expected behavior are explicit, current and within scope. Split a newly discovered migration/API/profile expansion out for a specific decision.
- **Before fixes:** a reproducible supported-surface defect and a failing regression exist. If standard language permits multiple safe policies, settle the compatibility/security decision first.
- **Before closure:** every selected requirement/case has applicable passing automated evidence, required candidate CI/local checks and audit; supplemental results and unavailable boundaries remain honestly classified. If no corrective scope survives, revise requirements/roadmap explicitly before closing.
- **Between milestones:** preserve original evidence, refresh rolling candidates, integrate through the normal reviewed train, verify exact main again, and leave clean owned worktrees or an explicit incomplete-delivery handoff.

## Exclusions

No UI redesign or subjective visual signoff; new flow families or broader FAPI/certification claims; standards-wide rewrites; token retry grace/reuse policy changes; dedicated verifier encryption migration; KMS/Vault; speculative performance work; host account/login/claim-policy ownership; new mandatory service; manual publication. Preserve all standing security defaults.

## Research Boundary

Three focused reviews covered protocol interoperability, security/sequencing and delivery hygiene; the orchestrator synthesized them and applies a final adversarial consistency pass. Further research requires a named open question that could change behavior, scope, dependency or proof. Relevant lenses are client/host developers, protocol/security reviewers, distributed storage, operations/CI and maintenance; unrelated technology/design specialties add no useful scope here.
