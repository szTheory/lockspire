# Phase 65: Release Truth & Support Contract Reconciliation - Research

**Researched:** 2026-05-07
**Domain:** release truth, support-contract authority, and protected publish-lane reconciliation for an Elixir/Hex library
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Release Posture Baseline

- **D-01:** Converge the repo on a strict artifact-first `1.0.0` GA baseline for the embedded Phoenix library wedge.
- **D-02:** The next trusted publish from the protected release lane should be the first authoritative `1.0.0` artifact. Do not keep a long-lived mismatch where package metadata says `0.x` while support docs and tests claim `1.0.0`.
- **D-03:** Do not introduce a transitional `1.0.0-rc`, “GA-ready”, or similar limbo posture. It adds ambiguity without reducing real risk.
- **D-04:** If planning reveals a materially missing proof gap that would make `1.0.0` dishonest, the fallback is to align docs and tests back down to truthful `0.x` posture immediately rather than carry contradictory claims forward.

### Canonical Support Contract Shape

- **D-05:** `docs/supported-surface.md` is the single authoritative public support contract.
- **D-06:** `README.md` remains the public entrypoint and orientation layer only. It should summarize what Lockspire is, who it is for, and point readers to the canonical support contract rather than restating it in full.
- **D-07:** `SECURITY.md` remains subordinate to the canonical support contract. It should cover disclosure workflow and security-surface boundaries without broadening product claims.
- **D-08:** `docs/maintainer-release.md` is maintainer-facing release operations guidance, not a second public support contract.
- **D-09:** Other docs may explain install, Sigra companion use, or feature slices, but they must not independently redefine what Lockspire publicly supports.

### Changelog And Version History

- **D-10:** Preserve the published `0.1.x` and `0.2.0` history as factual release history. Do not rewrite tags, manifests, or changelog chronology to pretend earlier releases were already `1.0`.
- **D-11:** The coordinated `1.0.0` release should include an explicit changelog or release-note explanation that the public GA contract becomes authoritative with that release, rather than relying on earlier overstated doc language.
- **D-12:** Release communication should prefer truthful continuity over narrative cleanup. No retroactive history smoothing.

### Proof Boundary For Release Claims

- **D-13:** Public release and support claims should depend first on checked-in repo proof:
  - package version metadata
  - changelog posture
  - canonical support docs
  - checked-in release workflow and release config
  - executable release-contract tests
- **D-14:** GitHub protected-environment settings, secret placement, bypass posture, and successful trusted publish runs remain maintainer evidence. They support the release story but should not become a broad public support promise that depends on live operational state outside git.
- **D-15:** A narrow per-release proof artifact is acceptable if it strengthens least-surprise release truth, but it must stay supplemental:
  - it must not become a second public support contract
  - it must not claim live environment guarantees it cannot itself prove
  - it should be schema-testable and tightly scoped to release-lane execution facts
- **D-16:** Release-contract tests should enforce the hierarchy directly: canonical support contract first, maintainer evidence second, no contradictory version or posture language across docs, metadata, and workflow contracts.

### Workflow Preference

- **D-17:** For Phase 65 and adjacent adoption-truth work, shift medium-impact decision pressure left inside GSD researcher/planner flows. Default to decisive recommendation bundles rather than surfacing option menus for documentation structure, test shape, or release-automation details.
- **D-18:** Escalate to the user only for decisions that materially change product boundary, security posture, release posture, or public API/support guarantees.

### Claude's Discretion

- Exact wording for GA, support, and non-claim language across README, SECURITY, and maintainer docs.
- Exact shape of any supplemental per-release proof artifact, if one is added.
- Exact contract-test structure, file organization, and assertion granularity.
- Exact changelog phrasing for the `1.0.0` transition note, provided it preserves factual `0.x` history and makes the release-truth shift explicit.

### Deferred Ideas (OUT OF SCOPE)

- Turning Lockspire’s release posture into a broader audited compliance or attestation program
- Creating a machine-generated schema as the primary human-facing support contract
- Broad enterprise marketing or certification language beyond the repo-proven embedded Phoenix surface
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUTH-01 | Package versioning, changelog, release automation, and support docs agree on Lockspire's actual public release posture. | Version-truth inventory, artifact-first release pattern, Release Please manifest guidance, protected publish-lane mapping, and new contract-test gaps below. [VERIFIED: mix.exs, CHANGELOG.md, .release-please-manifest.json, .github/workflows/release.yml, test/lockspire/release_readiness_contract_test.exs] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| TRUTH-02 | README, SECURITY, supported-surface docs, and release-contract tests describe only the embedded behaviors the repo can prove today and explicitly exclude unsupported host shapes or protocol claims. | Support-authority hierarchy, doc-role decomposition, current cross-file wording audit, and executable drift-fence recommendations below. [VERIFIED: README.md, SECURITY.md, docs/supported-surface.md, docs/maintainer-release.md, test/lockspire/release_readiness_contract_test.exs] |
</phase_requirements>

## Summary

Lockspire currently has a real release-truth contradiction: `mix.exs` still declares `0.2.0`, `.release-please-manifest.json` still records `0.2.0`, `CHANGELOG.md` stops at `0.2.0`, Hex reports recent releases `0.2.0` and `0.1.2`, and the remote Git tags stop at `lockspire-v0.2.0`. [VERIFIED: mix.exs, .release-please-manifest.json, CHANGELOG.md, mix hex.info lockspire, git ls-remote --tags origin 'refs/tags/lockspire-v*']

At the same time, the public docs and the current release-contract test suite already speak in `1.0.0` / `1.0 GA` terms: `README.md` says “What v1.0 includes,” `docs/supported-surface.md` calls `1.0.0` a GA release, `docs/maintainer-release.md` says the release lane stays inside the `1.0 GA` support contract, and `test/lockspire/release_readiness_contract_test.exs` asserts that wording but does not compare those claims against `mix.exs`, the release manifest, or the published Hex version. [VERIFIED: README.md, docs/supported-surface.md, docs/maintainer-release.md, test/lockspire/release_readiness_contract_test.exs, mix test test/lockspire/release_readiness_contract_test.exs]

Release automation itself is structurally sound for an artifact-first story: the checked-in workflow uses Release Please in manifest mode, publishes only from a protected `hex-publish` environment after `mix release.preflight`, and keeps `workflow_dispatch` recovery-only with immutable-ref validation. Release Please’s official docs match that shape: the Elixir strategy operates on `mix.exs` and `CHANGELOG.md`, and manifest mode uses `.release-please-manifest.json` as the tracked current version. [VERIFIED: .github/workflows/release.yml, .github/actions/release-please/action.yml, .github/actions/release-please/runtime/index.js] [CITED: https://github.com/googleapis/release-please] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]

**Primary recommendation:** Plan Phase 65 as an artifact-first `1.0.0` convergence phase: make the next trusted release the first authoritative `1.0.0` artifact, tighten doc authority around `docs/supported-surface.md`, and extend the release-contract tests so they fail on any future `0.x` vs `1.0.0` drift. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Package version truth | Repository metadata (`mix.exs`) | Release Please manifest | Release Please’s Elixir strategy updates `mix.exs` and `CHANGELOG.md`, while manifest mode records the tracked current version in `.release-please-manifest.json`. [VERIFIED: mix.exs, .release-please-manifest.json] [CITED: https://github.com/googleapis/release-please] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| Public support contract | `docs/supported-surface.md` | README, SECURITY | The phase context explicitly locks `docs/supported-surface.md` as the canonical contract and demotes README/SECURITY to entrypoint and subordinate policy roles. [VERIFIED: .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md, README.md, SECURITY.md, docs/supported-surface.md] |
| Maintainer release operations | `.github/workflows/release.yml` | `docs/maintainer-release.md` | The workflow is the executable lane; the maintainer guide explains its evidence buckets and recovery-only dispatch posture. [VERIFIED: .github/workflows/release.yml, docs/maintainer-release.md, test/lockspire/release_readiness_contract_test.exs] |
| Trusted publish proof | GitHub Actions protected environment | Hex package registry | The workflow references `environment: hex-publish`, and GitHub environments are the mechanism that gates jobs and environment secrets before runner access; the resulting Hex artifact is the public proof consumers actually install. [VERIFIED: .github/workflows/release.yml, mix hex.info lockspire] [CITED: https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments] |
| Drift detection | ExUnit contract tests | CI workflow | Current release-truth checks live in `test/lockspire/release_readiness_contract_test.exs`, and `mix ci` plus CI workflow wiring are the maintained contributor lane that should enforce them. [VERIFIED: test/lockspire/release_readiness_contract_test.exs, mix.exs, .github/workflows/ci.yml] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `release-please` | Repo pin `17.3.0`; npm latest `17.6.0` published 2026-04-13 | SemVer bumping, changelog updates, release PRs, and GitHub release tagging | Manifest-mode Release Please is already the repo’s checked-in version orchestrator; Phase 65 should reconcile truth through it rather than replace it. [VERIFIED: .github/actions/release-please/runtime/package.json] [VERIFIED: npm registry via `npm view release-please version time --json`] [CITED: https://github.com/googleapis/release-please] |
| GitHub Actions environments | Docs current as crawled 2026-04 | Protected publish boundary for `HEX_API_KEY` and branch/review restrictions | Environments are GitHub’s native mechanism for protected deployment jobs and environment-level secrets; Lockspire already uses `environment: hex-publish`. [VERIFIED: .github/workflows/release.yml] [CITED: https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments] |
| ExUnit | Bundled with Elixir `1.19.5` in local env | Executable contract tests for docs/workflow/version drift | The existing repo already enforces release-truth wording via ExUnit, so expanding that test suite is the least-surprise enforcement path. [VERIFIED: elixir --version, mix --version, test/test_helper.exs, test/lockspire/release_readiness_contract_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@actions/core` | Repo pin `1.10.0`; npm latest `3.0.1` | Composite-action output plumbing for the checked-in Release Please wrapper | Keep only if Lockspire continues to own the wrapper action; not central to the release-truth contradiction itself. [VERIFIED: .github/actions/release-please/runtime/package.json] [VERIFIED: npm registry via `npm view @actions/core version`] |
| `mix hex.publish` / Hex | Public Lockspire package line currently `0.2.0` | Public artifact publication and public package truth | Use as the final external truth check whenever docs or manifests claim a release state. [VERIFIED: mix.exs, mix hex.info lockspire] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Release Please manifest mode | Manual version bumps in `mix.exs`, manifest, and changelog | Manual updates would fix the current mismatch once, but they recreate the same drift risk that the checked-in release lane already solves. [VERIFIED: mix.exs, CHANGELOG.md, .release-please-manifest.json, .github/workflows/release.yml] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| Canonical contract in `docs/supported-surface.md` | Repeating full support posture in README and SECURITY | Duplicate contracts are the source of the current drift and directly contradict the locked phase decisions. [VERIFIED: .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md, README.md, SECURITY.md, docs/supported-surface.md] |
| Repo-owned executable drift fence | Manual “release checklist only” reviews | Checklists help maintainers, but the current mismatch shows prose review alone is not sufficient; the tests passed while artifact truth was still wrong. [VERIFIED: docs/maintainer-release.md, test/lockspire/release_readiness_contract_test.exs, mix test test/lockspire/release_readiness_contract_test.exs] |

**Installation:** Existing stack is already checked in; no new package is required to plan the phase. If the planner chooses to refresh the vendored Release Please runtime, the relevant verification command is `npm view release-please version`. [VERIFIED: .github/actions/release-please/runtime/package.json, npm registry via `npm view release-please version`]

**Version verification:** `release-please` latest is `17.6.0` on npm with repo pin `17.3.0`; `17.3.0` was published 2026-02-18 and `17.6.0` was published 2026-04-13. `@actions/core` latest is `3.0.1` while the repo pin is `1.10.0`. [VERIFIED: npm registry via `npm view release-please time --json` and `npm view @actions/core version`]

## Architecture Patterns

### System Architecture Diagram

```text
Merged conventional-commit changes on `main`
  -> Release Please manifest run
     -> reads `release-please-config.json` + `.release-please-manifest.json`
     -> updates release PR candidates (`mix.exs` + `CHANGELOG.md`)
     -> opens/updates release PR
        -> maintainer reviews artifact diff + support-contract docs + contract tests
        -> merge release PR
           -> protected `hex-publish` job runs
              -> `mix release.preflight`
              -> `mix hex.publish --yes`
                 -> public Hex artifact version becomes authoritative

Public docs flow
  `docs/supported-surface.md` (canonical contract)
    -> summarized by `README.md`
    -> bounded by `SECURITY.md`
    -> operationalized by `docs/maintainer-release.md`
    -> enforced by `test/lockspire/release_readiness_contract_test.exs`
```

### Recommended Project Structure
```text
mix.exs                                  # package version metadata
CHANGELOG.md                             # release chronology
release-please-config.json               # release policy
.release-please-manifest.json            # tracked current version
.github/workflows/release.yml            # protected publish lane
.github/actions/release-please/          # repo-controlled Release Please wrapper
README.md                                # public entrypoint only
SECURITY.md                              # subordinate disclosure/security policy
docs/supported-surface.md                # canonical public support contract
docs/maintainer-release.md               # maintainer release operations
test/lockspire/release_readiness_contract_test.exs  # executable drift fence
```

### Pattern 1: Artifact-First Release Truth
**What:** Treat `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, the remote tag line, and the published Hex version as the release-state chain that docs must follow. [VERIFIED: mix.exs, .release-please-manifest.json, CHANGELOG.md, git ls-remote --tags origin 'refs/tags/lockspire-v*', mix hex.info lockspire]

**When to use:** Any time Lockspire claims GA status, names a current release, or explains what “the current release” supports. [VERIFIED: README.md, docs/supported-surface.md, docs/maintainer-release.md]

**Example:**
```elixir
# Source: repo pattern in test/lockspire/release_readiness_contract_test.exs plus phase recommendation
manifest = Jason.decode!(File.read!(".release-please-manifest.json"))
mixfile = File.read!("mix.exs")
supported_surface = File.read!("docs/supported-surface.md")

assert manifest["."] == "1.0.0"
assert mixfile =~ ~s(version: "#{manifest["."]}")
assert supported_surface =~ "Lockspire `#{manifest["."]}` is a GA release"
```

### Pattern 2: One Canonical Public Contract
**What:** Put the full public support boundary in `docs/supported-surface.md`; make README a short orientation layer and SECURITY a bounded disclosure/security-surface document. [VERIFIED: .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md, README.md, SECURITY.md, docs/supported-surface.md]

**When to use:** For every support, scope, or non-claim statement that could drift between docs. [VERIFIED: docs/supported-surface.md, SECURITY.md, docs/maintainer-release.md]

**Example:**
```markdown
<!-- Source: phase-locked authority hierarchy -->
README.md
- one-paragraph product framing
- “The public support contract for the current release lives in docs/supported-surface.md”
- guide links only
```

### Pattern 3: Executable Cross-File Contract Tests
**What:** Expand the existing release-readiness contract suite from wording checks into semantic reconciliation checks across metadata, workflow, and docs. [VERIFIED: test/lockspire/release_readiness_contract_test.exs, mix test test/lockspire/release_readiness_contract_test.exs]

**When to use:** For any claim whose truth can drift because one file is updated without the others. [VERIFIED: current `0.2.0` artifact state vs `1.0.0` doc state]

**Example:**
```elixir
# Source: repo pattern in test/lockspire/release_readiness_contract_test.exs plus phase recommendation
release_workflow = File.read!(".github/workflows/release.yml")
readme = File.read!("README.md")

assert release_workflow =~ "environment: hex-publish"
assert release_workflow =~ "run: mix release.preflight"
assert readme =~ "The public support contract for the current release lives in"
refute readme =~ "What v1.0 includes" unless File.read!("mix.exs") =~ ~s(version: "1.0.0")
```

### Anti-Patterns to Avoid
- **Docs-only GA flip:** The current repo already demonstrates that GA wording can drift ahead of the real artifact when `mix.exs`, manifest, tags, and Hex remain `0.2.0`. [VERIFIED: mix.exs, .release-please-manifest.json, CHANGELOG.md, README.md, docs/supported-surface.md, mix hex.info lockspire]
- **Two public support contracts:** Repeating the full support boundary in README, SECURITY, and maintainer docs increases contradiction surface area and violates the locked authority hierarchy. [VERIFIED: .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md]
- **Treating GitHub settings as public contract:** Protected-environment settings are real release evidence, but they are live operational state and should stay maintainer evidence, not primary public support truth. [VERIFIED: docs/maintainer-release.md] [CITED: https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments]
- **One-off `Release-As` folklore as durable truth:** Release Please supports `release-as`, but the authoritative state still needs the merged release PR, updated `mix.exs`, updated manifest, and a published artifact. [CITED: https://github.com/googleapis/release-please-action] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] [VERIFIED: current repo mismatch]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version synchronization | Ad-hoc scripts that rewrite version strings in multiple files | Release Please manifest mode plus contract tests | Release Please already owns the version/changelog PR flow; tests should verify its outputs rather than replace it. [VERIFIED: .github/workflows/release.yml, .github/actions/release-please/runtime/index.js, test/lockspire/release_readiness_contract_test.exs] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| Support-policy duplication | A second human-maintained support matrix in README or SECURITY | `docs/supported-surface.md` as canonical contract | Duplicate prose is exactly what drifted here. [VERIFIED: README.md, SECURITY.md, docs/supported-surface.md, .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md] |
| Publish-proof inference | “Release PR exists, therefore the release is real” logic | Protected publish lane evidence plus public Hex version check | Release PRs are review-only; publication proof begins only after the protected lane runs and Hex shows the artifact. [VERIFIED: docs/maintainer-release.md, .github/workflows/release.yml, mix hex.info lockspire] |
| Human-only release review | Checklist-only reconciliation with no executable drift fence | ExUnit contract tests in `test/lockspire/release_readiness_contract_test.exs` | The current suite passed while the main contradiction remained, so the right move is stronger checks, not less automation. [VERIFIED: mix test test/lockspire/release_readiness_contract_test.exs, current repo mismatch] |

**Key insight:** Phase 65 should not invent a new release system; it should make the existing system authoritative by tightening inputs, doc roles, and failure conditions. [ASSUMED]

## Common Pitfalls

### Pitfall 1: Artifact Truth and Doc Truth Drift Apart
**What goes wrong:** Docs claim `1.0.0` GA while `mix.exs`, the manifest, tags, changelog, and Hex still show `0.2.0`. [VERIFIED: mix.exs, .release-please-manifest.json, CHANGELOG.md, README.md, docs/supported-surface.md, mix hex.info lockspire, git ls-remote --tags origin 'refs/tags/lockspire-v*']

**Why it happens:** Wording was updated independently from the artifact chain, and the contract test suite currently checks wording more than version reconciliation. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**How to avoid:** Add semantic assertions that compare the supported-surface claim, README posture, maintainer guide wording, `mix.exs`, manifest, and changelog/version lines. [ASSUMED]

**Warning signs:** `mix test test/lockspire/release_readiness_contract_test.exs` stays green while Hex or `mix.exs` still shows a different release line. [VERIFIED: mix test test/lockspire/release_readiness_contract_test.exs, mix hex.info lockspire]

### Pitfall 2: README Becomes a Shadow Support Contract
**What goes wrong:** README restates detailed “includes” and “does not include” lists that can fall out of sync with `docs/supported-surface.md`. [VERIFIED: README.md, docs/supported-surface.md]

**Why it happens:** README is the most visible file, so maintainers keep adding policy detail there instead of linking outward. [ASSUMED]

**How to avoid:** Reduce README to orientation, audience, and links; keep exhaustive support policy in the canonical contract only. [VERIFIED: locked D-05 through D-09 in 65-CONTEXT]

**Warning signs:** A support claim exists in README but not in `docs/supported-surface.md`, or vice versa. [ASSUMED]

### Pitfall 3: Release PR Review Is Mistaken for Publish Proof
**What goes wrong:** Maintainers treat a Release Please PR as if the package is already published or authenticated. [VERIFIED: docs/maintainer-release.md, .github/workflows/release.yml]

**Why it happens:** Release Please opens the version/changelog PR and GitHub release/tag logic, which looks like “the release happened” before the protected publish lane runs. [CITED: https://github.com/googleapis/release-please-action] [VERIFIED: docs/maintainer-release.md]

**How to avoid:** Keep “review-only PR” language explicit and require the protected `hex-publish` run plus Hex package verification for authoritative release truth. [VERIFIED: docs/maintainer-release.md, .github/workflows/release.yml, mix hex.info lockspire]

**Warning signs:** Docs mention the release PR or changelog draft as proof but do not mention `mix hex.publish --yes`, `hex-publish`, or the published Hex version. [ASSUMED]

### Pitfall 4: Phase 63/64 Worktree Drift Pollutes Phase 65 Truth
**What goes wrong:** Support docs for install/verify/upgrade/golden-path work land in the working tree but not in the committed base, so Phase 65 plans against transient local truth instead of repo truth on `main`. [VERIFIED: git status --short]

**Why it happens:** Phase 65 depends on adjacent adoption-truth work, and the current workspace has uncommitted Phase 63/64-related changes. [VERIFIED: git status --short, .planning/STATE.md]

**How to avoid:** Plan Phase 65 assuming Phase 63/64 land first, or explicitly scope any release-truth assertions to the exact commit boundary the release lane will publish. [ASSUMED]

**Warning signs:** `git status` is dirty in docs/tests that Phase 65 also needs to reconcile. [VERIFIED: git status --short]

## Code Examples

Verified patterns from repo and official sources:

### Protected Publish Lane
```yaml
# Source: .github/workflows/release.yml
publish:
  environment: hex-publish
  if: ${{ always() && needs.release-please.outputs.release_created == 'true' }}
  steps:
    - run: mix release.preflight
    - run: mix hex.publish --yes
```

### Release Please Manifest Ownership
```json
// Source: release-please official manifest docs
{
  "packages": {
    ".": {
      "release-type": "elixir",
      "package-name": "lockspire"
    }
  }
}
```

### Semantic Drift Fence
```elixir
# Source: phase recommendation extending test/lockspire/release_readiness_contract_test.exs
test "artifact version and GA wording agree" do
  manifest = Jason.decode!(File.read!(".release-please-manifest.json"))
  version = manifest["."]
  mixfile = File.read!("mix.exs")
  changelog = File.read!("CHANGELOG.md")
  supported = File.read!("docs/supported-surface.md")

  assert mixfile =~ ~s(version: "#{version}")
  assert changelog =~ "## [#{version}]"
  assert supported =~ "Lockspire `#{version}`"
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Docs or commit footers announce GA ahead of the artifact line | Manifest-driven release PR plus protected publish job create the authoritative version change | Release Please docs current as crawled 2026; Lockspire workflow already follows this shape | The repo must treat merged version files and published Hex state as truth, not prose-only GA wording. [VERIFIED: .github/workflows/release.yml, .github/actions/release-please/action.yml, current repo mismatch] [CITED: https://github.com/googleapis/release-please] |
| Multiple files each describe supported surface independently | Canonical contract page with subordinate entrypoint/security/maintainer docs | Locked in Phase 65 context on 2026-05-07 | Reduces contradiction surface and gives contract tests one primary authority target. [VERIFIED: .planning/phases/65-release-truth-support-contract-reconciliation/65-CONTEXT.md] |
| Wording-only release-readiness tests | Semantic cross-file reconciliation tests | Needed now; not fully present today | Prevents another `0.2.0` artifact / `1.0.0` doc split from shipping. [VERIFIED: test/lockspire/release_readiness_contract_test.exs, mix test test/lockspire/release_readiness_contract_test.exs] |

**Deprecated/outdated:**
- “Preview-versioning explicit” as the main release-policy framing is outdated for this phase because the public contradiction is no longer preview semantics; it is `0.x` artifact truth versus `1.0.0` doc truth. [VERIFIED: test/lockspire/release_readiness_contract_test.exs, current repo mismatch]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The repo-proven embedded surface is already sufficient for an honest `1.0.0` release once metadata, docs, and publish state are reconciled. | Summary, Primary recommendation | If false, the planner must trigger the D-04 fallback and align docs/tests back to `0.x` instead of shipping GA claims. |
| A2 | The live GitHub `hex-publish` environment still matches the maintainer guide’s expected branch restrictions, secret placement, and bypass posture. | Architectural Responsibility Map, Environment Availability | If false, the workflow contract remains truthful in git but the trusted-lane story is incomplete until maintainers fix GitHub settings. |
| A3 | The uncommitted Phase 63/64 changes in the current workspace will land before or alongside Phase 65 planning/execution. | Common Pitfalls, Validation Architecture | If false, Phase 65 could reconcile docs against local-only truth instead of the published commit boundary. |

## Open Questions (RESOLVED)

1. **Is there any remaining proof gap that would make a real `1.0.0` artifact dishonest?**
   - Resolution: No repo-local blocker was found in this planning pass. The checked-in support surface, release workflow, maintainer guide, and current contract tests all assume the intended public posture is `1.0.0` GA; the contradiction is that artifact metadata still says `0.2.0`, not that the embedded surface lacks a defined support contract. [VERIFIED: docs/supported-surface.md, README.md, docs/maintainer-release.md, .github/workflows/release.yml, test/lockspire/release_readiness_contract_test.exs]
   - Remaining boundary: live GitHub protected-environment settings are still maintainer evidence outside git and should stay secondary per D-14, not a blocker for planning. [VERIFIED: docs/maintainer-release.md]
   - Planning implication: default to `1.0.0` artifact convergence, but keep an early execution checkpoint that can trigger the D-04 fallback immediately if execution uncovers a concrete proof failure in checked-in repo truth. [VERIFIED: 65-CONTEXT D-04]

2. **Should Phase 65 include a Release Please runtime refresh from `17.3.0` to current `17.6.0`?**
   - Resolution: No. Treat runtime refresh as explicitly out of scope for Phase 65 unless execution finds a version-specific defect in the checked-in release lane. The release-truth contradiction exists independently of the vendored runtime version and should not be delayed behind an opportunistic tooling bump. [VERIFIED: .github/actions/release-please/runtime/package.json, 65-RESEARCH Summary]
   - Planning implication: keep the Phase 65 plans focused on metadata, docs, workflow contract alignment, and drift-fence coverage.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Running contract tests and Mix release aliases locally | ✓ | `1.19.5` | — |
| Mix | `mix test`, `mix release.preflight`, `mix hex.info` | ✓ | `1.19.5` | — |
| Node.js | Checked-in Release Please runtime install path and npm metadata verification | ✓ | `v22.14.0` locally; workflow installs Node `24` | Use GitHub Actions runtime even if local Node differs. |
| npm | Registry version verification for Release Please runtime | ✓ | `11.1.0` | — |
| Hex registry access | Verifying public package truth | ✓ | Public package line visible; current Lockspire version `0.2.0` | — |
| GitHub protected environment `hex-publish` | Trusted publish-lane proof | Unknown from local repo | — | Manual maintainer verification in GitHub settings. |

**Missing dependencies with no fallback:**
- None for planning research itself. [VERIFIED: local commands succeeded]

**Missing dependencies with fallback:**
- Live GitHub environment settings are not inspectable from the repo, so planner should treat them as maintainer evidence to verify manually. [VERIFIED: docs/maintainer-release.md] [CITED: https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5` [VERIFIED: elixir --version, test/test_helper.exs] |
| Config file | `test/test_helper.exs`, `config/test.exs` [VERIFIED: file presence] |
| Quick run command | `mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: command passed in this session] |
| Full suite command | `mix ci` [VERIFIED: mix.exs, docs/maintainer-release.md, .github/workflows/ci.yml] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRUTH-01 | `mix.exs`, manifest, changelog, workflow posture, and public docs agree on the same release state | unit/contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ but missing semantic version reconciliation assertions [VERIFIED: existing file contents] |
| TRUTH-02 | README, SECURITY, supported surface, and release tests describe only the repo-proven embedded surface and explicit non-claims | unit/contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ with good wording coverage, but canonical/subordinate authority checks can still be stronger [VERIFIED: existing file contents] |

### Sampling Rate
- **Per task commit:** `mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: targeted command is fast and passed]
- **Per wave merge:** `mix ci` [VERIFIED: mix.exs, .github/workflows/ci.yml]
- **Phase gate:** Full suite green plus one manual Hex/version truth check if the phase actually performs a release-state transition. [ASSUMED]

### Wave 0 Gaps
- [ ] Add assertions that parse and compare the artifact version across `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, and `docs/supported-surface.md`. [VERIFIED: currently absent from test file]
- [ ] Add assertions that README only points to the canonical support contract instead of independently restating authoritative scope/version language beyond the allowed orientation layer. [VERIFIED: README currently contains full “What v1.0 includes/does not include” lists]
- [ ] Add assertions that maintainer docs may say “1.0 GA support contract” only when artifact truth is also `1.0.0`. [VERIFIED: current guide says this while artifact truth is `0.2.0`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Release-truth reconciliation does not introduce end-user auth flows. [VERIFIED: phase scope] |
| V3 Session Management | no | No browser/session behavior is being added in this phase. [VERIFIED: phase scope] |
| V4 Access Control | yes | Protected `hex-publish` environment and maintainer-only trusted publish lane. [VERIFIED: .github/workflows/release.yml, docs/maintainer-release.md] [CITED: https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments] |
| V5 Input Validation | yes | `workflow_dispatch` recovery lane validates `recovery_ref` as a 40-char SHA or existing tag before publish. [VERIFIED: .github/workflows/release.yml] |
| V6 Cryptography | yes | `HEX_API_KEY` remains environment-secret material and should stay inside the protected lane; do not broaden secret exposure or publish paths. [VERIFIED: .github/workflows/release.yml, docs/maintainer-release.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized or accidental publish from the wrong ref | Elevation of privilege / Tampering | Protected environment, `main`-only normal path, recovery-only dispatch with immutable ref validation. [VERIFIED: .github/workflows/release.yml, docs/maintainer-release.md] |
| Secret exposure in contributor or review-only lanes | Information disclosure | Keep `HEX_API_KEY` only in the publish job’s environment secret boundary. [VERIFIED: .github/workflows/release.yml] [CITED: https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments] |
| Public claims outrun repo proof | Repudiation / Tampering | Canonical support contract plus executable cross-file tests and Hex/version checks. [VERIFIED: docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs, current repo mismatch] |
| Recovery publish targets mutable branch state | Tampering | Require exact SHA or existing tag, then detach checkout before publish. [VERIFIED: .github/workflows/release.yml] |

## Sources

### Primary (HIGH confidence)
- Repo files and commands:
  - `mix.exs`
  - `CHANGELOG.md`
  - `README.md`
  - `SECURITY.md`
  - `docs/supported-surface.md`
  - `docs/maintainer-release.md`
  - `release-please-config.json`
  - `.release-please-manifest.json`
  - `.github/workflows/release.yml`
  - `.github/actions/release-please/action.yml`
  - `.github/actions/release-please/runtime/package.json`
  - `.github/actions/release-please/runtime/index.js`
  - `.github/workflows/ci.yml`
  - `test/lockspire/release_readiness_contract_test.exs`
  - `mix hex.info lockspire`
  - `mix test test/lockspire/release_readiness_contract_test.exs`
  - `git ls-remote --tags origin 'refs/tags/lockspire-v*'`
- Release Please official docs:
  - https://github.com/googleapis/release-please
  - https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
- GitHub official docs:
  - https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments
  - https://docs.github.com/en/actions/concepts/security/github_token

### Secondary (MEDIUM confidence)
- npm registry metadata:
  - `npm view release-please version time --json`
  - `npm view @actions/core version`

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the repo’s current release toolchain and public artifact state were directly verified, and Release Please / GitHub behavior was checked against official docs.
- Architecture: HIGH - the doc/workflow/test authority boundaries are explicitly locked in `65-CONTEXT.md` and visible in checked-in files.
- Pitfalls: HIGH - the main failure mode is present right now in the repo (`0.2.0` artifact truth vs `1.0.0` doc truth), so the risks are evidenced rather than hypothetical.

**Research date:** 2026-05-07
**Valid until:** 2026-06-06
