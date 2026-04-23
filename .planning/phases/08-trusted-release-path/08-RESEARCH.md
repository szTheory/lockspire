# Phase 08: Trusted Release Path - Research

**Researched:** 2026-04-23
**Domain:** GitHub Actions protected release automation for an Elixir/Hex library [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] [CITED: https://github.com/googleapis/release-please]
**Confidence:** MEDIUM-HIGH [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Trusted publish proof
- **D-01:** The protected `hex-publish` GitHub environment is the only canonical proof of the trusted release path. Local maintainer checks are informative, but they are not authoritative release proof.
- **D-02:** `mix release.preflight` must keep running inside the protected publish job with the real `HEX_API_KEY` wiring. The trusted-path proof is the environment-gated workflow execution, not an equivalent local dry-run story.
- **D-03:** Lockspire should not add PyPI-style trusted-publishing overlays, provenance experiments, or other non-native supply-chain patterns in Phase 8. Hex API-key publishing inside a protected environment is the idiomatic current fit.

### Publish trigger posture
- **D-04:** Keep one release workflow chained from Release Please. When `release_created == true`, the workflow should advance to the publish lane rather than split into a second manual publish flow.
- **D-05:** The human hold point belongs at the protected `hex-publish` environment boundary, not in a separate workflow. Require environment approval before the authenticated preflight and `mix hex.publish --yes` steps run.
- **D-06:** `workflow_dispatch` may exist only as a recovery path. It must not become a second normal publish story or an easier bypass around the protected environment rules.
- **D-07:** Environment protections should be treated as part of the product contract: required reviewers, no self-review, and branch or tag restrictions tight enough that publish intent is explicit and auditable.

### Drift enforcement scope
- **D-08:** Release-readiness enforcement should stay narrow and executable. Contract checks should fail on critical release-path invariants, not on broad wording or YAML-shape trivia.
- **D-09:** The critical invariants for automation are: `mix ci` remains the contributor gate, the publish job targets `hex-publish`, `mix release.preflight` runs in that protected environment with `HEX_API_KEY`, and publish still happens via `mix hex.publish --yes`.
- **D-10:** Docs may keep coarse posture checks, but Phase 8 should reject brittle release tests that freeze exact action SHAs, exact prose wording, or non-risk-bearing workflow details into a large drift suite.

### Maintainer runbook shape
- **D-11:** The maintainer guide should stay compact and review-focused, but it must become evidence-driven. Each stop/go point should name the repo artifact or workflow evidence that proves the release is safe to continue.
- **D-12:** The guide should keep one canonical maintainer story: review the Release Please PR, verify the required repo-owned evidence, approve the protected environment deployment, and let the trusted workflow publish.
- **D-13:** The runbook must not ask maintainers to prove secret-gated steps locally. Any checklist item that depends on trusted credentials should point back to the protected workflow evidence instead.
- **D-14:** Hold points should explicitly cover claim drift across public docs, maintainer docs, workflow shape, and package metadata, but avoid turning the guide into a heavyweight ops playbook.

### Metadata and release ownership
- **D-15:** `mix.exs` remains the authoritative human-edited source for package metadata and version-bearing package fields. Lockspire should not introduce a second human-owned package metadata file.
- **D-16:** Add minimal checked-in Release Please configuration only for automation policy, not for package ownership. The purpose is to make preview-release behavior explicit and reviewable.
- **D-17:** During `v0.x` preview, release automation should encode pre-`1.0` versioning policy explicitly, including `bump-minor-pre-major: true`, so breaking preview releases do not surprise maintainers with an accidental `1.0` jump.
- **D-18:** If extra release config files are added, docs and contract checks should treat them as automation-owned policy artifacts. Maintainers should not hand-edit manifest state casually outside the normal release flow.

### Cohesive Phase 8 posture
- **D-19:** The coherent release story for Lockspire is: one Release Please driven path, one protected environment approval gate, one authenticated preflight inside that gate, one Hex publish command, and one concise maintainer runbook that points back to repo truth.
- **D-20:** Prefer least surprise over maximum ceremony. Lockspire should be stricter than a casual Elixir library because it is a security-sensitive auth library, but that strictness should live at the real trust boundary rather than in duplicated process.

### Claude's Discretion
- Exact contract-test implementation shape, as long as it enforces only the release invariants that materially affect trust.
- Exact Release Please config layout, as long as `mix.exs` remains package truth and pre-`1.0` versioning policy becomes explicit and reviewable.
- Exact wording and structure of maintainer evidence bullets, as long as they stay concise, auditable, and aligned with the protected publish path.

### Deferred Ideas (OUT OF SCOPE)
- PyPI-style trusted publishing, attestations, or provenance overlays before Hex supports a first-class equivalent story.
- A separate manual publish workflow or promotion workflow as a normal release path.
- A heavyweight release ops playbook with multi-stage recovery drills, signing procedures, or compliance-style evidence packs.
- A second human-edited release metadata file outside `mix.exs`.
- Broad YAML- and prose-freezing release drift suites that optimize for paper auditability over maintainer signal.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RELS-01 | The trusted release workflow runs `mix release.preflight` inside the protected `hex-publish` environment with the required credentials wired through environment secrets. | Protected-environment approvals unlock environment secrets only after review, so the canonical publish proof should stay as one workflow with one gated publish job. [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] |
| RELS-02 | Maintainer-facing release guidance references only real commands and the trusted publish path used by the repo. | The runbook should point to `mix ci`, the Release Please PR diff, and the approved protected deployment evidence rather than asking for local secret-gated proof. [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| RELS-03 | Release automation and package metadata remain pinned and reviewable enough that a preview release can be published without undocumented manual steps. | Release Please manifest config is the standard place for advanced policy such as pre-1.0 bump handling, while `mix.exs` remains package truth for the Elixir releaser. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
</phase_requirements>

## Summary

Lockspire already has the correct backbone for Phase 8: one `release.yml` workflow, a `release_created` gate from Release Please, a dedicated publish job, `environment: hex-publish`, `mix release.preflight`, and `mix hex.publish --yes`. [VERIFIED: repo grep] The missing hardening is mostly policy visibility and trust-boundary discipline, not a new release mechanism. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

GitHub environments are the right approval boundary for this phase because jobs waiting on required reviewers do not receive environment secrets until approval, and GitHub can prevent self-approval and restrict eligible deployment refs. [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments] That matches the locked Phase 8 posture better than a second manual publish workflow or local maintainer dry-run ceremony. [VERIFIED: repo grep]

The strongest planning move is to keep one release lane but make its policy explicit and test only the narrow invariants that affect trust: Release Please still owns release PR/tag/release creation, the publish job still targets `hex-publish`, `HEX_API_KEY` still enters only through the protected environment, `mix.exs` remains metadata truth, and maintainer docs point to release PR and protected-run evidence instead of prose-heavy checklists. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html]

**Primary recommendation:** Add minimal checked-in Release Please manifest policy, keep the single protected publish workflow, rewrite the maintainer guide around evidence checkpoints, and narrow the contract test to semantic release invariants instead of wording or SHA churn. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version bump, changelog, tag, GitHub release creation | GitHub Actions / Release Please [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please] | Repository source [VERIFIED: repo grep] | Release Please is designed to update release files and create tagged releases from Conventional Commits; repo files remain reviewable inputs. [CITED: https://github.com/googleapis/release-please] |
| Package metadata truth | Repository source (`mix.exs`) [VERIFIED: repo grep] | Release Please Elixir strategy [CITED: https://github.com/googleapis/release-please] | The Elixir strategy works from `mix.exs`, and Phase 8 explicitly forbids a second human-owned metadata source. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please] |
| Publish approval and secret access | GitHub protected environment [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] | GitHub workflow job [VERIFIED: repo grep] | Required reviewers and environment-secret release happen at the environment boundary, not in local shells. [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] |
| Package build and publish | Mix/Hex inside CI [VERIFIED: repo grep] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Hex registry [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | `mix hex.publish --yes` is the noninteractive Hex publish path, and docs publishing is automatic from Hex publish. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Drift detection for release invariants | ExUnit contract test [VERIFIED: repo grep] | Docs/workflow source files [VERIFIED: repo grep] | Lockspire already uses a repo-owned contract test; Phase 8 should narrow it to trust-bearing invariants. [VERIFIED: repo grep] |
| Maintainer release evidence | Docs + GitHub workflow run evidence [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] | Release Please PR/release artifacts [CITED: https://github.com/googleapis/release-please-action] | The runbook should cite repo truth and approved protected-run evidence, not undocumented local ritual. [VERIFIED: repo grep] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GitHub Actions protected environment `hex-publish` | repo policy, not package version [VERIFIED: repo grep] | Approval boundary and environment-secret boundary for publish [VERIFIED: repo grep] | GitHub environments support required reviewers, prevent self-review, and gate environment secrets until approval. [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments] |
| `googleapis/release-please-action` | pinned in repo at commit `16a9c90856f42705d54a6fda1823352bdc62cf38` (`v4.4.0` comment) [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please-action/releases] | Single-lane release PR/tag/release automation [VERIFIED: repo grep] | Official action exposes `release_created` and supports manifest config for advanced policy. [CITED: https://github.com/googleapis/release-please-action] |
| Release Please manifest policy files | `release-please-config.json` + `.release-please-manifest.json` layout [CITED: https://github.com/googleapis/release-please-action] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] | Checked-in release policy for pre-1.0 behavior and single-component config [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] | Advanced Release Please options are documented in manifest config, not action inputs. [CITED: https://github.com/googleapis/release-please-action] |
| Mix aliases in `mix.exs` | `0.1.0` package metadata and current aliases from repo [VERIFIED: repo grep] | Human-edited package metadata and release command truth [VERIFIED: repo grep] | The Elixir release type updates `mix.exs`, and Hex project config can read `HEX_API_KEY` from env or project config. [CITED: https://github.com/googleapis/release-please] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html] |
| Hex publish via `mix hex.publish --yes` | Hex docs current at v2.2.1 [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Noninteractive package publish inside CI [VERIFIED: repo grep] | Hex documents `--yes`, `--dry-run`, and automatic docs publishing as the standard package release path. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `actions/checkout` | pinned in repo at `de0fac2e4500dabe0009e67214ff5f5447ce83dd` (`v6.0.2` comment) [VERIFIED: repo grep] [CITED: https://github.com/actions/checkout/releases] | Immutable checkout for CI jobs [VERIFIED: repo grep] | Keep pinned in CI and release workflows; do not make it a contract-test invariant for Phase 8. [VERIFIED: repo grep] |
| `erlef/setup-beam` | pinned in repo at `8d44588995e53ce789721e96227122a67826542d` (`v1.24.0` comment) [VERIFIED: repo grep] | Deterministic Elixir/OTP setup in CI [VERIFIED: repo grep] | Keep exact version pinning; repo currently runs Elixir `1.19.5` and OTP `28` in CI. [VERIFIED: repo grep] |
| `actions/cache` | pinned in repo at `0400d5f644dc74513175e3cd8d07132dd4860809` (`v4.2.4` comment) [VERIFIED: repo grep] | Cache Mix deps/build outputs [VERIFIED: repo grep] | Keep v4+ because GitHub deprecated older cache service paths and recommends v4 or v3 for pinned SHAs. [CITED: https://github.com/actions/cache] |
| `gh` CLI | local `2.89.0` in this environment [VERIFIED: command - gh --version] | Convenient retrieval of workflow-run evidence during maintenance [VERIFIED: command - gh --version] | Optional for maintainers; helpful for linking approved deploy runs in the runbook. [VERIFIED: command - gh --version] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Release Please manifest policy | Action-input-only Release Please config [VERIFIED: repo grep] | Action inputs hide pre-1.0 bump policy in workflow YAML; manifest config is the documented path for advanced configuration and is easier to review narrowly. [CITED: https://github.com/googleapis/release-please-action] |
| Protected environment approval in the publish job | Separate manual publish workflow [VERIFIED: repo grep] | A second workflow creates a shadow normal path and contradicts the locked single-lane posture. [VERIFIED: repo grep] |
| Narrow invariant contract tests | Broad prose/SHA snapshot tests [VERIFIED: repo grep] | Broad snapshots generate false failures on harmless action bumps and wording edits, which weakens trust signal. [VERIFIED: repo grep] |

**Installation:**
```bash
# No new runtime package is required for Phase 8.
# Add checked-in Release Please policy files only:
#   release-please-config.json
#   .release-please-manifest.json
```

**Version verification:** The repo currently pins `googleapis/release-please-action` to commit `16a9c90` with comment `v4.4.0`, `actions/checkout` to `de0fac2` with comment `v6.0.2`, and `actions/cache` to `0400d5f` with comment `v4.2.4`. [VERIFIED: repo grep] GitHub release pages confirm `release-please-action v4.4.0` and `actions/checkout v6.0.2`. [CITED: https://github.com/googleapis/release-please-action/releases] [CITED: https://github.com/actions/checkout/releases]

## Architecture Patterns

### System Architecture Diagram

```text
merged PRs on main
  -> release.yml push trigger [VERIFIED: repo grep]
  -> Release Please job updates/opens release PR or creates release [CITED: https://github.com/googleapis/release-please-action]
  -> if release_created == true [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please-action]
  -> publish job targets environment: hex-publish [VERIFIED: repo grep]
  -> required reviewer approval at environment boundary [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments]
  -> environment secrets become available to job [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments]
  -> mix release.preflight [VERIFIED: repo grep]
  -> mix hex.publish --yes [VERIFIED: repo grep] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
  -> Hex package + docs published [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
```

### Recommended Project Structure

```text
.github/workflows/
├── ci.yml                     # Contributor gate equivalent to mix ci
└── release.yml                # Canonical Release Please -> protected publish path

./
├── mix.exs                    # Package metadata and Mix alias truth
├── release-please-config.json # Checked-in automation policy only
├── .release-please-manifest.json # Checked-in release state/bootstrap artifact
├── docs/maintainer-release.md # Evidence-driven maintainer runbook
└── test/lockspire/release_readiness_contract_test.exs # Narrow release invariant checks
```

### Pattern 1: Single Workflow With Protected Publish Job
**What:** Keep Release Please and Hex publish in one workflow, and use the environment approval gate on the publish job rather than a second normal workflow. [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments]
**When to use:** Always for Lockspire preview releases. [VERIFIED: repo grep]
**Example:**
```yaml
# Source: https://github.com/googleapis/release-please-action
jobs:
  release-please:
    steps:
      - id: release
        uses: googleapis/release-please-action@v4
        with:
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json

  publish:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    environment: hex-publish
```

### Pattern 2: Explicit Pre-1.0 Release Policy In Manifest Config
**What:** Put `bump-minor-pre-major: true` in checked-in Release Please policy so preview breaking changes stay in `0.x`. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
**When to use:** While Lockspire remains `v0.x` preview. [VERIFIED: repo grep]
**Example:**
```json
// Source: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
{
  "release-type": "elixir",
  "bump-minor-pre-major": true,
  "packages": {
    ".": {
      "package-name": "lockspire"
    }
  }
}
```

### Pattern 3: Evidence-Driven Maintainer Runbook
**What:** Each checklist item should point to repo truth or a workflow-run artifact, not to unverifiable local secret-dependent steps. [VERIFIED: repo grep]
**When to use:** In `docs/maintainer-release.md` and any future release incident note. [VERIFIED: repo grep]
**Example:**
```markdown
- Verify `mix ci` is green on the commit that produced the release PR. [VERIFIED: repo grep]
- Review the Release Please PR diff for `mix.exs` and `CHANGELOG.md`. [VERIFIED: repo grep]
- Approve the pending `hex-publish` environment deployment in the Release workflow. [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments]
- Treat the approved publish run as the only proof of authenticated `mix release.preflight`. [VERIFIED: repo grep]
```

### Anti-Patterns to Avoid

- **Shadow publish lane:** Do not let `workflow_dispatch` become a parallel normal publish story. [VERIFIED: repo grep]
- **Policy hidden in defaults:** Do not rely on Release Please defaults for pre-1.0 bump behavior. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
- **Credential proof in local docs:** Do not ask maintainers to prove `HEX_API_KEY`-gated steps locally. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html]
- **Brittle drift suite:** Do not freeze exact prose wording or exact action SHAs in the Phase 8 release contract test. [VERIFIED: repo grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release PR/version/changelog logic | Custom Mix release script or ad hoc git-tagging shell [VERIFIED: repo grep] | Release Please Elixir releaser + manifest config [CITED: https://github.com/googleapis/release-please] [CITED: https://github.com/googleapis/release-please-action] | Release Please already owns the release PR/tag/release lifecycle and exposes the outputs Lockspire needs. [CITED: https://github.com/googleapis/release-please-action] |
| Publish approval system | Manual checklist-only approval or second workflow [VERIFIED: repo grep] | GitHub protected environment reviewers and branch/tag restrictions [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments] | GitHub already provides reviewer gates, no-self-review, and restricted refs. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments] |
| Hex credential storage | Checked-in key files or maintainer-local required auth state [VERIFIED: repo grep] | Environment secret `HEX_API_KEY` consumed in CI only [VERIFIED: repo grep] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html] | Hex supports env override for API key, and GitHub environment secrets are only released after approval. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] |
| Release drift test framework | Full YAML/prose snapshotting [VERIFIED: repo grep] | Narrow file-content invariants around environment, commands, and metadata truth [VERIFIED: repo grep] | Trust regressions are semantic; wording churn and action bumps should not break Phase 8 tests. [VERIFIED: repo grep] |

**Key insight:** The dangerous parts here are approval boundary integrity, secret boundary integrity, and release-policy visibility, not changelog cosmetics. [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments] [CITED: https://github.com/googleapis/release-please-action]

## Common Pitfalls

### Pitfall 1: `workflow_dispatch` Becomes The Real Publish Lane
**What goes wrong:** Maintainers start treating manual dispatch as normal publish flow. [VERIFIED: repo grep]
**Why it happens:** The workflow already exposes `workflow_dispatch`, and GitHub makes reruns/manual starts easy. [VERIFIED: repo grep]
**How to avoid:** Keep it documented as recovery-only and keep the publish job behind the same protected environment. [VERIFIED: repo grep] [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments]
**Warning signs:** Runbook steps say “run the publish workflow manually” without first referencing a Release Please release event or recovery condition. [VERIFIED: repo grep]

### Pitfall 2: Release Please Defaults Hide Preview Versioning Policy
**What goes wrong:** A breaking preview release can bump unexpectedly if policy is implicit. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
**Why it happens:** Advanced policy now belongs in manifest config rather than action inputs. [CITED: https://github.com/googleapis/release-please-action]
**How to avoid:** Check in manifest policy with `bump-minor-pre-major: true` while Lockspire stays at `0.x`. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
**Warning signs:** No checked-in Release Please config file exists even though preview release policy is discussed in docs. [VERIFIED: repo grep]

### Pitfall 3: Contract Tests Fail On Harmless Churn
**What goes wrong:** Action SHA bumps or minor prose edits break tests unrelated to release trust. [VERIFIED: repo grep]
**Why it happens:** The current contract test asserts exact pinned action strings and exact doc phrases. [VERIFIED: repo grep]
**How to avoid:** Assert only release invariants: canonical gate command, protected environment, authenticated preflight, publish command, manifest-policy file presence, and metadata truth. [VERIFIED: repo grep]
**Warning signs:** A Dependabot action bump fails the release-readiness contract test even though the release path is still safe. [VERIFIED: repo grep]

### Pitfall 4: Maintainer Runbook Asks For Impossible Local Proof
**What goes wrong:** Docs imply local dry-runs are equivalent to protected publish proof. [VERIFIED: repo grep]
**Why it happens:** `mix package.publish-dry-run` is a real command, so it is tempting to over-document it outside the CI trust boundary. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
**How to avoid:** Keep local proof limited to repo-owned checks and point secret-bound steps back to the approved CI run. [VERIFIED: repo grep]
**Warning signs:** The guide tells maintainers to acquire or test `HEX_API_KEY` locally as part of the normal release path. [VERIFIED: repo grep]

### Pitfall 5: Release PR Checks Do Not Auto-Run
**What goes wrong:** The release PR can be reviewable but not automatically checked if Release Please uses the default `GITHUB_TOKEN`. [CITED: https://github.com/googleapis/release-please-action] [CITED: https://docs.github.com/actions/concepts/security/github_token]
**Why it happens:** GitHub suppresses new workflow runs for most events created by `GITHUB_TOKEN`. [CITED: https://docs.github.com/actions/concepts/security/github_token]
**How to avoid:** Decide explicitly whether Lockspire requires CI on the Release Please PR; if yes, use a narrow token that can trigger workflows. [CITED: https://github.com/googleapis/release-please-action]
**Warning signs:** Release PRs appear without CI checks even though normal contributor PRs require them. [CITED: https://github.com/googleapis/release-please-action]

## Code Examples

Verified patterns from official sources:

### Release Please Output-Gated Publish
```yaml
# Source: https://github.com/googleapis/release-please-action
- uses: googleapis/release-please-action@v4
  id: release

- name: Publish
  if: ${{ steps.release.outputs.release_created }}
  run: echo "${{ steps.release.outputs.tag_name }}"
```

### GitHub Environment Approval Semantics
```text
# Source: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments
pending job -> reviewer approves deployment -> job proceeds -> environment secrets become accessible
```

### Hex Noninteractive Publish And Dry Run
```bash
# Source: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html
mix hex.publish --dry-run --yes
mix hex.publish --yes
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Advanced Release Please behavior configured in workflow inputs | Advanced behavior configured in manifest config files [CITED: https://github.com/googleapis/release-please-action] | Current v4 guidance in the action README and manifest docs [CITED: https://github.com/googleapis/release-please-action] | Phase 8 should add explicit config files rather than overloading `release.yml`. [CITED: https://github.com/googleapis/release-please-action] |
| Broad cache-action legacy versions | `actions/cache` v4 or v3 recommended for the current cache service [CITED: https://github.com/actions/cache] | GitHub announced the cache-service migration for February 2025. [CITED: https://github.com/actions/cache] | Lockspire’s current v4 pin is on the safe side and should stay pin-based. [VERIFIED: repo grep] [CITED: https://github.com/actions/cache] |
| Manual library release instructions are common in Elixir OSS [ASSUMED] | Lockspire already uses reviewable Release Please + protected Hex publish [VERIFIED: repo grep] | Repo posture as of 2026-04-23 [VERIFIED: repo grep] | The remaining gap is hardening and alignment, not adopting an entirely new release model. [VERIFIED: repo grep] |

**Deprecated/outdated:**
- Action-input-only advanced Release Please policy: outdated for current advanced configuration guidance. [CITED: https://github.com/googleapis/release-please-action]
- Release-readiness tests that lock exact action SHAs as trust invariants: outdated for this phase because they create high-noise failures. [VERIFIED: repo grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Manual library release instructions are still common across Elixir OSS maintainers. [ASSUMED] | State of the Art | Low; Lockspire’s plan still stays within repo-specific evidence and official platform behavior. |

## Open Questions

1. **Does Lockspire require automatic CI on the Release Please PR itself?**
   - What we know: The current workflow does not pass a custom token to Release Please, and the action docs say resources created with the default `GITHUB_TOKEN` do not trigger future workflow runs except `workflow_dispatch` and `repository_dispatch`. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://docs.github.com/actions/concepts/security/github_token]
   - What's unclear: Whether maintainers are satisfied reviewing the release PR diff without automatic PR checks on that generated PR. [VERIFIED: repo grep]
   - Recommendation: Decide this in plan `08-01`; if CI-on-release-PR is required, add a narrow GitHub token secret for Release Please, otherwise document the exact review evidence expected before merge. [CITED: https://github.com/googleapis/release-please-action]

2. **What exact branch/tag restriction should the `hex-publish` environment enforce?**
   - What we know: GitHub environments can restrict deployment to protected branches or selected branch/tag patterns. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments]
   - What's unclear: Whether Lockspire wants `main`-only, release-tag-only, or a small selected-pattern policy during preview. [VERIFIED: repo grep]
   - Recommendation: Decide this in plan `08-01` and then encode it in both runbook evidence and narrow contract assertions. [VERIFIED: repo grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | `mix release.preflight`, package build, contract tests [VERIFIED: repo grep] | ✓ [VERIFIED: command - mix --version] | local toolchain present with OTP 28 in this shell [VERIFIED: command - mix --version] | — |
| `elixir` | local verification and test execution [VERIFIED: repo grep] | ✓ [VERIFIED: command - elixir --version] | local toolchain present with OTP 28 in this shell [VERIFIED: command - elixir --version] | — |
| `git` | release diff review and normal repo work [VERIFIED: repo grep] | ✓ [VERIFIED: command - git --version] | `2.41.0` [VERIFIED: command - git --version] | — |
| `node` / `npm` | Context7 CLI fallback used during this research [VERIFIED: command - node --version] [VERIFIED: command - npm --version] | ✓ [VERIFIED: command - node --version] | Node `v22.14.0`, npm `11.1.0` [VERIFIED: command - node --version] [VERIFIED: command - npm --version] | — |
| `gh` | optional maintainer evidence lookup [VERIFIED: command - gh --version] | ✓ [VERIFIED: command - gh --version] | `2.89.0` [VERIFIED: command - gh --version] | GitHub web UI |
| GitHub protected environment settings | RELS-01 trusted-path proof [VERIFIED: repo grep] | remote-only [VERIFIED: repo grep] | not locally inspectable in this shell [VERIFIED: repo grep] | planner must treat as human/CI verification boundary |
| `HEX_API_KEY` environment secret in `hex-publish` | RELS-01 trusted publish [VERIFIED: repo grep] | remote-only [VERIFIED: repo grep] | not locally inspectable in this shell [VERIFIED: repo grep] | none |

**Missing dependencies with no fallback:**
- Direct local inspection of GitHub environment reviewer/no-self-review/branch restriction settings and environment-secret presence. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments]

**Missing dependencies with fallback:**
- None for planning; the missing pieces are execution-time trust-boundary checks, not research blockers. [VERIFIED: repo grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit under Elixir test tooling already used by the repo [VERIFIED: repo grep] |
| Config file | none specific to this contract test; Mix test aliases in `mix.exs` are the control surface [VERIFIED: repo grep] |
| Quick run command | `mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: repo grep] |
| Full suite command | `mix ci` [VERIFIED: repo grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RELS-01 | release workflow uses `hex-publish`, `HEX_API_KEY`, `mix release.preflight`, and `mix hex.publish --yes` [VERIFIED: repo grep] | contract | `mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: repo grep] | ✅ |
| RELS-02 | maintainer doc points to `mix ci`, trusted workflow, and protected environment evidence without local secret proof [VERIFIED: repo grep] | contract | `mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: repo grep] | ✅ |
| RELS-03 | release policy is reviewable and `mix.exs` stays metadata truth while Release Please policy is explicit [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please-action] | contract | `mix test test/lockspire/release_readiness_contract_test.exs` plus file assertions for release policy files [VERIFIED: repo grep] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: repo grep]
- **Per wave merge:** `mix ci` [VERIFIED: repo grep]
- **Phase gate:** `mix ci` plus one reviewed protected-environment run artifact before `/gsd-verify-work` closure on RELS-01. [VERIFIED: repo grep]

### Wave 0 Gaps

- [ ] `release-please-config.json` — needed so pre-1.0 policy is explicit and reviewable. [CITED: https://github.com/googleapis/release-please-action] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
- [ ] `.release-please-manifest.json` — needed for manifest-mode configuration/state bootstrap. [CITED: https://github.com/googleapis/release-please-action]
- [ ] Narrower `test/lockspire/release_readiness_contract_test.exs` helpers — current test over-asserts exact action pins and doc wording. [VERIFIED: repo grep]
- [ ] Human verification artifact pattern for the protected `hex-publish` run — needed because RELS-01 crosses a real secret boundary. [VERIFIED: repo grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: repo grep] | Phase 8 does not add end-user auth behavior; it governs CI credentials. [VERIFIED: repo grep] |
| V3 Session Management | no [VERIFIED: repo grep] | Not in scope for release-path hardening. [VERIFIED: repo grep] |
| V4 Access Control | yes [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments] | GitHub environment required reviewers, no self-review, branch/tag restrictions. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments] |
| V5 Input Validation | yes [VERIFIED: repo grep] | Narrow contract tests over exact trust invariants, not free-form prose snapshots. [VERIFIED: repo grep] |
| V6 Cryptography | no [VERIFIED: repo grep] | Hex/GitHub secret transport is platform-managed; do not hand-roll signing or provenance systems in this phase. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publish without second-person review | Elevation of Privilege | Protected environment required reviewers and no self-review. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments] |
| Secret exposure outside CI | Information Disclosure | Keep `HEX_API_KEY` only in protected environment secrets and consume it via env in CI. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html] |
| Shadow manual publish path | Repudiation | One canonical workflow, `workflow_dispatch` recovery-only, contract tests for canonical commands/environment. [VERIFIED: repo grep] |
| Release policy drift causing wrong preview bump | Tampering | Checked-in manifest config with explicit pre-major bump policy. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| False-positive release blockers from brittle tests | Denial of Service | Narrow semantic invariants and avoid action-SHA/prose freeze tests. [VERIFIED: repo grep] |

## Sources

### Primary (HIGH confidence)

- [Lockspire repo files](./) - `08-CONTEXT.md`, `06-CONTEXT.md`, `07-CONTEXT.md`, `.github/workflows/release.yml`, `.github/workflows/ci.yml`, `mix.exs`, `docs/maintainer-release.md`, `test/lockspire/release_readiness_contract_test.exs`. [VERIFIED: repo grep]
- https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments - environment approvals, secret access after approval, self-approval behavior. [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments]
- https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments - required reviewers, no self-review, branch/tag restrictions, bypass behavior. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/deployments-and-environments]
- https://github.com/googleapis/release-please - supported `elixir` release type and release PR/tag/release model. [CITED: https://github.com/googleapis/release-please]
- https://github.com/googleapis/release-please-action - manifest config guidance, outputs, token behavior caveat. [CITED: https://github.com/googleapis/release-please-action]
- https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md - manifest config fields including `bump-minor-pre-major` and `release-as`. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html - `mix hex.publish --yes`, `--dry-run`, docs publishing. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html - `HEX_API_KEY` environment override precedence. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Config.html]

### Secondary (MEDIUM confidence)

- https://github.com/actions/checkout/releases - repo pin comment aligns to `v6.0.2`. [CITED: https://github.com/actions/checkout/releases]
- https://github.com/googleapis/release-please-action/releases - repo pin comment aligns to `v4.4.0`. [CITED: https://github.com/googleapis/release-please-action/releases]
- https://github.com/actions/cache - current migration guidance for cache action versions. [CITED: https://github.com/actions/cache]
- https://docs.github.com/actions/concepts/security/github_token - `GITHUB_TOKEN` does not trigger most downstream workflow runs. [CITED: https://docs.github.com/actions/concepts/security/github_token]

### Tertiary (LOW confidence)

- None. All material planning claims above were verified from repo state or official docs, except the single assumption listed in the assumptions log. [VERIFIED: repo grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo state and official platform docs align cleanly. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- Architecture: HIGH - current Lockspire workflow already matches the documented one-lane Release Please -> protected environment -> Hex pattern. [VERIFIED: repo grep]
- Pitfalls: MEDIUM - mostly strong because they come from current repo state and official GitHub/Release Please behavior, with one explicit open question around release-PR CI expectations. [VERIFIED: repo grep] [CITED: https://docs.github.com/actions/concepts/security/github_token]

**Research date:** 2026-04-23
**Valid until:** 2026-05-23 for repo-shape guidance; recheck official GitHub Actions and Release Please docs sooner if workflow policy changes materially. [VERIFIED: repo grep] [CITED: https://github.com/googleapis/release-please-action]
