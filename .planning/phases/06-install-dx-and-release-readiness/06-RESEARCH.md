# Phase 6: Install DX and Release Readiness - Research

**Researched:** 2026-04-23
**Domain:** Install DX, executable docs, CI/CD, release automation, maintainer guidance, and release-readiness for an embedded Phoenix OAuth/OIDC library
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Canonical onboarding path
- **D-01:** Lockspire will use one canonical onboarding path for v1: a plain Phoenix host app adopting Lockspire as an embedded library.
- **D-02:** The canonical happy path should feel generator-first and host-framework-first: add the dependency, run `mix lockspire.install`, run migrations, wire the generated host seam, create a client, and complete a real authorization-code + PKCE flow.
- **D-03:** Sigra remains a first-class companion recipe, not a co-equal default path and not the main install story. `--sigra-host` stays as an adjacent optimization for the same underlying integration seam.
- **D-04:** Phase 6 docs and generators must reinforce the established boundary: Lockspire owns protocol correctness and generated integration scaffolding; the host app owns login UX, layouts, branding, and product policy.

### Docs and proof surface
- **D-05:** The public documentation contract should be README + HexDocs guides + CI-verified generated-host fixtures, not a full demo app as the primary proof surface.
- **D-06:** The root `README.md` should stay short and decisive: what Lockspire is, who it is for, what v1 includes/excludes, the canonical install path in a few steps, security defaults, and links to deeper guides.
- **D-07:** HexDocs should carry the real product contract through focused guides: getting started, install/onboarding, operator/admin guide, security policy/disclosure path, supported surface/conformance matrix, and maintainer/releasing guidance.
- **D-08:** Lockspire should keep one intentionally minimal example or fixture host app to prove the flow end to end, but it must remain supplementary to the generated-install path rather than becoming a second golden path.
- **D-09:** Docs must end in proof, not prose alone. The canonical onboarding guide should terminate in a real issued token plus successful discovery/JWKS checks.

### Release automation and publish discipline
- **D-10:** Use Release Please for versioning, changelog updates, and reviewable release PRs rather than manual version drift or custom release scripting.
- **D-11:** Publish to Hex from the same trusted release workflow when a release is actually created, rather than through a separate tag-triggered chain that risks split-brain release state.
- **D-12:** Release automation should remain boring and Elixir-native: Mix stays the source of truth for package metadata, docs build, dry-run validation, and Hex publishing.
- **D-13:** Release gating must include formatter, compile with warnings-as-errors, tests, docs build, Credo, Dialyzer, Hex audit, and package dry-run validation before publish.
- **D-14:** Workflow security is part of the release model: least-privilege permissions, protected secrets/environment, action pinning, and explicit review around workflow changes are required.

### Public release bar
- **D-15:** Lockspire should use a two-threshold release posture: a serious public `0.x` preview bar and a stricter `1.0` release-ready bar.
- **D-16:** A public preview is allowed only after Lockspire can honestly prove safe defaults, a canonical Phoenix onboarding flow, executable docs/example coverage, repeatable release automation, private vulnerability reporting, and an explicit supported/non-supported feature matrix.
- **D-17:** Lockspire should not market itself as “release-ready” or “production-credible” until the stricter bar is met: the preview bar plus supported-profile conformance evidence and in-repo maintainer runbooks.
- **D-18:** Minimal “throw it on Hex and figure it out later” release posture is explicitly rejected. That would undercut the project’s core value for a security-sensitive library.

### Cohesion and DX posture
- **D-19:** All Phase 6 deliverables should point to the same story: one canonical Phoenix-first path, one narrow embedded-library shape, one truthful supported surface, and one boring release process.
- **D-20:** Prefer least surprise over ecosystem marketing. The docs and release shape should look like a serious Phoenix/Elixir library first, with Sigra and future ecosystem pairings presented as companion recipes.
- **D-21:** Treat docs, generators, CI, and release policy as product surface area, not project housekeeping. For Lockspire, adoption trust depends on them as much as protocol code does.

### Claude's Discretion
- Exact file layout and naming for HexDocs pages, as long as there is one canonical onboarding flow and the required guide set exists.
- The specific fixture/minimal example structure, as long as it proves the generated install path rather than replacing it.
- Whether preview and `1.0` bars are represented as one release checklist with thresholds or as separate docs, as long as the distinction is explicit and auditable.

### Deferred Ideas (OUT OF SCOPE)
- Dual-track “plain Phoenix” and “Sigra-host” co-equal onboarding paths — defer unless ecosystem demand proves the extra maintenance is worth it.
- A polished full demo app as a primary proof surface — defer until there is bandwidth to maintain it without displacing the canonical install path.
- Broader certification-profile work beyond the supported v1/provider surface — defer to later roadmap phases once the base release contract is stable.
- More advanced ecosystem recipes beyond Sigra companion hosting — defer until the main Phoenix-first path is stable and trustworthy.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RELS-01 | A Phoenix team can follow one canonical onboarding path and complete a real authorization flow in a fresh host app | Use the existing generator/task spine plus a new executable onboarding fixture that ends in token issuance and discovery/JWKS proof. [VERIFIED: lib/mix/tasks/lockspire.install.ex] [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |
| RELS-02 | The repo ships executable docs, CI gates, changelog/release workflow, and publish discipline suitable for a security-sensitive OSS library | Add ExDoc-backed docs, Hex dry-run, Release Please, dependency review, CODEOWNERS, and maintainer/release policy docs as versioned repo artifacts. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
</phase_requirements>

## Summary

Lockspire already has the correct Phase 6 backbone in code. `mix lockspire.install` is real, the generator centralizes its template inventory, reruns are safe because modified host files are not overwritten, and the Sigra path is already scoped as an adjacent companion recipe rather than the default install path. The install generator test passes locally today. [VERIFIED: lib/mix/tasks/lockspire.install.ex] [VERIFIED: lib/lockspire/generators/install.ex] [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: mix test test/integration/install_generator_test.exs] [VERIFIED: docs/sigra-companion-host.md]

The release-trust gaps are also concrete today. `mix docs` does not exist yet, `mix hex.publish --dry-run --yes` currently fails because package metadata is incomplete, the repo has no visible `README.md`, `CHANGELOG.md`, `SECURITY.md`, `LICENSE`, or `CODEOWNERS`, and the only workflow is `ci.yml`, which stops at format/compile/tests plus current integration lanes. It does not yet enforce docs, Credo, Dialyzer, Hex audit, package dry-run, dependency review, or a release workflow. [VERIFIED: mix help docs] [VERIFIED: mix hex.publish --dry-run --yes] [VERIFIED: repo file listing] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: mix.exs]

**Primary recommendation:** land Phase 6 in the roadmap’s natural order: `06-01` package metadata + generator/docs/onboarding proof, `06-02` CI and release workflow, then `06-03` maintainer guidance plus preview/1.0 release-readiness evidence. That ordering keeps automation validating real artifacts instead of placeholders. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: repo inspection] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

## Current Repo Assessment

### Strengths
- The install path is already generator-first and host-owned. `mix lockspire.install` is a thin task that delegates to generator code instead of hiding integration in runtime side effects. [VERIFIED: lib/mix/tasks/lockspire.install.ex] [VERIFIED: lib/lockspire/generators/install.ex]
- Generator safety is already credible: unchanged files are left alone and modified host files hard-fail rather than being overwritten. [VERIFIED: lib/lockspire/generators/install.ex] [VERIFIED: test/integration/install_generator_test.exs]
- The repo already has a useful proof seam: `test/integration/install_generator_test.exs` exercises the generated host fixture, and `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` gives an existing end-to-end protocol test shape to reuse for onboarding proof. [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs]
- CI already uses `erlef/setup-beam`, cache, PostgreSQL service containers, and named jobs, so Phase 6 can extend an existing workflow rather than rebuild it. [VERIFIED: .github/workflows/ci.yml]
- The Sigra companion doc already preserves the correct boundary and sequencing: no compile-time Sigra dependency and no promotion to a co-equal install path. [VERIFIED: docs/sigra-companion-host.md]

### Gaps
- Publishing is blocked today because Hex metadata is incomplete; dry-run publish stops on missing `description`, `licenses`, and `links`. [VERIFIED: mix hex.publish --dry-run --yes]
- Docs are blocked today because `mix docs` is unavailable, which means no HexDocs build gate can pass until ExDoc is added and configured. [VERIFIED: mix help docs]
- `mix.exs` does not currently declare package metadata, docs config, source/homepage links, or dev-only QA tooling for ExDoc, Credo, and Dialyxir. [VERIFIED: mix.exs]
- The root repo is missing the public release-trust artifacts users expect to inspect first: `README.md`, `CHANGELOG.md`, `SECURITY.md`, `LICENSE`, and `CODEOWNERS`. [VERIFIED: repo file listing]
- Workflow coverage is below the locked release bar. Current CI does not include docs build, Credo, Dialyzer, Hex audit, package dry-run, dependency review, Release Please, concurrency control, or immutable action pinning. [VERIFIED: .github/workflows/ci.yml] [CITED: https://docs.github.com/en/actions/reference/security/secure-use] [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency]

### Risks
- Adding release automation before package metadata and docs generation exist creates a release PR system that still cannot publish a trustworthy Hex artifact. [VERIFIED: mix hex.publish --dry-run --yes] [VERIFIED: mix help docs] [CITED: https://github.com/googleapis/release-please-action]
- Movable workflow tags are a weak fit for a security-sensitive library. GitHub’s secure-use guidance treats full-length SHAs as the immutable option. [VERIFIED: .github/workflows/ci.yml] [CITED: https://docs.github.com/en/actions/reference/security/secure-use]
- Prose-only onboarding will drift because the current install proof validates file output only, not the full guide path the user will follow. [VERIFIED: test/integration/install_generator_test.exs]
- Public preview claims can drift from reality if the supported provider surface is described from roadmap intent rather than CI-backed evidence. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: mix.exs] [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Install generation | API / Backend | Browser / Client | Mix task + generator code own the integration contract; generated host UI files are outputs, not the source of truth. [VERIFIED: lib/mix/tasks/lockspire.install.ex] [VERIFIED: lib/lockspire/generators/install.ex] |
| Canonical onboarding proof | API / Backend | Database / Storage | The proof should be driven by ExUnit/integration fixtures and real provider state, not screenshots. [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs] |
| Public docs contract | API / Backend | Browser / Client | Repo docs + ExDoc config own the contract; HexDocs/browser only render it. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] |
| Release/versioning | API / Backend | — | Mix owns package truth; GitHub Actions orchestrate reviewable release automation. [CITED: https://github.com/googleapis/release-please-action] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Workflow security and supply-chain review | API / Backend | — | GitHub Actions permissions, CODEOWNERS, pinning, and dependency review sit in repo policy/workflow code. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action?apiVersion=2022-11-28] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `googleapis/release-please-action` | `v5.0.0` (published 2026-04-22) [VERIFIED: GitHub releases API] | Release PRs, version bumps, changelog, tags, GitHub Releases [CITED: https://github.com/googleapis/release-please-action] | Official action supports Elixir repositories, manifest config, and outputs like `release_created`, `tag_name`, and `version`. [CITED: https://github.com/googleapis/release-please-action] |
| `erlef/setup-beam` | `v1.24.0` (published 2026-03-30) [VERIFIED: GitHub releases API] | Exact Elixir/OTP setup in GitHub Actions [CITED: https://github.com/erlef/setup-beam] | Official BEAM setup action; docs recommend exact versions with `version-type: strict`. [CITED: https://github.com/erlef/setup-beam] |
| `ex_doc` | `0.40.1` (published 2026-01-31) [VERIFIED: hex.pm API] | HexDocs generation and docs warnings gate [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] | Official docs path for Hex publishing; supports `mix docs --warnings-as-errors`. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `credo` | `1.7.18` (published 2026-04-10) [VERIFIED: hex.pm API] | Lint/static analysis | Add in `06-02` because the locked release gate explicitly includes Credo. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |
| `dialyxir` | `1.4.7` (published 2025-11-06) [VERIFIED: hex.pm API] | Dialyzer integration | Add in `06-02` because the locked release gate explicitly includes Dialyzer. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |
| `actions/dependency-review-action` | `v4.9.0` (published 2026-03-03) [VERIFIED: GitHub releases API] | PR dependency vulnerability gate [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action?apiVersion=2022-11-28] | Use once workflow security is in place. [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action?apiVersion=2022-11-28] |
| `actions/checkout` | `v6.0.2` (published 2026-01-09) [VERIFIED: GitHub releases API] | Workflow checkout | Keep using it, but pin to a full commit SHA in publish-critical workflows. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
| `actions/cache` | `v5.0.5` (published 2026-04-13) [VERIFIED: GitHub releases API] | Mix/deps/build cache | Use the current cache action family; its docs note older lines were deprecated around the cache backend migration. [CITED: https://github.com/actions/cache] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Release Please | Manual version/tag/changelog scripts | Rejected because Phase 6 explicitly wants reviewable release PRs and one trusted publish path. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |
| README + HexDocs + fixture proof | Full demo app as the primary proof surface | Rejected because locked scope says fixture/example proof should stay supplementary to the generated-install path. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |
| Major-tag workflow refs | Full-length SHA pinning | Tag refs are simpler to read, but GitHub documents SHAs as the immutable option. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |

**Installation:**
```bash
mix deps.get
```

Add Phase 6 dev-only dependencies in `mix.exs`: `ex_doc`, `credo`, and `dialyxir`. [VERIFIED: mix.exs] [VERIFIED: hex.pm API]

**Version verification:** `ex_doc` `0.40.1` was published on 2026-01-31, `credo` `1.7.18` on 2026-04-10, `dialyxir` `1.4.7` on 2025-11-06, `release-please-action` `v5.0.0` on 2026-04-22, `erlef/setup-beam` `v1.24.0` on 2026-03-30, `actions/checkout` `v6.0.2` on 2026-01-09, `actions/cache` `v5.0.5` on 2026-04-13, and `actions/dependency-review-action` `v4.9.0` on 2026-03-03. [VERIFIED: hex.pm API] [VERIFIED: GitHub releases API]

## Architecture Patterns

### System Architecture Diagram
```text
Maintainer edits docs/generator/workflows
        |
        v
mix lockspire.install -----------------> generated host seam files
        |                                         |
        v                                         v
README + HexDocs guides ----------------> executable onboarding commands
        |                                         |
        v                                         v
GitHub Actions CI ----> docs + tests + QA + dry-run publish ----> release gate result
        |                                                              |
        v                                                              v
Release Please PR ----> reviewed merge on main ----> release_created ----> mix hex.publish --yes
```

### Recommended Project Structure
```text
.github/
├── CODEOWNERS
├── dependabot.yml
└── workflows/
    ├── ci.yml
    ├── dependency-review.yml
    ├── release-please.yml
    └── unlocked-deps.yml
docs/
├── getting-started.md
├── install-and-onboard.md
├── operator-admin.md
├── security-policy.md
├── supported-surface.md
└── maintainer-release.md
test/
├── integration/
│   ├── install_generator_test.exs
│   └── onboarding_flow_test.exs
└── support/fixtures/
    └── generated_host_app/
```

### Pattern 1: Canonical Onboarding As Executable Contract
**What:** Keep one generator-first guide and bind every step to CI-verifiable commands. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
**When to use:** For README, HexDocs getting-started, and the Phase 6 end-to-end proof. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
**Example:**
```elixir
# Source: /Users/jon/projects/lockspire/test/integration/install_generator_test.exs
File.cd!(@fixture_root, fn ->
  Mix.Task.reenable("lockspire.install")

  Mix.Tasks.Lockspire.Install.run([
    "--web",
    "GeneratedHostAppWeb",
    "--scope",
    "GeneratedHostApp.Lockspire"
  ])
end)
```
[VERIFIED: test/integration/install_generator_test.exs]

### Pattern 2: Publish Only From Release Please Output
**What:** Use a dedicated release workflow where Release Please opens/updates the release PR and Hex publish runs only when `release_created` is true. [CITED: https://github.com/googleapis/release-please-action]
**When to use:** For `06-02`. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
**Example:**
```yaml
# Source: https://github.com/googleapis/release-please-action
- uses: googleapis/release-please-action@v4
  id: release

# later publish job
if: ${{ needs.release.outputs.release_created == 'true' }}
```
[CITED: https://github.com/googleapis/release-please-action]

### Pattern 3: Docs Build Is A Hard Gate
**What:** Configure ExDoc in `mix.exs` and fail CI on docs warnings. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]
**When to use:** For `06-01` metadata/docs setup and `06-02` CI enforcement. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]
**Example:**
```elixir
# Source: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
docs: [
  main: "readme",
  extras: ["README.md"]
]
```
[CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]

### Anti-Patterns to Avoid
- **Second golden path demo app:** the fixture should prove the generator path, not replace it. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
- **Split-brain releases:** do not tag manually and publish separately from the release PR workflow. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] [CITED: https://github.com/googleapis/release-please-action]
- **Workflow tags without immutability:** do not leave third-party actions on movable tags in publish-critical workflows. [VERIFIED: .github/workflows/ci.yml] [CITED: https://docs.github.com/en/actions/reference/security/secure-use]
- **Library-global config creep:** Elixir’s own guidance warns against treating library application config as the primary interface. [CITED: https://hexdocs.pm/elixir/main/Application.html] [CITED: https://hexdocs.pm/elixir/1.14/library-guidelines.html]

## Natural Plan Split

### `06-01` Polish generators, install flow, and executable onboarding docs
- Add package/docs metadata in `mix.exs`, plus `README.md`, `CHANGELOG.md`, `LICENSE`, and the HexDocs guide set so `mix docs` and `mix hex.publish --dry-run --yes` can pass. [VERIFIED: mix.exs] [VERIFIED: mix help docs] [VERIFIED: mix hex.publish --dry-run --yes]
- Keep the current generator/task shape and strengthen it only where the canonical guide needs clearer output or safer defaults. [VERIFIED: lib/mix/tasks/lockspire.install.ex] [VERIFIED: lib/lockspire/generators/install.ex]
- Extend the existing fixture-based proof into an onboarding proof that reaches a real auth-code flow plus discovery/JWKS checks. [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase3_oidc_token_lifecycle_e2e_test.exs] [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]

### `06-02` Establish CI/CD, changelog, and release/publish workflows
- Expand `ci.yml` into the locked release gate set: format, compile warnings-as-errors, tests, docs build, Credo, Dialyzer, Hex audit, and package dry-run. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
- Add dedicated workflows for dependency review, Release Please, and a nightly unlocked-deps compatibility lane. Elixir’s library guidelines explicitly recommend a second CI workflow that unlocks dependencies and tests against latest versions. [CITED: https://hexdocs.pm/elixir/1.14/library-guidelines.html]
- Apply workflow security now: concurrency, least-privilege permissions, full-SHA pinning, CODEOWNERS, protected publish environment, and Dependabot for `github-actions`. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency] [CITED: https://docs.github.com/en/actions/reference/security/secure-use] [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/keeping-your-actions-up-to-date-with-dependabot]

### `06-03` Finalize release-readiness checks, maintainer guidance, and conformance prep
- Add `SECURITY.md`, maintainer/release runbook, support policy, preview-vs-1.0 checklist, and supported-surface/conformance evidence docs. [VERIFIED: repo file listing] [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] [VERIFIED: prompts/lockspire-release-readiness-and-conformance.md]
- Tie release claims to evidence already exercised in CI: canonical onboarding, safe defaults, supported endpoints, and operator surfaces. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
- Add a manual recovery path for Hex publish and GitHub release repair, but document it as an exception path, not the normal release path. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [CITED: https://github.com/googleapis/release-please-action]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Versioning/changelog/release PRs | Custom scripts that edit `mix.exs`, tags, and changelog independently | Release Please manifest config | It already supports Elixir repos and exposes the exact outputs needed to gate publish-on-release. [CITED: https://github.com/googleapis/release-please-action] |
| Docs publication | Custom docs deploy logic | `mix docs` via ExDoc + Hex publish | Hex already builds/publishes docs during `mix hex.publish`, and ExDoc provides the expected docs task/output. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Package preflight validation | Ad hoc shell checks | `mix hex.publish --dry-run --yes` | Hex’s dry-run already performs the right local checks. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Workflow supply-chain diffing | Custom parsers | `actions/dependency-review-action` + Dependabot | GitHub already provides both. [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action?apiVersion=2022-11-28] [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/keeping-your-actions-up-to-date-with-dependabot] |
| Elixir/OTP setup on GitHub Actions | Custom install scripts | `erlef/setup-beam` | It is the standard BEAM setup action and documents strict versioning. [CITED: https://github.com/erlef/setup-beam] |

**Key insight:** the dangerous part of Phase 6 is drift and trust, not missing framework primitives. Compose official tooling around the repo’s existing generator/test spine instead of inventing a bespoke release platform. [VERIFIED: repo inspection] [CITED: https://github.com/googleapis/release-please-action] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

## Common Pitfalls

### Pitfall 1: Publishing Before Package Metadata Exists
**What goes wrong:** release automation appears to work, but Hex publish still fails at the last step. [VERIFIED: mix hex.publish --dry-run --yes]
**Why it happens:** `mix.exs` lacks complete package metadata and there is no package preflight gate yet. [VERIFIED: mix.exs] [VERIFIED: mix hex.publish --dry-run --yes]
**How to avoid:** make `mix hex.publish --dry-run --yes` pass in `06-01` and gate it in `06-02`. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
**Warning signs:** dry-run publish reports missing metadata fields. [VERIFIED: mix hex.publish --dry-run --yes]

### Pitfall 2: Docs Drift From The Generator
**What goes wrong:** README/HexDocs describe a flow that the generated host path does not actually prove. [VERIFIED: repo inspection]
**Why it happens:** the current install test validates rendered files, not a docs-driven onboarding script. [VERIFIED: test/integration/install_generator_test.exs]
**How to avoid:** promote the docs path to an executable onboarding test. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
**Warning signs:** guide changes land without fixture/test changes, or generator changes land without docs updates. [VERIFIED: repo inspection]

### Pitfall 3: Mutable Workflow Supply Chain
**What goes wrong:** a third-party action changes underneath Lockspire’s release workflow. [VERIFIED: .github/workflows/ci.yml]
**Why it happens:** current workflow refs use movable major tags and there is no CODEOWNERS or dependency-review workflow yet. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: repo file listing]
**How to avoid:** pin full SHAs, add CODEOWNERS for workflow files, and enable Dependabot plus dependency review. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/keeping-your-actions-up-to-date-with-dependabot] [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action?apiVersion=2022-11-28]
**Warning signs:** workflow changes merge without explicit review, or action refs are updated manually with no automated diff. [CITED: https://docs.github.com/en/actions/reference/security/secure-use]

### Pitfall 4: Truthful Preview Bar Gets Lost
**What goes wrong:** Lockspire markets support more broadly than the repo can actually prove. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
**Why it happens:** Phase 6 spans docs, CI, and release language, so it is easy to describe future scope instead of tested scope. [VERIFIED: prompts/lockspire-release-readiness-and-conformance.md]
**How to avoid:** maintain a supported-surface matrix tied to tested evidence and keep separate preview vs `1.0` checklists. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
**Warning signs:** release copy says “production-credible” without a referenced guide/test/checklist proving what that means. [VERIFIED: prompts/lockspire-release-readiness-and-conformance.md]

## Code Examples

Verified patterns from official sources:

### ExDoc As A Release Gate
```elixir
# Source: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
docs: [
  main: "readme",
  extras: ["README.md"]
]

# CI command
mix docs --warnings-as-errors
```
[CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]

### Hex Publish Preflight
```bash
# Source: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html
mix hex.publish --dry-run --yes
```
[CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

### Release Please Output-Gated Publish
```yaml
# Source: https://github.com/googleapis/release-please-action
- uses: googleapis/release-please-action@v4
  id: release

if: ${{ needs.release.outputs.release_created == 'true' }}
```
[CITED: https://github.com/googleapis/release-please-action]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual version/tag/changelog edits | Release PR automation with Release Please | Current official action docs [CITED: https://github.com/googleapis/release-please-action] | Makes releases reviewable and reduces drift between `mix.exs`, tags, and changelog. [CITED: https://github.com/googleapis/release-please-action] |
| Prose-only docs acceptance | Docs build as a hard CI gate with `mix docs --warnings-as-errors` | Present in current ExDoc docs [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] | Makes docs part of product correctness instead of optional polish. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] |
| Single deterministic CI only | Deterministic CI plus an unlocked-deps compatibility lane | Elixir library guidelines already recommend this pattern [CITED: https://hexdocs.pm/elixir/1.14/library-guidelines.html] | Gives earlier warning when dependency ecosystem changes break the library. [CITED: https://hexdocs.pm/elixir/1.14/library-guidelines.html] |
| Movable workflow tags | Full-length SHA pinning | Current GitHub secure-use guidance [CITED: https://docs.github.com/en/actions/reference/security/secure-use] | Reduces workflow supply-chain risk. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |

**Deprecated/outdated:**
- Tag-only trust for third-party actions in release-critical workflows. GitHub documents full-length SHAs as the immutable option. [CITED: https://docs.github.com/en/actions/reference/security/secure-use]
- “Publish first, document later” for Hex libraries. Current Hex publishing behavior assumes docs generation can run during publish. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

## Assumptions Log

All claims in this research were verified or cited — no user confirmation needed. [VERIFIED: research review]

## Open Questions

1. **Should public preview be blocked on formal Phase 3 completion in planning artifacts, or only on implemented/tested provider evidence?**
   - What we know: repo code and aliases already include Phase 3-oriented tests and endpoints, while roadmap/state still describe Phase 3 as pending. [VERIFIED: mix.exs] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/STATE.md]
   - What's unclear: whether release language should block on roadmap reconciliation or can rely solely on a tested supported-surface matrix. [VERIFIED: repo inspection]
   - Recommendation: make `06-03` define the public supported surface from test-backed evidence and update planning/status docs before any public preview announcement. [VERIFIED: prompts/lockspire-release-readiness-and-conformance.md]

2. **How far should the canonical onboarding proof go inside CI?**
   - What we know: the current install test proves file generation only, while the context explicitly wants issued-token plus discovery/JWKS proof. [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
   - What's unclear: whether the fixture should boot a minimal Phoenix host in-process or whether a scripted integration lane against the existing fixture app is sufficient. [VERIFIED: repo inspection]
   - Recommendation: reuse the existing fixture host and add the smallest end-to-end lane that proves the real flow, instead of introducing a separate demo app. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Docs build, tests, dry-run publish | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| Mix | Generators, CI commands, Hex publish | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| Git | Release metadata and workflow automation | ✓ [VERIFIED: local command] | `2.41.0` [VERIFIED: local command] | — |
| Docker | Local parity for Postgres-backed integration lanes | ✓ [VERIFIED: local command] | `29.3.1` [VERIFIED: local command] | — |
| GitHub CLI | Maintainer recovery guidance and release inspection | ✓ [VERIFIED: local command] | `2.89.0` [VERIFIED: local command] | GitHub UI [VERIFIED: repo inspection] |
| `actionlint` | Optional workflow linting lane | ✗ [VERIFIED: local command] | — | Add a CI-only actionlint step or install it during Phase 6. [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None identified for planning and implementation in this repo state. [VERIFIED: local command]

**Missing dependencies with fallback:**
- `actionlint` is absent locally, but workflow linting can still be added in CI or by installing the binary during Phase 6. [VERIFIED: local command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix [VERIFIED: test/integration/install_generator_test.exs] |
| Config file | none — current suite is Mix/ExUnit-driven [VERIFIED: repo inspection] |
| Quick run command | `mix test test/integration/install_generator_test.exs` [VERIFIED: local command] |
| Full suite command | `mix ci` today; Phase 6 should extend the gate with docs/QA/publish checks. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RELS-01 | Canonical install path generates host seam correctly | integration | `mix test test/integration/install_generator_test.exs` | ✅ [VERIFIED: local command] |
| RELS-01 | Canonical onboarding path completes real auth flow and OIDC endpoint proof | e2e/integration | `mix test test/integration/onboarding_flow_test.exs` | ❌ Wave 0 [VERIFIED: repo inspection] |
| RELS-02 | Docs build cleanly from package config | docs gate | `mix docs --warnings-as-errors` | ❌ Wave 0 [VERIFIED: mix help docs] |
| RELS-02 | Package can build and preflight-publish cleanly | release gate | `mix hex.publish --dry-run --yes` | ✅ command exists, ❌ currently failing [VERIFIED: mix hex.publish --dry-run --yes] |
| RELS-02 | Static quality gates cover release path | lint/static | `mix credo --strict && mix dialyzer && mix hex.audit` | ❌ Wave 0 for Credo/Dialyzer, ✅ for Hex audit [VERIFIED: mix help credo] [VERIFIED: mix help dialyzer] [VERIFIED: mix help hex.audit] |

### Sampling Rate
- **Per task commit:** `mix test test/integration/install_generator_test.exs` for generator/doc edits. [VERIFIED: local command]
- **Per wave merge:** `mix ci` plus the new docs/QA/publish dry-run gates. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md]
- **Phase gate:** full CI green, docs build green, dry-run publish green, and release workflow reviewed before `/gsd-verify-work`. [VERIFIED: prompts/lockspire-release-engineering-and-ci.md]

### Wave 0 Gaps
- [ ] `README.md` plus `docs/*.md` guide set — required so ExDoc has truthful extras and the canonical onboarding path exists. [VERIFIED: repo file listing]
- [ ] `test/integration/onboarding_flow_test.exs` — covers RELS-01 beyond file generation. [VERIFIED: repo inspection]
- [ ] Dev dependencies in `mix.exs` for ExDoc, Credo, and Dialyxir. [VERIFIED: mix.exs]
- [ ] `.github/workflows/release-please.yml` — release PR and publish orchestration. [VERIFIED: .github/workflows/ci.yml]
- [ ] `.github/workflows/dependency-review.yml` and `.github/dependabot.yml` — supply-chain maintenance. [VERIFIED: .github/workflows/ci.yml] [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action?apiVersion=2022-11-28] [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/keeping-your-actions-up-to-date-with-dependabot]
- [ ] `SECURITY.md`, `CODEOWNERS`, `CHANGELOG.md`, `LICENSE` — required repo policy/release artifacts. [VERIFIED: repo file listing]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Host auth remains out of scope for Phase 6. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |
| V3 Session Management | no [VERIFIED: phase scope] | No new end-user session model is introduced here. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: phase scope] | Least-privilege `GITHUB_TOKEN`, protected environments/secrets, and CODEOWNERS for workflow changes. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
| V5 Input Validation | yes [VERIFIED: repo inspection] | `OptionParser`-validated install task flags and explicit unknown-option rejection. [VERIFIED: lib/mix/tasks/lockspire.install.ex] |
| V6 Cryptography | yes [VERIFIED: phase scope] | Use GitHub secrets and Hex API keys; do not hand-roll secret storage or logging behavior. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Compromised third-party GitHub Action | Tampering / Elevation | Full-SHA pinning, source review, Dependabot, dependency review, CODEOWNERS. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/keeping-your-actions-up-to-date-with-dependabot] |
| Over-privileged workflow token | Elevation | Default `contents: read`, raise permissions only per job where needed. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
| Secret leakage in workflow logs | Information Disclosure | Use GitHub secrets, avoid structured secret blobs, mask transformed values, and review action source. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
| Release-state divergence between changelog/tag/package | Tampering | Single trusted Release Please → gated Hex publish flow. [CITED: https://github.com/googleapis/release-please-action] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Docs claiming unsupported provider surface | Spoofing / Repudiation | Supported-surface matrix tied to tested evidence and preview/1.0 checklist. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- Repo inspection of `mix.exs`, `.github/workflows/ci.yml`, generator/task modules, install tests, and `docs/sigra-companion-host.md` — current Lockspire implementation state. [VERIFIED: repo inspection]
- `mix test test/integration/install_generator_test.exs` — current generator proof passes. [VERIFIED: local command]
- `mix help docs` — current docs-task absence. [VERIFIED: local command]
- `mix hex.publish --dry-run --yes` — current package publish dry-run failure details. [VERIFIED: local command]
- `https://github.com/googleapis/release-please-action` — Release Please action behavior, Elixir support, permissions, manifest config, and outputs. [CITED: https://github.com/googleapis/release-please-action]
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` — Hex publish/dry-run/docs publication behavior. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- `https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html` — ExDoc config and warnings-as-errors. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]
- `https://github.com/erlef/setup-beam` — exact-version Elixir/OTP setup guidance. [CITED: https://github.com/erlef/setup-beam]
- `https://docs.github.com/en/actions/reference/security/secure-use` — least privilege, SHA pinning, CODEOWNERS, and workflow security guidance. [CITED: https://docs.github.com/en/actions/reference/security/secure-use]
- `https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency` — workflow concurrency guidance. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency]
- `https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action?apiVersion=2022-11-28` — dependency review workflow pattern. [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/manage-your-dependency-security/configuring-the-dependency-review-action?apiVersion=2022-11-28]
- `https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/keeping-your-actions-up-to-date-with-dependabot` — Dependabot for GitHub Actions. [CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/keeping-your-actions-up-to-date-with-dependabot]
- `https://hexdocs.pm/elixir/1.14/library-guidelines.html` and `https://hexdocs.pm/elixir/main/Application.html` — Elixir library CI/config guidance. [CITED: https://hexdocs.pm/elixir/1.14/library-guidelines.html] [CITED: https://hexdocs.pm/elixir/main/Application.html]
- Hex.pm API and GitHub Releases API — verified current versions and publish dates for recommended tools. [VERIFIED: hex.pm API] [VERIFIED: GitHub releases API]

### Secondary (MEDIUM confidence)
- `prompts/lockspire-release-readiness-and-conformance.md` — project-specific release bar and conformance expectations. [VERIFIED: repo inspection]
- `prompts/lockspire-release-engineering-and-ci.md` — project-specific release engineering preferences. [VERIFIED: repo inspection]
- `prompts/lockspire-elixir-oss-library-practices.md` — project-specific Elixir OSS expectations. [VERIFIED: repo inspection]

### Tertiary (LOW confidence)
- None. [VERIFIED: research review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and tool capabilities were verified from official docs/APIs and matched against repo gaps. [VERIFIED: hex.pm API] [VERIFIED: GitHub releases API] [VERIFIED: repo inspection]
- Architecture: HIGH - recommendations are tightly constrained by the Phase 6 context and current repo structure. [VERIFIED: .planning/phases/06-install-dx-and-release-readiness/06-CONTEXT.md] [VERIFIED: repo inspection]
- Pitfalls: HIGH - each pitfall is already visible in repo state or documented by the relevant vendor. [VERIFIED: mix help docs] [VERIFIED: mix hex.publish --dry-run --yes] [CITED: https://docs.github.com/en/actions/reference/security/secure-use]

**Research date:** 2026-04-23
**Valid until:** 2026-05-23 for repo-specific observations; re-verify tool versions before implementation after that date. [VERIFIED: research review]
