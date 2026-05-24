# Phase 66: Conformance Debt Retirement & Milestone Closure - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 66 closes v1.16 by retiring the remaining trust-affecting conformance debt from Phase 37,
making the current maintainer proof story truthful and reproducible, and producing closure artifacts
that trace every v1.16 requirement to shipped proof or explicit non-claim.

This phase does not broaden Lockspire into a certification program, a hosted authorization product,
or a broader protocol surface. It narrows the trust story to what the repo can prove today for the
embedded Phoenix library shape and makes any remaining non-claims explicit.

</domain>

<decisions>
## Implementation Decisions

### Debt disposition

- **D-01:** Retire the old Phase 37 external OIDF-suite lane as an explicit documented non-claim
  for the current Lockspire support story. Do not spend Phase 66 trying to close the historical
  gap on its original terms.
- **D-02:** The supported trust contract for this slice should center on repo-native strictness
  proof already owned by Lockspire: generated-host or integration proof, release-contract tests,
  and truthful support/maintainer docs.
- **D-03:** Optional external-suite execution may remain as maintainer-only corroborating evidence,
  but it must not be treated as milestone-closing proof, baseline maintainer workflow, or part of
  the public product contract.
- **D-04:** Do not preserve rhetoric that implies Lockspire has broad conformance or certification
  coverage because the historical external lane exists in the repo.

### Maintainer conformance story

- **D-05:** After Phase 66, maintainer guidance should center on current repo-native proof first.
  The baseline maintainer trust workflow should be fast, reproducible, and owned by the repo.
- **D-06:** Phase 37 and OIDF/FAPI external-suite material should be reframed as optional historical
  or escalation context, not the recommended day-to-day or milestone-close path.
- **D-07:** If external verification remains documented, it should be presented as supplemental
  assurance for standards-sensitive work, not as a required release gate and not as definitive
  proof of the shipped embedded-library contract.
- **D-08:** Maintainer docs must use the same truth hierarchy established in Phase 65:
  `docs/supported-surface.md` remains canonical for public claims; maintainer runbooks explain
  workflows without becoming a shadow support contract.

### Milestone closure package

- **D-09:** Keep durable truth in the canonical existing artifacts:
  `docs/supported-surface.md`, maintainer docs, executable tests, phase verification artifacts,
  and milestone audit artifacts.
- **D-10:** Add one explicit v1.16 closure artifact as an evidence index that maps milestone
  requirements (`HOST-*`, `SIGRA-*`, `TRUTH-*`, `CONF-*`, `V-01`) to proof, explicit non-claims,
  and any manual-only supplemental evidence.
- **D-11:** The closure artifact must stay index-like rather than becoming a second feature matrix
  or second support contract. It should point to canonical proof instead of restating it.
- **D-12:** Do not introduce a separate long-lived closure matrix plus report pair. That would add
  drift risk and conflict with the repo's one-canonical-truth-surface direction.

### Historical artifact handling

- **D-13:** Keep historical Phase 37 artifacts and planning history in the repo for auditability
  and post-mortem value, but actively demote them so they cannot read like current proof.
- **D-14:** Historical artifacts tied to the retired non-claim should carry explicit retired or
  historical labeling where needed, and current-proof documents should stop citing them as active
  evidence.
- **D-15:** Fix contradictory historical completion markers that still state `CONF-04` was
  completed when the verification record says otherwise.
- **D-16:** Do not delete useful raw history unless it is the only way to remove misleading proof
  implications. Preferred approach: preserve, label, and de-reference.

### UX, DX, and least-surprise posture

- **D-17:** Optimize for least surprise: maintainers and users should be able to tell quickly which
  artifacts define current truth, which are historical, and which are optional supplemental
  workflows.
- **D-18:** Prefer one obvious proof story over layered folklore. For this phase that means:
  repo-native proof first, optional external corroboration second, archived historical attempts
  clearly marked third.
- **D-19:** Phase 66 should strengthen Lockspire's embedded-library credibility by avoiding
  certification theater and by refusing to let optional or failed historical paths masquerade as
  product guarantees.

### Workflow preference

- **D-20:** Shift decision pressure left for Phase 66 and adjacent GSD work. Downstream
  researcher/planner/executor agents should default to decisive, cohesive recommendations and only
  escalate choices that materially affect product boundary, public support contract, security
  posture, or release/trust posture.
- **D-21:** Medium-value choices around documentation packaging, artifact naming, labeling, and test
  shape should be resolved coherently by downstream agents rather than surfaced back to the user as
  option menus unless new evidence creates a real conflict.

### the agent's Discretion

- Exact filenames and frontmatter shape for the v1.16 closure artifact.
- Exact retired/historical labeling text and placement for Phase 37 artifacts, docs, and summaries.
- Exact contract-test assertions and documentation wording, provided they preserve the canonical
  truth hierarchy and remove overclaims.
- Exact choice of whether the closure artifact is a dedicated closure report or an enriched
  milestone audit, provided it remains an index over canonical proof rather than a parallel truth
  surface.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle is:
  - retire the old Phase 37 external suite lane as a non-claim for current support truth,
  - center maintainer guidance on repo-native proof,
  - keep one explicit milestone-close artifact as an index over proof and non-claims,
  - preserve historical Phase 37 material but clearly demote it out of current-proof paths.
- This fits the repo's strongest existing pattern:
  - one canonical public support contract,
  - maintainer docs subordinate to that contract,
  - executable proof tied to the embedded Phoenix host path,
  - milestone audits or verification artifacts as evidence indexes rather than duplicate contracts.
- Ecosystem lessons that support this direction:
  - Phoenix generators and embedded-library flows work best when the host-owned seam and the
    repo-owned proof are explicit and reproducible.
  - Ecto-backed projects benefit from deterministic integration tests more than from cross-process
    external harnesses that bypass sandbox assumptions.
  - Embedded auth libraries such as Doorkeeper, OpenIddict, Spring Authorization Server, and
    Authlib succeed by being customizable host-integrated foundations, not by pretending they own
    all runtime conditions like a full hosted identity product.
  - Projects that do own more runtime, like `node-oidc-provider` or Keycloak, can justify stronger
    conformance matrices; Lockspire should not copy that trust posture blindly because its product
    boundary is narrower.
- Concrete footguns to avoid:
  - treating historical OIDF artifacts as active product proof,
  - leaving contradictory planning and summary markers that claim completed conformance work when
    verification says otherwise,
  - making maintainers infer the current truth story from a mix of old docs, artifact folders, and
    workflows,
  - introducing a second closure matrix that drifts from the canonical support contract.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone state
- `.planning/ROADMAP.md` — Phase 66 goal, requirements, and milestone-close success criteria
- `.planning/REQUIREMENTS.md` — `CONF-01`, `CONF-02`, and `V-01`
- `.planning/PROJECT.md` — embedded-library thesis, truthful posture, and v1.16 goals
- `.planning/STATE.md` — current milestone state and the carried-forward Phase 37 debt note

### Prior decisions that constrain this phase
- `.planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md` — original repo-native vs
  external-lane intent and strictness proof boundary
- `.planning/phases/42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep/42-CONTEXT.md` —
  preparatory OIDF lane wiring and the decision not to overclaim completion
- `.planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md` — truthful FAPI posture, manual
  external-suite boundary, and release-truth lessons
- `.planning/phases/58-milestone-closure-discovery/58-CONTEXT.md` — contract-coupled closure and
  strong recommendation posture
- `.planning/phases/62-docs-verification-closure/62-CONTEXT.md` — canonical truth surfaces and
  narrow claim-bearing closure strategy
- `.planning/phases/63-canonical-install-path-host-diagnostics/63-CONTEXT.md` — left-shifted
  decisive-default workflow preference
- `.planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md` — one canonical proof
  topology and support-truth guardrails
- `.planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md` — canonical
  support-contract hierarchy and anti-duplication release-proof posture

### Current proof, debt, and truth artifacts
- `.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md` — authoritative record
  of the unresolved Phase 37 gap and the DB-pollution failure mode
- `.planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md` — historical completion
  marker that may need demotion or correction
- `.artifacts/conformance/phase37/run-summary.json` — historical skipped-suite artifact that must
  not be mistaken for current proof
- `.artifacts/conformance/phase37/artifact-files.txt` — artifact bundle index for the retired lane
- `docs/supported-surface.md` — canonical public support contract that must stop overclaiming
- `docs/maintainer-conformance.md` — maintainer workflow doc to narrow and reframe
- `docs/maintainer-release.md` — maintainer evidence hierarchy precedent
- `test/lockspire/release_readiness_contract_test.exs` — executable docs and truth drift gate

### Milestone-close artifact precedents
- `.planning/milestones/v1.14-MILESTONE-AUDIT.md` — prior milestone audit shape
- `.planning/milestones/v1.15-MILESTONE-AUDIT.md` — prior milestone audit shape with deferred debt
  handling

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `test/lockspire/release_readiness_contract_test.exs` already acts as the canonical drift fence for
  documentation and support-truth claims.
- `docs/supported-surface.md` already establishes the one-canonical-contract model Phase 66 should
  preserve.
- Prior milestone audits already provide a usable evidence-index pattern without creating a parallel
  feature matrix.

### Established Patterns

- Lockspire prefers repo-owned executable proof over folklore or prose-only claims.
- Public support truth is intentionally narrower than maintainer operations guidance.
- Milestone closure works best when claim-bearing docs, tests, and verification artifacts move
  together.
- The project increasingly favors decisive defaults and least-surprise documentation hierarchy over
  open-ended option menus.

### Integration Points

- Phase 66 planning should likely center around:
  - supported-surface and maintainer-conformance wording cleanup,
  - release-contract test updates,
  - Phase 37 historical artifact demotion,
  - one v1.16 closure audit or report that indexes all shipped proof and explicit non-claims,
  - planning/state artifact cleanup so milestone closure truth and historical debt treatment match.

</code_context>

<deferred>
## Deferred Ideas

- Broad external certification or recurring conformance-program work beyond the repo-proven
  embedded-library surface
- Restoring the Phase 37 external-suite lane as a first-class release gate unless Lockspire later
  decides to own that operational burden explicitly
- Additional protocol breadth or hosted-runtime proof stories unrelated to v1.16 closure

</deferred>

---

*Phase: 66-conformance-debt-retirement-milestone-closure*
*Context gathered: 2026-05-07*
