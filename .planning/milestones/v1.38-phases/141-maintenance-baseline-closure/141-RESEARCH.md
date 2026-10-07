<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Terminal Acceptance and Evidence Identity
- **D-01:** Base the final baseline on Phase 140's post-summary acceptance for one synchronized full `main` SHA. Refresh and revalidate the terminal evidence at closure; predecessor receipts, entry-gate receipts, separate green runs, and local-only gates do not transfer. Phase 140 acceptance is still marked pending in the evidence reviewed for this discussion, so Phase 141 must not invent or pre-fill its final accepted SHA.
- **D-02:** Create one canonical dated Markdown baseline record in the Phase 141 directory. Connect the accepted source SHA to the exact local `mix ci` and hygiene results, required canonical CI jobs, successful Release no-publish graph, release evidence, Phase 140 dispositions, and explicit deferrals using full immutable SHAs and direct source links. Link to detailed Phase 140 artifacts instead of duplicating raw logs or the complete inventory; preserve redaction and existing historical evidence.
- **D-03:** Distinguish the SHA whose source tree was accepted from the commit that contains the final Phase 141 report and planning updates whenever they differ. State which evidence applies to which SHA. If a claim is made about a later tree, require matching proof for that tree; do not imply that a report's later documentation commit was covered by an earlier same-SHA receipt.

### Planning Completion and Published Release Truth
- **D-04:** Mark v1.38 and Phase 141 complete only after the evidence handoff and synchronized GSD records agree on completion and the next sustaining GA action. Milestone completion is not package publication. Leave version bumps, changelog release bookkeeping, tag creation, GitHub releases, and Hex publication to their existing release owners.
- **D-05:** At discussion time, authoritative Hex and GitHub evidence identifies `1.5.0` as the latest public release: published source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`, canonical CI run `33141161205`, protected publication run `33141484467`, and package checksum `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`. Repository metadata and prose conflict: `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, and `.planning/RELEASE-TRAIN.md` name `1.5.1`, while `.planning/PROJECT.md` and `.planning/MILESTONES.md` say public `1.5.0`; no public Hex release or GitHub tag for `1.5.1` was found. Revalidate public release and protected-run evidence at Phase 141 closure, then reconcile explanatory planning prose to that evidence. Do not treat source metadata as publication proof or manually rewrite release-owned files.

### Disposition and Deferral Truth
- **D-06:** Carry Phase 140's source-linked terminal dispositions and recheck triggers into the final handoff. Keep resolved, historical, deferred-with-trigger, and out-of-scope work distinguishable. A healthy baseline does not require an empty queue; deferral is not completion. Keep supplemental OIDF/FAPI evidence redacted, supplemental, and non-certifying, with future conformance work explicitly outside v1.38.

### Maintainer Journey and Scope
- **D-07:** Optimize the record for a release steward or future maintainer returning after a gap. They need to determine what was accepted, what proves it, what remains deferred, and the next supported action from the repository and its linked GitHub evidence. Use concise semantic headings, direct links, explicit text statuses, clear dates and SHA labels, and calm factual wording; meaning must not depend on color, icons, or backend knowledge.
- **D-08:** Keep this a repository documentation and planning-state phase. Do not add Phoenix UI, a public API, a Mix task, Ecto persistence, an admin design-system change, a dashboard, or a new maintenance framework. Use the current root `brandbook/` as the visual source if an in-scope visual product decision ever arises; Phase 141 itself has no UI or graphic-design work. Apply the relevant release-engineering and maintainer-documentation guidance from `prompts/`; do not pull unrelated protocol, host-seam, or LiveView design choices into this phase.

### the agent's Discretion
The user confirmed the recommendation set without corrections. Planning may choose the baseline filename, concise Markdown table layout, and ordering of evidence sections. It may group references for readability, but must preserve the decision set above, currentness labels, exact source identities, deferral triggers, release ownership, and accessible text-only status meaning.

### Deferred Ideas (OUT OF SCOPE)
- Supplemental OIDF/FAPI remediation remains future bounded conformance work unless Phase 140's final evidence demonstrates a specific in-scope regression.
- Protocol, host-seam, admin UI, design-system, public API, persistence, dashboard, broad dependency, and new maintenance-framework work remain outside Phase 141.
- Do not publish 1.5.1, dispatch a protected release, or edit Release Please-owned version/changelog metadata as part of baseline closure. Any future publication follows the existing protected release train.
- No additional ecosystem or UI research is required for this documentation-and-evidence phase; revisit those lenses when a phase contains an API, runtime, or user-interface decision.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BASE-04 | Maintainer can inspect a dated baseline record tying final Git state, local gates, required workflow runs, release evidence, loose-end dispositions, and explicit deferrals to exact SHAs and sources. | Use the final Phase 140 acceptance, accepted exact-SHA hygiene receipt, canonical CI and Release no-publish run identities, verified published-release chain, and Phase 140 disposition register as separate linked evidence sections. |
| BASE-05 | Maintainer can finish v1.38 with coherent GSD state and an explicit return to Lockspire's sustaining GA release train. | Reconcile the project, roadmap, requirements, state, milestone and release-train prose only after baseline and public release evidence are current; state the next sustaining-train condition without claiming a package was published. |
</phase_requirements>

# Phase 141: Maintenance-Baseline Closure - Research

**Researched:** 2026-10-02
**Domain:** Release evidence handoff and GSD planning-state reconciliation
**Confidence:** HIGH for repository ownership and evidence contracts; MEDIUM for current published-release status, which must be refreshed at closure.

## Summary

Phase 141 is a documentation and evidence-integrity task. Its working architecture is the existing repo-local maintainer workflow: a terminal acceptance command produces an exact-source receipt; required GitHub CI and Release no-publish runs establish the hosted evidence; Hex and GitHub release records establish separate publication truth; a dated Markdown handoff links these identities; GSD summary documents are then reconciled to the handoff. There is no Elixir/Phoenix runtime, application API, storage model, or product UI to implement. [VERIFIED: `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:86-100`]

The critical ordering rule is to wait for Phase 140's *post-summary* terminal acceptance and bind every claim to the full accepted source SHA. Phase 140's contract says candidate receipts are not terminal if later writes create a new candidate; it requires same-SHA local CI, exact hygiene, required CI, and successful Release no-publish evidence. Revalidate those records at Phase 141 closure, then independently revalidate the mutable public-release chain. [VERIFIED: `.planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md:1-3,34-38`]

**Primary recommendation:** Make one concise `141-BASELINE.md` the navigable evidence index, not a new proof mechanism. Link to the final source-native receipts and Phase 140 disposition register, label evidence SHA versus report/planning commit SHA, and update the GSD records only once the terminal baseline and public-release posture have been revalidated. The baseline report and project completion are planning events; package publication remains owned by the existing Release Please and protected exact-ref path. [VERIFIED: `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:16-30,97-100`; `.planning/RELEASE-TRAIN.md:11-30`]

### Phase 140 gate that planning must treat as a prerequisite

At research time, Phase 140's `140-ACCEPTANCE.md` explicitly calls itself a contract rather than a receipt and says the terminal candidate remains pending. Its 2026-10-02 update reports candidate `47fbdf68a33c0542afa479c43aa95da2174b2bd6` as a first pass but also says a later write creates another candidate; later lines say terminal acceptance was not run and CI-06/CI-07 remain pending. Therefore, the planner must not hard-code any historical/predecessor SHA as the Phase 141 accepted source. Phase 140 verifier/acceptance and exact hygiene JSON are the prerequisite source of truth. [VERIFIED: `.planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md:1-3,34-38,62-88`]

### Publication truth conflict to revalidate

Read-only official API checks during this research confirmed Hex's current `latest_version` is `1.5.0`, published at `2026-08-28T04:23:47.259960Z`, checksum `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`; the corresponding GitHub release/tag targets source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`. Canonical CI run `33141161205` and Release run `33141484467` are completed successfully on that same SHA. The protected Release run's job API reports `Validate exact main head and CI evidence`, `Prove exact package before publication`, `Publish verified release to Hex`, and `Verify public install truth` succeeded; `Maintain Release Please PR` was skipped. Hex release `1.5.1` and GitHub release tag `lockspire-v1.5.1` both returned HTTP 404 during this research. Thus the latest-release conflict remains real: release-owned source metadata and `.planning/RELEASE-TRAIN.md` say `1.5.1`, while public evidence and project/milestone prose say `1.5.0`. This verification is current as of 2026-10-02, not a substitute for closure-time revalidation. [VERIFIED: Hex package/release API and GitHub release/actions APIs queried 2026-10-02; sources: `https://hex.pm/api/packages/lockspire`, `https://hex.pm/api/packages/lockspire/releases/1.5.0`, `https://hex.pm/api/packages/lockspire/releases/1.5.1`, `https://api.github.com/repos/szTheory/lockspire/releases/tags/lockspire-v1.5.0`, `https://api.github.com/repos/szTheory/lockspire/releases/tags/lockspire-v1.5.1`, `https://api.github.com/repos/szTheory/lockspire/actions/runs/33141161205`, `https://api.github.com/repos/szTheory/lockspire/actions/runs/33141484467`, `https://api.github.com/repos/szTheory/lockspire/actions/runs/33141484467/jobs`; 404 probe output: `curl: (56) The requested URL returned error: 404` for each 1.5.1 endpoint. Context decision and source list: `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:21-24,75-79`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Accepted baseline source identity | Repository / Git evidence | Maintainer acceptance CLI | Full SHA and synchronized refs determine what the local and remote code proof covers. |
| Local acceptance proof | Repo-local maintainer tooling | Mix CI | Reuse `repo_hygiene_check.sh --accept-sha`; it joins local gates and exact hosted-run evidence. |
| Hosted CI / no-publish proof | GitHub Actions | Repo hygiene CLI | Workflow run/job records are authoritative for those workflow outcomes; the CLI verifies exact SHA and required job graph. |
| Public release identity | Hex and GitHub release records | Protected release workflow receipts | Package publication truth is distinct from source version metadata, GSD milestone status, and ordinary no-publish Release runs. |
| Durable handoff and GSD coherence | Markdown planning records | Evidence links | Markdown is the maintainer-facing index; preserve detailed source-native receipts instead of cloning their data. |

## Standard Stack

This is a repository documentation and planning-state phase. Lockspire's runtime/library stack (Elixir, Phoenix, LiveView, Ecto, PostgreSQL, Bandit, Oban, OpenTelemetry) and product UI stack are **not applicable** to implementation. No external package should be added. The relevant existing tools are Git, Bash, GitHub CLI (`gh`), `jq`, Mix's already-defined `mix ci` gate, GitHub Actions, Hex's read-only package records, the GSD planning files, and Markdown. [VERIFIED: `AGENTS.md:24-48`; `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:28-30,57-73`; `scripts/maintainer/repo_hygiene_check.sh:1-40`]

The local environment has Git 2.41.0, `gh`, `jq`, and the `mix` shim available. Their presence does not prove GitHub CLI authentication or a correct asdf toolchain; the public Hex and GitHub APIs did respond during this read-only research. Closure must still revalidate mutable release state. No version matrix or install task is warranted. [VERIFIED: local availability probe and public API queries on 2026-10-02]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One dated canonical handoff linking source receipts | Copy raw logs and full inventory into Phase 141 | A self-contained copy is convenient initially, but duplicates mutable or sensitive evidence and will drift. The locked model keeps source-native records authoritative. |
| Existing exact-SHA hygiene acceptance | New Phase 141 acceptance script or a Mix task | A new tool would duplicate the proof join and expand the maintainer surface. Existing repo-local CLI already checks exact-SHA local/remote/workflow evidence. |
| Release-owner metadata and protected publish lane | Manually repair version/changelog/tag/Hex state | Manual changes can bypass Release Please and protected publication ownership. Update explanatory planning prose to evidence; leave release-owned artifacts for the release workflow. |
| Accessible semantic Markdown | Dashboard or branded operator interface | A dashboard adds runtime/UI lifecycle and access concerns for a durable maintainer handoff. No live UI or recurring query need is in this phase. |

**Package legitimacy audit:** Not applicable; no package installation is planned.

## Architecture Patterns

### Recommended evidence flow

```text
Phase 140 post-summary writes
        │
        ▼
Refresh refs and obtain terminal exact-SHA acceptance
        │  local mix ci + exact hygiene + required CI + Release no-publish
        ▼
Freeze accepted source SHA and direct source links
        │
        ├── Revalidate published release via Hex + GitHub release/tag/workflow proof
        ├── Link Phase 140 disposition records and triggers
        ▼
Write dated Phase 141 baseline index
        │  distinguish accepted source SHA from report commit SHA
        ▼
Reconcile GSD project/roadmap/requirements/state/milestone/release prose
        │
        ▼
Verify cross-document agreement; mark v1.38/Phase 141 complete
```

### Pattern 1: Immutable evidence, mutable state

**What:** Preserve dated receipts as evidence for their exact observed objects; refresh current refs and hosted release state at the point a decision depends on them. Link to prior evidence without overwriting it. **When to use:** Any acceptance claim, release-truth update, or disposition carried forward from earlier phases.

**Implementation guidance:** Record UTC date/time and full source SHAs. Identify source SHA separately from the commit that contains the report and planning edits. If the report commit claims its own code/doc tree is accepted, it needs its own proof. Phase 138 already distinguishes `observed_at`, source update time, mutable names and immutable observed SHA, and its evidence rule disallows arbitrary TTL in favor of boundary revalidation. [VERIFIED: `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-CONTEXT.md:Freshness, Provenance, and Completeness`; `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:16-19,91-100`]

### Pattern 2: One canonical handoff, linked source evidence

**What:** A dated Markdown record summarizes what a returning maintainer needs, gives exact IDs/SHAs and links to receipts, and states deferrals with triggers. **When to use:** Closing the current maintenance baseline. Avoid repeating log bodies, full inventories, or historical receipt contents. The prior inventory pattern calls Markdown authoritative and prefers compact tables plus detail for ambiguous/actionable rows. [VERIFIED: `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-CONTEXT.md`, “Inventory Artifact and Ownership” and “Maintainer Experience and Verification”; `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:16-19`]

**Suggested handoff sections:**

1. Decision and observation timestamps, repository identity, accepted source SHA, report commit SHA (if already known), and currentness label.
2. Git refs/worktree result plus local `mix ci` and exact hygiene JSON receipt identity.
3. Canonical CI run and all required job results; Release no-publish run and job graph.
4. Current public release chain: public version, tag/release, source SHA, matching CI and protected release runs, artifact checksum, Hex record; mark historical identities as historical.
5. Phase 140 disposition link/table grouped as resolved, historical, deferred-with-trigger, or out of scope.
6. Explicit v1.38 deferrals and next supported sustaining-train action/condition.
7. Sources with direct links and recheck/currentness dates.

### Pattern 3: Fail-closed exact-source acceptance

The existing CLI's exact mode is intended to combine synchronized refs, local gates, seven required CI jobs, and the successful Release no-publish graph. [VERIFIED: `scripts/maintainer/repo_hygiene_check.sh:386-473`]

The required CI job names are exactly: `"Dialyzer"`, `"Release Hygiene Drift"`, `"Fast Checks"`, `"Minimum Supported Elixir/OTP"`, `"Integration Checks"`, `"Complete Coverage Evidence"`, `"Adoption Demo Smoke"`. The release no-publish graph requires `"Maintain Release Please PR|success"`, `"Validate exact main head and CI evidence|skipped"`, `"Prove exact package before publication|skipped"`, `"Publish verified release to Hex|skipped"`, `"Verify public install truth|skipped"`. [VERIFIED: `scripts/maintainer/repo_hygiene_check.sh:410-430,454-473`]

Suggested terminal command, after Phase 140 determines the final SHA and observed warning labels:

```sh
bash scripts/maintainer/repo_hygiene_check.sh \
  --accept-sha "$FINAL_SHA" \
  --warn-disposition "$OBSERVED_LABEL=$SPECIFIC_DISPOSITION" \
  --format json
```

Repeat the warning option for each observed warning, and omit it only when none were observed. This is an acceptance run, not a read-only documentation check: it refreshes evidence and runs local gates. Do not run it as part of research; Phase 140's acceptance owner runs it at the terminal boundary. [VERIFIED: `scripts/maintainer/repo_hygiene_check.sh:17-40,63-99`; `.planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md:13-33`]

### Document ownership and update order

- First accept Phase 140 and revalidate the public release evidence. If the Phase 140 gate is incomplete, record that Phase 141 cannot truthfully close yet; do not fill in provisional SHAs or mark CI-06/CI-07 complete.
- Create the baseline handoff from final source evidence. Keep discussion-time facts visibly historical until refreshed.
- Update `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`, and explanatory `.planning/RELEASE-TRAIN.md` prose from their respective evidence sources. Keep public package truth separate from the v1.38 milestone state. Release-Please-owned `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, tags, releases, and package publication state remain outside this phase. [VERIFIED: `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:21-30,97-100`; `.planning/RELEASE-TRAIN.md:11-30`; `.planning/REQUIREMENTS.md:23-50`]
- Validate every cross-document status and link, then ensure the final Phase 141 report/planning commit is not described as covered by source acceptance for a prior SHA.

### Anti-patterns to avoid

- Promote a predecessor or historical candidate receipt into terminal acceptance.
- Treat a successful Release no-publish graph as proof that a package was published.
- Treat `mix.exs`, manifest, changelog, tag naming convention, or a Release Please PR as proof of public package availability.
- Rewrite Release-Please-owned files manually to resolve explanatory prose drift.
- Make completion depend on an empty queue or imply deferred conformance/cleanup was completed.
- Copy raw CI logs, tokens, credentials, or supplemental OIDF/FAPI data into the handoff.
- Use color, icons, or unexplained internal workflow jargon as the only expression of status.
- Add product UI, Mix tasks, runtime dependencies or a recurring maintenance subsystem for this one-off closure.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Joined exact-SHA readiness | A parallel Phase 141 shell script or bespoke JSON proof | `scripts/maintainer/repo_hygiene_check.sh --accept-sha … --format json` and its existing contract | It already validates the exact acceptance boundary and required job graph; a second implementation risks conflicting semantics. |
| Phase 140 final evidence | A report-derived summary or reassembled run selection | Final `140-ACCEPTANCE.md`, verifier, and exact hygiene receipt | Phase 140 source-native acceptance knows which candidate is terminal after all writes. |
| Loose-end disposition | A fresh abbreviated queue or “all clear” assertion | `140-DISPOSITIONS.md` entries and their source/recheck triggers | Reuse preserves evidence identity and prevents deferral from being misread as completion. |
| Published package truth | Version inference from source files | Current Hex package/release and GitHub release/tag plus matching protected-run evidence | Publication is an external event, separate from source metadata and milestone closure. |
| Cross-document version bookkeeping | Manual version/changelog/tag or publish action | Existing Release Please and protected exact-ref release lane | Preserves release ownership and artifact provenance. |

**Key insight:** The difficult part is not generating a report; it is maintaining a one-to-one relation between claim, exact source identity, authoritative evidence, and currentness. A short linked index is safer and easier for maintainers than a second evidence database.

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate embedded companion library; do not make it a Sigra module or required standalone auth service.
- Preserve boundaries among protocol core, storage, generators, Plug/Phoenix integration, and admin surfaces. Phase 141 has no implementation in these runtime tiers.
- Keep host ownership of accounts, login UX, branding, claims, redirects and product policy; do not broaden v1 into SAML, LDAP/AD, hosted auth, or CIAM.
- Preserve security defaults in any related evidence language: PKCE S256, exact redirect matching, hashed client secrets, short-lived single-use authorization codes, rotating refresh tokens with family-wide reuse revocation, no implicit flow or `alg=none`, and redacted logs/operator surfaces.
- Follow the project’s release, planning and scope references. No project instruction calls for running tests for this documentation research task.

## Common Pitfalls

### Pitfall 1: Proving the wrong SHA

**What goes wrong:** A green local run, an older acceptance receipt, or the latest green GitHub run is attached to a later baseline claim. **Why:** Documentation updates create commits after the original acceptance. **How to avoid:** Require the Phase 140 post-summary terminal receipt for the one synchronized full SHA; print source SHA and report commit SHA as separate labeled values. **Warning signs:** SHA absent/abbreviated, run links point to another SHA, or Phase 140 CI-06/CI-07 are still pending.

### Pitfall 2: Confusing no-publish with publication

**What goes wrong:** A successful push-triggered Release run is called a release. **Why:** The Release workflow can succeed while protected publication jobs intentionally skip. **How to avoid:** Describe it as the no-publish graph; prove public release separately with Hex plus GitHub release/tag and the matching protected run/artifact evidence. The local contract enumerates all five expected job results. [VERIFIED: `scripts/maintainer/repo_hygiene_check.sh:454-473`]

### Pitfall 3: Resolving the 1.5.0/1.5.1 mismatch from repository metadata

**What goes wrong:** A checked-in version or changelog line is used as proof of public release. **Why:** Release-owned metadata may have advanced without a successful publication. **How to avoid:** At closure query official Hex package and release endpoints and GitHub release/tag/run records. Correct explanatory planning claims only; leave release-owned files to the protected workflow. Current evidence in context is date-bound and must be rechecked. [CITED: `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:21-24,75-79`; `.planning/RELEASE-TRAIN.md:7-20`]

### Pitfall 4: Losing disposition meaning during summary

**What goes wrong:** The final handoff calls all remaining work “done,” “clean,” or “deferred” without triggers. **Why:** Concision can collapse meaningful distinctions between resolved, historical, deferred-with-trigger, and out of scope. **How to avoid:** Carry forward exact Phase 140 source links and next proof/reopen trigger. A healthy baseline does not require an empty queue. [VERIFIED: `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md:25-30`; `.planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md`]

### Pitfall 5: Updating documents in a sequence that creates contradictory interim truth

**What goes wrong:** The project or requirements marks the milestone complete before the evidence record and other GSD state are consistent. **How to avoid:** Draft from the verified baseline, make one coherent documentation update set, then cross-check the status of each record and links before declaring closure. Do not represent the final docs commit as part of an earlier receipt.

### Pitfall 6: Hiding a blocking external dependency

**What goes wrong:** Planning assumes Hex/GitHub can be queried at execution time or that discussion-time data is still current. **How to avoid:** At implementation time verify `gh` authentication/network access and public Hex/GitHub read access. If current source evidence cannot be obtained, state the missing observation and keep publication reconciliation pending; do not convert lookup failure into a claim of absence.

## Code Examples

No application code is required. Use the existing shell acceptance command only after the terminal SHA and all observed WARN labels are known (see Pattern 3). The exact-acceptance interface is defined in `repo_hygiene_check.sh` lines 17–40, 63–99; Phase 140's contract supplies the order and gate meaning in `140-ACCEPTANCE.md` lines 13–33. Avoid adding a parser or acceptance helper.

Suggested shell-only documentation checks for the plan: `git diff --check` and verify every local/hosted evidence link and every repeated completion/status claim across the six required planning docs. These are recommendations, not tests run during this research task.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat any prior successful check or newest green run as baseline proof | Join local gates, hygiene, canonical CI and Release no-publish results to one synchronized full SHA | Phases 138-140; locked in 141 D-01 | Exact source identity survives later planning/report commits. |
| Treat version/changelog metadata as release truth | Verify published artifact and release records through Hex/GitHub and protected-run evidence | Release train already distinguishes exact-ref publish from push/no-publish | GSD milestone completion can be accurate without claiming package publication. |
| Re-copy inventory and raw evidence into every phase | Preserve immutable source receipts and link a concise dated handoff | Phase 138 evidence taxonomy and Phase 141 D-02 | Less drift, redaction risk and duplicated maintenance. |

**Deprecated/outdated:** The discussion-time `1.5.0` public-release snapshot is not a currentness guarantee; query the cited primary endpoints again at closure. No deprecation of runtime libraries applies to this phase.

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation=true`). This phase makes no runtime code change and should not add a test suite or test infrastructure. Verification is documentary plus reuse of already-existing proof seams; do not manufacture a code test for prose reconciliation.

| Validation target | Type | Recommended check | Pass condition |
|-------------------|------|-------------------|----------------|
| Phase 140 terminal acceptance | Existing automated acceptance receipt | Review final verifier and run `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha "$FINAL_SHA" --format json` with one exact disposition per observed WARN | Terminal receipt says accepted for current synchronized full SHA; no predecessor substitution. |
| Public release truth | Read-only external source verification | Re-fetch Hex package/release records, GitHub release/tag and matching CI/protected release runs | All cited identity edges agree; otherwise record conflict and do not assert current version. |
| Baseline document links and evidence identities | Manual contract review | Inspect every source link, full SHA/run ID, timestamp, evidence currentness, disposition trigger, source-SHA/report-SHA label | Every claim is traceable, dated and status meaning is explicit. |
| Planning truth coherence | Manual consistency review | Cross-check PROJECT, ROADMAP, REQUIREMENTS, STATE, MILESTONES, RELEASE-TRAIN | Same completed v1.38 posture and next sustaining action; package publication separately stated. |
| Documentation hygiene | Static diff check | `git diff --check` plus link/claim review | No whitespace issues, broken local links, stale “active phase” statements, or unsupported latest-release claim. |

No Wave 0 gaps: no test file, config, dependency, or fixture is needed. Do not run local acceptance from research; it executes `mix ci` and interacts with remote evidence, both outside this research task. The final plan should allocate the terminal acceptance to its Phase 140 owner/checkpoint and reserve Phase 141 for consuming the completed result.

## Security Domain

This is not protocol or application security implementation. The security-relevant work is evidence integrity and confidentiality:

- Keep full identifiers and safe workflow result metadata needed to audit source identity; redact credentials, tokens, uncontrolled bodies, and raw supplemental logs.
- Treat the accepted SHA and receipt links as evidence, not as permission to push, publish, dispatch, delete or modify refs.
- Keep public package evidence and protected publish evidence distinct from ordinary no-publish run evidence.
- Do not include sensitive data from Phase 140 raw CI/OIDF logs in the durable Markdown index.

ASVS V2 Authentication, V3 Session Management, V4 Access Control and V6 Cryptography are not implementation targets in this documentation phase. The transferable control is evidence integrity/redaction and separation of authority; do not make protocol certification claims from these records. Security defaults for the library remain as stated by `AGENTS.md`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Git | Ref/SHA inspection | Yes | 2.41.0 | None for exact repository object IDs |
| GitHub CLI (`gh`) | Required workflow and release evidence | Binary present; authentication unverified | — | Read official GitHub web/API records if available; otherwise leave claims pending |
| `jq` | Existing hygiene CLI | Yes | Not queried | Existing script requires `jq`; no alternate acceptance implementation |
| Mix | Local `mix ci` via Phase 140 acceptance | Shim present; toolchain not verified | — | Phase 140 acceptance owner resolves supported toolchain |
| Network access to Hex/GitHub | Current release revalidation | Yes; unauthenticated public APIs responded | — | Revalidate again at closure because release state is mutable |

No remote service was modified and no tests or acceptance gates were run during this research task. Public Hex/GitHub APIs were queried read-only; results are dated evidence and should be revalidated at closure.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The verified 2026-10-02 Hex/GitHub release identity remains current at Phase 141 execution. | Publication truth conflict | Planning records could state the wrong latest public version; explicitly revalidate before writing the closure record. |
| A2 | GitHub workflow records remain accessible to the maintainer at closure. | Environment Availability | Hosted proof cannot be freshly joined; closure must remain pending or state the observation gap. |
| A3 | `141-BASELINE.md` is a useful filename for the canonical dated handoff. | Summary / Architecture Patterns | Low impact; filename is delegated discretion and can change without changing evidence semantics. |

## Open Questions (RESOLVED)

The values below remain unknown until the relevant mutable evidence is observed at execution time. Their **planning questions are resolved**: Phase 141 has an explicit source-native procedure and fail-closed outcome for each value. `(RESOLVED)` here means no design or planning ambiguity remains; it does not claim that closure-time observations have already happened.

1. **What is the terminal Phase 140 accepted SHA?** — RESOLVED for planning: Task 1 consumes only the Phase 140 owner's post-summary terminal receipt and matching verifier. If absent, contradictory, or inaccessible, Phase 141 stops without inventing a SHA or making closure claims.
   - What we know: The acceptance file says prior candidate receipts are not terminal if subsequent writes create another candidate.
   - What's unclear: The exact post-summary accepted source SHA after Phase 140 verifier and all evidence writes.
   - Recommendation: Leave it unknown in the plan template; consume only the completed Phase 140 verifier and final exact-hygiene JSON receipt.
2. **Which version is the latest public release when Phase 141 closes?** — RESOLVED for planning: Task 1 re-queries authoritative Hex/GitHub publication and workflow evidence at closure; Task 2 updates explanatory prose only from that evidence. Failed/unavailable queries remain pending observations, not absence claims.
   - What we know: Phase 141 context cites discussion-time Hex/GitHub proof for `1.5.0`, while `.planning/RELEASE-TRAIN.md` contains `1.5.1` claims.
   - What's unclear: Whether public release truth changed between discussion and execution, and what exact tag/run/package chain is current then.
   - Recommendation: Read current Hex and GitHub primary records at closure; update explanatory planning claims only, preserve release-owned state.
3. **What exact sustaining GA action should be recorded?** — RESOLVED for planning: Task 2 re-reads the release-train conditions and current evidence, then records the next supported conditional action. It does not invent a patch intent or execute publication.
   - What we know: The release train says patch-eligible changes flow through Release Please and a next patch is cut only when at least one such change is merged, exact current-main CI is green, hygiene has no BLOCK, and supported-surface truth remains current. [VERIFIED: `.planning/RELEASE-TRAIN.md:22-30`]
   - What's unclear: Whether a qualifying merged change exists at closure; that is mutable.
   - Recommendation: Re-read current main/release train evidence, then state the next action/condition precisely. Do not invent a patch intent if its entry conditions are absent.

## Sources

### Primary (repository source of truth)

- `.planning/phases/141-maintenance-baseline-closure/141-CONTEXT.md` — Locked decisions, currentness warning, evidence sources, scope and maintainer JTBD.
- `.planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md` — Fail-closed exact-SHA terminal acceptance sequence and current pending status.
- `.planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md` — Goal-backward status, open CI-06/CI-07 and deferred outcomes.
- `.planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md` — Canonical source-linked dispositions and recheck triggers.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-CONTEXT.md` — Immutable evidence, source completeness, redaction, accessible Markdown and maintainer UX principles.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/METHODOLOGY.md`, `.planning/RELEASE-TRAIN.md`, `.planning/DEVELOPMENT-TRAIN.md`, `.planning/REPO-HYGIENE-CHECKLIST.md` — Phase requirements, lifecycle, release ownership and acceptance vocabulary.
- `scripts/maintainer/repo_hygiene_check.sh`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`, and existing release contract tests — Executable exact-SHA and job-graph ownership.
- `prompts/README.md`, `prompts/lockspire-release-engineering-and-ci.md`, `prompts/lockspire-release-readiness-and-conformance.md`, `prompts/lockspire-elixir-oss-library-practices.md` — Applicable release, evidence, docs-as-contract, package and maintainer UX guidance; no runtime/API recommendations imported.
- `AGENTS.md` — Project boundary and security defaults.

### Authoritative mutable publication records (must revalidate at closure)

- Hex package API: https://hex.pm/api/packages/lockspire
- Hex exact release APIs: https://hex.pm/api/packages/lockspire/releases/1.5.0 and https://hex.pm/api/packages/lockspire/releases/1.5.1
- GitHub public release: https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.0
- Canonical CI and protected release run: https://github.com/szTheory/lockspire/actions/runs/33141161205 and https://github.com/szTheory/lockspire/actions/runs/33141484467

No additional framework/ecosystem research was performed because the locked scope explicitly excludes runtime/API/UI decisions and says no further ecosystem research is needed for this docs-and-evidence phase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — docs/evidence scope is locked and existing tooling/source owners are directly identified in repo.
- Architecture: HIGH — Phase 138-140 established evidence lifecycle and Phase 141 names the exact integration points.
- Pitfalls: HIGH — same-SHA, release ownership and deferral boundaries are explicit; publication freshness remains contingent on closure-time source checks.

**Research date:** 2026-10-02
**Valid until:** 2026-10-09 for mutable release/publication facts; repository ownership patterns remain valid until changed.
