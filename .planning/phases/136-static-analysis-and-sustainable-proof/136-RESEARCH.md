# Phase 136: Static Analysis and Sustainable Proof - Research

**Researched:** 2026-08-27  
**Domain:** Elixir static analysis, behavior-oriented test proof, and deterministic test-runtime logging  
**Confidence:** HIGH

## User Constraints

### Locked Decisions

No Phase 136 CONTEXT.md exists. The roadmap and requirements are binding: make every library source file subject to Credo without file-wide suppression; replace admin/release proof archaeology and count contracts with capability-oriented behavior checks; make ordinary successful test runs quiet without weakening failure/redaction assertions; and leave compilation, strict Credo, zero-warning Dialyzer, ExDoc, package build, and focused integration proof green. [VERIFIED: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

### the agent's Discretion

- Choose the smallest capability helper modules and test migration order.
- Split or refactor source modules where that removes a real Credo/Dialyzer issue.
- Choose the exact quiet-test harness, so long as expected failure/redaction evidence remains asserted.

### Deferred Ideas (OUT OF SCOPE)

- Router-wide Sobelow policy, coverage aggregation/floor changes, CI workflow restructuring, OIDC/FAPI external conformance, immutable release evidence, and package-install publication proof belong to Phase 137.
- New protocol grants, hosted auth, product policy, database schema changes, and admin UI redesign remain out of scope. [VERIFIED: `.planning/ROADMAP.md`, `AGENTS.md`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QUAL-01 | Credo evaluates every library source file without file-wide suppression; remaining suppressions are local, named, narrow, and justified. | Current exclusion/suppression inventory and source-first remediation strategy. |
| QUAL-02 | Admin and release proof uses small capability helpers and behavioral assertions rather than injected macros, count contracts, or obsolete phase archaeology. | Helper decomposition and test ownership map. |
| QUAL-03 | Successful routine tests emit no KeyCache errors, Ecto query flood, or telemetry handler warnings while failure/redaction assertions remain effective. | Startup ordering/log-level and telemetry lifecycle plan. |
| QUAL-04 | Compilation, strict Credo, zero-warning Dialyzer, ExDoc, package build, and focused integration proof stay green. | Exact baseline, warning clusters, and incremental validation matrix. |
</phase_requirements>

## Summary

The project already runs strict Credo through `scripts/ci/run_credo.sh`, uses a 30-second parse timeout, and fails if Credo reports unparsed configured files. However, `.credo.exs` includes all of `lib/` and `test/`, while three library modules are globally suppressed (`protocol/dpop.ex`, `protocol/jar.ex`, and `protocol/request_object.ex`). Eleven more library locations use next-line directives, four of which omit the check name. The required end state is a strict full-library run with only named, local exceptions that explain a legitimate protocol/security complexity boundary. [VERIFIED: `.credo.exs`, `scripts/ci/run_credo.sh`, local suppression inventory; CITED: https://hexdocs.pm/credo/config_comments.html]

`mix qa.dialyzer` currently fails with 66 project warnings across 22 files. The dominant clusters are recent Phase 134/135 collaborator typing: `ClientLifecycle` (11), repository facade (10), internal refresh exchange (11), `GrantSupport` (7), registration management (6), and token issuer (4). They are primarily `no_return`, `pattern_match`, `unused_fun`, `call`, and invalid-contract evidence, not dependency noise; the project intentionally has no ignore file. Fix types and unreachable branching at their owning facade/collaborator seams rather than adding an ignore baseline. [VERIFIED: fresh `mix qa.dialyzer` run on 2026-08-27; CITED: https://github.com/jeremyjh/dialyxir]

The test-quality debt is concrete and bounded. `AdminContractHelpers` is a 1,606-line `__using__/1` macro that injects dozens of `@phase_*` paths, milestone-artifact reads, and proof routines into three active contract suites. `ReleaseContractHelpers` similarly injects a large catalog of unrelated paths into three release suites. `release_readiness_contract_test.exs` enforces 47 named historical capabilities and at least 588 textual assertions rather than checking current observable release properties. Routine test startup starts `KeyCache` before `mix test`'s alias has migrated the database, and its asynchronous initial refresh logs an error when the signing-key table is unavailable; test config does not suppress Ecto debug logging. [VERIFIED: `test/support/admin_contract_helpers.ex`, `test/support/release_contract_helpers.ex`, `test/lockspire/release_readiness_contract_test.exs`, `Lockspire.Application`, `Lockspire.KeyCache`, `mix.exs`, `config/test.exs`]

**Primary recommendation:** make static-quality proof a sequence of small, behavior-preserving extractions: establish targeted regression tests, remove library-wide Credo bypasses, resolve all Dialyzer warnings at public/internal seam boundaries, turn macros into imported capability helpers, and introduce a test-only quiet-runtime policy that treats startup-before-migration as expected while preserving explicit `capture_log` and telemetry assertions.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Credo scope and local suppression policy | Build/tooling | Library source | Tooling must scan all `lib/`; source code must explain isolated complexity. [VERIFIED: `.credo.exs`, `scripts/ci/run_credo.sh`] |
| Dialyzer types and unreachable paths | Library protocol/storage/admin collaborators | Build/tooling | Owner modules, not a warning file, define correct return contracts and branches. [VERIFIED: Dialyzer baseline] |
| Admin proof behavior | Test capability helpers | Admin LiveView/source routes | Tests should own current source/HTML behavior; historical plans are not runtime dependencies. [VERIFIED: `AdminContractHelpers` usage] |
| Release proof behavior | Test capability helpers | Current docs/workflows/package config | Release contracts should inspect durable current artifacts only. [VERIFIED: `ReleaseContractHelpers` usage] |
| Quiet routine execution | Test config and test support | OTP children/Ecto/telemetry | Test environment controls log level/startup handling; application failures remain observable in dedicated tests. [VERIFIED: config, application, KeyCache] |

## Project Constraints (from AGENTS.md)

- Keep Lockspire an embedded companion library, not a standalone authorization service.
- Preserve protocol, storage, generators, Plug/Phoenix, and LiveView/admin boundaries.
- Keep account resolution, claims, login redirects, branding, and product policy at the narrow host seam.
- Do not add SAML, LDAP/AD, hosted auth, or CIAM scope.
- Preserve PKCE S256, exact redirect matching, hashed client secrets, short-lived single-use codes, refresh-family replay revocation, no implicit flow/`alg=none`, and log/operator redaction. [VERIFIED: `AGENTS.md`]

## Standard Stack

### Core

| Tool/library | Version | Purpose | Why standard |
|--------------|---------|---------|--------------|
| Credo | `~> 1.7` | Strict source analysis and local directives | Already installed and used by the project-wide strict runner. [VERIFIED: `mix.exs`, local `mix credo --strict --format oneline`] |
| Dialyxir | `~> 1.4` | Dialyzer analysis and PLT lifecycle | Already installed with project-local PLT locations. [VERIFIED: `mix.exs`, fresh `mix qa.dialyzer`; CITED: https://dialyxir.hexdocs.pm/] |
| ExUnit / ExUnit.CaptureLog | Elixir 1.19.5 | Behavior, log, and telemetry assertions | Existing tests use explicit captures and attach/detach handlers. [VERIFIED: local runtime, test inventory] |
| Ecto SQL | `~> 3.13.5` | Test sandbox and SQL logging control | Existing test repo is an Ecto SQL sandbox. [VERIFIED: `mix.exs`, `config/test.exs`] |

**Installation:** none. This phase must not add packages; the required tools and test framework are already dependencies. [VERIFIED: phase scope, `mix.exs`]

## Package Legitimacy Audit

No external packages are installed. [VERIFIED: phase scope]

## Architecture Patterns

### System Architecture Diagram

```text
source modules ──> strict Credo / Dialyzer ──> named local exception or source fix
       |                                         |
       v                                         v
 capability tests <── focused helpers <── current code/docs/workflows
       |
       v
 test runtime ──> migrated test DB + quiet SQL ──> KeyCache/telemetry healthy startup
       |
       +── explicit failure/redaction/log and telemetry behavior assertions
```

### Pattern 1: Source-first static-analysis remediation

**What:** retain the full `lib/` Credo include and the existing parse-timeout guard. For each currently file-wide-suppressed library module, split a cohesive validation/parser helper or simplify the function; if a genuine check exception remains, put a `# credo:disable-for-next-line Fully.Named.Check` immediately above that function with a reason stating the protocol invariant it protects.

**Why:** global suppression makes the module invisible to future maintainers. Credo supports named inline next-line configuration; strict mode includes all priorities. [CITED: https://hexdocs.pm/credo/config_comments.html; CITED: https://hexdocs.pm/credo/cli_switches.html]

**Concrete offenders:**

| File | Current state | Safe remediation |
|------|---------------|------------------|
| `lib/lockspire/protocol/dpop.ex` | file-wide Credo bypass | Extract proof/header parsing or verification branches, then retain only named local complexity exceptions if necessary. |
| `lib/lockspire/protocol/jar.ex` | file-wide Credo bypass | Isolate request-object/JWT validation branches behind private helpers; retain fail-closed behavior tests. |
| `lib/lockspire/protocol/request_object.ex` | file-wide Credo bypass | Split retrieval/verification/claim validation; preserve public error struct and discovery behavior. |
| `domain/client.ex`, `jwks_fetcher.ex`, `security/policy.ex`, `authorization_request.ex`, `rfc8693_exchange.ex` | unnamed next-line directives | Name the exact Credo check and add a concise invariant-oriented reason, or refactor it away. |

### Pattern 2: Typed seam repair, never Dialyzer debt hiding

**What:** use `@spec`/types that match actual public return unions, remove branches proven impossible after Phase 135 extraction, and delete dead compatibility/private helpers only after focused behavior tests pass. Do not introduce `.dialyzer_ignore.exs` for project-owned warnings.

**Why:** the current 66 warnings identify contradictory return shapes and stale internal routing around the exact collaborators just extracted. Dialyxir can support granular ignores, but its own documentation presents those for irreducible warnings; here the phase requirement is zero warning Dialyzer. [VERIFIED: fresh baseline, no ignore file; CITED: https://github.com/jeremyjh/dialyxir]

**Remediation order:**

1. Repair `ClientLifecycle`, `RegistrationManagement`, and repository facade contracts so admin/DCR lifecycle calls have one typed result shape.
2. Repair `TokenExchange` facade and grant delegates so `{:ok, Success}` and `{:error, Error}` unions flow through the public result adapter without impossible matching.
3. Delete stale `GrantSupport`/internal refresh functions after call-site proof, then align `TokenIssuer`/storage types with issued token types.
4. Resolve small leaf warnings (`Admin.Tokens`, migration/install tasks, registration controller, LiveViews, token store) and rerun the full strict command after every cluster.

### Pattern 3: Plain capability helper modules, not `__using__` macro state

**What:** replace injected attributes/functions with small `test/support/admin_proof/*` and `test/support/release_proof/*` modules. Each exposes a narrow function returning current inputs or asserting one capability, and consuming tests explicitly `alias`/`import` only what they use. Keep fixtures and HTML behavior assertions near the capability suite.

**Why:** a plain helper has a visible call graph, compiles once, does not import unrelated historical state, and permits individual suites to change without a 1,600-line macro coupling them. [VERIFIED: active macro usages and helper sizes]

**Migration targets:**

| Existing proof | Replace with | Keep | Remove |
|----------------|--------------|------|--------|
| `AdminContractHelpers` route/CSS/design-system readers | `AdminProof.Paths`, `AdminProof.RouteAssertions`, `AdminProof.CssAssertions`, `AdminProof.RedactionAssertions` | Current routes, source/HTML checks, user-facing admin docs | `@phase_109..125_*` state, milestone file reads, phase-named helper APIs |
| `ReleaseContractHelpers` injected paths | `ReleaseProof.Paths`, `ReleaseProof.WorkflowAssertions`, `ReleaseProof.PackageAssertions`, `ReleaseProof.DocumentationAssertions` | Current release workflow/docs/package checks | unused injected paths and phase-specific archaeology |
| `release_readiness_contract_test` 47-name/588-count guard | a small release capability matrix with one behavior per current surface | package/version/workflow/docs truth | assertion count as quality proxy and historical names |

### Pattern 4: Quiet startup is an explicit test-runtime contract

**What:** make test SQL logging quiet through test configuration and arrange KeyCache's initial test-environment refresh so it does not error before `test.setup` migrates the schema. Handle only the known bootstrap-unavailable condition as a deferred/empty cache; preserve logging for unexpected production errors. Use unique telemetry handler IDs plus `on_exit` cleanup, preferably through a small test helper, and retain `capture_log` tests for failure/redaction paths.

**Why:** `Lockspire.Application` starts KeyCache before alias subtask migrations, and KeyCache currently logs every `list_active_keys/0` error. Test output should distinguish expected bootstrap order from a real cache failure. [VERIFIED: `mix test.fast` alias order, application/KeyCache source, test configuration]

**Do not:** disable `Logger` globally, swallow arbitrary storage failures, remove `capture_log` assertions, or reuse literal telemetry handler IDs in asynchronous tests. These would hide the exact failures QUAL-03 still requires to be observable. [VERIFIED: existing capture-log and telemetry attach/detach tests]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Lint baseline | custom parser or broad `.credo` exclusion | existing strict Credo runner + named inline directives | It already checks parse completeness and all configured sources. [VERIFIED: `run_credo.sh`] |
| Type-warning suppression | broad Dialyzer ignore baseline | source/spec repair; only a narrowly documented upstream exception if demonstrated irreducible | Current warnings are project code, not upstream. [VERIFIED: baseline] |
| Log assertions | global logger mute | `capture_log` around the expected failure path | Allows routine quietness without losing failure evidence. [VERIFIED: `verify_token_test.exs`, `access_token_signer_test.exs`] |
| Telemetry test lifecycle | shared handler name registry | unique handler IDs plus `on_exit` detach helper | Avoids cross-test duplicate handler warnings/races. [VERIFIED: current handler patterns] |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | No protocol record/key/schema rename; KeyCache reads existing signing-key rows. | No data migration. Test bootstrap must tolerate pre-migration table absence without treating it as a cache failure. [VERIFIED: phase scope, KeyCache/store source] |
| Live service config | Test logger, Ecto repo, and OTP children come from `config/test.exs`/application start; no external UI-held configuration was found. | Code/config edits only. [VERIFIED: config/application audit] |
| OS-registered state | None in scope. | None — verified by repository-scope audit. |
| Secrets/env vars | DB environment variables configure the test repo but no key names are renamed. | Preserve current env lookup and redaction behavior. [VERIFIED: `config/test.exs`] |
| Build artifacts | Dialyzer PLTs under `priv/plts` are generated and ignored; no package rename is planned. | Rebuild PLTs through normal `mix qa.dialyzer`; do not commit artifacts. [VERIFIED: `mix.exs`, fresh Dialyzer output] |

## Common Pitfalls

### Pitfall 1: “Clean” Credo by hiding whole files

**What goes wrong:** a file-wide directive makes future checks silent, so refactors reintroduce readability debt.  
**Avoid:** source-level extraction first; a named local directive only where the function’s security/protocol complexity is intentional.  
**Warning sign:** `credo:disable-for-this-file` or an unnamed `disable-for-next-line` under `lib/`. [VERIFIED: current inventory]

### Pitfall 2: Zero Dialyzer output by ignore-file baseline

**What goes wrong:** actual no-return and contradictory result paths remain.  
**Avoid:** use the warning clusters as a removal queue, especially the Phase 135 lifecycle/grant seams.  
**Warning sign:** an added generic file/type ignore or `@dialyzer` annotation without an upstream false-positive rationale. [VERIFIED: baseline; CITED: https://github.com/jeremyjh/dialyxir]

### Pitfall 3: Quiet tests that suppress failures

**What goes wrong:** global Logger suppression masks failed key refreshes and redaction regressions.  
**Avoid:** suppress routine Ecto debug output in `config/test.exs`, classify only expected pre-migration KeyCache bootstrap failure, and keep dedicated captured-log tests. [VERIFIED: config and existing log assertions]

### Pitfall 4: Helper extraction that merely moves archaeology

**What goes wrong:** a renamed mega-helper retains phase directories, inventory counts, and broad imports.  
**Avoid:** one helper per current capability, explicit imports, and a source-fitness test rejecting phase-numbered paths/count contracts in active quality tests. [VERIFIED: helper inventory and release readiness test]

## Code Examples

### Named local Credo exception

```elixir
# The compact branch preserves the DPoP error precedence required by the protocol.
# credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
defp verify_proof(...), do: ...
```

Use only after a focused test characterizes the observable behavior. Credo supports named next-line directives. [CITED: https://hexdocs.pm/credo/config_comments.html]

### Test-only explicit telemetry lifecycle

```elixir
handler_id = "feature-test-#{System.unique_integer([:positive])}"
:ok = :telemetry.attach(handler_id, event, handler, self())
on_exit(fn -> :telemetry.detach(handler_id) end)
```

This follows the existing project’s successful pattern; encapsulate it only when multiple capability suites share the same behavior. [VERIFIED: `test/lockspire/protocol/registration_management_test.exs`, `test/support/token_exchange_case.ex`]

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| File-wide lint suppression | Named local configuration comments and source decomposition | A module stays analyzable as it evolves. [CITED: https://hexdocs.pm/credo/config_comments.html] |
| Assertion quantity as proof | Behavior/capability assertions | Tests explain maintained outcomes rather than past implementation volume. [VERIFIED: QUAL-02] |
| Global noisy async startup | Explicit test bootstrap and narrowly captured failure logs | Routine output stays signal-rich while negative behavior remains tested. [VERIFIED: QUAL-03] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The expected KeyCache error is caused by initial refresh racing test database migration rather than a separate persistent database fault. | Quiet startup | Medium — verify with a focused pre/post-migration startup test before changing error classification. |

## Open Questions

1. **Which KeyCache bootstrap condition is safely deferrable?**
   - What we know: `list_active_keys/0` rescues every exception and KeyCache logs every returned error before alias migration. [VERIFIED: source]
   - What's unclear: exact Postgrex/Ecto exception shape on a brand-new database versus an unavailable configured repo.
   - Recommendation: write a narrow characterization test and match only that verified table-undefined/bootstrap condition; unexpected errors remain logged.

2. **Are any Dialyzer warnings caused by intentionally broad behavior contracts?**
   - What we know: 66 warnings concentrate in recent collaborator seams. [VERIFIED: baseline]
   - Recommendation: repair public contract types first, then only document an exception if a reduced reproducer proves an upstream analyzer limitation.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | compile, Credo, Dialyzer, ExDoc | ✓ | Mix 1.19.5 / OTP 28 | — |
| PostgreSQL client/server | test setup and DB-backed focused proof | ✓ | psql 14.17 | existing configured local test DB |
| Docker | not required in this phase | ✓ | 29.5.2 | Phase 137-only release/conformance work remains deferred |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, Ecto SQL sandbox, project aliases |
| Config | `test/test_helper.exs`, `config/test.exs`, `mix.exs` |
| Quick run | `mix test path/to/focused_test.exs` |
| Full phase gate | `mix compile --warnings-as-errors && mix qa && mix qa.dialyzer && mix docs.verify && mix package.build && mix test.integration` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QUAL-01 | all library files analyzed; no file-wide/unnamed suppressions | source-fitness + strict Credo | `mix qa` | ❌ Wave 0 |
| QUAL-02 | helpers expose current capabilities; no phase archaeology/count contract | focused source/behavior tests | `mix test test/lockspire/...quality...` | ❌ Wave 0 |
| QUAL-03 | routine happy path is quiet; negative logs/redaction and telemetry remain observable | focused integration/log tests | `mix test test/lockspire/key_cache_test.exs ...` | partial |
| QUAL-04 | compile/Credo/Dialyzer/docs/package/integration pass | tool and integration gates | full phase gate | existing aliases, warning repair required |

### Recommended Waves

1. **Wave 0 — characterization/fitness:** add source-fitness tests for library suppressions and active proof archaeology, a KeyCache pre/post-migration startup characterization, and explicit routine-log capture contract.
2. **Wave 1 — Credo and proof helpers:** replace three file-wide library suppressions; decompose admin/release macro users into small capability helpers; replace the release count contract.
3. **Wave 2 — static types:** eliminate Dialyzer clusters in lifecycle/registration/repository and token grants, then leaf warnings; no ignore baseline.
4. **Wave 3 — quiet runtime/final proof:** configure quiet test SQL, make KeyCache startup classification narrow, consolidate telemetry lifecycle support, and run all gates.

### Sampling Rate

- **Per task commit:** targeted ExUnit file plus `mix credo --strict --format oneline` for static-source changes.
- **Per wave merge:** `mix qa && mix qa.dialyzer`.
- **Phase gate:** full phase gate above, plus `git diff --check`.

### Wave 0 Gaps

- [ ] Static-analysis fitness test rejects `credo:disable-for-this-file` and unnamed library next-line directives.
- [ ] Proof-quality fitness test rejects active test/support references to archived phase paths and assertion-count thresholds.
- [ ] KeyCache test proves expected bootstrap behavior is quiet but unexpected refresh failure remains logged/captured.
- [ ] Shared telemetry test helper proves unique attach/detach lifecycle.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Preserve DPoP/JAR/request-object behavior while simplifying static-analysis offenders. |
| V3 Session Management | yes | Preserve token and refresh-family behavior during type repairs. |
| V4 Access Control | yes | Preserve admin/release proof boundaries and no public-surface expansion. |
| V5 Input Validation | yes | Keep parser/validation tests around Credo-driven source splits. |
| V6 Cryptography | yes | Keep JOSE/key-cache errors fail-visible outside the verified test bootstrap condition. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Broad static-analysis suppression hides security regression | Tampering | Full `lib/` scan and local named exception fitness test. |
| Overbroad quiet logging conceals key/cache failure | Repudiation / information disclosure | Test-only narrow condition, explicit negative log/redaction tests. |
| Refactor changes OAuth/OIDC error precedence | Elevation of privilege | Focused public result and endpoint characterization before/after extraction. |
| Stale proof artifact asserts a false release guarantee | Repudiation | Current-artifact capability tests, with immutable CI proof deferred to Phase 137. |

## Sources

### Primary

- Local `mix.exs`, `.credo.exs`, CI scripts, test config/support, source, and fresh static-analysis runs — current project behavior and offender inventory. [VERIFIED]

### Secondary

- https://hexdocs.pm/credo/config_comments.html — named local Credo configuration comments. [CITED]
- https://hexdocs.pm/credo/cli_switches.html — strict mode includes all priorities. [CITED]
- https://github.com/jeremyjh/dialyxir — Dialyxir warning/ignore behavior and PLT workflow. [CITED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — installed dependency/runtime and fresh commands.
- Architecture: HIGH — direct current helper/config/source inventory.
- Pitfalls: HIGH — reproduced Dialyzer baseline and traced startup ordering; KeyCache exception shape remains explicitly characterized as an open question.

**Research date:** 2026-08-27  
**Valid until:** 2026-09-26
