# Phase 142: Merge the Corrected Main Baseline - Research

**Researched:** 2026-10-06
**Domain:** Repository release-truth maintenance, GitHub Actions CI evidence, and maintainer hygiene
**Confidence:** HIGH for repository contracts; LOW for mutable GitHub state, which must be queried during execution

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Reviewed merge and release truth
- **D-01:** Merge the Phase 141 correction through the normal reviewed PR path. Keep 1.5.0 identified as the latest public package until current public evidence proves 1.5.1 was published. Release automation continues to own version and changelog bookkeeping, tag/release creation, and package publication; source metadata, a merged PR, green CI, or a no-publish run is not public-package proof.
- **D-02:** Phase 142 ends with an exact-main readiness handoff. It does not dispatch or perform package publication. Phase 143 owns protected publication after Phase 142's gates pass.

#### Exact-main readiness
- **D-03:** Prove readiness only after the correction is merged: refresh `origin/main`, require local `main` and `origin/main` to identify the same full commit SHA, and require canonical CI to pass for that exact SHA. Do not reuse pre-merge CI or Phase 140's earlier accepted SHA as proof for this commit.
- **D-04:** Run the maintained repository-hygiene check for that same SHA. There must be no `BLOCK`; every `WARN` needs one explicit recorded disposition. Use the existing `--accept-sha` receipt only when its own checks and output establish the required evidence; do not claim the full receipt passed if a prerequisite is missing. Keep OIDF/FAPI supplemental results non-certifying and outside the release gate.
- **D-05:** Before merging, inspect the live Release Please PR and workflow state. If merging the correction could cause the automation to publish 1.5.1 before Phase 142's readiness evidence is complete, stop and resolve that timing boundary before proceeding. Do not infer live PR or workflow state from repository files.

#### Maintainer record and shift-left check
- **D-06:** Correct the Phase 141 baseline link in `.planning/RELEASE-TRAIN.md` to its archived path: `milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`.
- **D-07:** Add a small automated contract in the existing release-hygiene test area that checks local links in `.planning/RELEASE-TRAIN.md` resolve. Keep it narrow to this maintained record; do not introduce a repository-wide Markdown-link framework. This turns the observed broken baseline link into a CI-detectable regression.
- **D-08:** Do not add manual UAT for properties proved by exact-SHA CI and repository hygiene. The normal PR review and authorization to perform consequential GitHub actions remain separate from verification evidence.

### the agent's Discretion
- Choose the filename and concise layout for Phase 142's durable result record. It should record the exact accepted SHA, matching CI evidence, hygiene summary, each warning disposition, current public-release truth, and the Phase 143 boundary without copying raw logs.
- Reuse the existing workflow and contract-test structure. If a required live check is unavailable or contradicts the record, stop with the specific missing evidence rather than assuming success.
- No Elixir API, Plug/Phoenix/Ecto, UI, or brandbook decision applies to this repository-maintenance phase. The local release process and prompt corpus provide enough guidance; no broad ecosystem comparison is needed.

### Deferred Ideas (OUT OF SCOPE)
- Protected publication, Hex checksum verification, matching GitHub release, and clean-room public install proof remain Phase 143 work.
- Broad release-workflow redesign, new release interfaces, OAuth/OIDC behavior, host integration, admin UI, and visual design are outside this phase.
- If live release automation state would bypass Phase 142 readiness, treat it as a concrete stop condition for planning/execution; do not widen this phase into speculative release-system changes.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUTH-06 | Maintainer can merge the corrected Phase 141 release record through the reviewed PR path and keep 1.5.0 identified as the latest public package until public proof for 1.5.1 exists. | Maintain public-release wording separately from Release Please metadata; use the approved PR review and check mutable public/live state before consequential action. The Phase 141 baseline is historical context only. |
| CI-09 | Maintainer can verify that required CI and the repository-hygiene check pass for the exact current `main` revision before release; every reported warning has an explicit disposition. | The existing `--accept-sha` mode joins synchronized local/remote refs, local `mix ci`, exact-SHA canonical CI, Release no-publish evidence, and hygiene warnings into one receipt. |
</phase_requirements>

## Summary

This is a repository-owned release-evidence phase, not an application or dependency change. The smallest coherent plan is to update the Phase 141 baseline link in `.planning/RELEASE-TRAIN.md`, add one focused ExUnit link-resolution contract beside the existing release-hygiene tests, merge the correction through its normal reviewed PR, then collect fresh evidence for the resulting exact `main` SHA. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:20-28]` The checked-in ledger currently points to `phases/141-maintenance-baseline-closure/141-BASELINE.md`, while the approved destination is archived under `milestones/v1.38-phases/`. `[VERIFIED: .planning/RELEASE-TRAIN.md:15]` Quote: `See the [dated Phase 141 baseline](phases/141-maintenance-baseline-closure/141-BASELINE.md)`. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:25-27]` Quote: `milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`.

The existing exact-acceptance path should remain authoritative. It refreshes and rechecks identity through local gates, requires same-SHA workflow evidence, rejects `BLOCK`, and requires a one-to-one disposition for each observed `WARN`; it emits an allowlisted JSON receipt when all prerequisites pass. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:596-628]` Do not carry forward the Phase 140 accepted SHA or its CI run IDs as Phase 142 proof. The Phase 141 baseline explicitly scopes those results to its own accepted source. `[VERIFIED: .planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md:8-15]`

The Release Please PR and workflow runs are mutable external state. The repository shows that successful `main` CI can trigger an automation path that may merge an eligible Release Please PR, dispatch CI for its merge SHA, and then dispatch the protected release workflow for a just-merged release PR. `[VERIFIED: .github/workflows/release-please-automerge.yml:27-30,74-89,93-109]` That code does not establish which live PRs or runs exist now. Inspect them immediately before merging; stop if the timing boundary could permit publication before Phase 142 readiness. Do not dispatch publication in Phase 142. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:17-23]`

**Primary recommendation:** Reuse the existing release-hygiene command and test home, retain 1.5.0 public truth until fresh public proof changes it, and make the exact post-merge SHA the only readiness identity.

## Project Constraints (from AGENTS.md)

- Keep Lockspire as a separate companion library and preserve its embedded-library shape; do not move it into Sigra or turn it into a required standalone auth service. `[VERIFIED: AGENTS.md:3-18]`
- Preserve boundaries among protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces; account resolution, claims, login redirects, branding, and product policy remain host-owned. `[VERIFIED: AGENTS.md:19-20]`
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. `[VERIFIED: AGENTS.md:21]`
- Preserve listed secure defaults: “PKCE S256 required by default”; “Exact-match redirect URI validation”; “Client secrets hashed at rest”; “Authorization codes short-lived and single-use”; “Refresh token rotation with family-wide revocation on reuse”; “No implicit flow”; “No `alg=none`”; “Strong redaction in logs and operator surfaces.” `[VERIFIED: AGENTS.md:43-50]`
- The project’s documented technology baseline is Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Ecto SQL `3.13.5`, PostgreSQL `14+`, Bandit `1.6.1`, Oban `2.21.x`, and OpenTelemetry `1.6.0`. `[VERIFIED: AGENTS.md:26-32]` These are project-wide constraints, but this phase changes none of those runtime technologies.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Maintained release-truth record and result handoff | Repository documentation | — | The release train is a maintained Markdown ledger; Phase 142's durable result record is also repository documentation. `[VERIFIED: .planning/RELEASE-TRAIN.md:1-16; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:30-33]` |
| Repeatable local-link regression check | ExUnit contract test | CI fast checks | The existing release-hygiene contract file is included in the `test/lockspire` target of `test.fast`, which the CI fast job runs. `[VERIFIED: test/lockspire/release/repository_hygiene_contract_test.exs:1-15; mix.exs:94-97; .github/workflows/ci.yml:80-115,149-167]` |
| Canonical CI / release orchestration | GitHub Actions | Maintainer CLI | The checked-in `CI` workflow runs on PR, `main` push, and workflow dispatch; the hygiene helper validates GitHub run evidence for exact-SHA acceptance. `[VERIFIED: .github/workflows/ci.yml:1-8; scripts/maintainer/repo_hygiene_check.sh:596-628]` |
| Human judgment and consequential GitHub action | Maintainer / PR review | — | Human review and action authorization remain independent of deterministic CI/hygiene results. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:27-28]` |

## Standard Stack

### Core

| Tool / surface | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| Elixir / ExUnit | Existing project Mix setup | Add the narrow local-link contract to the maintained release-hygiene test suite. | The existing contract file and `mix test.fast` path already cover `test/lockspire`. `[VERIFIED: test/lockspire/release/repository_hygiene_contract_test.exs:1-15; mix.exs:94-97]` |
| `scripts/maintainer/repo_hygiene_check.sh` | Repository-owned script | Produce exact-current-main acceptance evidence. | It already verifies refs, local gates, canonical CI, Release no-publish, hygiene, and warning dispositions. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:596-628]` |
| GitHub Actions `CI` | Repository workflow | Required post-merge CI for the exact main SHA. | Existing workflow runs seven named jobs; do not create a parallel release-readiness workflow. `[VERIFIED: .github/workflows/ci.yml:1-8,23-25,53-55,80-82,190-192,273-275,367-370,401-403]` |

### Supporting

| Tool / surface | Version | Purpose | When to Use |
|---------------|---------|---------|-------------|
| `git`, `gh`, `jq`, `mix` | Local versions observed: git 2.41.0; gh 2.101.0; jq 1.7.1; Mix reports Elixir 1.20.4 / OTP 29 | Refresh refs, query exact workflow state, process receipt JSON, and run the maintained contributor gate. | Exact acceptance requires `gh`, `jq`, and `mix`; use the CI-pinned toolchain for authoritative hosted CI. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:596-603]` |

No package installation is needed. Package-legitimacy audit is not applicable to this phase. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:25-33]` No package names or external dependencies are recommended.

## Architecture Patterns

### Recommended Project Structure

```text
.planning/RELEASE-TRAIN.md                              # maintained release truth and Phase 141 link
test/lockspire/release/repository_hygiene_contract_test.exs # narrow local-link regression contract
Phase 142 result record in its phase directory         # durable post-merge handoff; filename is discretionary
```

The result-record filename may be chosen during planning. Keep it concise and record the accepted SHA, matching CI run identity/link, hygiene counts and each warning disposition, the current public-release truth observation, and the Phase 143 boundary; avoid raw logs. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:30-33]`

### Pattern 1: Exact-SHA acceptance after merge

**What:** First merge the reviewed correction; then refresh `origin/main`, ensure `HEAD`, local `main`, and refreshed `origin/main` all equal the same full lowercase SHA; run exact acceptance and preserve its result. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:148-190,596-628]`

**When to use:** For the Phase 142 readiness handoff after merge. Pre-merge PR CI is useful review evidence but cannot certify the merge commit. The release-train checklist also requires matching CI and Release no-publish for that SHA. `[VERIFIED: .planning/REPO-HYGIENE-CHECKLIST.md:18-21]` Quote: `Recency alone is not acceptance evidence.`

**Example command (run only after the merge; replace placeholder with the fetched full SHA):**

```bash
git fetch --prune --tags origin
git switch main
git pull --ff-only origin main
git rev-parse HEAD
bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <40-lowercase-hex-current-main-sha> --format json
```

If exact acceptance reports a warning, rerun with one `--warn-disposition LABEL=DISPOSITION` per actual warning label. The script validates labels against warnings, rejects duplicate/unknown labels, requires all warnings to be covered exactly once, and encodes the sorted mappings in `warn_dispositions`; a zero-warning receipt retains `"warn_dispositions": []`. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:501-560; .planning/REPO-HYGIENE-CHECKLIST.md:18-21]` Quote: `Every \`WARN\` requires one explicit \`--warn-disposition CODE=DISPOSITION\`.`

Do not fabricate a receipt from separate green runs or claim acceptance if any prerequisite is missing. The receipt also includes local `mix ci`, canonical CI, Release push `no_publish`, pass/warn/block totals, warning dispositions, and a non-certifying supplemental OIDF classification. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:569-593]` This is an existing receipt shape; do not rename or broaden it as part of this phase.

### Pattern 2: Narrow local Markdown-link test

Add one focused test in `Lockspire.Release.RepositoryHygieneContractTest`, which already owns maintained release-record contracts. `[VERIFIED: test/lockspire/release/repository_hygiene_contract_test.exs:1-15]` Read only `.planning/RELEASE-TRAIN.md`; extract Markdown link destinations; ignore URI schemes and fragment-only links; remove any `#fragment`; resolve relative destinations against the directory containing the record; assert each target exists and include the broken destination in the assertion message. Keep it scoped to this one file rather than adding a Markdown framework. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:25-28]`

The source value to correct is `phases/141-maintenance-baseline-closure/141-BASELINE.md`; the approved value is `milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`. `[VERIFIED: .planning/RELEASE-TRAIN.md:15; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:25-27]` Quote: `milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`.

The contract belongs in `test/lockspire/release/repository_hygiene_contract_test.exs`; `mix test.fast` includes `test/lockspire`, and CI's fast job runs `mix test.fast`. `[VERIFIED: mix.exs:94-97; .github/workflows/ci.yml:149-167]` Add an ExUnit tag such as `:release_train_links` to that one test, then target it with `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only release_train_links`. Do not run tests during research.

### Human checkpoint boundary

Keep one normal PR review and explicit authorization for consequential GitHub operations such as merging. These actions need maintainer judgment/authority, not duplicate UAT. Exact-SHA CI and hygiene remain machine-verifiable acceptance. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:27-28]`

Before merge, query the live Release Please PR plus relevant current workflow runs/settings. If the observed state means this merge could advance a 1.5.1 publication before the Phase 142 exact-SHA receipt is complete, halt and resolve the concrete timing boundary. The checked-in workflow permits CI-triggered Release Please auto-merge and dispatches a release workflow after matching post-merge CI, but the repo cannot attest current hosted state. `[VERIFIED: .github/workflows/release-please-automerge.yml:74-109; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:22-23]`

### Recommended sequencing and evidence identity

1. Make the release-train link correction and local-link contract in the reviewed PR; run the focused test and PR CI.
2. Before merge, inspect live Release Please PR and workflow state, review the correction, and authorize the ordinary PR merge. Stop on an unsafe release timing boundary.
3. After merge, refresh main, record the full merge SHA, wait for canonical CI for that SHA, and run the exact-SHA hygiene acceptance. Resolve any `BLOCK`; give every actual `WARN` exactly one disposition.
4. Write the durable Phase 142 result handoff with that accepted source SHA, evidence links, hygiene totals/dispositions, and current public truth observation. Do not imply a later report commit was included in the source acceptance. `[VERIFIED: .planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md:8-15]`

**Evidence identity footgun:** If the durable result record is committed after the accepted main SHA, that documentation commit creates a newer `main` SHA not covered by the earlier exact-SHA receipt. Name the accepted source SHA and, if distinct, the report-containing commit separately. Do not say the report commit is covered by the earlier checks. If the execution plan requires the report-containing commit itself to be the accepted current main, its own CI/hygiene must be established after it exists; do not backdate its evidence. Phase 143 must revalidate the current SHA before protected publication regardless. This follows Phase 141's source-vs-report identity rule. `[VERIFIED: .planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-CONTEXT.md:16-23; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:20-22]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Same-commit release acceptance | A new acceptance CLI, manual list of unrelated CI links, or reused predecessor receipt | `repo_hygiene_check.sh --accept-sha ... --format json` | Existing code refreshes identity around checks, validates matching required CI and Release no-publish, runs local `mix ci`, and enforces warning dispositions. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:596-628]` |
| Link linting across the whole repository | New markdown parser/framework | Small ExUnit contract limited to `.planning/RELEASE-TRAIN.md` | This is the explicit approved scope and existing test home. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:25-28]` |
| Release ownership | Manual version/changelog/tag/package mutation or Phase 142 publication | Existing Release Please + protected release workflow; Phase 143 owns publication | Maintainer docs assign version bookkeeping and publication to automation/protected lane. `[VERIFIED: docs/maintainer-release.md:18-42; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:17-18]` |

## Common Pitfalls

### Reusing earlier-SHA evidence

**What goes wrong:** A pre-merge CI run, the Phase 140 acceptance SHA, or Phase 141's dated baseline is reported as proof for the new merge commit.

**How to avoid:** Capture the full post-merge SHA and require refreshed `HEAD`, local `main`, and `origin/main` to match it before and after exact acceptance. The maintainer checklist expressly says that recency alone is not acceptance evidence. `[VERIFIED: .planning/REPO-HYGIENE-CHECKLIST.md:18-20; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:20-22]`

### Committing the handoff after accepting main

**What goes wrong:** The result-record commit is mistaken for the already accepted source SHA, even though that commit did not exist when CI/hygiene ran.

**How to avoid:** Identify accepted source SHA and report-containing SHA separately when different; never carry acceptance across a documentation commit. If latest `main` must remain the accepted candidate, ensure checks target the final report-containing commit before calling it current, while keeping the record honest about which SHA each receipt covers. Phase 143 revalidates before publication. `[VERIFIED: .planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-CONTEXT.md:16-23; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:20-22]`

### Confusing metadata or no-publish CI with public release proof

**What goes wrong:** A merged PR, `1.5.1` Release Please metadata, green CI, or a successful no-publish run is treated as proof that Hex/GitHub published 1.5.1.

**How to avoid:** Preserve 1.5.0 as latest public until current public package/release evidence proves 1.5.1. The current ledger's public proof observation is dated 2026-10-05, so revalidate public state before making a current claim; this research did not query live Hex or GitHub. `[VERIFIED: .planning/RELEASE-TRAIN.md:9-15; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:16-18]`

### Treating warning output as accepted without dispositions

**What goes wrong:** A receipt is claimed despite a warning, an omitted disposition, duplicate labels, or a guessed label.

**How to avoid:** Use the actual observed `WARN` labels. Record exactly one disposition for each and summarize each mapping in the result record. The script fails closed on missing or duplicate/unknown mappings and retains an empty JSON list when there are none. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:501-560,623-628]`

### Letting automation cross the Phase 143 boundary

**What goes wrong:** A successful main CI event drives eligible Release Please auto-merge and its post-merge workflow chain before Phase 142 has a completed handoff.

**How to avoid:** Inspect current live PR/workflow state before merge, and stop if the release boundary could be crossed. Repository YAML is evidence of behavior, not proof of the live PR queue or run state. No publication workflow dispatch belongs in Phase 142. `[VERIFIED: .github/workflows/release-please-automerge.yml:27-30,74-109; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:17-23]`

### Expanding the link test into a new subsystem

**What goes wrong:** A generic repository-wide Markdown parser/framework adds scope and maintenance burden for one known broken pointer.

**How to avoid:** Limit the test to local links in `.planning/RELEASE-TRAIN.md`; keep it in the existing release-hygiene contract module. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:25-28]`

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json`. `[VERIFIED: .planning/config.json:15-17]` Use automated verification for deterministic properties; no manual UAT is needed for the exact-SHA or local-link properties.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix |
| Config file | Existing project Mix aliases in `mix.exs` |
| Quick targeted command | `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only release_train_links` |
| Full contributor command | `mix ci` |
| Hosted exact-SHA gate | Canonical `CI` workflow on the post-merge `main` SHA |
| Exact readiness command | `bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <40-lowercase-hex-current-main-sha> --format json` |

Do not run tests as part of research. The next plan should run the focused test after implementation and rely on the full required CI plus exact hygiene acceptance for the final merge SHA. `mix ci` composes QA, docs/dependency/package checks, fast tests, and integration tests. `[VERIFIED: mix.exs:128-157]`

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRUTH-06 | Maintained ledger points at archived baseline and retains correct public-release truth; merge follows reviewed path. | Focused ExUnit contract + PR review + live evidence check | `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only release_train_links`; verify PR review and query live Hex/GitHub at execution | Test file exists; add local-link assertion. Public proof remains a human evidence observation, not a source-only test. |
| CI-09 | Exact current `main` has successful canonical CI and hygiene with zero `BLOCK`, and every `WARN` has a disposition. | Required CI + exact acceptance receipt | `bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <sha> --format json` | Existing maintained command and CI contracts exist. |

### Required canonical CI jobs

The current workflow defines these seven job display names: `Dialyzer`, `Release Hygiene Drift`, `Fast Checks`, `Minimum Supported Elixir/OTP`, `Integration Checks`, `Complete Coverage Evidence`, and `Adoption Demo Smoke`. `[VERIFIED: .github/workflows/ci.yml:23-25,53-55,80-82,190-192,273-275,367-370,401-403]` Quote: `name: Dialyzer`; `name: Release Hygiene Drift`; `name: Fast Checks`; `name: Minimum Supported Elixir/OTP`; `name: Integration Checks`; `name: Complete Coverage Evidence`; `name: Adoption Demo Smoke`. The exact-acceptance helper validates required jobs, so use its receipt as the governing evidence; confirm every job is attached to the accepted SHA rather than relying on a recent green workflow summary. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:596-628]`

### Wave 0 Gaps

- Add one ExUnit test that enumerates local Markdown destinations from `.planning/RELEASE-TRAIN.md` and fails with the unresolved target. No new framework, dependency, shared fixture, or workflow is needed. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:25-28]`

## Security Domain

This phase has no OAuth/OIDC or application authentication/session change. Security work is confined to release-truth integrity and authorized workflow boundaries. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:6-9]`

### Applicable ASVS Categories

Use the categories from the versioned OWASP ASVS 5.0.0 source: category numbers differ from the older V2-authentication/V3-session/V4-access-control layout. In ASVS 5.0.0, `V2` is Validation and Business Logic, `V6` is Authentication, `V7` is Session Management, `V8` is Authorization, and `V11` is Cryptography. `[CITED: github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json]`

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Validation and Business Logic | Yes, narrow workflow/hygiene inputs | Reuse strict full-SHA parsing and bounded warning-disposition parsing in the existing helper. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:148-180,501-546]` `[CITED: github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json]` |
| V6 Authentication | No | No application authentication changes; GitHub CLI authentication availability is checked at execution. `[CITED: github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json]` |
| V7 Session Management | No | No application session behavior changes. `[CITED: github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json]` |
| V8 Authorization | Yes, for consequential workflow authority | Preserve normal PR review/action authorization and existing scoped workflow permissions; don't dispatch protected publication during Phase 142. `[VERIFIED: .github/workflows/release-please-automerge.yml:22-25; .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:17-18,27-28]` `[CITED: github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json]` |
| V11 Cryptography | No | No cryptographic code or key material is in scope. `[CITED: github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json]` |

### Known Threat Patterns for Release Evidence

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale or substituted SHA/run evidence | Tampering / Spoofing | Join all evidence on one full immutable SHA and refresh identity around checks. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:148-190,596-628]` |
| Wrong or mismatched workflow run presented as canonical CI | Spoofing | Validate workflow path/ID, repository, branch, event, conclusion, and head SHA using the maintained gate and workflow contracts. `[VERIFIED: test/lockspire/release_ci_evidence_contract_test.exs:15-48]` |
| Automated release crossing the publication boundary | Elevation of privilege / Tampering | Inspect mutable live state before merge; halt if it can publish before Phase 142 readiness; retain protected publication for Phase 143. `[VERIFIED: .planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md:17-23]` |

## Environment Availability

The phase uses local Git/Mix plus authenticated GitHub CLI access for final acceptance. Version probes were read-only and tests were not run. `[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:596-603]`

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| git | Ref refresh and SHA identity | Yes | 2.41.0 `[VERIFIED: local version probe, 2026-10-06]` | None for exact local acceptance |
| gh | Live PR/workflow queries and exact acceptance | Yes | 2.101.0 `[VERIFIED: local version probe, 2026-10-06]`; authentication/live access not queried | Halt acceptance and report missing live evidence |
| jq | Receipt and GitHub JSON validation | Yes | 1.7.1 `[VERIFIED: local version probe, 2026-10-06]` | None for exact acceptance |
| Mix / Elixir | Contract test and local contributor gate | Yes | Elixir 1.20.4 / OTP 29 `[VERIFIED: local version probe, 2026-10-06]`; CI uses its pinned matrix | Hosted canonical CI is authoritative for the exact SHA |

**Missing dependencies with no fallback:** None observed for the local CLI binaries; authenticated GitHub availability still requires execution-time confirmation.

## Sources

### Primary (repository source of truth)

- `.planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md` — locked decisions, boundaries, required evidence, live-state halt condition.
- `.planning/RELEASE-TRAIN.md` — current release wording, ownership rules, Phase 141 link, historical readiness observation.
- `.planning/REPO-HYGIENE-CHECKLIST.md` — exact-SHA invocation and warning disposition expectations.
- `docs/maintainer-release.md` — reviewed merge flow, `mix ci`, automation/protected-publish boundary.
- `scripts/maintainer/repo_hygiene_check.sh` — exact acceptance logic, required CI/release evidence, warning receipt.
- `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `.github/workflows/release-please-automerge.yml` — checked-in workflow contracts; not live hosted state.
- `test/lockspire/release/repository_hygiene_contract_test.exs`, `test/lockspire/release_ci_evidence_contract_test.exs` — current contract test homes.
- `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-CONTEXT.md` and `141-BASELINE.md` — historical evidence and identity boundaries.
- `prompts/README.md`, `prompts/lockspire-release-engineering-and-ci.md`, `prompts/lockspire-release-readiness-and-conformance.md`, and the release/packaging sections of `prompts/lockspire-elixir-oss-library-practices.md` — applicable local maintainer guidance. Broad API and UI material was excluded as instructed.

### External security taxonomy

- [OWASP ASVS 5.0.0 source JSON](https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json) — verified the current category labels relevant to the scoped workflow/input review.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A concise `142-RESULT.md` filename is suitable for the durable post-merge record. | Architecture Patterns | Low; filename is explicitly discretionary and can be changed during planning. |
| A2 | The implementation can parse the simple local links currently present in `.planning/RELEASE-TRAIN.md` with a small regex-based ExUnit helper. | Architecture Patterns | Low; if link syntax expands, keep test narrow and adapt parsing without making a general framework. |

## Open Questions

1. **What Release Please PRs and workflow runs are live immediately before merge, and can the current automation publish before the Phase 142 handoff?**
   - What we know: checked-in automation can act after a successful main CI run, but it only shows program logic.
   - What's unclear: current live PR and run state; no live GitHub queries were made for this research.
   - Recommendation: inspect live state immediately before merge; if it can cross the Phase 143 publication boundary, halt and resolve the concrete timing issue. Never infer state from these checked-in workflow files.

2. **What is the latest public package at the time of the Phase 142 result record?**
   - What we know: the Phase 141 baseline records a 2026-10-05 observation that Hex/GitHub supported 1.5.0 as latest public.
   - What's unclear: later publication state may have changed.
   - Recommendation: revalidate public evidence before writing the result record; keep 1.5.0 truth until current public proof establishes 1.5.1.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing project scripts, test area, and CI workflow were read directly.
- Architecture: HIGH — phase boundaries and exact evidence joins are explicit in repository sources.
- Pitfalls: HIGH for checked-in contracts; LOW for mutable GitHub/Hex state until queried during execution.

**Research date:** 2026-10-06
**Valid until:** 2026-10-13 for mutable hosted-state assumptions; repository implementation guidance remains valid until relevant files change.
