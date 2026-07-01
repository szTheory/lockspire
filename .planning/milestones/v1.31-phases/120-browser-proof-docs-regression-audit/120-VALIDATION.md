---
phase: 120
slug: browser-proof-docs-regression-audit
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-26
updated: 2026-06-26
requirements:
  - PROOF-02
  - PROOF-03
  - PROOF-04
---

# Phase 120 - Validation Strategy

Nyquist audit result: planned and compliant. Phase 120 must prove the v1.31 admin design-system pass with fast deterministic ExUnit/LiveView guardrails first, then maintainer-only browser evidence as supplemental proof. Browser tooling is optional and quarantined; the fallback is manual browser evidence against the same route, viewport, theme, and motion matrix.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Phoenix LiveViewTest, LazyHTML; optional Playwright Test plus axe only after human package verification |
| Config file | `mix.exs`, `test/test_helper.exs`; no Playwright config exists at planning time |
| Quick run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` |
| Focused route command | `MIX_ENV=test mix test test/lockspire/web/live/admin/*_test.exs test/lockspire/web/admin_router_test.exs --max-failures 1` |
| Docs command | `mix docs.verify` |
| Full suite command | `MIX_ENV=test mix test.fast` |
| Optional browser command | Maintainer-only command if adopted after `checkpoint:human-verify`; otherwise manual browser evidence recorded in `120-BROWSER-PROOF.md` |
| Estimated runtime | Quick contracts under 60 seconds; full suite depends on local database setup |

## Sampling Rate

- After every task commit: run the quick command for changed admin tests, or the narrow focused command named in the task.
- After every plan wave: run `MIX_ENV=test mix test.fast`; run `mix docs.verify` after documentation changes.
- Before `$gsd-verify-work`: full suite, docs verification, completed proof artifact, and final adversarial audit must be green or explicitly gap-noted.
- Max feedback latency: target under 90 seconds for focused checks; use targeted tests when the full suite is slower.

## Requirements Classification

| Requirement | Observable behavior | Test type | Coverage status |
|-------------|---------------------|-----------|-----------------|
| PROOF-02 | Browser evidence covers 320px, 390px, 768px, 1024px, and 1440px across representative light, dark, system, and reduced-motion route risks. | proof artifact plus optional browser automation | FILLED |
| PROOF-03 | Guardrails fail on route drift, token/raw-color drift, responsive/focus/accessibility regressions, duplicate IDs, missing labels/descriptions, plaintext secrets, generic CTA drift, and public support creep. | source contract, rendered component stress, mounted LiveView tests | FILLED |
| PROOF-04 | Operator docs explain workflow, component lab boundary, theme behavior, and verification expectations without implying a public design-system/browser-testing support surface. | docs contract plus manual review | FILLED |

## Planned Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 120-01-01 | 01 | 0 | PROOF-02, PROOF-03 | T-120-01, T-120-02 | Route matrix is source-derived from `AdminRouter`, includes `/admin/clients/:client_id/edit?workflow=logout-propagation`, and catches stale `/admin/logout-deliveries` links. | source contract + mounted route test | `MIX_ENV=test mix test test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` | yes | green |
| 120-01-02 | 01 | 1 | PROOF-02 | T-120-03, T-120-04 | Proof artifact maps each representative route to JTBD, viewport, theme, motion, evidence path, accessibility note, and gap note without sensitive values. | manual/browser proof artifact | `rg -n "320px|390px|768px|1024px|1440px|reduced-motion|JTBD|gap" .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` | yes | green |
| 120-01-03 | 01 | 1 | PROOF-02, PROOF-03 | T-120-04, T-120-05 | Optional Playwright/axe is either adopted only after package verification or explicitly declined with equivalent manual evidence. | package/support boundary check | `rg -n "checkpoint:human-verify|manual browser evidence|maintainer-only" .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` | yes | green |
| 120-02-01 | 02 | 0 | PROOF-03 | T-120-06, T-120-07 | Rendered-markup helpers or inline checks catch duplicate IDs, broken `aria-describedby`, missing labels, generic CTAs, and plaintext secret leakage. | LazyHTML/rendered component stress | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes | green |
| 120-02-02 | 02 | 1 | PROOF-03 | T-120-08, T-120-09 | Source/CSS/docs contracts catch brand-token drift, raw color drift, contrast-token pair gaps, responsive/focus/reduced-motion regressions, and public-support browser-tooling creep. | source contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | green |
| 120-02-03 | 02 | 1 | PROOF-03 | T-120-01, T-120-10 | Representative mounted admin pages render host-guarded operator workflows with valid links, stable copy, redaction, and no unsupported queue actions. | mounted LiveView route tests | `MIX_ENV=test mix test test/lockspire/web/live/admin/*_test.exs --max-failures 1` | yes | green |
| 120-03-01 | 03 | 1 | PROOF-04 | T-120-11, T-120-12 | `docs/operator-admin.md` explains the v1.31 workflow, shared primitive boundary, internal lab boundary, theme behavior, and verification expectations. | docs review + docs build | `mix docs.verify` | yes | green |
| 120-03-02 | 03 | 1 | PROOF-04 | T-120-13, T-120-14 | Public docs and package content do not create a public design-system, lab route, theming engine, screenshot product, or browser-testing support claim. | source/docs contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | green |
| 120-03-03 | 03 | 2 | PROOF-02, PROOF-03, PROOF-04 | T-120-15 | Final audit explicitly covers accessibility, responsive reflow, IA, redaction, theme/motion, tooling weight, maintainability, docs truth, and DX. | proof artifact + final verification | `MIX_ENV=test mix test.fast && mix docs.verify` | yes | green |

## Wave 0 Requirements

- [x] `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` - maintainer-only route matrix, commands, evidence paths, browser/axe/manual notes, gaps, and final audit checklist.
- [x] `test/support/lockspire/web/admin_proof/html_assertions.ex` or inline equivalent - LazyHTML helpers if rendered accessibility assertions outgrow the existing tests.
- [x] `checkpoint:human-verify` before any `package.json`, Playwright config, browser install, or axe dependency is added.
- [x] A fallback manual evidence path documented in the proof artifact if Playwright/axe is not adopted.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Keyboard order and focus comprehension | PROOF-02, PROOF-03 | Automated checks do not prove operator comprehension or every focus-order issue. | Walk the representative route matrix with keyboard only; record route, viewport, theme, issue, and resolution/gap in `120-BROWSER-PROOF.md`. |
| Visual hierarchy and JTBD clarity | PROOF-02, PROOF-04 | Dense operator UI quality depends on route-specific task comprehension, not screenshot existence alone. | For each route, answer Orient/Configure/Support/Operate job, primary next action, risk copy, and any backend-guts leakage. |
| Destructive consequence framing | PROOF-03, PROOF-04 | Microcopy and domain consequence clarity require human review. | Check revoke, delete, disable, copy-once, and retry-like surfaces for exact consequence language and no unsupported actions. |
| Screen-reader risk review | PROOF-03 | Axe can miss semantic comprehension and state announcement risks. | Inspect labels, descriptions, headings, table/list semantics, status text, and non-color cues; record results in final audit. |

## Threat References

| Threat | Description | Mitigation |
|--------|-------------|------------|
| T-120-01 | Route drift creates dead admin links or proof coverage of nonexistent routes. | Derive matrix from `AdminRouter`; add mounted route/link assertions; fix `/admin/logout-deliveries` drift to `/admin/logouts`. |
| T-120-02 | Screenshot filenames become the source of truth. | Store evidence as proof only; route truth remains source-derived. |
| T-120-03 | Browser proof omits small widths, dark/system themes, or reduced motion. | Route matrix must map each required width/theme/motion risk explicitly. |
| T-120-04 | Evidence leaks secrets, tokens, cookies, private keys, auth codes, or token-looking values. | Use redaction-safe fixtures/seeds; denylist proof artifacts and rendered HTML. |
| T-120-05 | Playwright/axe becomes public support surface or required runtime/package dependency. | Human package checkpoint, maintainer-only naming, public docs/package tests, manual fallback. |
| T-120-06 | Duplicate IDs or broken accessible references make generated pages confusing. | LazyHTML rendered assertions for IDs, labels, and descriptions. |
| T-120-07 | Generic CTAs or backend implementation terms leak into operator workflows. | Source/docs/rendered copy contracts plus final JTBD audit. |
| T-120-08 | Brand tokens, raw colors, or contrast pairs drift from brandbook/admin CSS contracts. | Source contract tests against `brandbook/` and `Admin.CSS`. |
| T-120-09 | Responsive/focus/reduced-motion CSS regresses while source tests stay shallow. | CSS contract tests plus browser/manual evidence at required widths/media settings. |
| T-120-10 | Operation queues imply unsupported retry/discard/approval actions. | Mounted page assertions and proof artifact review keep queues read-only unless backed by domain APIs. |
| T-120-11 | Docs teach implementation internals instead of operator jobs. | Docs review anchored in Orient/Configure/Support/Operate JTBD. |
| T-120-12 | Docs blur host-owned staff auth/branding/policy with Lockspire-owned admin state. | Explicit ownership split in `docs/operator-admin.md`; support-boundary tests. |
| T-120-13 | A public design-system/lab/theming promise is accidentally created. | Keep lab/test artifacts internal and do not add public design-system docs. |
| T-120-14 | Package contents ship proof tooling or screenshots. | Verify Hex files list and public docs deny browser tooling claims. |
| T-120-15 | Final phase closes on screenshots without adversarial review. | Require final audit checklist across design-quality pillars and DX/support boundaries. |

## Validation Sign-Off

- [x] All planned tasks have automated verification, manual evidence, or Wave 0 dependency.
- [x] Sampling continuity: no three consecutive planned tasks lack automated feedback.
- [x] Wave 0 names every missing artifact or optional tool dependency.
- [x] No watch-mode flags.
- [x] Browser/axe proof remains optional and maintainer-only.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** verified 2026-06-26

## Validation Audit 2026-06-26

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Final evidence:

- `120-VERIFICATION.md` passed with 11/11 must-haves verified and 0 behavior-unverified items.
- `MIX_ENV=test mix compile --warnings-as-errors` passed.
- Focused component plus contract guardrails reported 49 tests, 0 failures.
- Route truth and stale logout drift guard reported 17 tests, 0 failures.
- Representative mounted route guardrails reported 25 tests, 0 failures.
- `mix docs.verify` passed during Phase 120 verification.
