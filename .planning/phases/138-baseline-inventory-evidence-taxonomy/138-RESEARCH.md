# Phase 138: Baseline Inventory & Evidence Taxonomy - Research

**Researched:** 2026-08-28  
**Domain:** Repository-maintainer evidence collection, Git/GitHub enumeration, and operational-record taxonomy  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Produce one canonical dated Markdown ledger under the Phase 138 planning directory. Use compact YAML front matter for snapshot-wide metadata, stable domain sections for Git, GitHub, and maintained records, and stable evidence IDs that later phases can reference without copying rows.
- **D-02:** Markdown is the authoritative record. The collector may use temporary JSON internally to parse structured command output, but no JSON/YAML sidecar is canonical or committed unless later evidence proves a recurring machine-consumption need.
- **D-03:** Add a purpose-built repo-local Bash collector under `scripts/maintainer/` rather than a Mix task, Ecto schema, Phoenix route, LiveView, Oban job, or runtime module. Repository-maintainer workflow must not become supported Hex-library or host-application surface.
- **D-04:** Keep `scripts/maintainer/repo_hygiene_check.sh` focused on recurring `PASS`/`WARN`/`BLOCK` readiness gates. The inventory collector answers what was observed and proposed; it must not overload gate semantics or turn the hygiene script into an artifact store.
- **D-05:** Prefer compact summary tables plus detail blocks for ambiguous or actionable entries. Do not copy raw command output when exact structured fields, source links, and reproduction commands are sufficient.
- **D-06:** Record a UTC RFC 3339 collection window, repository identity, local HEAD, refreshed `origin/main`, full immutable SHAs, tool versions, commands, exit status, query scope, canonical paths or URLs, and limitations. Keep `observed_at`, upstream `source_updated_at`, mutable ref names, and immutable observed SHAs as separate concepts.
- **D-07:** Every evidence source reports `complete`, `partial`, `unavailable`, or `not_applicable`. A failed fetch, missing or unauthenticated tool, API error, pagination boundary, inaccessible source, or redacted field is never represented as an empty or clean result.
- **D-08:** Do not assign an arbitrary time-to-live to a snapshot. Revalidate relevant mutable evidence at the start of Phases 139 and 140, immediately before any Phase 140 mutation, and again during Phase 141 exact-SHA closure.
- **D-09:** Refresh origin branches and tags as required, but explicitly prevent local-tag pruning. Fetch is the only permitted local metadata mutation during collection; the collector must not alter the working tree, local branches, tags, worktrees, GitHub objects, release-owned files, or historical evidence.
- **D-10:** Use stable, script-oriented interfaces such as Git porcelain output, `git for-each-ref`, and structured/paginated GitHub CLI or API output. Default or silently bounded list limits are not completeness evidence.
- **D-11:** Redact secrets and uncontrolled bodies. Preserve full identifiers, safe status fields, counts, URLs, and redacted receipt links; do not embed raw CI/OIDF logs, tokens, credentials, environment values, or issue-body dumps.
- **D-12:** Use a layered model: shared evidence/lifecycle fields plus exact domain-native proposed dispositions. Shared lifecycle values are `active`, `resolved`, `historical`, and `incidental`; confidence values are `direct_current`, `corroborated`, and `inferred`.
- **D-13:** Branches, tags, and worktrees use `keep`, `proposed-remove`, or `defer`. Pull requests use `merge-ready`, `needs-work`, `close`, or `defer`. Issues use `close`, `retain`, or `defer`. Maintained findings use `fix-now`, `defer-with-trigger`, `retain-historical`, `already-resolved`, or `out-of-scope`.
- **D-14:** Each row includes a stable ID and kind, canonical subject, observed state, lifecycle, domain-specific proposed disposition, evidence reference, concise rationale, confidence, recheck trigger or next proof, required authority, and explicit proposed-versus-executed state.
- **D-15:** Phase 138 dispositions are proposals only. Phase 140 must revalidate the exact target, current state, authority, recovery path, uncommitted-work safety, historical-evidence safety, and required gates before any action.
- **D-16:** `resolved` requires terminal proof; `historical` means intentionally preserved, never disposable; `close` must distinguish completed from not planned; and a green PR check snapshot alone does not establish merge readiness.
- **D-17:** Drive discovery from an explicit source-family manifest rather than an unrestricted full-repository text dump. Include `.planning/todos/`, `.planning/debug/`, `.planning/quick/`, `.planning/threads/`, `.planning/seeds/`, active or ambiguous review/audit/verification/UAT/handoff/checkpoint records, `.continue-here.md`, current roadmap/state/milestone/release-train claims, retained supplemental conformance findings, and credible tracked `TODO`/`FIXME` follow-ups.
- **D-18:** Summarize completed milestone, quick-work, debug, audit, review, and verification archive containers instead of re-triaging every fulfilled file. Expand only unresolved, contradictory, ambiguous, or still-actionable findings.
- **D-19:** Exclude generated and incidental paths such as `deps`, `_build`, `cover`, generated `doc`, `.artifacts`, `tmp`, `.DS_Store`, caches, and abandoned tool workspaces from per-file inventory. If a repository-owned gate reports a meaningful problem in such a path, record one finding with its exact source rather than inventorying the tree.
- **D-20:** Deduplicate repeated mentions into one canonical evidence row with references from other records. Preserve supersession and rationale instead of rewriting historical records.
- **D-21:** The primary persona is the release steward returning after a milestone; secondary personas are an on-call maintainer, a contributor evaluating queued work, and a future maintainer reconstructing prior decisions. Their job is to establish what is true, retained, and justified without deleting proof.
- **D-22:** This phase's user experience is terminal plus accessible Markdown, not a Phoenix UI. Use semantic headings and tables, deterministic ordering, concise low-anxiety copy, explicit text statuses, and no color- or emoji-only meaning. Follow the current repo-root brandbook when presentation guidance applies.
- **D-23:** Prefer microcopy such as `Observed`, `Proposed disposition`, `Collection unavailable`, `Revalidation required before action`, and `No open issues observed; query succeeded with 0 results`. Avoid unconditional claims such as `Everything clean`, `Safe to delete`, or `Nothing found` when evidence is incomplete.
- **D-24:** Add focused contract proof for deterministic ordering, stable IDs and headings, complete Git/GitHub enumeration, pagination/count handling, failed-source semantics, redaction, non-destructive command policy, tag-pruning safety, and the absence of new public/runtime/Mix-task surface.

### the agent's Discretion
The user delegated the complete decision set to the agent after research. Downstream planning may choose internal shell function names, exact table layout, and temporary parsing mechanics, provided the locked ownership, evidence, taxonomy, safety, accessibility, and phase-boundary decisions above remain intact.

### Deferred Ideas (OUT OF SCOPE)
- A recurring machine-readable repository-health database, JSON schema, generator pipeline, or CI-enforced inventory subsystem is deferred unless v1.38 demonstrates a repeatable mechanically detectable gap, consistent with FUTURE-04.
- A Phoenix/LiveView dashboard or consumer-facing Mix task is not warranted for this maintainer-only phase and remains outside the embedded-library surface.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BASE-01 | Refresh origin refs and tags; prove clean/synchronized local `main` or exact divergence. | Use a fetch receipt, full SHA capture, `git status --porcelain=v2 --branch`, and left/right `git rev-list --left-right --count main...origin/main`. |
| BASE-02 | Inventory relevant local/remote branches, tags, and worktrees with a proposed disposition. | Deterministic `git for-each-ref` and `git worktree list --porcelain` collectors feed domain-native evidence rows. |
| TRIAGE-01 | Inventory every open PR with evidence-backed disposition. | A cursor-paginated GitHub GraphQL query provides complete enumeration; per-PR safe fields provide review/check evidence without retaining bodies. |
| TRIAGE-02 | Inventory every open issue with evidence-backed disposition. | A separate cursor-paginated GraphQL issue query records a successful zero-result query explicitly rather than treating it as a health metric. |
| LOOSE-01 | Inventory todos, historical findings, debug/handoff artifacts, roadmap notes, and maintained follow-ups. | A source-family manifest scans only maintained paths, summarizes fulfilled archives, expands actionable/ambiguous records, and deduplicates cross-references. |
</phase_requirements>

## Summary

Phase 138 should be a single purpose-built Bash collector and a single dated Markdown snapshot under this phase directory; it is deliberately repository tooling, not Lockspire runtime or Hex-library surface. The current repository already separates recurring readiness gates (`scripts/maintainer/repo_hygiene_check.sh`) from maintainer evidence, and release contract tests already enforce that boundary. [VERIFIED: codebase]

The collector needs a receipt-first design: initialize metadata and source status, perform the one allowed metadata mutation (`git fetch --prune --tags origin`, explicitly never `--prune-tags`), collect deterministic records into temporary files, then render a stable ledger only after each source has an explicit completion outcome. Git documents that `--prune` removes stale remote-tracking refs while `--prune-tags` can remove local tags; GitHub CLI documents that list commands default to 30 items and its API paginator can fetch all pages. [CITED: https://git-scm.com/docs/git-fetch] [CITED: https://cli.github.com/manual/gh_api] [CITED: https://cli.github.com/manual/gh_pr_list] [CITED: https://cli.github.com/manual/gh_issue_list]

**Primary recommendation:** Plan a contract-tested, deterministic Bash collector that records source receipts and proposal-only evidence rows; keep the existing hygiene script unchanged except, at most, a non-owning pointer to the latest inventory. [VERIFIED: codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Git baseline and ref inventory | Repository-maintainer CLI | Git remote/local metadata | Git state is observed through Git’s script-oriented interfaces; no application tier owns it. [CITED: https://git-scm.com/docs/git-fetch] |
| GitHub PR/issue enumeration | Repository-maintainer CLI | GitHub API | The collector must make paginated read-only queries and retain only safe structured fields. [CITED: https://cli.github.com/manual/gh_api] |
| Maintained-record discovery | Repository-maintainer CLI | Versioned `.planning/` records | The explicit source manifest keeps scope bounded and preserves historical records. [VERIFIED: CONTEXT.md] |
| Canonical evidence ledger | Versioned planning artifact | Repository-maintainer CLI | Markdown is the canonical durable record; transient JSON is only an implementation detail. [VERIFIED: CONTEXT.md] |
| Boundary enforcement | ExUnit release-proof contracts | CI hygiene job | Existing tests and CI already protect repository-maintainer tooling from becoming product surface. [VERIFIED: codebase] |

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate companion library, not a Sigra module. [VERIFIED: AGENTS.md]
- Preserve the embedded-library shape and narrow host seam; do not create a standalone auth service. [VERIFIED: AGENTS.md]
- Preserve strong boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Do not expand v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve the listed OAuth/OIDC security defaults, including PKCE S256, exact redirects, hashed secrets, token lifecycle safeguards, no implicit flow/`alg=none`, and redaction. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library / Tool | Version observed | Purpose | Why Standard |
|----------------|------------------|---------|--------------|
| Bash | 5.2.37 | Repo-local collector and deterministic renderer. | Existing maintainer hygiene tooling uses Bash and its contract tests keep it outside runtime surface. [VERIFIED: codebase] |
| Git | 2.41.0 | Fetch receipt, refs, worktrees, status, and divergence evidence. | Git exposes porcelain and ref-iteration interfaces intended for scripting. [VERIFIED: local tool help] [CITED: https://git-scm.com/docs/git-fetch] |
| GitHub CLI (`gh`) | 2.95.0 | Authenticated, structured GitHub API collection. | It is authenticated locally and supports API pagination. [VERIFIED: local environment] [CITED: https://cli.github.com/manual/gh_api] |
| jq | 1.7.1 | Parse temporary JSON and render only allowlisted fields. | Installed locally; keeps raw GitHub responses out of the committed ledger. [VERIFIED: local environment] |
| ExUnit | project test stack | Contract proof for script boundary and output contract. | Existing release-proof test entry points and support modules are the project pattern. [VERIFIED: codebase] |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `git for-each-ref` | Stable branch/tag enumeration with explicit sort and format. | For all local and remote branch/tag rows. [VERIFIED: CONTEXT.md] |
| `git worktree list --porcelain` | Script-oriented worktree state. | For each registered worktree, including path and branch/HEAD state. [VERIFIED: CONTEXT.md] |
| `git status --porcelain=v2 --branch` | Machine-oriented working-tree and branch-state evidence. | For root-worktree cleanliness and tracking state. [ASSUMED] |
| `git rev-list --left-right --count main...origin/main` | Exact ahead/behind count. | After successful fetch, paired with full SHA capture. [ASSUMED] |
| `gh api graphql --paginate` | Cursor-based unbounded PR/issue enumeration. | For authoritative queue completeness; pipe pages through `jq -s`, because this `gh` version disallows `--slurp` with `--jq`. [VERIFIED: local environment] [CITED: https://cli.github.com/manual/gh_api] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Repo-local Bash collector | Mix task | Rejected: locked scope forbids exposing maintenance workflow as a supported library/runtime surface. [VERIFIED: CONTEXT.md] |
| Explicit GraphQL pagination | `gh pr list` / `gh issue list` | Rejected for completeness proof: both list commands default to 30 items; a manually high limit is still an implicit boundary. [CITED: https://cli.github.com/manual/gh_pr_list] [CITED: https://cli.github.com/manual/gh_issue_list] |
| Bounded source-family manifest | Unrestricted repository search | Rejected: it mixes incidental/generated content with maintained follow-up evidence and conflicts with the locked discovery boundary. [VERIFIED: CONTEXT.md] |

**Installation:** None. This phase must not add packages. [VERIFIED: codebase]

## Architecture Patterns

### System Architecture Diagram

```text
release steward
      |
      v
scripts/maintainer/baseline_inventory.sh
      |
      +--> preflight receipt: git/gh/jq availability and auth
      |
      +--> controlled fetch: origin branches + tags, no local-tag pruning
      |       |
      |       +--> Git state: HEAD, status, divergence, refs, tags, worktrees
      |
      +--> GitHub GraphQL pagination
      |       |
      |       +--> safe PR fields + safe issue fields, page/count receipts
      |
      +--> maintained-source manifest
      |       |
      |       +--> active/ambiguous records + archive summaries + TODO/FIXME candidates
      |
      +--> normalize, sort, deduplicate, redact
      |
      v
dated Phase 138 Markdown ledger (canonical, proposal-only)
      |
      +--> Phase 139/140 revalidation by stable evidence ID
      +--> ExUnit contract proof (not product runtime)
```

### Recommended Project Structure

```text
scripts/maintainer/
└── baseline_inventory.sh                 # collector; writes a dated ledger only

.planning/phases/138-baseline-inventory-evidence-taxonomy/
├── 138-RESEARCH.md
└── baseline-inventory-YYYY-MM-DD.md      # canonical collected snapshot

test/lockspire/release/
└── repository_hygiene_contract_test.exs  # focused source/output contract entry point

test/support/lockspire/release_proof/
└── package_assertions.ex                 # shared repository-boundary assertions
```

### Pattern 1: Receipt-first, fail-visible collection

**What:** Give each domain source a status (`complete`, `partial`, `unavailable`, or `not_applicable`) and a receipt containing command, exit status, collection timing, scope, and limitation before rendering its rows. [VERIFIED: CONTEXT.md]

**When to use:** Always; a source failure must render a visible unavailable/partial section, never an empty table. [VERIFIED: CONTEXT.md]

**Example:**

```bash
collect_source "github-open-prs" "gh api graphql --paginate ..." || \
  record_source_unavailable "github-open-prs" "gh query exited $?: no queue conclusion"
```

### Pattern 2: Allowlisted records, not raw responses

**What:** Build the Markdown rows from explicit safe fields: identifiers, titles, immutable SHAs, ref names, timestamps, URLs, status/check summaries, rationale, and disposition. Do not pass bodies/logs/tokens/environment values through the renderer. [VERIFIED: CONTEXT.md]

**When to use:** For GitHub data and every free-text planning record. [VERIFIED: CONTEXT.md]

### Pattern 3: Stable identity plus proposal/execution split

**What:** Construct deterministic IDs by sorted domain and subject (`GIT-BR-*`, `GIT-TAG-*`, `GIT-WT-*`, `GH-PR-*`, `GH-ISSUE-*`, `REC-*`) and include an `Execution: not performed in Phase 138` field on every actionable row. [VERIFIED: CONTEXT.md]

**When to use:** For every row later phases may cite. The action phase must revalidate the exact current target; a proposed removal/close is not authorization. [VERIFIED: CONTEXT.md]

### Pattern 4: Complete GitHub enumeration with cursors

**What:** Use GraphQL collections with `first: 100`, `$endCursor`, `pageInfo { hasNextPage endCursor }`, and `gh api graphql --paginate`; combine pages with `jq -s` after the command. [CITED: https://cli.github.com/manual/gh_api]

**When to use:** For separate open PR and open issue queues. GitHub CLI’s `--paginate` sequentially requests pages until none remain, but its current local CLI rejects combining `--slurp` with `--jq`. [VERIFIED: local environment] [CITED: https://cli.github.com/manual/gh_api]

### Anti-Patterns to Avoid

- **`git fetch --prune-tags`:** It can remove local tags; use `git fetch --prune --tags origin` and contract-test the absence of `--prune-tags`. [CITED: https://git-scm.com/docs/git-fetch]
- **Treating a failed command as zero results:** A nonzero fetch/API/auth/pagination result must render `unavailable` or `partial`. [VERIFIED: CONTEXT.md]
- **Using `gh pr list`/`gh issue list` defaults as complete enumeration:** Their default maximum is 30. [CITED: https://cli.github.com/manual/gh_pr_list] [CITED: https://cli.github.com/manual/gh_issue_list]
- **Using REST `/issues` without separating PRs:** GitHub’s issue-style endpoints can overlap PR records; use distinct GraphQL `pullRequests` and `issues` collections. [ASSUMED]
- **Calling a green check snapshot `merge-ready`:** Merge readiness also requires current review, mergeability, and policy evidence. [VERIFIED: CONTEXT.md]
- **Inventorying all archive files individually:** Summarize fulfilled containers; expand only unresolved, contradictory, ambiguous, or actionable records. [VERIFIED: CONTEXT.md]
- **Editing `repo_hygiene_check.sh` into an artifact generator:** It must remain a recurring PASS/WARN/BLOCK gate. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Git ref parsing | Ad hoc `git branch` human-output parser | `git for-each-ref`, porcelain status, and worktree porcelain. | Locked source contract favors stable script interfaces. [VERIFIED: CONTEXT.md] |
| GitHub pagination | Offset/page loop that guesses a maximum | `gh api graphql --paginate` with cursor/pageInfo. | CLI supports fetching all pages and exposes cursor-based pagination. [CITED: https://cli.github.com/manual/gh_api] |
| JSON parser | Shell regex parser for nested API output | Installed `jq` against temporary response files. | Reduces quoting/escaping errors and supports field allowlisting. [VERIFIED: local environment] |
| Evidence database/UI | Ecto schema, dashboard, Mix task, or job | Committed Markdown ledger and repo-local script. | Locked scope excludes new runtime/public surface and recurring subsystem. [VERIFIED: CONTEXT.md] |

**Key insight:** The difficult part is not querying Git or GitHub; it is preserving completeness, temporal provenance, redaction, and the distinction between an evidence-backed proposal and an authorized mutation. [VERIFIED: CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Fetch command silently violates tag safety

**What goes wrong:** A convenience `--prune-tags` flag deletes a local tag that is intentionally retained as historical evidence. [CITED: https://git-scm.com/docs/git-fetch]

**Why it happens:** `--prune-tags` is a shorthand for explicit tag refspec pruning, unlike ordinary remote-tracking-branch pruning. [CITED: https://git-scm.com/docs/git-fetch]

**How to avoid:** Hard-code `git fetch --prune --tags origin`; reject `--prune-tags`, explicit tag-destination prune refspecs, and all commands that mutate worktrees/branches/tags. [VERIFIED: CONTEXT.md]

**Warning signs:** The rendered command receipt contains `--prune-tags`, `tagOpt`, a tag refspec destination, or a tag-count reduction. [ASSUMED]

### Pitfall 2: “No items” has unknown provenance

**What goes wrong:** An unauthenticated or partially paginated GitHub query renders an empty PR/issue section. [VERIFIED: CONTEXT.md]

**Why it happens:** A default 30-item limit and failure-blind shell pipelines do not prove query completeness. [CITED: https://cli.github.com/manual/gh_pr_list] [CITED: https://cli.github.com/manual/gh_issue_list]

**How to avoid:** Capture `gh auth status`, GraphQL pageInfo, page count, item count, exit status, and query scope; state `No open issues observed; query succeeded with 0 results` only on a complete successful receipt. [VERIFIED: CONTEXT.md]

**Warning signs:** No pagination receipt, an `--limit` default, `set -e` exit before ledger finalization, or no source-status field. [VERIFIED: local tool help] [VERIFIED: CONTEXT.md]

### Pitfall 3: Disposition names conceal authority or finality

**What goes wrong:** A reader treats `proposed-remove` or `close` as proof an action happened, or discards historical evidence. [VERIFIED: CONTEXT.md]

**Why it happens:** Lifecycle and disposition are different axes; “resolved” requires terminal proof and historical records are retained intentionally. [VERIFIED: CONTEXT.md]

**How to avoid:** Require `lifecycle`, `proposed_disposition`, `required_authority`, `recheck_trigger`, `evidence_ref`, `confidence`, and `executed: no` fields. [VERIFIED: CONTEXT.md]

**Warning signs:** A row has a conclusion but lacks an immutable SHA/source URL or next proof. [VERIFIED: CONTEXT.md]

### Pitfall 4: Archive noise overwhelms actionable records

**What goes wrong:** The collector emits hundreds of historical planning files, hiding the few current contradictions or todos. [VERIFIED: CONTEXT.md]

**Why it happens:** An unrestricted recursive text search treats generated, incidental, and completed records as active work. [VERIFIED: CONTEXT.md]

**How to avoid:** Implement the locked source-family manifest and archive-summary rule, then deduplicate all repeated mentions into one `REC-*` row with cross-references. [VERIFIED: CONTEXT.md]

**Warning signs:** Per-file rows from `deps`, `_build`, `cover`, `doc`, `.artifacts`, `tmp`, or completed milestone containers. [VERIFIED: CONTEXT.md]

## Code Examples

### Safe origin refresh and divergence receipt

```bash
# Source: https://git-scm.com/docs/git-fetch
if git fetch --prune --tags origin; then
  fetch_exit=0
else
  fetch_exit=$?
fi

local_head="$(git rev-parse main)"
origin_head="$(git rev-parse origin/main)"
read -r behind ahead < <(git rev-list --left-right --count main...origin/main)
git status --porcelain=v2 --branch
```

The implementation must render the command, exit code, full SHAs, and counts even when synchronization is blocked; it must not use `--prune-tags`. [VERIFIED: CONTEXT.md] [CITED: https://git-scm.com/docs/git-fetch]

### Complete, safe GitHub GraphQL collection

```bash
# Source: https://cli.github.com/manual/gh_api
gh api graphql --paginate -f query='query($endCursor: String) {
  repository(owner: "szTheory", name: "lockspire") {
    pullRequests(first: 100, states: OPEN, after: $endCursor) {
      nodes { number title url updatedAt isDraft mergeStateStatus reviewDecision }
      pageInfo { hasNextPage endCursor }
    }
  }
}' >"$tmp_dir/open-pr-pages.json"

jq -s '[.[].data.repository.pullRequests.nodes[]]
       | sort_by(.number)
       | .[] | {number, title, url, updatedAt, isDraft, mergeStateStatus, reviewDecision}' \
  "$tmp_dir/open-pr-pages.json"
```

The collector should issue a separate GraphQL collection query for `issues`, preserve page/count receipts, and avoid `body`, comments, logs, or token-bearing fields. [VERIFIED: CONTEXT.md] [CITED: https://cli.github.com/manual/gh_api]

### Deterministic evidence-row contract

```markdown
| ID | Kind | Subject | Observed state | Lifecycle | Proposed disposition | Evidence | Confidence | Recheck / next proof | Authority | Executed |
|----|------|---------|----------------|-----------|----------------------|----------|------------|----------------------|-----------|----------|
| GIT-BR-001 | local_branch | `verify/final` @ `<full SHA>` | upstream/current relationship observed | historical | keep | Git refs receipt | direct_current | Revalidate before Phase 140 action | maintainer | no — Phase 138 proposal only |
```

The exact table layout is discretionary, but all locked fields, deterministic ordering, accessibility, and proposal-only semantics are required. [VERIFIED: CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Human-formatted Git/GitHub inspection with implicit limits | Porcelain/ref iteration plus cursor-paginated structured queries and explicit receipts | Current Phase 138 decision | Enables repeatable, completeness-aware evidence without new runtime dependencies. [VERIFIED: CONTEXT.md] |
| Monolithic “clean/dirty” readiness claim | Source-specific completeness and proposal-only dispositions | Current Phase 138 decision | Preserves uncertainty and avoids false cleanup authority. [VERIFIED: CONTEXT.md] |

**Deprecated/outdated:** Treating `gh pr list` or `gh issue list` with no explicit pagination/count handling as complete queue evidence is unsuitable for this phase because the documented default maximum is 30. [CITED: https://cli.github.com/manual/gh_pr_list] [CITED: https://cli.github.com/manual/gh_issue_list]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `git status --porcelain=v2 --branch` provides the required machine-oriented status fields on the project’s Git version. | Standard Stack; Code Examples | Collector needs a compatible fallback/format contract. |
| A2 | `git rev-list --left-right --count main...origin/main` returns behind then ahead counts in the shown assignment. | Standard Stack; Code Examples | Divergence could be mislabeled; focused test/fixture must pin ordering. |
| A3 | Separate GitHub GraphQL `issues` and `pullRequests` collections are the safest way to avoid REST issue/PR overlap. | Anti-Patterns | A query design change may be needed to guarantee mutually exclusive inventory rows. |
| A4 | The shown GraphQL fields are available with the locally authenticated GitHub CLI/API schema. | Code Examples | Collector needs field reduction or a receipt-visible unavailable outcome. |
| A5 | A tag-count reduction is a sufficient warning sign of unsafe pruning. | Pitfall 1 | It may be incomplete; the command allowlist remains the primary protection. |

## Open Questions (RESOLVED)

1. **RESOLVED — How should the collector select its dated ledger filename when run more than once per UTC day?**
   - What we know: The canonical artifact must be dated and a single Markdown ledger is authoritative. [VERIFIED: CONTEXT.md]
   - Resolution: The collector accepts explicit `--output PATH`, otherwise selects the UTC-date default `baseline-inventory-YYYY-MM-DD.md`; it refuses to overwrite an existing target unless the caller explicitly passes `--replace`. The canonical Phase 138 run supplies the dated phase-directory path explicitly, and replacement is reserved for a failed/truncated candidate created by that same task under the lock/temp/atomic-write guarantees. [RESOLVED: 138-01-PLAN.md, 138-03-PLAN.md]

2. **RESOLVED — Which exact PR status fields should be retained as “safe status fields”?**
   - What we know: Raw bodies and uncontrolled logs must not be retained; a green check snapshot alone is insufficient for merge readiness. [VERIFIED: CONTEXT.md]
   - Resolution: Retain only immutable node ID, number, escaped/redacted title, URL, source updated time, head/base ref and full SHAs, draft flag, mergeability/state, review decision, and summarized required-check counts/conclusions. Omit bodies, comments, raw check logs, environment values, and tokens; a missing required field produces a fail-visible source limitation rather than broadening the allowlist. [RESOLVED: 138-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Bash | Collector | ✓ | 5.2.37 | — [VERIFIED: local environment] |
| Git | Fetch and Git inventory | ✓ | 2.41.0 | — [VERIFIED: local environment] |
| GitHub CLI with authenticated `repo` scope | GitHub PR/issue evidence | ✓ | 2.95.0; authenticated | Record `unavailable` receipt if unavailable on a later host. [VERIFIED: local environment] |
| jq | Temporary structured-output parsing | ✓ | 1.7.1 | Bash-only renderer only if deliberately redesigned and re-reviewed. [VERIFIED: local environment] |
| Mix/ExUnit | Focused contract proof | ✓ | OTP 28 / project Mix | — [VERIFIED: local environment] |

**Missing dependencies with no fallback:** None observed. [VERIFIED: local environment]

**Missing dependencies with fallback:** None observed. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (project-native). [VERIFIED: codebase] |
| Config file | `mix.exs`. [VERIFIED: codebase] |
| Quick run command | `mix test test/lockspire/release/repository_hygiene_contract_test.exs`. [VERIFIED: codebase] |
| Full suite command | `mix ci`. [VERIFIED: REQUIREMENTS.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BASE-01 | Fetch command excludes local-tag pruning; metadata and divergence receipt schema are present. | source/contract | `mix test test/lockspire/release/repository_hygiene_contract_test.exs` | ❌ Wave 0 extension [VERIFIED: codebase] |
| BASE-02 | Stable headings/IDs/order cover refs, tags, and worktrees. | source/contract | `mix test test/lockspire/release/repository_hygiene_contract_test.exs` | ❌ Wave 0 extension [VERIFIED: codebase] |
| TRIAGE-01 | PR collection uses cursor pagination and safe fields; failed collection is visible. | source/contract | `mix test test/lockspire/release/repository_hygiene_contract_test.exs` | ❌ Wave 0 extension [VERIFIED: codebase] |
| TRIAGE-02 | Issue collection uses cursor pagination and explicit successful-zero semantics. | source/contract | `mix test test/lockspire/release/repository_hygiene_contract_test.exs` | ❌ Wave 0 extension [VERIFIED: codebase] |
| LOOSE-01 | Manifest covers required source families, excludes incidental trees, summarizes archives, and deduplicates evidence. | source/contract | `mix test test/lockspire/release/repository_hygiene_contract_test.exs` | ❌ Wave 0 extension [VERIFIED: codebase] |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/release/repository_hygiene_contract_test.exs`. [VERIFIED: codebase]
- **Per wave merge:** `mix test test/lockspire/release_readiness_contract_test.exs`. [VERIFIED: codebase]
- **Phase gate:** `mix ci` green before `$gsd-verify-work`. [VERIFIED: REQUIREMENTS.md]

### Wave 0 Gaps

- [ ] Extend `test/lockspire/release/repository_hygiene_contract_test.exs` and/or its `PackageAssertions` helper with explicit collector contract checks. [VERIFIED: codebase]
- [ ] Add a hermetic fixture/override strategy for deterministic rendered inventory assertions; live GitHub state cannot be a unit-test fixture. [ASSUMED]
- [ ] Add the collector source under `scripts/maintainer/`; no new framework installation is required. [VERIFIED: CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Require `gh auth status` before GitHub collection and render unavailable status when it fails. [VERIFIED: CONTEXT.md] |
| V3 Session Management | no | No Lockspire browser session/runtime change. [VERIFIED: CONTEXT.md] |
| V4 Access Control | yes | Proposal-only rows name required maintainer authority; Phase 138 performs no GitHub mutation. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Treat GitHub/planning text as uncontrolled input; only render allowlisted, escaped fields and redact bodies/logs. [VERIFIED: CONTEXT.md] |
| V6 Cryptography | no | No cryptographic operation is added. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for repository-maintainer collector

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret/body leakage into ledger | Information disclosure | Allowlist safe fields; never embed tokens, environment values, raw logs, or uncontrolled bodies. [VERIFIED: CONTEXT.md] |
| Command injection from ref/title/path text | Tampering / elevation | Quote shell expansions, avoid `eval`, parse JSON with `jq`, and render escaped Markdown. [ASSUMED] |
| False clean result after API/fetch failure | Repudiation / integrity | Source completeness states plus command/exit/page/count receipts. [VERIFIED: CONTEXT.md] |
| Accidental destructive collection | Tampering | Command allowlist permits only fetch metadata mutation; reject tag pruning and all delete/checkout/reset commands. [VERIFIED: CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- [Project Phase 138 context](138-CONTEXT.md) - locked ownership, taxonomy, source-family scope, safety, and test requirements. [VERIFIED: CONTEXT.md]
- [Requirements](../../REQUIREMENTS.md) - BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, and LOOSE-01 scope. [VERIFIED: REQUIREMENTS.md]
- [Existing hygiene script](../../../scripts/maintainer/repo_hygiene_check.sh) and [release proof](../../../test/lockspire/release/repository_hygiene_contract_test.exs) - repo-local Bash and ExUnit boundary patterns. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- [Git fetch documentation](https://git-scm.com/docs/git-fetch) - fetch, porcelain, pruning, and local-tag risk.
- [GitHub CLI API manual](https://cli.github.com/manual/gh_api) - cursor pagination and `--slurp` behavior.
- [GitHub CLI PR list manual](https://cli.github.com/manual/gh_pr_list) and [issue list manual](https://cli.github.com/manual/gh_issue_list) - default 30-item list limit and JSON fields.

### Tertiary (LOW confidence)

- Git porcelain-v2/rev-list exact field and ordering details, plus final GraphQL field availability; listed in Assumptions Log for execution-time confirmation.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new libraries; local tools and existing repo patterns were inspected. [VERIFIED: local environment] [VERIFIED: codebase]
- Architecture: HIGH — constrained directly by locked Phase 138 decisions. [VERIFIED: CONTEXT.md]
- Pitfalls: HIGH — critical tag, pagination, source-failure, and historical-evidence risks are directly specified or official-tool documented. [VERIFIED: CONTEXT.md] [CITED: https://git-scm.com/docs/git-fetch] [CITED: https://cli.github.com/manual/gh_api]

**Research date:** 2026-08-28  
**Valid until:** 2026-09-04 for GitHub CLI/API behavior and live state; Phase 138’s evidence itself must be recollected at execution and revalidated before downstream mutation. [VERIFIED: CONTEXT.md]
