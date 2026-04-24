# Phase 09: Preview Posture Lock - Research

**Researched:** 2026-04-23
**Domain:** Preview support-contract hardening, repo-truth documentation, and narrow drift enforcement for an embedded Phoenix OAuth/OIDC library
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a two-tier public posture: keep `README.md` concise and Phoenix-library-friendly, while making `docs/supported-surface.md` the canonical preview contract that defines audience, supported scope, non-goals, proof posture, and `v0.1` boundaries.
- **D-02:** Public wording must keep Lockspire framed as an embedded Phoenix/Elixir library added to an existing host app, not a hosted auth service, CIAM suite, or separate identity product.
- **D-03:** The canonical preview contract should state the exact repo-proven surface in decisive language: auth code + PKCE, OIDC discovery/JWKS, userinfo, revocation, introspection, refresh rotation, host-owned login/consent seams, operator/admin workflows, and generator-backed install flow.
- **D-04:** Public docs should explicitly name the intended posture as `v0.1` preview and avoid vague "production-ready", broad compatibility, or unsupported protocol claims.

### Proof surface
- **D-05:** Preview claims should point to repo-owned proof first: named test suites, executable onboarding flow, checked-in workflows, and versioned docs. Lockspire should not rely on a demo app, external environment state, or unverifiable maintainer folklore as the primary public proof surface.
- **D-06:** The public proof story should be a curated CI-backed proof index plus one executable install/onboarding path. The canonical onboarding guide and generated-host proof remain the user-facing evidence for "this works in a Phoenix host app"; deeper protocol and release claims should point to the relevant test lanes and workflow docs.
- **D-07:** Do not introduce a maintained reference provider app or certification-style public claim as part of Phase 9. Those add drift and support burden that do not fit the current preview-hardening goal.

### Drift-test scope
- **D-08:** Phase 9 contract tests should follow the Phase 8 pattern: narrow ExUnit sentinel invariants over material trust claims, not prose snapshots or large markdown-schema enforcement.
- **D-09:** The preview-posture drift suite should lock only the claims that materially affect honesty and user expectations: preview-only `v0.1` posture, supported surface, explicit out-of-scope items, secure defaults, private disclosure path, and PAR-next-but-not-supported wording.
- **D-10:** Cross-file consistency checks are allowed only where they prevent dishonest divergence between README, supported-surface docs, security policy, workflow/runbook posture, and roadmap state. Avoid regex-heavy checks, duplicated release-path assertions, and tests that freeze harmless wording.

### PAR handoff shape
- **D-11:** PAR should be documented only as the next roadmap/milestone candidate and explicitly marked as not implemented, not advertised in discovery/metadata, and not supported in `v1.1`.
- **D-12:** Do not add PAR to current support matrices, feature lists, examples, operator docs, or any wording that could be mistaken for partial support or near-term interoperability.
- **D-13:** If contributor-facing docs need future-shape guidance, they may mention PAR as a later protocol-expansion seam, but Phase 9 must not add placeholders, public badges, or aspirational API/documentation surface that implies implementation work has started.

### the agent's Discretion
- Exact wording and placement of the preview-contract links, as long as `docs/supported-surface.md` remains the canonical source for public support posture.
- Whether preview-posture drift assertions live in the existing release-readiness contract test or a nearby companion contract test, as long as they stay narrow and reviewable.
- The exact phrasing of the PAR future-work note, as long as it remains clearly out of current scope and cannot be read as present support.

### Deferred Ideas (OUT OF SCOPE)
- Public certification/conformance claims or badges — later milestone once Lockspire has a stable, certifiable surface that the library can honestly own.
- Maintained demo/reference provider app as a first-class proof artifact — deferred unless the project intentionally decides to support it as real surface area.
- Any PAR implementation work, metadata signaling, examples, or compatibility claims — explicitly deferred to the next milestone candidate.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POST-01 | Public docs and supported-surface guidance describe only the implemented `v0.1` preview scope and explicitly avoid unsupported protocol claims. | Make `docs/supported-surface.md` the canonical contract, keep `README.md` short and linked, and align `SECURITY.md`, onboarding, and maintainer docs to the same exact supported/out-of-scope surface. [VERIFIED: 09-CONTEXT.md] [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: docs/maintainer-release.md] |
| POST-02 | Contract tests fail if release docs, security policy, or workflow files drift from the supported preview posture. | Extend the existing narrow file-assertion pattern in `test/lockspire/release_readiness_contract_test.exs` to lock only trust-bearing invariants across README, supported-surface docs, security policy, release guidance, workflow posture, and roadmap language. [VERIFIED: 09-CONTEXT.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release.yml] |
| POST-03 | The next protocol-expansion milestone is documented as PAR, but PAR itself is not added during v1.1. | Keep PAR language in roadmap/project/planning metadata as the next milestone candidate and explicitly keep it out of present-tense support docs, discovery claims, examples, and current support matrices. [VERIFIED: 09-CONTEXT.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Lockspire must remain a separate embedded companion library rather than a required standalone auth service. [VERIFIED: AGENTS.md]
- Host apps must continue owning accounts, login UX, layouts, branding, and product policy; the public preview contract should not imply Lockspire owns those concerns. [VERIFIED: AGENTS.md]
- Phase 9 must preserve the existing narrow OAuth/OIDC wedge and must not broaden v1 into SAML, LDAP/AD federation, hosted auth, or full CIAM scope. [VERIFIED: AGENTS.md]
- The public posture should continue preserving secure defaults including PKCE S256, exact redirect matching, hashed client secrets, short-lived single-use authorization codes, refresh-family revocation on reuse, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]

## Summary

Phase 9 should be planned as a documentation-and-contract-tightening phase, not as a new product-surface phase. The repo already contains the canonical artifact split the user chose: a concise `README.md`, a dedicated `docs/supported-surface.md`, a security policy, a maintainer release runbook, checked-in CI/release workflows, and existing contract tests that assert trust-bearing file invariants. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md] [VERIFIED: docs/maintainer-release.md] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release.yml] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

The strongest planning move is to declare one canonical truth source and make everything else point back to it. `docs/supported-surface.md` already has the right shape for audience, in-scope/out-of-scope surface, preview bar, and `1.0` bar, while `README.md` already links to it and names the exact `v0.1` feature set in concise library language. Phase 9 therefore should tighten that document into the hard preview contract, then make `README.md`, `SECURITY.md`, `docs/install-and-onboard.md`, and `docs/maintainer-release.md` echo only the small subset of claims they need. [VERIFIED: docs/supported-surface.md] [VERIFIED: README.md] [VERIFIED: SECURITY.md] [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/maintainer-release.md]

The proof surface is also already present and runnable. The current repo exposes one canonical onboarding guide, one generator proof, one end-to-end onboarding proof, a contributor gate via `mix ci`, and a protected release workflow that documents where authenticated release proof begins; all three named proof tests passed in this research session. That means the plan should curate those existing proofs into a public proof index instead of inventing a demo app, a new conformance badge, or broad prose-heavy “supported” language. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release.yml] [VERIFIED: mix test test/lockspire/release_readiness_contract_test.exs] [VERIFIED: MIX_ENV=test mix test test/integration/install_generator_test.exs] [VERIFIED: MIX_ENV=test mix test --include integration test/integration/phase6_onboarding_e2e_test.exs]

**Primary recommendation:** Plan Phase 9 around one canonical preview contract (`docs/supported-surface.md`), one curated repo-owned proof map, one narrow ExUnit drift suite, and one roadmap-only PAR note that is explicitly not current support. [VERIFIED: 09-CONTEXT.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: .planning/ROADMAP.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical public support contract | Documentation | Planning Metadata | `docs/supported-surface.md` already carries the support matrix and preview/`1.0` threshold language, while roadmap/project files carry milestone intent. [VERIFIED: docs/supported-surface.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] |
| Entry-point framing for users | README / Docs Index | Documentation | `README.md` is the public entrypoint and already links users into the guide set instead of trying to restate every rule. [VERIFIED: README.md] |
| Proof of install/onboarding reality | Executable Tests | Documentation | `docs/install-and-onboard.md` names the generator test and onboarding E2E test as the canonical proof path. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] |
| Proof of release/support honesty | Contract Tests | CI / Workflow | `test/lockspire/release_readiness_contract_test.exs` already checks trust-bearing file posture against checked-in workflow and mix aliases. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release.yml] [VERIFIED: mix.exs] |
| PAR-next without present-support leakage | Planning Metadata | Contract Tests | The roadmap and project docs already position PAR as the next milestone candidate; Phase 9 should lock that wording and prevent it from appearing as current support. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.5` | Defines the host-framework context the preview contract should describe. | The public posture is explicitly for an embedded Phoenix app, not a generic hosted provider product. [VERIFIED: AGENTS.md] |
| Phoenix LiveView | `1.1.28` | Anchors the operator/admin surface that is part of the current proven scope. | The README and supported-surface docs include LiveView-native admin workflows as part of `v0.1`. [VERIFIED: AGENTS.md] [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] |
| Ecto SQL | `3.13.5` | Anchors the durable storage posture behind the currently proven flow. | The repo stack and integration tests assume the embedded library runs against the existing Ecto/Postgres backing model. [VERIFIED: AGENTS.md] [VERIFIED: mix.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] |
| PostgreSQL | `14+` | Provides the maintained durable test/runtime shape. | CI spins PostgreSQL services and local probes show PostgreSQL 14 tooling is available in this environment. [VERIFIED: AGENTS.md] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: pg_isready --version] [VERIFIED: psql --version] |
| ExUnit | `bundled with Elixir 1.19.5 in this environment` | Provides the narrow contract-test mechanism Phase 9 should reuse. | The repo already uses ExUnit for file-sentinel contract checks and the local Elixir/Mix toolchain is present. [VERIFIED: test/test_helper.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: elixir --version] [VERIFIED: mix --version] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Mix aliases | `repo-defined` | Provide the canonical contributor and release proof commands: `mix ci`, `mix docs.verify`, `mix release.preflight`, `mix test.integration`, and `mix test.phase3`. | Use these aliases as proof labels in docs and validation instead of inventing new one-off command names. [VERIFIED: mix.exs] |
| GitHub Actions | `checked-in workflow config at repo HEAD` | Supplies the CI-backed proof lanes that Phase 9 should cite for contributor and trusted release posture. | Use workflow files as canonical evidence boundaries for public claims about CI and release discipline. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release.yml] |
| Release Please config | `checked-in repo config at repo HEAD` | Keeps preview versioning and release policy reviewable in git. | Use as supporting proof for release posture, not as a public feature list. [VERIFIED: release-please-config.json] [VERIFIED: .release-please-manifest.json] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `docs/supported-surface.md` as canonical contract | A new support-policy or compatibility-matrix document | Adds another source of truth with no new proof value and increases drift risk. [VERIFIED: docs/supported-surface.md] [VERIFIED: 09-CONTEXT.md] |
| Narrow ExUnit sentinel assertions | Markdown snapshots or regex-heavy schema enforcement | Snapshot-style tests would freeze harmless prose and make review harder than the current release-readiness pattern. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: 09-CONTEXT.md] |
| Repo-owned proof index | Demo/reference provider app or public certification posture | Both add maintenance burden and imply broader support than the current milestone intends to claim. [VERIFIED: 09-CONTEXT.md] |

**Installation:**
```bash
# No new packages are recommended for Phase 9.
# Reuse the existing repo stack, docs corpus, workflows, and ExUnit contract-test layer.
```

**Version verification:** The phase does not require adding dependencies; the relevant stack versions were verified from `AGENTS.md`, `mix.exs`, checked-in workflows, and local tool probes during this session. [VERIFIED: AGENTS.md] [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release.yml] [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: pg_isready --version] [VERIFIED: psql --version]

## Architecture Patterns

### System Architecture Diagram

```text
repo truth at HEAD
  |
  +--> README.md -----------------------------+
  |                                           |
  +--> docs/supported-surface.md ------------ | --> public preview contract
  |                                           |     - audience
  +--> SECURITY.md -------------------------- |     - supported scope
  |                                           |     - non-goals
  +--> docs/install-and-onboard.md ---------- |     - proof map
  |                                           |     - preview-only posture
  +--> docs/maintainer-release.md -----------+
  |
  +--> mix.exs aliases ------------+
  |                                |
  +--> .github/workflows/ci.yml ---+--> repo-owned proof lanes
  |                                |     - contributor gate
  +--> .github/workflows/release.yml      - trusted release boundary
  |
  +--> integration proofs ------------------> install/onboard evidence
  |
  +--> contract tests ----------------------> drift lock on trust claims
  |
  +--> roadmap/project docs ----------------> PAR-next planning only
```

The phase architecture is “documentation backed by executable proof,” not “documentation backed by intent.” Public claims should flow from checked-in docs and runnable proof files, then be re-checked by contract tests. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: docs/install-and-onboard.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]

### Recommended Project Structure
```text
README.md                         # concise public entrypoint and link hub
docs/
├── supported-surface.md          # canonical preview contract
├── install-and-onboard.md        # canonical host-app proof guide
├── maintainer-release.md         # release/runbook posture tied to repo proof
└── getting-started.md            # supporting docs, not support-policy authority
SECURITY.md                       # private disclosure path and supported security surface
.planning/
├── PROJECT.md                    # milestone posture and next-step framing
├── ROADMAP.md                    # PAR-next candidate, not current support
└── REQUIREMENTS.md               # POST-01..03 truth source
test/lockspire/
└── release_readiness_contract_test.exs  # narrow drift invariants
test/integration/
├── install_generator_test.exs    # generator-backed install proof
└── phase6_onboarding_e2e_test.exs # onboarding/OIDC proof
```

### Pattern 1: One Canonical Contract, Many Short Echoes
**What:** Put the full preview contract in `docs/supported-surface.md`, then keep `README.md`, `SECURITY.md`, onboarding, and release docs intentionally thinner and referential. [VERIFIED: docs/supported-surface.md] [VERIFIED: README.md] [VERIFIED: SECURITY.md] [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/maintainer-release.md]  
**When to use:** Any claim about audience, supported scope, non-goals, preview posture, or `1.0` threshold. [VERIFIED: docs/supported-surface.md]  
**Example:**
```markdown
<!-- Source: README.md + docs/supported-surface.md -->
- [Supported surface](docs/supported-surface.md)
```

### Pattern 2: Proof by Named Repo Artifacts
**What:** Public docs should point to named tests, workflows, mix aliases, and versioned docs rather than to maintainers’ intent or external environments. [VERIFIED: 09-CONTEXT.md] [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/maintainer-release.md]  
**When to use:** Install/onboard proof, contributor-gate proof, release-lane proof, and security/reporting posture. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/maintainer-release.md] [VERIFIED: SECURITY.md]  
**Example:**
```elixir
# Source: test/lockspire/release_readiness_contract_test.exs
assert guide =~ "`mix ci` is the maintained contributor lane"
assert release_workflow =~ "run: mix release.preflight"
```

### Pattern 3: Sentinel Assertions Over Material Trust Claims
**What:** Lock only the smallest set of phrases whose drift would change user expectations or honesty. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: 09-CONTEXT.md]  
**When to use:** Preview-only `v0.1` posture, supported surface, out-of-scope items, secure defaults, private disclosure path, and PAR-next-not-supported wording. [VERIFIED: 09-CONTEXT.md]  
**Example:**
```elixir
# Source: test/lockspire/release_readiness_contract_test.exs
assert guide =~ "public docs and `SECURITY.md` still match the supported surface"
```

### Anti-Patterns to Avoid
- **New policy artifact:** Creating another “support policy” doc would duplicate `docs/supported-surface.md` and dilute authority. [VERIFIED: docs/supported-surface.md] [VERIFIED: 09-CONTEXT.md]
- **Prose snapshot tests:** Snapshotting large markdown files would freeze harmless edits and make drift review noisy. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: 09-CONTEXT.md]
- **Aspirational PAR hints in current docs:** Adding PAR to feature lists, examples, discovery claims, or operator docs would read as partial support. [VERIFIED: 09-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]
- **Demo-app-as-proof:** A maintained reference app would create extra surface area that the current preview posture does not want to own. [VERIFIED: 09-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Support policy sprawl | A new support-policy framework or matrix generator | `docs/supported-surface.md` as the canonical contract | The repo already has the right artifact; adding machinery increases drift without increasing proof. [VERIFIED: docs/supported-surface.md] [VERIFIED: 09-CONTEXT.md] |
| Doc drift enforcement | Markdown AST snapshot tooling | Small ExUnit file assertions | The repo already has a readable, reviewable contract-test style that matches the phase decisions. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: 09-CONTEXT.md] |
| Present-tense future signaling | PAR placeholders in product docs, examples, or metadata | Roadmap/project note that explicitly says “next milestone candidate, not current support” | This preserves forward direction without misrepresenting the current preview surface. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: 09-CONTEXT.md] |
| Proof narrative | Demo app, certification badge, or folklore-based support claims | Named repo-owned tests, workflows, and versioned docs | The current milestone values evidence that is checked in and runnable. [VERIFIED: 09-CONTEXT.md] [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/maintainer-release.md] |

**Key insight:** Phase 9 should harden trust by reducing the number of authoritative statements, not by increasing the amount of documentation. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: 09-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating the README as the full contract
**What goes wrong:** The README grows into a second support matrix and drifts from the canonical support doc. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md]  
**Why it happens:** README is the first file people edit when tightening public posture. [ASSUMED]  
**How to avoid:** Keep README concise, link to `docs/supported-surface.md`, and move detailed scope language there. [VERIFIED: 09-CONTEXT.md] [VERIFIED: README.md]  
**Warning signs:** README starts restating every supported/non-supported feature or release threshold. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md]

### Pitfall 2: Freezing wording instead of freezing claims
**What goes wrong:** Drift tests become fragile and block harmless copy edits. [VERIFIED: 09-CONTEXT.md]  
**Why it happens:** It is easy to assert entire headings or paragraphs when checking markdown files. [ASSUMED]  
**How to avoid:** Assert only claim-bearing phrases such as `v0.1` preview posture, explicit out-of-scope items, secure defaults, disclosure path, and PAR-next-not-supported wording. [VERIFIED: 09-CONTEXT.md]  
**Warning signs:** Tests start matching broad sections, exact list order, or stylistic copy rather than trust-bearing content. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: 09-CONTEXT.md]

### Pitfall 3: Letting PAR leak into present-tense support
**What goes wrong:** Users infer partial PAR support from docs or examples even though the roadmap only names it as a future milestone. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: 09-CONTEXT.md]  
**Why it happens:** “What’s next” language often gets added to feature matrices, install guides, or protocol docs. [ASSUMED]  
**How to avoid:** Keep PAR language in roadmap/project planning artifacts or explicitly future-facing contributor notes only, with “not implemented” and “not supported in v1.1” wording. [VERIFIED: 09-CONTEXT.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md]  
**Warning signs:** PAR appears in README feature bullets, supported-surface in-scope lists, metadata claims, or operator docs. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: 09-CONTEXT.md]

### Pitfall 4: Calling release discipline “proof” without naming the actual boundary
**What goes wrong:** Docs imply that release PRs or local dry-runs are equivalent to the protected publish lane. [VERIFIED: docs/maintainer-release.md] [VERIFIED: .github/workflows/release.yml]  
**Why it happens:** Release workflows have several evidence layers and they are easy to collapse into one statement. [VERIFIED: docs/maintainer-release.md]  
**How to avoid:** Keep the repo-owned proof, GitHub-settings proof, and workflow-run proof separated exactly as the maintainer guide does now. [VERIFIED: docs/maintainer-release.md]  
**Warning signs:** Docs stop distinguishing “review-only Release Please PR” from “trusted proof starts only after merge in the protected `hex-publish` lane.” [VERIFIED: docs/maintainer-release.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Code Examples

Verified patterns from repo sources:

### Narrow Contract Assertion
```elixir
# Source: test/lockspire/release_readiness_contract_test.exs
guide = File.read!(@maintainer_guide_path)
assert guide =~ "`mix ci` is the maintained contributor lane"
assert guide =~ "public docs and `SECURITY.md` still match the supported surface"
```

### Canonical Onboarding Proof References
```markdown
# Source: docs/install-and-onboard.md
The executable repo proof lives in:

- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad implementation milestone first | Polish-first release hardening before new protocol breadth | `v1.1` planning on 2026-04-23 | Public claims should stay narrow until repo proof and release posture are boring and repeatable. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] |
| Future protocol candidates left implicit | PAR named explicitly as the next milestone candidate | `v1.1` planning on 2026-04-23 | Phase 9 should document direction without implying present support. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] |
| Release-doc truthfulness enforced mainly for release mechanics | Release-doc truthfulness now needs preview-surface drift locks too | Phase 9 scope defined on 2026-04-23 | The contract-test layer should expand slightly from release-lane honesty into preview-posture honesty. [VERIFIED: 09-CONTEXT.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

**Deprecated/outdated:**
- Broad “production-ready” or vague compatibility claims for `v0.1`: they contradict the locked preview posture and should not appear in public docs. [VERIFIED: 09-CONTEXT.md]
- PAR hints in current support matrices or examples: they conflict with the requirement that PAR is next, not current. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: 09-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | README is the file most likely to grow into an accidental second contract during posture edits. | Common Pitfalls | Low; the mitigation still stands because the user already chose README-short plus canonical support doc. |
| A2 | Teams commonly over-assert whole markdown sections when writing drift tests. | Common Pitfalls | Low; if this repo would not do that, the recommended narrow sentinel style is still consistent with existing tests and user decisions. |
| A3 | “What’s next” protocol language tends to leak from roadmap intent into public docs unless explicitly fenced. | Common Pitfalls | Medium; if this risk is lower here, the plan still benefits from an explicit PAR-only-in-planning rule. |

## Open Questions

1. **Should preview-posture assertions stay inside `test/lockspire/release_readiness_contract_test.exs` or move into a nearby companion file?**
   - What we know: The existing release-readiness contract already asserts narrow trust-bearing file invariants and is the established style for this repo. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
   - What's unclear: Whether adding preview-posture checks there keeps the file readable enough, or whether a second adjacent contract file would review more cleanly. [VERIFIED: 09-CONTEXT.md]
   - Recommendation: Default to extending the existing file first; split only if the assertions stop reading as one coherent trust-contract suite. [VERIFIED: 09-CONTEXT.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

2. **Where should the PAR-next note live outside planning metadata, if anywhere?**
   - What we know: The user allows contributor-facing future-shape guidance, but forbids present-support signaling in current support docs and matrices. [VERIFIED: 09-CONTEXT.md]
   - What's unclear: Whether any non-planning file needs a PAR mention beyond roadmap/project docs. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md]
   - Recommendation: Treat planning metadata as sufficient by default; only mention PAR elsewhere if the sentence is explicitly future-facing and equally explicit that PAR is not implemented and not supported in `v1.1`. [VERIFIED: 09-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Running contract tests and docs checks | ✓ | `1.19.5` | — [VERIFIED: elixir --version] |
| Mix | Running `mix docs.verify`, targeted tests, and `mix ci` | ✓ | `1.19.5` | — [VERIFIED: mix --version] |
| Git | Normal repo inspection and commit flow | ✓ | `2.41.0` | — [VERIFIED: git --version] |
| PostgreSQL client tools | Full integration/onboarding proof and CI parity investigation | ✓ | `14.17` | Use existing local PostgreSQL service rather than Docker if needed. [VERIFIED: pg_isready --version] [VERIFIED: psql --version] |
| Docker | Matching GitHub Actions service-backed runs locally if desired | ✓ | `29.3.1` | Use local PostgreSQL directly for targeted ExUnit runs. [VERIFIED: docker --version] |
| GitHub CLI | Inspecting live workflow or environment settings if Phase 9 needs maintainer proof follow-up | ✓ | `2.89.0` | Browser/manual GitHub UI check. [VERIFIED: gh --version] |

**Missing dependencies with no fallback:**
- None for planning or for the narrow Phase 9 doc/contract work. [VERIFIED: elixir --version] [VERIFIED: mix --version]

**Missing dependencies with fallback:**
- None. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: pg_isready --version] [VERIFIED: docker --version]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: test/test_helper.exs] [VERIFIED: elixir --version] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/lockspire/release_readiness_contract_test.exs`. [VERIFIED: mix.exs] [VERIFIED: mix test test/lockspire/release_readiness_contract_test.exs] |
| Full suite command | `mix ci`. [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| POST-01 | Public docs only claim the proven `v0.1` preview surface and keep unsupported protocol claims out. | contract | `mix test test/lockspire/release_readiness_contract_test.exs` after Phase 9 extends it or its companion file. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | ✅ existing contract file; Phase 9 adds assertions. |
| POST-02 | Drift between README, supported-surface docs, security policy, release docs, workflows, and roadmap state fails fast. | contract | `mix test test/lockspire/release_readiness_contract_test.exs`. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | ✅ |
| POST-03 | PAR is recorded as next but not current support. | contract + docs | `mix test test/lockspire/release_readiness_contract_test.exs` plus `mix docs.verify`. [VERIFIED: mix.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/lockspire/release_readiness_contract_test.exs`. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- **Per wave merge:** `mix docs.verify` and the targeted contract test. [VERIFIED: mix.exs]
- **Phase gate:** `mix ci` plus the canonical onboarding proofs if Phase 9 edits their referenced docs materially. [VERIFIED: mix.exs] [VERIFIED: docs/install-and-onboard.md]

### Wave 0 Gaps
- [ ] Add preview-posture sentinel assertions for `README.md`, `docs/supported-surface.md`, `SECURITY.md`, and planning metadata into the existing release-readiness contract or an adjacent companion file. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: 09-CONTEXT.md]
- [ ] Add explicit PAR-next-not-supported drift coverage so roadmap/project future-work wording cannot leak into current support claims. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: 09-CONTEXT.md]
- [ ] Decide whether `docs/install-and-onboard.md` should be asserted directly or only treated as proof referenced from the canonical contract. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: 09-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep public claims aligned to the current host-owned login seam and auth-code + PKCE surface only. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: AGENTS.md] |
| V3 Session Management | no | Phase 9 should not broaden Lockspire into host-login/session ownership; that remains explicitly host-owned. [VERIFIED: AGENTS.md] [VERIFIED: SECURITY.md] |
| V4 Access Control | yes | Preserve the current supported operator/admin scope without implying additional hosted-product capabilities. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] |
| V5 Input Validation | yes | Contract tests should validate the integrity of trust-bearing file claims so unsupported protocol promises cannot drift in silently. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: 09-CONTEXT.md] |
| V6 Cryptography | yes | The preview contract should continue naming the existing secure defaults, including PKCE S256, hashed client secrets, and no `alg=none`. [VERIFIED: README.md] [VERIFIED: SECURITY.md] [VERIFIED: AGENTS.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsupported capability signaling in public docs | Spoofing | Centralize the support contract in `docs/supported-surface.md` and keep other docs referential. [VERIFIED: docs/supported-surface.md] [VERIFIED: README.md] |
| Cross-file posture drift | Tampering | Use narrow ExUnit sentinel assertions over trust-bearing phrases and workflow boundaries. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: 09-CONTEXT.md] |
| PAR future-work language read as current support | Repudiation | Keep PAR in roadmap/project planning language and assert “not implemented” / “not supported in v1.1” wording. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: 09-CONTEXT.md] |
| Collapsing release evidence boundaries into one vague statement | Repudiation | Preserve the maintainer guide’s separate repo-proof, GitHub-settings, and workflow-run evidence buckets. [VERIFIED: docs/maintainer-release.md] |

## Sources

### Primary (HIGH confidence)
- `AGENTS.md` - project boundaries, stack versions, product priorities, and security defaults. [VERIFIED: AGENTS.md]
- `.planning/phases/09-preview-posture-lock/09-CONTEXT.md` - locked decisions, proof-surface rules, drift-test scope, and PAR handoff posture. [VERIFIED: 09-CONTEXT.md]
- `.planning/PROJECT.md` - milestone thesis, current `v0.1` preview posture, and PAR-next sequencing. [VERIFIED: .planning/PROJECT.md]
- `.planning/ROADMAP.md` - Phase 9 goal, plan titles, and next milestone candidate. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - POST-01, POST-02, and POST-03 requirements. [VERIFIED: .planning/REQUIREMENTS.md]
- `README.md` - current public entrypoint, in-scope/out-of-scope surface, and guide links. [VERIFIED: README.md]
- `docs/supported-surface.md` - current canonical support-surface draft. [VERIFIED: docs/supported-surface.md]
- `SECURITY.md` - private disclosure path and supported security surface. [VERIFIED: SECURITY.md]
- `docs/maintainer-release.md` - release evidence boundaries and preview posture. [VERIFIED: docs/maintainer-release.md]
- `docs/install-and-onboard.md` - canonical onboarding guide and proof references. [VERIFIED: docs/install-and-onboard.md]
- `mix.exs` - contributor/release aliases and docs extras. [VERIFIED: mix.exs]
- `.github/workflows/ci.yml` and `.github/workflows/release.yml` - CI/release proof lanes. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release.yml]
- `test/lockspire/release_readiness_contract_test.exs` - existing narrow contract-test pattern. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- `test/integration/install_generator_test.exs` and `test/integration/phase6_onboarding_e2e_test.exs` - current canonical onboarding proofs. [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]
- Local tool probes and targeted test runs executed during this session. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: git --version] [VERIFIED: pg_isready --version] [VERIFIED: psql --version] [VERIFIED: docker --version] [VERIFIED: gh --version] [VERIFIED: mix test test/lockspire/release_readiness_contract_test.exs] [VERIFIED: MIX_ENV=test mix test test/integration/install_generator_test.exs] [VERIFIED: MIX_ENV=test mix test --include integration test/integration/phase6_onboarding_e2e_test.exs]

### Secondary (MEDIUM confidence)
- None. All planning-critical claims in this research were verified directly from repo sources or local execution. [VERIFIED: repo grep]

### Tertiary (LOW confidence)
- Pitfall-likelihood statements about common editing behavior are assumptions called out in the Assumptions Log. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 9 reuses the already-declared repo stack and does not depend on unverified new dependencies. [VERIFIED: AGENTS.md] [VERIFIED: mix.exs]
- Architecture: HIGH - The recommended shape is derived directly from existing docs, workflows, planning files, and contract tests already present in the repo. [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- Pitfalls: MEDIUM - The repo-specific drift risks are well grounded, but a few “how teams usually regress” explanations are intentionally marked as assumptions. [VERIFIED: 09-CONTEXT.md] [ASSUMED]

**Research date:** 2026-04-23
**Valid until:** 2026-05-23
