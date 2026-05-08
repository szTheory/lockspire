# Phase 66: Conformance Debt Retirement & Milestone Closure - Research

**Researched:** 2026-05-07 [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]
**Domain:** Repo-native conformance-truth retirement, proof-hierarchy tightening, and milestone closure evidence for an embedded Phoenix OAuth/OIDC library [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repository inspection across planning artifacts, docs, tests, workflows, and historical conformance artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from [`.planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md`](/Users/jon/projects/lockspire/.planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md:1). [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

### Locked Decisions

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

### Claude's Discretion

- Exact filenames and frontmatter shape for the v1.16 closure artifact.
- Exact retired/historical labeling text and placement for Phase 37 artifacts, docs, and summaries.
- Exact contract-test assertions and documentation wording, provided they preserve the canonical
  truth hierarchy and remove overclaims.
- Exact choice of whether the closure artifact is a dedicated closure report or an enriched
  milestone audit, provided it remains an index over canonical proof rather than a parallel truth
  surface.

### Deferred Ideas (OUT OF SCOPE)

- Broad external certification or recurring conformance-program work beyond the repo-proven
  embedded-library surface
- Restoring the Phase 37 external-suite lane as a first-class release gate unless Lockspire later
  decides to own that operational burden explicitly
- Additional protocol breadth or hosted-runtime proof stories unrelated to v1.16 closure
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement text copied from [`.planning/REQUIREMENTS.md`](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:1). Research-support mapping derived from this research. [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| CONF-01 | Historical conformance or verification debt that materially affects the public trust story is either closed with executable proof or converted into an explicit documented non-claim with rationale. [VERIFIED: .planning/REQUIREMENTS.md] | Retire the unresolved Phase 37 external OIDF lane as a documented non-claim, preserve the strictness E2E as executable proof, and correct or demote contradictory historical markers. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md] [VERIFIED: docs/supported-surface.md] |
| CONF-02 | Maintainer-facing conformance guidance distinguishes fast repo-native proof from external-suite verification clearly enough that a maintainer can reproduce the claimed trust story without folklore. [VERIFIED: .planning/REQUIREMENTS.md] | Reframe `docs/maintainer-conformance.md` around repo-native proof first, with external OIDF/FAPI workflows explicitly supplemental. [VERIFIED: docs/maintainer-conformance.md] [VERIFIED: docs/maintainer-release.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] |
| V-01 | The milestone closes with generated-host proof, release-truth proof, and full traceability for every shipped requirement in this milestone. [VERIFIED: .planning/REQUIREMENTS.md] | Use one v1.16 milestone-close audit artifact as the evidence index that maps `HOST-*`, `SIGRA-*`, `TRUTH-*`, `CONF-*`, and `V-01` to existing proof or explicit non-claims. [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] |
</phase_requirements>

## Summary

The best repo-native Phase 66 approach is to stop treating the unresolved Phase 37 external OIDF lane as debt that must be “finished” on its original terms and instead retire it as a documented non-claim for the current support contract. The repo already has stronger current proof for the trust story Lockspire actually wants to ship: canonical supported-surface wording, generated-host and integration E2E tests, release-readiness contract tests, and milestone audit artifacts. The evidence shows the remaining problem is contradiction and hierarchy drift, not missing protocol breadth. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md]

The repo’s current truth hierarchy is already clear in release work: `docs/supported-surface.md` is canonical, maintainer docs are subordinate, and contract tests pin the hierarchy. Phase 66 should reuse that exact pattern for conformance instead of inventing a new program, a new matrix, or a new proof lane. The main inconsistency is that `docs/maintainer-conformance.md`, `mix conformance.phase37`, `.github/workflows/oidf-conformance.yml`, and `37-04-SUMMARY.md` still preserve an older “lane wiring equals meaningful proof” posture, while `37-VERIFICATION.md` and the current milestone state explicitly say the historical external proof never closed. [VERIFIED: docs/maintainer-release.md] [VERIFIED: docs/maintainer-conformance.md] [VERIFIED: mix.exs] [VERIFIED: .github/workflows/oidf-conformance.yml] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: .planning/STATE.md]

The minimum coherent deliverable set for this phase is therefore: one canonical non-claim update in `docs/supported-surface.md`, one maintainer-workflow rewrite in `docs/maintainer-conformance.md`, one release-contract test realignment to pin the narrower truth hierarchy, one historical-artifact demotion pass for Phase 37 summaries and stub artifacts, and one v1.16 closure audit artifact that indexes all milestone requirements to canonical proof or explicit non-claims. That satisfies `CONF-01`, `CONF-02`, and `V-01` without expanding Lockspire into a certification program. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md]

**Primary recommendation:** Use `docs/supported-surface.md` as the only claim-bearing conformance truth, demote the unresolved Phase 37 external lane to historical supplemental context, and close v1.16 with one milestone audit artifact that indexes existing executable proof plus explicit non-claims. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/maintainer-release.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public conformance/support claim | CDN / Static | API / Backend | Public truth lives in checked-in docs, while tests enforce drift from backend-owned proof. [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Maintainer trust workflow | CDN / Static | API / Backend | Maintainer runbooks are docs, but they should point to mix aliases, workflows, and tests rather than define claims themselves. [VERIFIED: docs/maintainer-conformance.md] [VERIFIED: docs/maintainer-release.md] [VERIFIED: mix.exs] |
| Executable drift fence for trust hierarchy | API / Backend | CDN / Static | `test/lockspire/release_readiness_contract_test.exs` is the enforcement point that keeps docs and workflow contracts honest. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Historical debt demotion | CDN / Static | API / Backend | Summary, verification, and milestone-history files are static artifacts; contract tests may need to stop treating old wiring as active proof. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Milestone closure traceability index | CDN / Static | API / Backend | Prior milestone audits are markdown evidence indexes over tests and docs, not new executable systems. [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] |

## Standard Stack

No new runtime or package adoption is justified for Phase 66. The standard stack is the repo’s existing docs, tests, workflows, and planning artifacts. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 [VERIFIED: `mix --version`] | Runs repo-native aliases and tests that enforce trust hierarchy. [VERIFIED: mix.exs] | Already powers the canonical executable proof story. [VERIFIED: mix.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| ExUnit contract tests | bundled with the app test stack [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Pins doc, workflow, and claim hierarchy. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Existing precedent for release-truth enforcement and the right place to pin conformance-truth enforcement. [VERIFIED: docs/maintainer-release.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Markdown evidence artifacts | n/a [VERIFIED: repository files] | Holds canonical support contract, maintainer runbooks, phase verification, and milestone audits. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/maintainer-conformance.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] | The repo already treats these as durable human-readable truth surfaces. [VERIFIED: docs/maintainer-release.md] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Docker | 29.4.1 [VERIFIED: `docker --version`] | Optional corroborating execution for the historical OIDF lane. [VERIFIED: scripts/conformance/run_phase37_suite.sh] [VERIFIED: docs/maintainer-conformance.md] | Only for maintainer-only supplemental evidence, not milestone-close proof. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] |
| GitHub Actions `oidf-conformance.yml` | checked-in workflow [VERIFIED: .github/workflows/oidf-conformance.yml] | Preserves optional scheduled/manual external-lane wiring. [VERIFIED: .github/workflows/oidf-conformance.yml] | Keep only if clearly labeled as supplemental or historical corroboration. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Canonical supported-surface + milestone audit hierarchy | A separate long-lived conformance matrix/report pair | Rejected because the phase context explicitly forbids duplicate truth surfaces and milestone-audit precedent already fits the job. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] |
| Repo-native generated-host/integration proof first | External OIDF/FAPI suite as the release gate | Rejected because the repo’s current support contract is narrower than broad certification posture, and the historical Phase 37 lane never actually closed. [VERIFIED: docs/supported-surface.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] |

**Installation:** No new packages recommended for this phase. [VERIFIED: repository inspection]

**Version verification:** Elixir/Mix `1.19.5` and Docker `29.4.1` are available in the current environment. [VERIFIED: `elixir --version`] [VERIFIED: `mix --version`] [VERIFIED: `docker --version`]

## Architecture Patterns

### System Architecture Diagram

```text
Public/support claim request
  -> docs/supported-surface.md (canonical claim surface)
      -> release_readiness_contract_test.exs (asserts wording and evidence links)
          -> mix aliases / workflows / integration tests (executable proof)
              -> generated-host and protocol behavior

Maintainer asks "how do I verify conformance?"
  -> docs/maintainer-conformance.md (subordinate workflow guide)
      -> repo-native proof first:
         - phase37 strictness E2E
         - release-truth contract tests
         - milestone audit evidence index
      -> optional supplemental lane second:
         - OIDF/FAPI suite workflow
         - Docker/manual environment

Historical Phase 37 artifacts
  -> preserved in planning/artifacts directories
      -> explicit retired/historical labels
      -> not cited as current proof by canonical docs or contract tests

Milestone close
  -> v1.16 milestone audit artifact
      -> maps HOST/SIGRA/TRUTH/CONF/V requirements
      -> points to canonical docs/tests/non-claims
      -> does not create a second support matrix
```

The diagram reflects the repo’s existing evidence flow: canonical docs point to tests and workflows, and milestone audits index proof rather than replacing it. [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md]

### Recommended Project Structure

```text
docs/
├── supported-surface.md          # Canonical public claim surface
├── maintainer-conformance.md     # Subordinate maintainer workflow
└── maintainer-release.md         # Precedent for evidence hierarchy

test/lockspire/
└── release_readiness_contract_test.exs   # Executable drift fence for docs/workflow truth

.planning/phases/37-protocol-strictness-conformance/
├── 37-VERIFICATION.md            # Authoritative unresolved debt record
└── 37-04-SUMMARY.md              # Historical summary that needs demotion/correction

.planning/milestones/
└── v1.16-MILESTONE-AUDIT.md      # Recommended closure evidence index
```

This structure reuses the repo’s existing canonical surfaces instead of adding a second conformance subsystem. [VERIFIED: repository files] [VERIFIED: docs/supported-surface.md] [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md]

### Pattern 1: Canonical Truth Hierarchy

**What:** Put all public conformance truth in `docs/supported-surface.md`; let maintainer docs explain workflows without becoming claim-bearing artifacts. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/maintainer-release.md]

**When to use:** Any time the phase changes support posture, proof boundaries, or trust claims. [VERIFIED: .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

**Example:**

```markdown
## Trust posture

- Repo-native proof for Lockspire's current conformance story lives in generated-host and integration tests plus release-contract tests.
- External OIDF/FAPI runs are optional maintainer corroboration and are not part of the public support contract.
```

Source pattern: canonical support contract plus subordinate maintainer evidence buckets. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/maintainer-release.md]

### Pattern 2: Executable Claim-Drift Fence

**What:** Encode the claim hierarchy in `test/lockspire/release_readiness_contract_test.exs` so docs cannot silently drift back toward overclaim. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**When to use:** Whenever docs, workflow contracts, or proof references change. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**Example:**

```elixir
test "conformance docs keep repo-native proof primary" do
  supported_surface = File.read!("docs/supported-surface.md")
  maintainer_conformance = File.read!("docs/maintainer-conformance.md")

  assert supported_surface =~ "canonical public support contract"
  assert maintainer_conformance =~ "optional supplemental"
  refute maintainer_conformance =~ "release gate"
end
```

Source pattern: the existing contract test already pins hierarchy and wording for release and conformance docs. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

### Pattern 3: Preserve History, Demote Authority

**What:** Keep raw Phase 37 artifacts for auditability, but relabel and de-reference them so they cannot be misread as active proof. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md]

**When to use:** When a prior artifact remains useful history but is misleading as current truth. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

**Example:**

```markdown
## Historical note

This Phase 37 external OIDF lane is preserved for audit history only.
It is not current milestone-close proof for Lockspire's shipped support contract.
```

Source pattern: preserve useful history, label it, and stop current-proof docs from citing it as active evidence. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

### Anti-Patterns to Avoid

- **Second conformance matrix:** It duplicates `docs/supported-surface.md` and contradicts the locked “one canonical truth hierarchy” decision. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]
- **External suite as milestone-close gate:** It conflicts with the requirement to prefer repo-native proof and with the verified failure state of the historical Phase 37 external lane. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]
- **Keeping Phase 37 contract assertions unchanged:** The current release contract test still asserts preservation of the old lane wiring, which would lock in the very posture Phase 66 is supposed to retire. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Milestone closure traceability | A new standalone closure dashboard or matrix system | `v1.16-MILESTONE-AUDIT.md` following v1.14/v1.15 precedent | Existing milestone audits already act as evidence indexes without becoming parallel contracts. [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] |
| Public conformance claims | A second maintainer-facing claim surface | `docs/supported-surface.md` | Phase 65 already established it as the only canonical public support contract. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/maintainer-release.md] |
| Proof retirement | Deleting all Phase 37 history | Explicit historical labeling and de-referencing | The phase context prefers preserving audit value while removing misleading authority. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] |
| External corroboration policy | A new certification program | Optional existing OIDF/FAPI wiring with sharper wording | The phase explicitly forbids broad certification-program expansion. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] |

**Key insight:** Phase 66 should retire a misleading proof posture, not replace it with a fresh documentation platform. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating Wiring As Proof

**What goes wrong:** Maintainers keep `mix conformance.phase37`, the OIDF workflow, and `.artifacts/conformance/phase37` in the trust story even though the recorded run was skip-mode with `exported_files: []`. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: .artifacts/conformance/phase37/run-summary.json]

**Why it happens:** The summary and contract tests preserved the lane wiring as if that meant closure. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**How to avoid:** Rewrite the docs and tests to distinguish “repo-owned proof” from “optional historical or supplemental lane.” [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

**Warning signs:** `run-summary.json` still says `mode: "local-integration-only"` and `skipped`, while docs cite the bundle as proof. [VERIFIED: .artifacts/conformance/phase37/run-summary.json] [VERIFIED: docs/supported-surface.md]

### Pitfall 2: Parallel Truth Surfaces

**What goes wrong:** The repo ends up with supported-surface docs, maintainer conformance docs, phase summaries, and a closure report all restating different versions of the truth. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/maintainer-conformance.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md]

**Why it happens:** Historical docs were allowed to stay claim-bearing after the canonical support-contract model was established in later phases. [VERIFIED: .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md] [VERIFIED: docs/maintainer-release.md]

**How to avoid:** Put claims in one place, make everything else reference that place, and use ExUnit to enforce the rule. [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**Warning signs:** A maintainer can answer “what do we prove?” differently depending on whether they open `supported-surface`, `maintainer-conformance`, or Phase 37 history. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/maintainer-conformance.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md]

### Pitfall 3: Over-Retiring Useful History

**What goes wrong:** The team deletes artifact and summary files that still provide post-mortem value. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

**Why it happens:** It is tempting to remove the contradiction by removing the history. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

**How to avoid:** Keep the raw files, add explicit retired or historical framing, and stop current-proof docs from pointing at them as proof. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

**Warning signs:** Historical files remain unlabelled but new docs silently stop mentioning them. [VERIFIED: repository inspection]

## Code Examples

Verified patterns from repo sources:

### Claim Hierarchy Assertion

```elixir
test "public truth stays canonical" do
  guide = File.read!("docs/maintainer-conformance.md")
  contract = File.read!("docs/supported-surface.md")

  assert contract =~ "canonical public support contract"
  refute guide =~ "public support contract"
end
```

Source pattern: existing release-readiness assertions already encode canonical-vs-subordinate wording checks. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

### Closure Audit Entry

```markdown
| CONF-01 | satisfied | `docs/supported-surface.md`; `37-VERIFICATION.md`; `37-04-SUMMARY.md` | Phase 37 external OIDF lane retired as explicit non-claim; strictness E2E remains executable proof. |
```

Source pattern: existing milestone audits use requirement-to-evidence rows rather than duplicate feature matrices. [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treating Phase 37 lane wiring and stub artifacts as part of the active trust story | Treating Phase 37 strictness E2E plus current docs/tests as the active proof story, with the external lane retired to optional/historical context | The contradiction is visible by 2026-04-28 verification and explicitly targeted in Phase 66 context on 2026-05-07. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] | Removes overclaim risk without requiring a certification program. [VERIFIED: .planning/REQUIREMENTS.md] |
| Maintainer conformance guide as a quasi-claim surface | Maintainer conformance guide as subordinate workflow documentation under the supported-surface contract | Phase 65 established the hierarchy; Phase 66 should apply it to conformance. [VERIFIED: .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md] [VERIFIED: docs/maintainer-release.md] | Lets maintainers reproduce trust story without folklore or duplicate matrices. [VERIFIED: .planning/REQUIREMENTS.md] |
| Separate evidence fragments spread across phase summaries, workflows, and docs | Single milestone audit as evidence index over canonical artifacts | Existing v1.14 and v1.15 audits already show the intended shape. [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] | Gives Phase 66 a minimal coherent closure package. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**

- Treating `37-04-SUMMARY.md` frontmatter `requirements-completed: [CONF-04]` as authoritative is outdated because `37-VERIFICATION.md`, `v1.8` requirements, and milestone state all record the gap as unresolved or deferred. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: .planning/milestones/v1.8-REQUIREMENTS.md] [VERIFIED: .planning/STATE.md]
- Treating `.artifacts/conformance/phase37/run-summary.json` as proof of an executed external OIDF suite is outdated because the artifact itself records skip-mode output with no exported suite files. [VERIFIED: .artifacts/conformance/phase37/run-summary.json]

## Assumptions Log

All material claims in this research were verified against the repository state read during this session. [VERIFIED: repository inspection]

## Open Questions (RESOLVED)

1. **Where should the single v1.16 closure index live?**
   - Decision: use `.planning/milestones/v1.16-MILESTONE-AUDIT.md` as the sole durable closure index for Phase 66 and v1.16.
   - Why: prior shipped milestones already use the milestone-audit shape successfully, and Phase 66 explicitly rejects a second long-lived closure matrix or parallel contract surface. [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]
   - Effect on planning: do not create a second phase-local closeout report beyond normal phase summaries; make `v1.16-MILESTONE-AUDIT.md` the claim-bearing closure index. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

2. **How much of the old external-lane wiring should remain executable?**
   - Decision: retain existing workflow, alias, and shell wiring only as supplemental maintainer corroboration and historical audit trail, not as claim-bearing or milestone-closing proof.
   - Why: Docker and the wiring still exist, but Phase 66 decisions require repo-native proof to stay primary and external execution to remain optional. [VERIFIED: .github/workflows/oidf-conformance.yml] [VERIFIED: mix.exs] [VERIFIED: scripts/conformance/run_phase37_suite.sh] [VERIFIED: `docker --version`] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]
   - Effect on planning: docs and contract tests must demote the old lane to explicit supplemental or historical corroboration; if any claim-bearing tests still treat it as primary proof, remove or rewrite those assertions first. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Release-contract tests and mix alias inspection | ✓ [VERIFIED: `elixir --version`] | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Mix | Contract-test and alias-based proof surfaces | ✓ [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: `mix --version`] | — |
| Docker | Optional external OIDF corroboration lane only | ✓ [VERIFIED: `docker --version`] | 29.4.1 [VERIFIED: `docker --version`] | Demote to documentation-only supplemental path if not used. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] |
| GitHub Actions hosted runner | Scheduled/manual OIDF workflow lane | n/a from local shell [VERIFIED: workflow is checked in, live hosted execution not inspected] | — | Rely on checked-in workflow contract plus repo-native tests for milestone closure. [VERIFIED: .github/workflows/oidf-conformance.yml] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

**Missing dependencies with no fallback:** None for the recommended repo-native closure path. [VERIFIED: repository inspection]

**Missing dependencies with fallback:** Live hosted GitHub Actions execution is outside local verification, but the recommended milestone-close proof does not require it. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] [VERIFIED: .github/workflows/oidf-conformance.yml]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit under Mix / Elixir test stack. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Config file | `mix.exs` aliases and test tasks are the relevant phase-level contract surface. [VERIFIED: mix.exs] |
| Quick run command | `mix test test/lockspire/release_readiness_contract_test.exs -x` [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Full suite command | `MIX_ENV=test mix ci` for contributor proof; `MIX_ENV=test mix conformance.phase37` only if optional external corroboration remains documented. [VERIFIED: docs/maintainer-release.md] [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONF-01 | Public docs and historical artifacts stop implying unresolved Phase 37 external proof is current support truth. [VERIFIED: .planning/REQUIREMENTS.md] | contract + doc audit | `mix test test/lockspire/release_readiness_contract_test.exs -x` | ✅ [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| CONF-02 | Maintainer conformance docs make repo-native proof primary and external suites supplemental only. [VERIFIED: .planning/REQUIREMENTS.md] | contract | `mix test test/lockspire/release_readiness_contract_test.exs -x` | ✅ [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| V-01 | v1.16 milestone closure maps every requirement to proof or explicit non-claim. [VERIFIED: .planning/REQUIREMENTS.md] | artifact audit | No dedicated automated command today; planner should add at least one contract assertion for existence or wording if the audit path becomes stable. [VERIFIED: .planning/milestones/v1.14-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] | ❌ Wave 0 [VERIFIED: `.planning/milestones/v1.16-MILESTONE-AUDIT.md` absent during this session] |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/release_readiness_contract_test.exs -x` [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- **Per wave merge:** `MIX_ENV=test mix test.integration` if docs continue to cite generated-host proof, plus the contract test. [VERIFIED: docs/supported-surface.md] [VERIFIED: mix.exs]
- **Phase gate:** Contract test green, milestone audit written, and canonical docs no longer cite retired Phase 37 external proof as current evidence. [VERIFIED: docs/supported-surface.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md]

### Wave 0 Gaps

- [ ] Add or revise contract-test assertions so Phase 66 locks the new conformance truth hierarchy instead of the old lane-preservation posture. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- [ ] Create `v1.16-MILESTONE-AUDIT.md` or equivalent single closure index artifact that maps all v1.16 requirements to proof/non-claims. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 66 does not add or modify end-user authentication behavior; it changes claim and proof posture. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md] |
| V3 Session Management | no | No session-runtime changes are required by the recommended closure path. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | no | No new authorization or admin access logic is introduced by the recommended closure path. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes | Use contract tests and doc assertions to prevent overclaim or stale-proof regressions. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| V6 Cryptography | no | The phase should not change cryptographic behavior; it only reframes conformance and truth surfaces. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: docs/maintainer-conformance.md] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misleading trust claim caused by stale docs or historical artifacts | Spoofing / Repudiation | Canonical support contract plus contract tests that reject overclaim wording. [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Folklore-based release or conformance workflow | Repudiation | Maintainer docs must defer to canonical proof and explicitly mark optional supplemental lanes. [VERIFIED: docs/maintainer-release.md] [VERIFIED: docs/maintainer-conformance.md] |
| Historical artifact interpreted as current certification evidence | Spoofing | Explicit retired/historical labeling and removal from current-proof citation chains. [VERIFIED: .planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md] [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md] |

## Sources

### Primary (HIGH confidence)

- [`.planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md`](/Users/jon/projects/lockspire/.planning/phases/66-conformance-debt-retirement-milestone-closure/66-CONTEXT.md:1) - locked decisions, canonical refs, and artifact-shape constraints.
- [`.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md`](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md:1) - authoritative unresolved Phase 37 debt record.
- [`.planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md`](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md:1) - contradictory completion marker and historical lane posture.
- [`docs/supported-surface.md`](/Users/jon/projects/lockspire/docs/supported-surface.md:1) - canonical public support contract and current trust posture language.
- [`docs/maintainer-conformance.md`](/Users/jon/projects/lockspire/docs/maintainer-conformance.md:1) - current maintainer conformance workflow wording.
- [`docs/maintainer-release.md`](/Users/jon/projects/lockspire/docs/maintainer-release.md:1) - established evidence hierarchy precedent.
- [`test/lockspire/release_readiness_contract_test.exs`](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:1) - executable doc/workflow drift fence.
- [`.planning/milestones/v1.14-MILESTONE-AUDIT.md`](/Users/jon/projects/lockspire/.planning/milestones/v1.14-MILESTONE-AUDIT.md:1) - prior closure index precedent.
- [`.planning/milestones/v1.15-MILESTONE-AUDIT.md`](/Users/jon/projects/lockspire/.planning/milestones/v1.15-MILESTONE-AUDIT.md:1) - prior closure index precedent and explicit deferred Phase 37 note.

### Secondary (MEDIUM confidence)

- [`.github/workflows/oidf-conformance.yml`](/Users/jon/projects/lockspire/.github/workflows/oidf-conformance.yml:1) - optional workflow wiring and artifact handling.
- [`scripts/conformance/run_phase37_suite.sh`](/Users/jon/projects/lockspire/scripts/conformance/run_phase37_suite.sh:1) - external-lane harness shape and skip-mode artifact generation.
- [`.artifacts/conformance/phase37/run-summary.json`](/Users/jon/projects/lockspire/.artifacts/conformance/phase37/run-summary.json:1) - recorded stub artifact showing no suite export files.
- [`.planning/MILESTONES.md`](/Users/jon/projects/lockspire/.planning/MILESTONES.md:1) - milestone-history wording and deferred-gap references.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the recommendation is to reuse existing repo-native docs, tests, and audit patterns already present in the repository. [VERIFIED: repository inspection]
- Architecture: HIGH - the canonical hierarchy and audit-index precedent are directly visible in current docs, tests, and milestone artifacts. [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/maintainer-release.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md]
- Pitfalls: HIGH - the main failure modes are explicitly recorded in `37-VERIFICATION.md`, the current contract tests, and the stub artifact bundle. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: .artifacts/conformance/phase37/run-summary.json]

**Research date:** 2026-05-07 [VERIFIED: current session date]
**Valid until:** 2026-06-06 for this repo state, or until the conformance docs/tests/history are modified. [VERIFIED: repository-state-bound recommendation]
