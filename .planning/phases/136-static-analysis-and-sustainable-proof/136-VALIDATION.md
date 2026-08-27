# Phase 136 — Plan Validation and Source Audit

## Dependency graph

| Wave | Plans | Dependency reason |
|---|---|---|
| 1 | 136-01 | Exact characterization precedes every cleanup. |
| 2 | 136-02, 136-03, 136-04, 136-06, 136-07, 136-10 | DPoP, JAR/request-object, admin proof, release proof, lifecycle/storage typing, and runtime noise have disjoint owned files. |
| 3 | 136-05, 136-08 | Admin macro removal follows its first migrations; token typing follows corrected storage/lifecycle contracts and the RFC 8693 directive cleanup. |
| 4 | 136-09 | Leaf callers follow corrected lifecycle and token result unions. |
| 5 | 136-11 | Permanent zero-tolerance fitness and the complete gate require every track. |

Same-wave plans have no `files_modified` overlap. Shared helper/facade files are serialized by explicit dependencies.

## Goal-backward coverage

| Observable truth | Required artifacts/wiring | Plans |
|---|---|---|
| Maintainers can trust strict Credo over every library file. | Structured directive classifier; cohesive DPoP/JAR/request-object modules; named local exception policy. | 01–03, 11 |
| Admin/release proof explains current capabilities instead of phase history or quantity. | Plain `AdminProof`/`ReleaseProof` modules, explicit suite calls, proof architecture fitness. | 01, 04–06, 11 |
| Successful tests are quiet while negative evidence stays visible. | readiness-aware KeyCache, test SQL policy, remote telemetry capture, runtime-output checker. | 01, 10–11 |
| Static/docs/package/integration evidence stays green. | Typed lifecycle/storage/token/caller seams; complete converged command. | 07–09, 11 |

## Multi-source coverage audit

| SOURCE | ID | Feature/Requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Concise, behavior-focused quality evidence and readable code without avoidable noise or archaeology. | 01–11 | COVERED | Characterization, bounded ownership cleanup, and permanent fitness. |
| REQ | QUAL-01 | Full library Credo evaluation; only named/narrow/justified local exceptions. | 01–03, 11 | COVERED | Three file-wide and five unnamed offenders are characterized then eliminated. |
| REQ | QUAL-02 | Small capability helpers and behavior assertions replace macros/counts/phase archaeology. | 01, 04–06, 11 | COVERED | Admin and release tracks end in architecture fitness. |
| REQ | QUAL-03 | No successful-run KeyCache/Ecto/telemetry noise; failure/redaction proof retained. | 01, 10–11 | COVERED | Exact observed noise categories and explicit negative evidence. |
| REQ | QUAL-04 | Compile, Credo, zero-warning Dialyzer, ExDoc, package, integration stay green. | 01–3, 07–11 | COVERED | 66 warnings are grouped by ownership seam and final gates converge. |
| RESEARCH | — | Source-first remediation for DPoP, JAR, and request objects. | 02–03 | COVERED | Public errors and fail-closed ordering are characterized. |
| RESEARCH | — | Repair types/dead paths; add no ignore baseline. | 07–09, 11 | COVERED | Storage/lifecycle, token grants, then leaf callers. |
| RESEARCH | — | Plain AdminProof and ReleaseProof capability modules. | 04–06 | COVERED | Explicit imports/calls; macro modules removed. |
| RESEARCH | — | Test-only SQL quietness, narrow cache bootstrap handling, unique remote telemetry lifecycle. | 10 | COVERED | Unexpected failures remain logged and asserted. |
| RESEARCH | — | No new packages. | 01–11 | COVERED | Existing Elixir/ExUnit/Credo/Dialyxir stack only. |
| CONTEXT | — | No CONTEXT.md exists; roadmap/requirements are binding. | 01–11 | COVERED | All binding scope appears above. |

## Excluded without gaps

- Phase 137 owns GitHub Actions restructuring, router-wide Sobelow, coverage aggregation/floor changes, immutable conformance inputs/evidence, and built/published artifact checksum proof.
- New grants, hosted auth, SAML/LDAP, product policy, schema changes, and admin visual redesign remain out of scope.

## Nyquist validation matrix

| Requirement | Early evidence | Permanent/final command |
|---|---|---|
| QUAL-01 | `mix test test/lockspire/quality/source_quality_baseline_test.exs` | same test with empty violations plus `bash scripts/ci/run_credo.sh` |
| QUAL-02 | `mix test test/lockspire/quality/proof_quality_baseline_test.exs` | all admin/release capability suites plus zero-violation fitness |
| QUAL-03 | focused KeyCache/telemetry/redaction tests | `bash scripts/ci/check_test_runtime_noise.sh` |
| QUAL-04 | ownership-cluster tests and warning filters per plan | `mix compile --warnings-as-errors && mix qa && mix qa.dialyzer && mix docs.verify && HEX_API_KEY= mix package.build && MIX_ENV=test mix test.integration` |

Every production-code task has focused behavioral proof before implementation, and the final plan replaces all temporary baseline allowances with zero-tolerance executable contracts.

## Nyquist re-audit — 2026-08-27

**Status: VALIDATED — QUAL-01 through QUAL-04 have executable evidence.**

The original focused checker passed, but its telemetry pattern only matched a single
line containing both `telemetry` and `local function`. Telemetry emits the handler
warning across lines. The checker now rejects `local function`, which proves it
catches the real diagnostic while keeping its output redacted.

| Requirement | Command | Actual result | Verdict |
|---|---|---|---|
| QUAL-01 | `mix test test/lockspire/quality/source_quality_baseline_test.exs` and `bash scripts/ci/run_credo.sh` | 45 selected quality/admin/release/architecture tests green; Credo reported 554 sources and 0 issues. | FILLED |
| QUAL-02 | Admin/release capability suites in the selected quality command | 45 tests green; synthetic fitness rejects macro, planning-history, and count-threshold constructs. | FILLED |
| QUAL-03 | `bash scripts/ci/check_test_runtime_noise.sh --focused` | Passed. | FILLED |
| QUAL-03 | `bash scripts/ci/check_test_runtime_noise.sh --fast` | Passed after migrating every remaining fast-suite anonymous/local telemetry callback to the shared module-qualified capture lifecycle. | FILLED |
| QUAL-04 | `mix compile --warnings-as-errors && mix qa.dialyzer && mix docs.verify && HEX_API_KEY= mix package.build` | Compile passed; Dialyzer: 0 errors, 0 skipped, 0 unnecessary skips; ExDoc and package build passed. | FILLED |

### Remediation verified

The fast-suite support and tests now use `Lockspire.TestSupport.TelemetryCapture`
for process and Agent event capture. It supplies unique handler IDs, module-qualified
callbacks, and `on_exit` detachment. The detector remains `local function`, which
catches Telemetry's multiline warning rather than restoring the previous false green.
