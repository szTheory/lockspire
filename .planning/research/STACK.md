# Stack Research

**Domain:** Repository maintenance baseline for an embedded Phoenix/Elixir OAuth/OIDC library
**Researched:** 2026-08-28
**Confidence:** MEDIUM

## Recommendation

Add no new framework, CI service, GitHub bot, test runner, security scanner, or release system in v1.38. The repository already has a mature, intentionally integrated maintenance stack. This milestone should reconcile its evidence and run its existing gates from a clean, synchronized `main`, fixing only demonstrated drift or failures.

The current local checkout is one commit ahead of `origin/main` because it contains the v1.38 milestone-start documentation commit. It has one intentional worktree. GitHub currently has one legacy draft milestone PR (#83) and five Dependabot upgrade PRs (#86--88, #90--91); these require explicit triage, not another dependency-management tool. Latest observed `main` CI and Release runs for the prior head `d82eaa1c` are successful.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir / Mix | CI: Elixir 1.19.5; supported floor 1.18.4 | Compile, test, package, docs, quality aliases | `mix ci` already composes the repo's contributor gate, while targeted aliases preserve fast diagnosis. Keep the declared library requirement `~> 1.18`. |
| Erlang/OTP | CI: OTP 28; supported floor 27 | BEAM runtime compatibility proof | CI runs both current and minimum Elixir/OTP lanes; retain that contract rather than adding a version manager or second compatibility service. |
| GitHub Actions | SHA-pinned actions: checkout 7.0.1, cache 6.1.0, upload-artifact 7, download-artifact 8, setup-beam 1.24.1 | Required CI, release, dependency review, supplemental conformance | Existing workflows cover canonical gates and use immutable full-SHA action references. GitHub's security guidance identifies a full commit SHA as the immutable action reference. |
| GitHub CLI (`gh`) | Maintainer-installed current CLI | PR/issue/run triage | The hygiene checklist already uses `gh pr list`, `gh issue list`, and `gh run list`; these official commands support repo, state, branch/workflow, and JSON filtering. |
| Git + Git worktrees | Git-native | Local state, refs, tags, worktrees | The existing hygiene script checks working-tree state, main divergence, worktrees, and release-prep branches. No wrapper or GUI is required. |

### Supporting Libraries

| Library | Current locked version | Purpose | When to Use |
|---------|------------------------|---------|-------------|
| Credo | 1.7.18 | Strict Elixir static analysis | Through `mix qa` / `scripts/ci/run_credo.sh`; retain its zero-warning contributor role. |
| Dialyxir | 1.4.7 | Dialyzer integration | Through the existing dedicated CI job and `mix qa.dialyzer`; run when type-level regressions are suspected. |
| Sobelow | 0.14.1 | Router-focused Phoenix security checks | Through `mix qa`; the open Dependabot PR #88 is the evidence-led path for evaluating 0.15.0. |
| MixAudit | 2.1.5 | Retired/CVE dependency audit | Through `mix deps.audit`, already included in `mix ci`. |
| ExDoc | 0.40.3 | Warning-as-error API/documentation build | Through `mix docs.verify`; retain it as release-preflight evidence. |
| Release Please | 17.11.2, checked-in Node runtime | Version/changelog/release PR bookkeeping | Keep the repository-controlled composite action and lockfile. Protected exact-SHA release workflow remains the publisher. |
| actionlint + ShellCheck | actionlint 1.7.12; ShellCheck 0.11.0 | Workflow and maintained shell validation | Keep `scripts/ci/lint_workflows.sh`, which checksum-verifies downloaded Linux tools before linting. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `mix ci` | Default local contributor gate | Runs QA, docs, dependency audit, package build, fast tests, and integration tests. Use after repository cleanup; it is intentionally broader than a formatter/linter command. |
| `bash ./scripts/maintainer/repo_hygiene_check.sh` | Local Git, worktree, GitHub, release-truth, demo-artifact, and `mix ci` disposition | The pre-milestone/release command. `--ci` is intentionally Docker-daemon-free and verifies only repo-owned source contracts. |
| `bash scripts/ci/lint_workflows.sh` | GitHub Actions and shell-script linting | Already executed by the CI release-hygiene job. Do not install its tools globally or add a Node lint framework. |
| `mix release.preflight` | Package, publish dry run, docs verification | Use only when release evidence is being reconciled; publishing remains exclusively in the protected release lane. |
| `gh pr list`, `gh issue list`, `gh run list` | Explicit remote triage | Use the commands in `.planning/REPO-HYGIENE-CHECKLIST.md`; do not automate closure or merge decisions. |

## Integration and Verification Commands

```bash
# Refresh and inspect intentional local state
git fetch --prune --tags origin
git status --short --branch
git worktree list --porcelain

# Run the established quality and hygiene gates
mix ci
bash ./scripts/maintainer/repo_hygiene_check.sh

# Narrow diagnosis only when a relevant gate fails
mix qa
mix qa.dialyzer
mix docs.verify
mix deps.audit
bash scripts/ci/lint_workflows.sh
mix release.preflight

# Explicit GitHub triage (read-only)
gh pr list -R szTheory/lockspire --state open
gh issue list -R szTheory/lockspire --state open
gh run list -R szTheory/lockspire --workflow ci.yml --branch main
gh run list -R szTheory/lockspire --workflow release.yml --branch main
```

`mix ci` is the default quality gate. `repo_hygiene_check.sh` should run immediately after it because it verifies planning and release evidence that Mix cannot know. Do not convert the supplemental `oidf-conformance.yml` workflow into a required repository gate: its immutable suite receipts intentionally remain non-certifying evidence and may retain classified suite failures.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Existing GitHub Actions plus SHA pins and actionlint | A new hosted CI/security platform | Only after evidence that GitHub Actions cannot express a required repository-owned gate; none exists. |
| Existing Mix aliases, Credo, Dialyxir, Sobelow, MixAudit, ExDoc | A new umbrella Elixir quality framework | Never for v1.38. It would duplicate already executable checks and create policy drift. |
| `gh` plus the checklist | A GitHub SDK, custom triage bot, or bulk-close automation | Only if repeatable remote triage becomes a separately authorized product/operations concern. Current open PRs need human disposition. |
| Release Please + exact-ref protected release | Manual version/changelog bumps or a second publisher | Never. The hygiene contract explicitly forbids manual `mix.exs`, manifest, or changelog bumps outside the release process. |
| Bounded dependency PR review | Wholesale dependency refresh | Review #86--88 and #90--91 independently with lockfile, compatibility, CI, and release-truth evidence. In particular, Oban 2.21.1 → 2.23.1 is a minor-line change and is not a baseline-wide upgrade authorization. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| New OAuth/OIDC or Phoenix runtime dependency | v1.38 excludes protocol/host-seam/feature work. | Existing application stack; fix only evidenced maintenance defects. |
| GitHub bot or automated PR/issue closure | Open PR disposition is an intentional maintainer decision; automatic actions could close active dependency updates or stale history incorrectly. | `gh` inspection plus documented close/merge/defer rationale. |
| Required OIDF/FAPI certification gate | Existing supplemental receipts are honestly non-certifying and may fail due to classified suite findings. | Keep `oidf-conformance.yml` supplemental and retain receipts. |
| Docker-dependent CI hygiene | The repo's `--ci` hygiene path is deliberately daemon-free. | Source-contract checks in `repo_hygiene_check.sh --ci`; reserve Docker checks for local demo lifecycle. |
| Manual release versioning/publishing | It breaks the manifest-bound exact-CI release proof. | Release Please bookkeeping and protected exact-ref `release.yml`. |
| Broad refactor or dependency-upgrade campaign | The milestone is bounded cleanup, and CI already identifies concrete PR candidates. | Address only a proven blocker, regression, contradiction, stale actionable artifact, or small gap. |

## Stack Patterns by Variant

**If a local gate fails:**

- Run the smallest existing alias or script that owns the failure, then return to `mix ci` and the hygiene check.
- Because parallel new tooling would obscure the regression signal and duplicate CI policy.

**If an external dependency update is assessed:**

- Start from its open Dependabot PR and existing lockfile; verify compatibility and run the existing CI/release-hygiene checks before merge.
- Because the supported Elixir/OTP floors and exact release artifact are already tested by the repository pipeline.

**If the OIDF workflow reports failures:**

- Preserve/triage its redacted immutable receipt as supplemental evidence; do not reclassify it as a required green gate without a separate conformance milestone.
- Because the project records explicitly limit it to non-certifying comparison evidence.

## Version Compatibility

| Package / Tool | Compatible With | Notes |
|----------------|-----------------|-------|
| Lockspire `elixir ~> 1.18` | CI 1.19.5 / OTP 28; minimum CI 1.18.4 / OTP 27 | The current and floor lanes are the executable compatibility contract. |
| Phoenix `~> 1.8.5` | Locked 1.8.13 | Runtime stack already resolves the maintained Phoenix line. |
| Phoenix LiveView `>= 1.1.28 and < 2.0.0` | Locked 1.2.10; compatibility fixture for 1.1 | The broad supported range is deliberate host-library compatibility, not a reason to pin all adopters to 1.2. |
| Oban `~> 2.21.0` | Locked 2.21.1; PR #86 proposes 2.23.1 | Evaluate as one bounded update: it changes the accepted minor line under `~> 2.21.0`. |
| Req `~> 0.5` | Locked 0.7.1; PR #90 proposes 0.7.3 | Candidate update is already isolated in Dependabot; assess with existing tests. |

## Sources

- [Repository `mix.exs`](../../mix.exs) and [lockfile](../../mix.lock) — current aliases, dependency constraints, and resolved versions (repository evidence; HIGH).
- [CI workflow](../../.github/workflows/ci.yml), [release workflow](../../.github/workflows/release.yml), [dependency review](../../.github/workflows/dependency-review.yml), and [supplemental conformance workflow](../../.github/workflows/oidf-conformance.yml) — current integration points (repository evidence; HIGH).
- [Repository hygiene checklist](../REPO-HYGIENE-CHECKLIST.md) and [hygiene script](../../scripts/maintainer/repo_hygiene_check.sh) — required commands and scope (repository evidence; HIGH).
- [GitHub Actions secure-use reference](https://docs.github.com/en/actions/reference/security/secure-use?learn=getting_started&learnProduct=actions) — full-length SHA pinning guidance (official; MEDIUM from verified research seam).
- [GitHub CLI `gh run list`](https://cli.github.com/manual/gh_run_list), [issue list](https://cli.github.com/manual/gh_issue_list), and [pull request commands](https://cli.github.com/manual/gh_pr) — current triage command capabilities (official; MEDIUM from verified research seam).

---
*Stack research for: Lockspire v1.38 Repository Baseline & Reconciliation*
*Researched: 2026-08-28*
