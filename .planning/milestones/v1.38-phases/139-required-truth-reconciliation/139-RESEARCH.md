# Phase 139: Required Truth Reconciliation - Research

**Researched:** 2026-09-11
**Domain:** Repository acceptance, GitHub Actions evidence, release provenance, and planning-truth reconciliation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Exact-SHA Acceptance Boundary
- **D-01:** Use one synchronized final `main` SHA as Phase 139's acceptance anchor. The Phase 138 publication SHA, a phase-branch HEAD, the historical `1.5.0` source SHA, and an arbitrary latest successful workflow run are distinct evidence and must not substitute for that anchor.
- **D-02:** Revalidate the immutable Phase 138 inventory relation at Phase 139's required authority boundaries. The inventory remains proposal-only; any `refresh_required`, incomplete source, identity mismatch, or unauthorized post-snapshot movement fails closed instead of being reinterpreted as current acceptance evidence.
- **D-03:** Bind fresh `mix ci`, repository-hygiene results, the canonical required-CI result, and the release-workflow outcome to the same reconciled final `main` SHA. A successful workflow result for another SHA cannot satisfy the phase even if it is the newest green run.

### Release Outcome and Historical Traceability
- **D-04:** Treat a successful push-triggered Release workflow whose publication-only jobs intentionally skip as a valid no-publish outcome for the reconciled baseline. Only the existing protected exact-ref dispatch path may publish.
- **D-05:** Preserve the proven `1.5.0` release chain as historical evidence: source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`, canonical CI run `33141161205`, protected release run `33141484467`, package SHA-256 `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`, its tag, public Hex package, and maintained release records. Do not rewrite that chain as though it describes the newer reconciliation SHA.
- **D-06:** Treat the executable protected-release workflow and its contract tests as the authority for release ordering and eligibility. Where maintained explanatory prose disagrees, reconcile the prose to the executable contract without manually changing versions, changelog entries, manifests, tags, or package publication state.

### Deterministic Hygiene and Supply-Chain Guardrails
- **D-07:** Add or tighten a repository-health check only when Phase 139 execution demonstrates a repeatable repository-owned gap. Keep any correction narrow, deterministic, and tied to an already-required invariant rather than building a new maintenance subsystem.
- **D-08:** Close the demonstrated exact-head evidence gap: repository checks that claim required workflow success must compare the observed workflow SHA to the reconciled baseline SHA. Preserve full-commit-SHA pinning across workflow actions and the repository-controlled composite Release Please action.
- **D-09:** Keep Phase 139 maintainer enforcement in existing repo-local shell and focused ExUnit contract tests. Do not introduce a Mix task, Phoenix route, LiveView, Ecto schema, Oban job, or packaged/runtime Lockspire API.

### Planning and Supplemental-Evidence Taxonomy
- **D-10:** Planning truth and shipped-release truth are related but distinct: `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` should identify v1.38 and Phase 139 as active, while release records continue to identify v1.37 / Lockspire `1.5.0` as the latest shipped state until the normal release train changes that fact.
- **D-11:** Keep OIDF/FAPI results in a separate redacted, supplemental, non-certifying evidence class. Supplemental results neither satisfy required acceptance nor block a baseline whose required repository-owned checks pass; retained failures remain future bounded conformance evidence.
- **D-12:** Reconcile maintained planning and release prose only where current repository evidence proves a contradiction. Preserve historical records and explicit deferrals instead of rewriting archives or declaring the active maintenance milestone released.

### the agent's Discretion
Downstream planning may choose internal shell helper names, the exact compact format used to record SHA-bound receipts and hygiene `WARN` dispositions, deterministic ordering, and which existing focused contract-test module owns each assertion. Those choices must preserve the exact-SHA boundary, immutable historical evidence, release ownership, fail-closed semantics, supplemental-evidence taxonomy, and repo-local tooling boundary above.

### Deferred Ideas (OUT OF SCOPE)
- Per-PR dependency compatibility, security, and merge/close decisions remain Phase 140 work.
- Branch, tag, worktree, issue, PR, or maintained-record cleanup remains Phase 140 work and requires exact-target revalidation.
- Final dated baseline publication and the return to the sustaining GA release train remain Phase 141 work.
- Supplemental OIDF/FAPI failure remediation remains a future bounded conformance-hardening milestone unless Phase 139 proves a narrow repository regression.
- A new CI platform, maintenance database/dashboard, broad dependency campaign, protocol capability, host seam, or admin surface remains outside v1.38.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CI-06 | Maintainer can prove all required repo-owned CI checks pass for the exact synchronized final `main` SHA. | Exact-run REST validation, final-main sequencing, and required-CI receipt design. [VERIFIED: .planning/REQUIREMENTS.md:23-27] |
| CI-07 | Maintainer can prove the release workflow is successful or intentionally skipped/no-op for that same baseline without publishing or manually changing release-owned files. | Push/no-publish job graph and explicit skipped-publication receipt. [VERIFIED: .planning/REQUIREMENTS.md:25-27] |
| CI-08 | Maintainer can distinguish required acceptance checks from supplemental OIDF runs and retain OIDF findings as redacted, non-certifying evidence. | Separate required/supplemental evidence classes and existing OIDF contract reuse. [VERIFIED: .planning/REQUIREMENTS.md:25-27] |
| QUAL-05 | Maintainer can run `mix ci` from the reconciled baseline with all checks passing. | Current failing proof-quality test and canonical alias analysis. [VERIFIED: .planning/REQUIREMENTS.md:29-33] |
| HYGIENE-05 | Maintainer can run the repository hygiene check with no unresolved `BLOCK` result and an explicit disposition for every `WARN`. | Exact-SHA hygiene mode, structured results, and WARN disposition record. [VERIFIED: .planning/REQUIREMENTS.md:31-33] |
| HYGIENE-06 | Maintainer can add or tighten a deterministic repository-health check only when execution demonstrates a repeatable repository-owned gap. | Demonstrated latest-run mismatch and composite-action scan gaps. [VERIFIED: .planning/REQUIREMENTS.md:31-33] |
| TRUTH-03 | Maintainer can verify that planning and maintained records describe one coherent current milestone and release posture. | Enumerated, source-backed prose contradictions and active-vs-shipped model. [VERIFIED: .planning/REQUIREMENTS.md:35-39] |
| TRUTH-04 | Maintainer can trace the current public release through its immutable release chain without rewriting historical evidence. | Live and maintained-record cross-check of the `1.5.0` chain. [VERIFIED: .planning/REQUIREMENTS.md:35-39] |
| TRUTH-05 | Maintainer can verify Release Please ownership, protected exact-ref publishing, full-SHA action pins, and manifest-bound artifact proof remain intact. | Executable release ordering, manifest schema, and expanded supply-chain contract. [VERIFIED: .planning/REQUIREMENTS.md:35-39] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve Lockspire as a separate embedded Phoenix/Elixir companion library; do not turn it into a standalone auth service or a Sigra module. [VERIFIED: AGENTS.md:1-21]
- Keep protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin boundaries strong; keep host-owned account resolution, claims, login redirects, branding, and product policy behind the narrow host seam. [VERIFIED: AGENTS.md:14-21]
- Do not expand v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md:14-21]
- Preserve the security defaults: `"PKCE S256 required by default"`, `"Exact-match redirect URI validation"`, `"Client secrets hashed at rest"`, `"Authorization codes short-lived and single-use"`, `"Refresh token rotation with family-wide revocation on reuse"`, `"No implicit flow"`, `"No alg=none"`, and `"Strong redaction in logs and operator surfaces"`. [VERIFIED: AGENTS.md:41-50]
- This phase must remain maintainer-only repository work; it must not add product or runtime surface. [VERIFIED: .planning/phases/139-required-truth-reconciliation/139-CONTEXT.md:7-10]

## Summary

Phase 139 should be planned as reconciliation of three distinct truths joined by one full commit SHA: repository-local acceptance (`mix ci` plus hygiene), canonical GitHub CI plus the push-triggered Release no-publish outcome, and maintained planning/release records. The existing release automation already contains the stronger exact-SHA and manifest-bound patterns to reuse: it verifies a 40-hex current `origin/main`, validates CI workflow identity/event/branch/status/conclusion/head SHA/repository, checks out that exact commit, moves one tar through a SHA-named artifact, verifies its manifest, publishes the package, and only then creates the matching GitHub release. [VERIFIED: .github/workflows/release.yml:70-202] [VERIFIED: .github/workflows/release.yml:204-315]

Research found three immediate repository-owned blockers/gaps. First, the production Phase 138 relation verifier currently exits 1 with the exact verdict `"snapshot_relation: refresh_required"`; the two Phase 139 context/lifecycle commits are classified `unknown`, while the ledger contract says any nonzero exit or `refresh_required` requires recollection and a new ledger-only replacement. [VERIFIED: production verifier output, 2026-09-11] [VERIFIED: .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md:199-213] Second, workflow lint exits 1 on four ShellCheck warnings in `baseline_inventory.sh`. [VERIFIED: `bash scripts/ci/lint_workflows.sh` output, 2026-09-11] Third, the focused proof-quality baseline exits 2 because thirteen phase-numbered proof labels now appear in `test/support/lockspire/release_proof/package_assertions.ex`. [VERIFIED: focused ExUnit output, 2026-09-11]

The plan must end with an external, read-only mainline checkpoint after every Phase 139 repository mutation is present on synchronized `main`. At that checkpoint, capture the full SHA once; run or validate local gates at exactly that checkout; query required CI and Release runs by that exact SHA; prove the push Release run succeeded while dispatch-only publication jobs skipped; and make no subsequent Phase 139 repository write that would create an untested SHA. [VERIFIED: .planning/phases/139-required-truth-reconciliation/139-CONTEXT.md:16-24] Phase 141, not Phase 139, owns the final dated committed baseline record. [VERIFIED: .planning/REQUIREMENTS.md:47-50]

**Primary recommendation:** Repair the fail-closed/current gate blockers first, implement one exact-SHA acceptance path in the existing hygiene shell plus focused ExUnit contracts, reconcile only the proven prose contradictions, then perform one final read-only proof against the synchronized final `main` SHA without dispatching a release.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Phase 138 input currentness | Repository maintainer shell | Immutable planning ledger | The production relation verifier owns semantic currentness; the ledger defines fail-closed refresh semantics. [VERIFIED: baseline-inventory-2026-08-28.md:199-213] |
| Local acceptance | Mix/ExUnit and maintainer shell | Git checkout | `mix ci` owns the contributor gate; hygiene owns repository state and receipt aggregation. [VERIFIED: mix.exs:147-155] [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:402-526] |
| Required CI evidence | GitHub Actions | Maintainer evidence reader | CI runs remotely, while the repo-local reader must validate exact run metadata rather than trust “latest.” [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:453-487] |
| No-publish Release outcome | GitHub Actions | Focused ExUnit contracts | Push owns Release Please only; dispatch validation gates all publication jobs. [VERIFIED: .github/workflows/release.yml:3-20] [VERIFIED: .github/workflows/release.yml:33-122] |
| Artifact provenance | Protected release workflow | `release_artifact.py` | The workflow moves the one tar; the helper validates the manifest, checksum, and source SHA. [VERIFIED: .github/workflows/release.yml:168-202] [VERIFIED: scripts/publish/release_artifact.py:104-174] |
| Supply-chain immutability | Workflow/composite YAML | ExUnit contract | External action refs live in both locations; contract coverage must include both. [VERIFIED: test/lockspire/workflow_supply_chain_contract_test.exs:4-20] [VERIFIED: .github/actions/release-please/action.yml:121-135] |
| Supplemental OIDF evidence | Supplemental workflow | Redacted receipt contracts | It is scheduled/dispatch-only, read-only, separately named, and retains bounded receipt JSON. [VERIFIED: .github/workflows/oidf-conformance.yml:1-25] [VERIFIED: .github/workflows/oidf-conformance.yml:79-97] |
| Planning and release prose | Repository planning/docs | Executable workflow/contracts | Prose is corrected to the executable authority while historical records remain immutable. [VERIFIED: .planning/phases/139-required-truth-reconciliation/139-CONTEXT.md:31-36] |

## Standard Stack

### Core

| Tool | Version/contract | Purpose | Why Standard |
|------|------------------|---------|--------------|
| GNU Bash | 5.2.37 locally | Extend the existing fail-closed maintainer checks. | Locked repo-local shell boundary; no new subsystem. [VERIFIED: environment audit output, 2026-09-11] |
| Git | 2.41.0 locally; full 40-hex commit identity | Synchronize and prove the final main checkout. | Existing verifiers and workflows use exact Git object identity. [VERIFIED: environment audit output, 2026-09-11] [VERIFIED: .github/workflows/release.yml:95-115] |
| GitHub CLI + REST | `gh` 2.95.0 locally | Query workflow identity and exact-SHA run evidence. | Existing automation already uses `gh api` and structured `jq` validation. [VERIFIED: environment audit output, 2026-09-11] [VERIFIED: .github/workflows/release.yml:104-115] |
| `jq` | 1.7.1 locally | Parse and compare workflow JSON structurally. | Avoids substring matching of unordered/partial JSON. [VERIFIED: environment audit output, 2026-09-11] |
| Mix/ExUnit | Mix 1.19.5 / Elixir 1.19.5, OTP 28 locally | Run canonical gates and drift contracts. | Existing alias and focused contract test architecture. [VERIFIED: environment audit output, 2026-09-11] [VERIFIED: mix.exs:130-155] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| ShellCheck | 0.11.0 locally | Validate changed maintainer shell. | Through `scripts/ci/lint_workflows.sh` on every shell change. [VERIFIED: environment audit output, 2026-09-11] |
| actionlint | 1.7.12 locally | Validate workflow syntax and embedded shell. | Through the existing workflow lint lane. [VERIFIED: environment audit output, 2026-09-11] |
| Python | 3.14.4 locally | Existing release manifest/receipt verifier only. | Preserve `release_artifact.py`; do not create a second acceptance implementation. [VERIFIED: environment audit output, 2026-09-11] [VERIFIED: scripts/publish/release_artifact.py:1-24] |
| PostgreSQL | 14.17 locally, accepting connections | Required by integration portions of `mix ci`. | Full acceptance, not exact-head metadata parsing. [VERIFIED: environment audit output, 2026-09-11] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing shell + ExUnit | New Mix task or service | Rejected by locked D-09; it would add a second maintainer surface. [VERIFIED: 139-CONTEXT.md:26-29] |
| `gh api` + `jq` | `gh run list` substring tests | Current implementation proves this loses exact workflow/SHA semantics. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:463-487] |
| Exact-SHA run query | Latest green run | Rejected by CI-06 and D-03 because recency is not identity. [VERIFIED: .planning/REQUIREMENTS.md:23-27] |

**Installation:** None. This phase must add no external package; all required tools and test infrastructure already exist. [VERIFIED: 139-CONTEXT.md:7-10]

## Package Legitimacy Audit

Not applicable. No external package installation is recommended or authorized. [VERIFIED: 139-CONTEXT.md:7-10]

## Architecture Patterns

### System Architecture Diagram

```text
immutable Phase 138 ledger
          |
          v
production relation verifier ---- refresh_required/incomplete/mismatch ----> STOP + replace ledger
          |
          | authorized/current
          v
narrow repairs + focused contracts + prose reconciliation
          |
          v
all Phase 139 repo mutations land on synchronized main
          |
          v
capture BASELINE_SHA once
   |             |                         |
   v             v                         v
clean checkout   required CI query         push Release query
mix ci           exact head_sha            same exact head_sha
hygiene          identity/event/success    Release Please success
SHA before/after required jobs green        publish-only jobs skipped
   \_____________|_________________________/
                 |
                 v
          one read-only acceptance receipt
                 |
                 v
       Phase 140 consumes; Phase 141 records final dated baseline
```

### Recommended Project Structure

```text
scripts/maintainer/
├── baseline_inventory.sh        # existing fail-closed currentness authority
└── repo_hygiene_check.sh        # exact-SHA acceptance and PASS/WARN/BLOCK aggregation
.github/
├── workflows/
│   ├── ci.yml                   # canonical required remote checks
│   ├── release.yml              # push no-publish / protected dispatch publish split
│   └── oidf-conformance.yml     # supplemental-only evidence
└── actions/release-please/
    └── action.yml               # composite action included in full-SHA scan
test/lockspire/
├── release/repository_hygiene_contract_test.exs
├── release_ci_evidence_contract_test.exs
└── workflow_supply_chain_contract_test.exs
```

### Pattern 1: Capture Once, Compare Everywhere

**What:** Resolve `BASELINE_SHA` from synchronized `main`, require a clean detached or main checkout at that SHA, and compare every local and remote observation to the same literal 40-hex value. Capture HEAD before and after a long local gate so a checkout mutation cannot inherit a PASS. [VERIFIED: .github/workflows/release.yml:95-115]

**When to use:** The final acceptance mode only; preserve the existing diagnostic hygiene mode for ordinary maintainers. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:402-526]

**Example:**

```bash
# Source: repository protected-release validation pattern
test "$(git rev-parse HEAD)" = "$BASELINE_SHA"
test "$(git rev-parse main)" = "$BASELINE_SHA"
test "$(git rev-parse origin/main)" = "$BASELINE_SHA"
before_sha="$(git rev-parse HEAD)"
mix ci
test "$(git rev-parse HEAD)" = "$before_sha"
```

All discrete values in this skeleton—`HEAD`, `main`, and `origin/main`—mirror the repository's exact-ref validation vocabulary. [VERIFIED: .github/workflows/release.yml:99-115]

### Pattern 2: Structured Workflow Identity Validation

**What:** Query runs filtered by `head_sha`, then validate workflow ID/path/name, repository, branch, event, status, conclusion, head SHA, run ID, and URL. The current string search for only `conclusion` or `status` is insufficient. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:463-487]

**When to use:** Any hygiene result that claims canonical CI or Release success.

GitHub's workflow-runs REST endpoint supports `head_sha` filtering and exposes the run fields needed for the receipt. [CITED: https://docs.github.com/en/rest/actions/workflow-runs]

### Pattern 3: Model Intentional Skip as a Positive No-Publish State

**What:** For a push event at the baseline SHA, require the Release run itself and the `"Maintain Release Please PR"` job to succeed, while requiring `"Validate exact main head and CI evidence"`, `"Prove exact package before publication"`, `"Publish verified release to Hex"`, and `"Verify public install truth"` to be skipped. Those exact job names are the executable state vocabulary. [VERIFIED: .github/workflows/release.yml:33-122] [VERIFIED: .github/workflows/release.yml:204-315]

**When to use:** CI-07 acceptance for a non-release reconciliation push. Do not dispatch `release.yml` to manufacture evidence.

GitHub documents that an intentionally skipped job reports success and does not block a required check. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions]

### Pattern 4: Test the Whole Action Reference Surface

**What:** Expand the existing immutable-reference scan from `.github/workflows/*.yml` to include `.github/actions/release-please/action.yml`; continue allowing local `./` actions and requiring external `uses:` references to end in a full 40-hex SHA. The current contract scans only workflow YAML, while the composite contains `"actions/setup-node@2028fbc5c25fe9cf00d9f06a71cc4710d4507903"`. [VERIFIED: test/lockspire/workflow_supply_chain_contract_test.exs:4-20] [VERIFIED: .github/actions/release-please/action.yml:121-135]

GitHub recommends pinning third-party actions to full-length commit SHAs because that is the immutable reference form. [CITED: https://docs.github.com/en/actions/reference/security/secure-use]

### Pattern 5: Preserve One Manifest-Bound Tar

**What:** Keep the existing manifest allowlist exactly: `"schema_version", "package", "version", "source_sha", "artifact", "runtime"`; keep artifact keys exactly `"filename", "sha256", "bytes"`; keep receipt stages exactly `"prepublish", "postpublish"`; and keep status exactly `"verified"`. [VERIFIED: scripts/publish/release_artifact.py:134-162] [VERIFIED: scripts/publish/release_artifact.py:222-252]

**When to use:** TRUTH-05 contract proof and historical release traceability. No Phase 139 publication occurs.

### Anti-Patterns to Avoid

- **Latest-run heuristics:** `--limit 1` plus a success substring can bless another SHA. Filter and compare exact run metadata. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:463-487]
- **Treating a branch run as final-main proof:** The existing script records the current branch but runs `mix ci` without tying it to local or remote main. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:403-425] [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:492-500]
- **Weakening a gate to make it green:** Repair the thirteen fixture/proof labels and four ShellCheck findings; do not exclude their files or suppress the rules globally. [VERIFIED: focused ExUnit and workflow-lint outputs, 2026-09-11]
- **Calling a push skip a missing release:** Publication jobs are structurally dispatch-only; their skip is the required no-publish result. [VERIFIED: .github/workflows/release.yml:70-122]
- **Storing a receipt after final SHA capture:** That creates a new untested SHA. Keep Phase 139's final evidence read-only; Phase 141 owns the committed dated baseline. [VERIFIED: .planning/REQUIREMENTS.md:47-50]
- **Rewriting shipped history:** The active planning milestone and latest shipped release are different facts. [VERIFIED: .planning/PROJECT.md:11-20] [VERIFIED: .planning/MILESTONES.md:3-24]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Snapshot currentness | Second commit classifier | `baseline_inventory.sh --verify-snapshot-relation` | The production verifier already checks ancestry, ledger blob, source completeness, later commits, and worktree projection. [VERIFIED: baseline-inventory-2026-08-28.md:203-213] |
| Workflow result parsing | JSON substring/regex parser | `gh api` plus `jq -e` | Exact identity requires structured field equality. [VERIFIED: .github/workflows/release.yml:104-115] |
| Release artifact evidence | New checksum/receipt format | `release_artifact.py` | It already enforces source SHA, size, filename, checksum, runtime allowlist, and exact Hex checksum. [VERIFIED: scripts/publish/release_artifact.py:104-196] |
| Release bookkeeping | Manual version/changelog/manifest/tag changes | Release Please and protected dispatch | Manual ownership is explicitly out of scope. [VERIFIED: .planning/REQUIREMENTS.md:62-72] |
| OIDF certification interpretation | New conformance dashboard/status | Existing redacted supplemental receipts | Existing contracts explicitly pin `"not OpenID certification"` and `"not a release gate"`. [VERIFIED: test/lockspire/conformance_workflow_contract_test.exs:61-88] |
| Acceptance framework | New Mix task, database, or service | Existing shell + focused ExUnit | Locked D-09. [VERIFIED: 139-CONTEXT.md:26-29] |

**Key insight:** This phase is about strengthening joins among existing authorities, not creating another authority.

## Exact Existing Gaps and Required Reconciliation

### 1. Phase 138 Currentness Is Currently Fail-Closed

The production verifier reports the ledger commit `"cacd53cfd7af9876d2ccf93b1e65a2d2cdec3968"`, parent `"539967ad962b325c839a2df0a6edc5a3f00ee72e"`, and final `"snapshot_relation: refresh_required"`. It authorizes the Phase 138 verification/completion/transition commits, but classifies the Phase 139 context commit `"c8ed29404c6df9d0a670083125e8f96fea5bd8c3"` and state commit `"dd67b848bba2609dcc7932ea31ca0bfe180c7b90"` as `"unknown"`. [VERIFIED: production verifier output, 2026-09-11]

Plan a hard precondition: either publish the prescribed new ledger-only replacement from a clean evidence base, or stop. Do not relabel the two commits in prose as authorized. Re-run after any lifecycle write not in the disclosed table. [VERIFIED: baseline-inventory-2026-08-28.md:201-218]

### 2. Local Required Gates Are Not Green

`bash scripts/ci/lint_workflows.sh` exits 1 with SC2209 at line 865 and SC2034 at lines 1094, 2853, and 3251 of `baseline_inventory.sh`. [VERIFIED: workflow-lint output, 2026-09-11] These are narrow Phase 139 gate repairs because the required CI workflow invokes workflow/shell lint as repository hygiene; they are not Phase 140 cleanup. [VERIFIED: `.github/workflows/ci.yml` repository-hygiene job, opened 2026-09-11]

The focused proof-quality test exits 2 with thirteen locations in `test/support/lockspire/release_proof/package_assertions.ex`: `1978`, `1994`, `2015`, `2036`, `2273`, `2431`, `2475`, `2484`, `2500`, `3514`, `3527`, `3535`, and `3615`. [VERIFIED: focused ExUnit output, 2026-09-11] Repair the fixture/proof labels while preserving the rule; do not broaden exclusions.

### 3. Hygiene Claims “Latest,” Not “This SHA”

The hygiene script fetches a single CI run and a single Release run with `--limit 1`, then recognizes success via substring; although `headSha` is requested, it is never compared. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:453-487] It also compares `main` to `origin/main` separately from the current branch and later executes `mix ci` without a before/after SHA binding. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:403-429] [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:492-500]

Add a narrow exact-SHA acceptance mode or helper while retaining the ordinary diagnostic report. The exact mode must block if HEAD, local main, or origin/main differs; if workflow identity or metadata differs; if the query is incomplete; or if HEAD moves during local gates. It should print one compact receipt containing baseline SHA, local gate result, CI run ID/event/conclusion/URL, Release run ID/event/conclusion/URL, no-publish job results, and every WARN disposition. [VERIFIED: 139-CONTEXT.md:16-29] [VERIFIED: 139-CONTEXT.md:36-37]

At research time, remote main was `"d82eaa1c74f396c5eb5dcfa393ddd5dd952acb92"`. Canonical CI run `"33143200540"` and Release run `"33143200622"` were both completed push successes at that exact SHA. The Release jobs reported `"Maintain Release Please PR" = "success"` and all four dispatch/publication jobs—`"Validate exact main head and CI evidence"`, `"Prove exact package before publication"`, `"Publish verified release to Hex"`, and `"Verify public install truth"`—as `"skipped"`. [VERIFIED: authenticated GitHub API output, 2026-09-11] This is a verified example of the intended no-publish shape, but it cannot satisfy Phase 139 because it predates the final reconciliation SHA. [VERIFIED: 139-CONTEXT.md:16-24]

### 4. Focused Contracts Miss Two Required Shapes

The supply-chain contract scans only `.github/workflows/*.yml`, so it does not protect the full-SHA external action inside `.github/actions/release-please/action.yml`. [VERIFIED: test/lockspire/workflow_supply_chain_contract_test.exs:4-20] Add the composite file to the scan and keep local action references permitted.

The release CI evidence contract proves exact dispatch eligibility, but it does not explicitly prove the successful push/no-publish job graph. [VERIFIED: test/lockspire/release_ci_evidence_contract_test.exs:7-54] Add a focused structural test for push-only Release Please and dispatch-only recovery/publication dependencies, then validate the actual job outcomes during the final live checkpoint.

### 5. Maintained Prose Has Proven Contradictions

Apply only these source-backed corrections:

- `.planning/REPO-HYGIENE-CHECKLIST.md` says confirm the `"latest"` main CI and Release runs; change this to the same exact synchronized baseline SHA. [VERIFIED: .planning/REPO-HYGIENE-CHECKLIST.md:13-24]
- The checklist says PROJECT, ROADMAP, STATE, and MILESTONES must all agree on the “current milestone posture”; clarify that active planning truth and latest-shipped history are intentionally distinct. [VERIFIED: .planning/REPO-HYGIENE-CHECKLIST.md:26-31] [VERIFIED: .planning/PROJECT.md:11-20] [VERIFIED: .planning/MILESTONES.md:3-24]
- `.planning/RELEASE-TRAIN.md` describes a push-triggered Hex publisher, but executable push behavior runs Release Please only. [VERIFIED: .planning/RELEASE-TRAIN.md:17-27] [VERIFIED: .github/workflows/release.yml:33-69]
- `.planning/RELEASE-TRAIN.md` says create the GitHub release before Hex publish, but the executable contract publishes the package first and creates the GitHub release second. [VERIFIED: .planning/RELEASE-TRAIN.md:22-27] [VERIFIED: .github/workflows/release.yml:256-284]
- `.planning/RELEASE-TRAIN.md` and `docs/maintainer-release.md` use “latest main CI” for eligibility; require the exact candidate/current-main SHA. [VERIFIED: .planning/RELEASE-TRAIN.md:46-52] [VERIFIED: docs/maintainer-release.md:96-109]
- `docs/maintainer-release.md` says dispatch may publish a SHA or tag; executable validation accepts only an exact lowercase 40-hex commit that equals current `origin/main`. [VERIFIED: docs/maintainer-release.md:78-84] [VERIFIED: docs/maintainer-release.md:96-107] [VERIFIED: .github/workflows/release.yml:95-115]
- `docs/maintainer-release.md` claims `mix ci` includes `mix test.phase3`; the alias contains only dependency fetch, QA, docs, audit, package build, fast tests, and integration tests. Remove the extra claim rather than altering the gate. [VERIFIED: docs/maintainer-release.md:56-72] [VERIFIED: mix.exs:147-155]
- `.planning/PROJECT.md` has a stale “Next Milestone Goals” paragraph saying to return to sustaining GA after archiving v1.37 even though its current milestone is v1.38 and Phase 139 is active; reconcile only that stale present-tense paragraph. [VERIFIED: .planning/PROJECT.md:11-18] [VERIFIED: .planning/PROJECT.md:37-49] [VERIFIED: .planning/PROJECT.md:83-85]

Do not change the historical `1.5.0` receipts, MILESTONES shipped record, archived milestone documents, release-owned version files, or supplemental failure history. [VERIFIED: .planning/RELEASE-TRAIN.md:7-15] [VERIFIED: .planning/MILESTONES.md:3-24]

### 6. Historical Release Chain Is Coherent

The maintained record quotes: source `"5d10ce2219c2e687cf9573c8b280abfb118a47d8"`, CI run `"33141161205"`, protected release run `"33141484467"`, version `"1.5.0"`, and tar SHA-256 `"30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de"`. [VERIFIED: .planning/RELEASE-TRAIN.md:7-15] The same values appear in shipped milestone production proof. [VERIFIED: .planning/MILESTONES.md:16-24]

Live GitHub/Hex queries on 2026-09-11 independently matched that chain: CI run 33141161205 succeeded at the exact source SHA; release run 33141484467 succeeded at that SHA; tag/release `lockspire-v1.5.0` targets it; and Hex reports version 1.5.0 with the same checksum. [VERIFIED: authenticated GitHub and Hex API outputs, 2026-09-11] Treat this as immutable historical evidence, never as Phase 139 acceptance.

### 7. Required vs Supplemental Evidence Is Already Sound

The OIDF workflow is separately named `"Supplemental OIDF Conformance"`, has only schedule/dispatch entry points, read-only contents permission, immutable tool/action inputs, and bounded receipt uploads. [VERIFIED: .github/workflows/oidf-conformance.yml:1-25] [VERIFIED: .github/workflows/oidf-conformance.yml:57-97] Its focused contract requires guide language `"not OpenID certification"`, `"not a release gate"`, plus classified statuses `"integration_only"`, `"infrastructure_failure"`, and `"suite_failure"`. [VERIFIED: test/lockspire/conformance_workflow_contract_test.exs:61-88]

No OIDF implementation change is indicated. Reuse the existing taxonomy in receipts and prose; do not make recent supplemental failures block required acceptance. [VERIFIED: 139-CONTEXT.md:31-34]

## Recommended Implementation Sequencing

1. **Precondition — currentness:** Run the Phase 138 production relation verifier. Because it currently returns `refresh_required`, plan the prescribed recollection/new ledger-only replacement before consuming inventory dispositions; rerun until exit 0 and exact `authorized_bookkeeping`. [VERIFIED: production verifier output, 2026-09-11] [VERIFIED: baseline-inventory-2026-08-28.md:203-213]
2. **Make existing gates green:** Add focused regression expectations, repair the four ShellCheck findings, and repair the thirteen active phase-number labels without weakening either guardrail. Run the focused tests and workflow lint. [VERIFIED: focused command outputs, 2026-09-11]
3. **Close deterministic evidence gaps test-first:** Extend the supply-chain scan to the composite action; add push/no-publish structure assertions; add exact-baseline hygiene cases for match, wrong SHA, wrong workflow identity, incomplete/malformed response, in-progress/cancelled/failure, and HEAD movement. [VERIFIED: test/lockspire/workflow_supply_chain_contract_test.exs:4-20] [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:453-500]
4. **Implement the narrow hygiene seam:** Reuse `gh api`/`jq`, the existing `PASS`/`WARN`/`BLOCK` aggregator, and one baseline SHA. Preserve non-acceptance diagnostic behavior; fail closed in exact acceptance mode. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:402-526]
5. **Reconcile maintained prose:** Apply only the enumerated contradictions; preserve active-v1.38 versus shipped-v1.37/1.5.0 distinction and all historical evidence. [VERIFIED: .planning/PROJECT.md:11-49] [VERIFIED: .planning/MILESTONES.md:3-24]
6. **Candidate verification:** From a clean candidate checkout, revalidate inventory relation, run focused tests, workflow lint, full `mix ci`, and hygiene. Record and explicitly disposition every WARN. [VERIFIED: .planning/REQUIREMENTS.md:29-39]
7. **Final exact-main checkpoint:** Put every Phase 139 mutation on synchronized `main`; capture the full SHA; wait for canonical CI and push Release runs for exactly that SHA; validate required CI success and intentional publication-job skips; rerun local gates at that SHA; do not dispatch the release workflow and do not write another Phase 139 repository commit. [VERIFIED: 139-CONTEXT.md:16-24]

## Common Pitfalls

### Pitfall 1: Evidence-Time Race
**What goes wrong:** A run is queried as “latest,” then main advances, yet the old green result is reported against the new state. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:463-487]
**How to avoid:** Capture SHA once, filter by exact SHA, validate returned metadata, and recheck local/remote SHA after gates.
**Warning signs:** `--limit 1`, unconsumed `headSha`, or receipt text with no run ID/SHA.

### Pitfall 2: Self-Invalidating Final Receipt
**What goes wrong:** Committing the receipt after acceptance changes the SHA being claimed. [VERIFIED: 139-CONTEXT.md:16-24]
**How to avoid:** Make final Phase 139 acceptance read-only; leave committed dated closure to Phase 141. [VERIFIED: .planning/REQUIREMENTS.md:47-50]
**Warning signs:** Any planned Phase 139 commit after live exact-main validation.

### Pitfall 3: Refresh Semantics Softened
**What goes wrong:** Unknown post-ledger commits are rationalized as harmless instead of refreshing the immutable snapshot. [VERIFIED: production verifier output, 2026-09-11]
**How to avoid:** Treat any nonzero/`refresh_required` as a stop and follow the ledger replacement contract. [VERIFIED: baseline-inventory-2026-08-28.md:209-213]
**Warning signs:** Prose says “effectively current” while verifier exits nonzero.

### Pitfall 4: Skip Means Failure—or Publication
**What goes wrong:** A push Release run with dispatch-only jobs skipped is either rejected or mistaken for proof of a published release. [VERIFIED: .github/workflows/release.yml:33-122]
**How to avoid:** Validate event plus per-job outcomes and name the state `no-publish`.
**Warning signs:** Receipt contains only overall conclusion.

### Pitfall 5: Contract Coverage Stops at Workflows
**What goes wrong:** A mutable external action can enter through the repo-controlled composite. [VERIFIED: test/lockspire/workflow_supply_chain_contract_test.exs:4-20]
**How to avoid:** Scan both workflow and composite action YAML.
**Warning signs:** Glob contains only `.github/workflows/*.yml`.

### Pitfall 6: Prose “Fix” Changes Executable Ownership
**What goes wrong:** A documentation contradiction triggers a release-workflow or version-file redesign. [VERIFIED: 139-CONTEXT.md:21-24] [VERIFIED: 139-CONTEXT.md:31-34]
**How to avoid:** Correct prose to current executable ordering; do not publish or alter release-owned files.
**Warning signs:** Plan touches `mix.exs` version, manifest, CHANGELOG release entry, tag, or Hex state.

## Code Examples

### Exact Workflow Run Selection and Validation

```bash
# Source: GitHub workflow-runs REST API + repository release validation pattern
runs_json="$(gh api "repos/$GH_REPO/actions/workflows/ci.yml/runs?branch=main&event=push&status=success&head_sha=$BASELINE_SHA&per_page=100")"
run="$(jq -cer --arg sha "$BASELINE_SHA" '[.workflow_runs[] | select(.head_sha == $sha)] | sort_by(.run_number) | last' <<<"$runs_json")"
test "$(jq -r '.path' <<<"$run")" = ".github/workflows/ci.yml"
test "$(jq -r '.head_branch' <<<"$run")" = "main"
test "$(jq -r '.status' <<<"$run")" = "completed"
test "$(jq -r '.conclusion' <<<"$run")" = "success"
test "$(jq -r '.head_sha' <<<"$run")" = "$BASELINE_SHA"
test "$(jq -r '.repository.full_name' <<<"$run")" = "$GH_REPO"
```

The values `".github/workflows/ci.yml"`, `"main"`, `"completed"`, and `"success"` appear verbatim in the repository's authoritative release validator. [VERIFIED: .github/workflows/release.yml:104-115] The `head_sha` query parameter is documented by GitHub. [CITED: https://docs.github.com/en/rest/actions/workflow-runs]

### Full Action Surface

```elixir
# Source: extension of existing focused contract
paths =
  Path.wildcard(Path.expand("../../.github/workflows/*.yml", __DIR__)) ++
    [Path.expand("../../.github/actions/release-please/action.yml", __DIR__)]
```

Both paths are verbatim repository paths from the current test and composite action location. [VERIFIED: test/lockspire/workflow_supply_chain_contract_test.exs:4-20] [VERIFIED: .github/actions/release-please/action.yml:121-125]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Newest green workflow | Query and validate exact `head_sha` plus workflow identity | Prevents unrelated green runs from satisfying acceptance. [CITED: https://docs.github.com/en/rest/actions/workflow-runs] |
| Tag/branch action refs | Full-length commit SHA | Makes third-party action source immutable. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
| Overall Release conclusion only | Event-aware per-job no-publish result | Distinguishes successful reconciliation from publication. [VERIFIED: .github/workflows/release.yml:33-122] |
| Separate build/publish artifacts | One SHA-named manifest-bound tar | Preserves source/package/checksum identity end to end. [VERIFIED: .github/workflows/release.yml:168-202] [VERIFIED: .github/workflows/release.yml:237-267] |

**Deprecated/outdated:**
- “Latest main CI” as acceptance language is outdated for this phase; use exact baseline SHA. [VERIFIED: .planning/REQUIREMENTS.md:23-27]
- Dispatch by tag is incompatible with the executable validator; use exact current-main 40-hex SHA. [VERIFIED: .github/workflows/release.yml:95-115]
- GitHub-release-before-Hex prose is inverted relative to the executable order. [VERIFIED: .github/workflows/release.yml:256-284]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. Recommendations are derived from locked context, opened repository authorities, executed gates, authenticated APIs, and official GitHub documentation. | — | — |

## Open Questions (RESOLVED)

1. **RESOLVED — What exact orchestration step lands all Phase 139 artifacts on `main` before the final read-only checkpoint?**
   - What we know: CI-06/07 require the synchronized final main SHA, and any later commit invalidates that anchor. [VERIFIED: .planning/REQUIREMENTS.md:23-27]
   - Resolution selected by Plans 139-06 and 139-07: Extend the already-consented project capability so `execute:complete:post` runs only after GSD seals the Phase 139 verification, completion, and transition writes. Its phase-aware router invokes `finalize_phase_139_acceptance.sh`, which validates the sealed host receipt, performs the exact non-force fast-forward to synchronized local and `origin/main`, runs final exact-SHA acceptance, and returns before host completion. No repository write follows the acceptance receipt. [VERIFIED: 139-06-PLAN.md; 139-07-PLAN.md]

2. **RESOLVED — Where should the compact live acceptance receipt be retained during Phase 139?**
   - What we know: D-03 requires a joined result, while Phase 141 owns final dated baseline publication. [VERIFIED: 139-CONTEXT.md:16-24] [VERIFIED: .planning/REQUIREMENTS.md:47-50]
   - Resolution selected by Plans 139-06 and 139-07: Retain `lockspire-phase-139-acceptance-v1.json` as an atomic mode-0600 regular file under the resolved Git common directory, outside the tracked worktree. The host completes by removing only its pending lifecycle state, the receipt remains available for Phase 141, and Phase 139 does not commit or stage it. [VERIFIED: 139-06-PLAN.md; 139-07-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Bash | maintainer scripts | ✓ | 5.2.37 | — |
| Git | SHA synchronization | ✓ | 2.41.0 | — |
| `gh` authenticated CLI | live run evidence | ✓ | 2.95.0 | GitHub REST via existing credential only if CLI breaks |
| `jq` | structured JSON validation | ✓ | 1.7.1 | None recommended |
| Elixir/Mix | local gates | ✓ with explicit ASDF selection | 1.19.5 / OTP 28 | Set `ASDF_ELIXIR_VERSION=1.19.5-otp-28` and `ASDF_ERLANG_VERSION=28.1` |
| ShellCheck | workflow lint | ✓ | 0.11.0 | CI runner |
| actionlint | workflow lint | ✓ | 1.7.12 | CI runner |
| Python | existing artifact helper | ✓ | 3.14.4 | CI-pinned runtime |
| PostgreSQL | integration suite | ✓ | 14.17, accepting connections | CI PostgreSQL service |

All availability and version values above come from direct command probes on 2026-09-11. [VERIFIED: environment audit output, 2026-09-11]

**Missing dependencies with no fallback:** None observed. [VERIFIED: environment audit output, 2026-09-11]

**Missing dependencies with fallback:** Plain `mix` selection was unavailable without explicit ASDF version variables because the local ignored tool-version file selects only Node; the installed Elixir/OTP pair works with the variables shown above. [VERIFIED: environment probe output, 2026-09-11]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with repo-local shell/action lint [VERIFIED: mix.exs:147-155] |
| Config file | `test/test_helper.exs`; existing workflow lint script [VERIFIED: repository file inspection, 2026-09-11] |
| Quick run command | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix test <focused files>` plus `bash scripts/ci/lint_workflows.sh` |
| Full suite command | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix ci` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CI-06 | Exact baseline SHA required for canonical CI success | shell contract + live checkpoint | focused repository hygiene test; final `gh api` exact-SHA query | ✅ extend existing + manual live gate |
| CI-07 | Push Release succeeds with publish-only jobs skipped | ExUnit structure + live checkpoint | `mix test test/lockspire/release_ci_evidence_contract_test.exs` | ✅ extend existing |
| CI-08 | OIDF remains supplemental/redacted/non-certifying | ExUnit contract | `mix test test/lockspire/conformance_workflow_contract_test.exs test/lockspire/conformance_redacted_evidence_contract_test.exs` | ✅ |
| QUAL-05 | Canonical contributor gate green | full integration | `mix ci` | ✅, currently failing |
| HYGIENE-05 | No BLOCK and every WARN disposition recorded | ExUnit + shell | focused repository hygiene test; `repo_hygiene_check.sh --ci`; exact acceptance mode | ✅ extend existing |
| HYGIENE-06 | Only demonstrated deterministic gaps become checks | ExUnit contract | workflow supply-chain + repository hygiene focused tests | ✅ extend existing |
| TRUTH-03 | Maintained records encode active-vs-shipped truth | source contract/review | focused release documentation/automation contract tests | ✅ extend existing |
| TRUTH-04 | Historical release chain remains exact | ExUnit + live API | release artifact/automation contracts plus read-only API queries | ✅ |
| TRUTH-05 | Release ownership, pins, manifest proof intact | ExUnit contract | `mix test test/lockspire/workflow_supply_chain_contract_test.exs test/lockspire/release_workflow_artifact_contract_test.exs test/lockspire/release_artifact_chain_contract_test.exs` | ✅ extend supply-chain test |

### Sampling Rate

- **Per task commit:** Run the directly affected focused ExUnit modules and `bash scripts/ci/lint_workflows.sh` for shell/YAML changes.
- **Per wave merge:** Run all Phase 139 focused contract modules plus `bash scripts/maintainer/repo_hygiene_check.sh --ci`.
- **Phase gate:** From the exact final main SHA, full `mix ci`, exact hygiene acceptance, exact canonical CI success, exact push Release success/no-publish, and current Phase 138 relation must all pass.

### Wave 0 Gaps

- [ ] Extend `test/lockspire/release/repository_hygiene_contract_test.exs` or its existing helper coverage for exact baseline SHA/run metadata and WARN dispositions.
- [ ] Extend `test/lockspire/release_ci_evidence_contract_test.exs` for the push/no-publish job graph.
- [ ] Extend `test/lockspire/workflow_supply_chain_contract_test.exs` to scan `.github/actions/release-please/action.yml`.
- [ ] Add/extend a maintained-release prose contract only if it can assert the proven executable ordering without duplicating a broad document snapshot.
- [ ] No framework installation or new config is needed. [VERIFIED: repository test-infrastructure inspection, 2026-09-11]

### Current Verification Evidence

- Eight focused release/conformance files completed with `"24 tests, 0 failures (36 excluded)"`; the focused proof currently misses the exact-head/no-publish/composite-action gaps described above. [VERIFIED: focused ExUnit output, 2026-09-11]
- `repo_hygiene_check.sh --ci` completed with `"18 PASS, 0 WARN, 0 BLOCK"`; this mode does not exercise live exact-head checks because `local_checks` is skipped in CI mode. [VERIFIED: hygiene command output, 2026-09-11] [VERIFIED: scripts/maintainer/repo_hygiene_check.sh:506-510]
- Full `mix ci` completed in 746.9 seconds with `"1406 tests, 1 failure, 6 skipped (286 excluded)"`; the sole test failure was the same proof-quality baseline violation. [VERIFIED: full `mix ci` output, 2026-09-11]
- Workflow lint and proof-quality baseline currently fail as detailed above. [VERIFIED: focused command outputs, 2026-09-11]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no product/runtime change | Preserve existing GitHub/Hex authentication boundaries; Phase 139 adds no auth surface. [VERIFIED: 139-CONTEXT.md:7-10] |
| V3 Session Management | no | No browser/runtime session work is authorized. [VERIFIED: 139-CONTEXT.md:7-10] |
| V4 Access Control | yes, maintainer automation | Read-only default workflow permissions and protected `hex-publish` publication environment. [VERIFIED: .github/workflows/release.yml:25-27] [VERIFIED: .github/workflows/release.yml:204-215] |
| V5 Input Validation | yes | Full-SHA regex, exact workflow/repository/event/status equality, allowlisted manifest fields, and fail-closed JSON parsing. [VERIFIED: .github/workflows/release.yml:95-115] [VERIFIED: scripts/publish/release_artifact.py:123-162] |
| V6 Cryptography | yes, artifact integrity | Standard SHA-256 via Python `hashlib`; never implement a custom digest. [VERIFIED: scripts/publish/release_artifact.py:6-32] |

### Known Threat Patterns for Repository Acceptance

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unrelated green run substituted for baseline | Spoofing | Exact SHA plus workflow ID/path/name/repository validation. [VERIFIED: .github/workflows/release.yml:104-115] |
| Mutable external action retargeted | Tampering | Full 40-hex action pin across workflows and composite action. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
| Acceptance result cannot be attributed | Repudiation | Receipt with baseline SHA, run IDs, events, conclusions, and URLs. [VERIFIED: 139-CONTEXT.md:36-37] |
| Supplemental logs disclose secrets | Information disclosure | Retain only redacted allowlisted receipts; keep hosted secrets isolated. [VERIFIED: test/lockspire/conformance_workflow_contract_test.exs:45-88] |
| Unauthorized publication during reconciliation | Elevation of privilege | Do not dispatch Release; keep publication behind exact-ref validation and `hex-publish`. [VERIFIED: .github/workflows/release.yml:70-122] [VERIFIED: .github/workflows/release.yml:204-215] |
| Malformed/incomplete API response yields false PASS | Tampering | `jq -e` required fields and fail closed on zero/multiple/invalid candidates. [VERIFIED: .github/workflows/release.yml:104-115] |

## Sources

### Primary (HIGH confidence)

- `139-CONTEXT.md` — locked exact-SHA, release, taxonomy, boundary, and sequencing decisions.
- Phase 138 immutable ledger and production relation-verifier output — currentness contract and observed `refresh_required` state.
- `.github/workflows/release.yml`, `.github/workflows/ci.yml`, `.github/workflows/release-please-automerge.yml`, and `.github/actions/release-please/action.yml` — executable CI/release/supply-chain authority.
- `scripts/maintainer/repo_hygiene_check.sh`, `mix.exs`, and `scripts/publish/release_artifact.py` — local gate, evidence, and artifact contracts.
- Focused ExUnit sources and executed test/lint outputs — verified gaps and existing proof.
- Authenticated GitHub/Hex API outputs — current and historical workflow/release observations.

### Secondary (MEDIUM confidence)

- [GitHub REST workflow runs documentation](https://docs.github.com/en/rest/actions/workflow-runs) — exact `head_sha` filtering and run metadata.
- [GitHub job conditions documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions) — skipped job result semantics.
- [GitHub secure use reference](https://docs.github.com/en/actions/reference/security/secure-use) — full-length commit SHA action pinning.

### Tertiary (LOW confidence)

- None used.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing locked tools and local versions were directly probed.
- Architecture: HIGH — derived from opened executable repository authorities and locked phase decisions.
- Pitfalls: HIGH — each key failure mode is demonstrated by current code or an executed failing gate.
- GitHub platform semantics: MEDIUM — verified against official GitHub documentation through web lookup.

**Research date:** 2026-09-11
**Valid until:** 2026-10-11 for repository structure; re-run all live/currentness observations immediately before planning execution.
