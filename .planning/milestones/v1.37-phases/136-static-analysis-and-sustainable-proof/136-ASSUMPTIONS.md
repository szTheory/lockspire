## Assumptions

### Complete, Local Static Analysis
- **Assumption:** Phase 136 will make strict Credo evaluate all `lib/` sources and replace every file-wide suppression with either ordinary compliant code or a named, next-line suppression that documents the exceptional check.
  - **Why this way:** `.credo.exs` already runs `strict: true` over `lib/` and `test/`, and `scripts/ci/run_credo.sh` fails if any configured source is not parsed. Three library modules still bypass all checks with `# credo:disable-for-this-file`: `lib/lockspire/protocol/request_object.ex`, `lib/lockspire/protocol/jar.ex`, and `lib/lockspire/protocol/dpop.ex`. Existing local suppressions demonstrate the intended narrow convention, e.g. `lib/lockspire/jwks_fetcher.ex:125` names `Credo.Check.Refactor.CyclomaticComplexity`.
  - **If wrong:** A future readability, complexity, or correctness regression in a protocol module can land without Credo evaluating the file, defeating QUAL-01 even though the CI command remains green.
  - **Confidence:** Confident

### Capability-Focused Admin and Release Evidence
- **Assumption:** Admin and release tests should retain observable routing, rendering, redaction, and packaging contracts, but express them through small domain-named capability helpers rather than compile-time injection, historic phase paths, or source-level assertion inventories.
  - **Why this way:** `test/support/admin_contract_helpers.ex` is a 1,606-line `__using__/1` macro that injects paths, historical `@phase_*` constants, and helper functions into suites. The three design-system capability suites total 2,195 lines and pin historical counts in `test/lockspire/web/live/admin/design_system/inventory_contract_test.exs:10-54`; the release inventory additionally requires at least 588 assertions in `test/lockspire/release_readiness_contract_test.exs:6-87`. The prior milestone explicitly defers operator visual redesign while user review capacity is limited (`.planning/REQUIREMENTS.md`, Future Requirements / Out of Scope), so the sustainable proof should preserve behavior rather than expand UI scope.
  - **If wrong:** Refactoring a test's structure could either fail solely because an obsolete phase artifact or count changed, or pass while the user-facing capability it was meant to protect is no longer actually exercised.
  - **Confidence:** Confident

### Quiet Routine Test Infrastructure, Explicit Failure Proof
- **Assumption:** Routine happy-path tests should start the repository/cache in a deterministic order, suppress routine Ecto SQL logging at the test boundary, and isolate telemetry capture; tests that assert failure diagnostics or redaction must still explicitly capture and inspect those logs/events.
  - **Why this way:** `Lockspire.Application` starts `Lockspire.KeyCache` unconditionally (`lib/lockspire/application.ex:9-18`), and its first asynchronous refresh logs an error when `Repository.list_active_keys/0` fails (`lib/lockspire/key_cache.ex:31-67`). `config/test.exs` configures `Lockspire.TestRepo` with a SQL sandbox while `test/support/data_case.ex:13-20` checks out ownership per test, which creates an early-refresh race. The shared Ecto wrapper currently disables logging only for explicitly sensitive operations (`lib/lockspire/storage/ecto/repository/support.ex:31-40`), so ordinary test setup/query traffic remains noisy. In contrast, focused failure proof already attaches and detaches telemetry per test (`test/support/token_exchange_case.ex:44-74`) and captures/inspects DCR redaction outcomes (`test/lockspire/protocol/dcr_telemetry_redaction_test.exs:31-120`).
  - **If wrong:** Developers will either ignore real KeyCache/telemetry errors amid routine output, or over-suppress logs and lose the redaction and failure evidence that guards OAuth secrets.
  - **Confidence:** Likely
  - **Alternatives considered:** Disable KeyCache in all tests (risks hiding application-supervision behavior); make its initial refresh silent (risks hiding a real production storage outage); provide a deterministic test startup/readiness seam and test-only SQL log policy while retaining explicit error-path capture (recommended).

### Quality Gates Remain One Executable Contract
- **Assumption:** Phase 136 will preserve a single maintainable set of executable gates for warning-free compilation, strict Credo, zero-warning Dialyzer, ExDoc, package build, and a focused integration proof; it will clarify their composition rather than duplicate CI/release/conformance work reserved for Phase 137.
  - **Why this way:** `mix.exs:117-143` already defines QA, architecture, docs, package, and fast/integration aliases; `.github/workflows/ci.yml:23-50` runs the zero-warning Dialyzer script, and the fast lane executes QA, docs, package build, and tests. Phase 135’s final evidence records separate fast/integration, architecture, docs, and Dialyzer-compatible checks (`.planning/phases/135-cohesive-internals/135-VERIFICATION.md`; `135-SECURITY.md`). Phase 137 is explicitly allocated coverage aggregation, immutable conformance inputs, and before/after publish clean-room evidence (`.planning/ROADMAP.md`, Phase 137).
  - **If wrong:** The structural cleanup could silently remove a release-quality check, or Phase 136 could duplicate mutable CI/conformance/release work without delivering the narrower QUAL-04 maintainability outcome.
  - **Confidence:** Confident

## Risks and Boundaries

- Historical admin proof reaches prior `.planning/milestones/...` artifacts via runtime file reads (`test/support/admin_contract_helpers.ex:46-65`, `1524-1534`). Removing those dependencies must retain current supported admin behavior and redaction checks, but must not make archived phase archaeology a release prerequisite.
- Test logging changes must be scoped to the test environment. The production repository wrapper deliberately suppresses sensitive query values (`lib/lockspire/storage/ecto/repository/support.ex:31-40`); Phase 136 must not broaden that into production diagnostic loss.
- Local Credo exceptions may remain only where a specific check is genuinely disproportionate and must name the exact check/reason. Unnamed next-line exceptions such as those in `lib/lockspire/domain/client.ex:89` and `lib/lockspire/protocol/authorization_request.ex:900` are also candidates for clarification.

## Deferred to Phase 137

- CI-wide low-severity Sobelow router coverage and unused-dependency/cycle enforcement (CI-01, CI-03).
- Truthful complete-suite coverage aggregation and the 84% floor (CI-02).
- Immutable OIDC/FAPI conformance inputs, scheduled evidence retention, built-artifact clean-room verification, public Hex checksum matching, and retained release manifests (CONF-01, CONF-02, REL-01, REL-02).

## Needs External Research

None required for Phase 136 planning. The remaining choices are repository-local test lifecycle, Credo configuration, and proof structure decisions. Phase 137 will require external/pinned-tooling research for conformance and published-artifact verification.
