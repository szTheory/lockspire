---
phase: 117
slug: component-lab-fixtures-foundation-hardening
status: verified
threats_open: 0
asvs_level: standard
block_on: open_threats
created: 2026-06-25
verified: 2026-06-25
register_authored_at_plan_time: true
---

# Phase 117 - Security

Per-phase security contract for `117-component-lab-fixtures-foundation-hardening`.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Test lab -> production admin surface | Test-only modules render production components but must not create runtime routes or support claims. | Component markup and internal lab classification. |
| Fixture data -> rendered HTML | Fake scenario data crosses into lab output and future proof artifacts. | Redaction-safe client, token, consent, key, DCR/IAT, and operations fixtures. |
| Maintainer proof -> Hex package | Test-support lab files must stay outside package files and public docs. | Test-support modules, browser-proof placeholders, package file declarations. |
| CSS source -> embedded admin runtime | CSS changes affect all mounted admin pages. | Theme aliases, color-scheme behavior, transition and reduced-motion rules. |
| Maintainer proof wording -> public docs | Unsupported lab/browser proof claims must not become host-facing support commitments. | Supported-surface documentation text. |
| Package files -> Hex artifact | Maintainer proof tooling must not enter the published package boundary. | Hex package `files` list and root tooling paths. |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-117-01 | Elevation of Privilege | `Lockspire.Web.AdminRouter` | mitigate | Boundary test reads `lib/lockspire/web/admin_router.ex` and refutes component/design-system lab route strings; router source contains only supported admin LiveView routes. Evidence: `test/lockspire/web/live/admin/design_system_component_stress_test.exs:136`, `lib/lockspire/web/admin_router.ex:13`. | closed |
| T-117-02 | Information Disclosure | `Lockspire.Web.AdminLab.Fixtures` and rendered HTML | mitigate | Fixtures centralize forbidden secret-like substrings and tests refute them in both `inspect(Fixtures.all())` and rendered HTML. Evidence: `test/support/lockspire/web/admin_lab/fixtures.ex:37`, `test/lockspire/web/live/admin/design_system_component_stress_test.exs:49`, `test/lockspire/web/live/admin/design_system_component_stress_test.exs:114`. | closed |
| T-117-03 | Repudiation | Lab classification | mitigate | Stress surface carries internal lab evidence and tests prevent public supported-surface/router promotion of the component/design-system lab. Evidence: `test/support/lockspire/web/admin_lab/stress_surface.ex:29`, `test/lockspire/web/live/admin/design_system_component_stress_test.exs:136`, `test/lockspire/web/live/admin/design_system_contract_test.exs:1046`. | closed |
| T-117-04 | Information Disclosure | Hex package boundary | mitigate | Lab modules live under `test/support`, and package boundary tests assert `mix.exs` package files exclude `test/support`; `mix.exs` package files include only `lib priv docs .formatter.exs mix.exs README.md CHANGELOG.md LICENSE`. Evidence: `test/support/lockspire/web/admin_lab/fixtures.ex:1`, `test/lockspire/web/live/admin/design_system_component_stress_test.exs:141`, `mix.exs:203`. | closed |
| T-117-SC | Tampering | npm/pip/cargo installs | accept | Accepted risk documented below: Phase 117 has no package-manager dependency additions; summaries record `tech-stack.added: []`, and no root Node/Playwright lock/config files were found during audit. | closed |
| T-117-05 | Tampering | `lib/lockspire/web/admin_css.ex` theme aliases | mitigate | Source contracts assert semantic alias remapping, explicit light/dark/system selectors, and no primitive color redeclaration in dark/system blocks; CSS implements stable primitives with dark/system semantic remaps. Evidence: `test/lockspire/web/live/admin/design_system_contract_test.exs:216`, `test/lockspire/web/live/admin/design_system_contract_test.exs:238`, `lib/lockspire/web/admin_css.ex:1512`, `lib/lockspire/web/admin_css.ex:1551`. | closed |
| T-117-06 | Denial of Service | Admin motion CSS | mitigate | Source contracts ban broad `transition`/`transition-property: all`, require explicit transition property/duration/timing, and assert reduced-motion neutralization; CSS implements explicit transitions and reduced-motion active transform neutralization. Evidence: `test/lockspire/web/live/admin/design_system_contract_test.exs:258`, `test/lockspire/web/live/admin/design_system_contract_test.exs:281`, `lib/lockspire/web/admin_css.ex:221`, `lib/lockspire/web/admin_css.ex:522`, `lib/lockspire/web/admin_css.ex:1491`. | closed |
| T-117-07 | Information Disclosure | `docs/supported-surface.md` | mitigate | Boundary tests read supported-surface docs and refute unsupported component-lab, design-system-lab, Playwright proof, and axe proof support wording. Evidence: `test/lockspire/web/live/admin/design_system_contract_test.exs:300`, `docs/supported-surface.md:9`, `docs/supported-surface.md:113`. | closed |
| T-117-08 | Tampering | Hex package boundary | mitigate | Contract tests assert package files exclude maintainer browser proof directories and Node/Playwright config paths; `mix.exs` package files remain scoped to library/docs files. Evidence: `test/lockspire/web/live/admin/design_system_contract_test.exs:310`, `mix.exs:203`. | closed |
| T-117-SC | Tampering | npm package supply chain | accept | Accepted risk documented below: Phase 117 performed no npm install and keeps suspicious browser packages out of implementation; contract tests also fence Node/Playwright config paths from package files. Evidence: `test/lockspire/web/live/admin/design_system_contract_test.exs:310`. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-117-SC-01 | T-117-SC (`npm/pip/cargo installs`) | Plan 117-01 declared no package-manager dependency installation in scope. Audit verified no dependency additions in summaries and no root Node/Playwright package files; no implementation mitigation is required for an install that did not occur. | Plan-time threat register; verified by security audit | 2026-06-25 |
| AR-117-SC-02 | T-117-SC (`npm package supply chain`) | Plan 117-02 declared no npm install in scope. Audit verified browser tooling remains quarantined by contract tests and package boundaries. | Plan-time threat register; verified by security audit | 2026-06-25 |

## Threat Flags

No `## Threat Flags` section was present in `117-01-SUMMARY.md` or `117-02-SUMMARY.md`; no unregistered flags were recorded.

## Verification Commands

| Command | Result |
|---------|--------|
| `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | Passed: 4 tests, 0 failures. |
| `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | Passed: 32 tests, 0 failures. |

Both commands emitted the existing pre-test `Failed to refresh KeyCache` log before ExUnit ran; the test processes exited successfully.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-25 | 10 | 10 | 0 | Codex security auditor |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-25
