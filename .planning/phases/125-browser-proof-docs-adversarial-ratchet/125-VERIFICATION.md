---
phase: 125-browser-proof-docs-adversarial-ratchet
verified: 2026-06-30T18:18:21Z
status: gaps_found
score: "6/7 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Browser/manual evidence covers representative v1.32 routes at 320px, 390px, 768px, 1024px, and 1440px across light, dark, system, reduced motion, keyboard focus, empty, dense, and long-data states."
    status: failed
    reason: "125-V1.32-PROOF.md has passing representative rows for the required widths, journeys, themes, motion modes, focus paths, dense, and long-data coverage, but no browser/manual evidence row records an empty or no-match state."
    artifacts:
      - path: ".planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md"
        issue: "Representative browser/manual evidence table lacks an empty-state row."
      - path: "test/lockspire/web/live/admin/design_system_contract_test.exs"
        issue: "Closeout artifact contract asserts required rows and viewports, but does not require empty-state evidence."
    missing:
      - "Add a redaction-safe browser/manual evidence row for an empty/no-match representative state with route/surface, journey, viewport, theme, motion, focus path, numeric scrollWidth/clientWidth, result pass, sensitive evidence check, and gap note none."
      - "Extend the closeout artifact contract to require empty-state coverage in BrowserEvidence rows."
      - "Rerun the Phase 125 focused route proof command from 125-VALIDATION.md."
---

# Phase 125: Browser Proof, Docs & Adversarial Ratchet Verification Report

**Phase Goal:** Prove the page-first polish is repeatable, accessible, responsive, and bounded.  
**Verified:** 2026-06-30T18:18:21Z  
**Status:** gaps_found  
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Redaction-safe fixtures cover ugly Support, Operate, Configure, Orient, and internal-lab states. | VERIFIED | `Fixtures.scenario_states/0` and `proof_matrix` include empty, one/many/high/zero count, long values, missing optional, warning, incident, disabled, expired, revoked, reuse-detected, copy-once, stale/read-only, light/dark/system, reduced motion, focus, mobile width, and journey states. Component stress tests assert these states and passed locally. |
| 2 | Deterministic guardrails cover scorecard drift, unsupported action drift, generic CTA drift, redaction drift, accessibility references, long values, theme/motion, and responsive source claims. | VERIFIED | `design_system_contract_test.exs` imports `RouteScorecards`, `HtmlAssertions`, and `BrowserEvidence`; it asserts route parity, docs/package/router fences, secret evidence patterns, unsupported labels, duplicate IDs, labels/ARIA/hrefs, token usage, focus-visible, theme aliases, reduced motion, and responsive CSS contracts. |
| 3 | Focused route proof is wired for Support, Operate, Configure, Orient, and policy routes. | VERIFIED | Route tests under `test/lockspire/web/live/admin/**` call `HtmlAssertions` and exercise route-local hostile states; local focused route proof passed: 167 tests, 0 failures. |
| 4 | Maintainer proof rows are redaction-safe, non-gap, and passing for the required widths, journeys, themes, motion modes, and focus paths. | VERIFIED | `BrowserEvidence.parse!/1` validates row shape, numeric widths, allowed result values, duplicate rows, and sensitive evidence. `125-V1.32-PROOF.md` has five passing rows for 320/390/768/1024/1440, light/dark/system, default/reduced-motion, Orient/Configure/Support/Operate/Internal lab. |
| 5 | Browser/manual evidence includes empty-state coverage named by the roadmap success criterion. | FAILED | The proof artifact has no row whose state or notes identify an empty/no-match state. `grep -i empty 125-V1.32-PROOF.md` found no evidence row coverage. |
| 6 | Operator docs explain the page-first loop without expanding public support surface. | VERIFIED | `docs/operator-admin.md` names `scorecard -> page change -> deterministic guardrails -> browser/manual notes -> adversarial signoff`, says browser/manual notes are supplemental maintainer proof, and keeps `docs/supported-surface.md` as the public ceiling. `docs/supported-surface.md` was not expanded with lab/browser/screenshot/theming/AI promises. |
| 7 | Final adversarial review checks the required boundedness concerns. | VERIFIED | `125-V1.32-PROOF.md` includes final review rows for aesthetic overfit, accessibility, generic admin-template drift, backend leakage, host seam, screenshot-only quality, theme/motion/focus, redaction, unsupported actions, stale route evidence, package/runtime creep, and support-surface expansion. |

**Score:** 6/7 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/support/lockspire/web/admin_lab/fixtures.ex` | Shared PROOF-01 fixture matrix | VERIFIED | Exists, substantive, exports `scenario_states/0`, `fixture_keys/0`, `forbidden_substrings/0`, and `proof_matrix` data. |
| `test/support/lockspire/web/admin_lab/stress_surface.ex` | Internal stress rendering | VERIFIED | Renders `data-lab-surface="component-stress"` and `data-phase="125-proof-matrix"` with existing admin components. |
| `test/support/lockspire/web/admin_proof/html_assertions.ex` | Rendered HTML guardrails | VERIFIED | Provides duplicate ID, ARIA target, label, href, disabled-link, generic CTA, token-like text, and unsupported-control helpers. |
| `test/support/lockspire/web/admin_proof/browser_evidence.ex` | Proof artifact parser/redaction validator | VERIFIED | Parses required Markdown table columns, validates widths/results/routes, rejects sensitive evidence, and is used by contract tests. |
| `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md` | Maintainer-only proof artifact | PARTIAL | Artifact exists and is contract-tested, but lacks required empty-state browser/manual evidence. |
| `docs/operator-admin.md` | Page-first proof loop docs | VERIFIED | Bounded maintainer guidance; docs verify passed. |
| `docs/supported-surface.md` | Public support ceiling unchanged/narrow | VERIFIED | No public lab/browser/screenshot/design-system/theming/AI proof promise added. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `design_system_component_stress_test.exs` | `AdminLab.Fixtures` | `Fixtures.scenario_states/0`, `Fixtures.all/0` | VERIFIED | Manual trace found alias and calls; generic checker missed alias-based pattern. |
| `design_system_component_stress_test.exs` | `AdminLab.StressSurface` | `StressSurface.render/1` | VERIFIED | Rendered component stress proof calls the internal surface. |
| `design_system_contract_test.exs` | `RouteScorecards` | `RouteScorecards.expected_routes/0` | VERIFIED | Manual trace found route parity assertions and workflow exception checks. |
| focused route tests | `HtmlAssertions` | rendered route guardrails | VERIFIED | Plan 03/04/05 key-link checks passed for Support, Operate, Configure, Orient, and policy files. |
| `design_system_contract_test.exs` | `BrowserEvidence` and `125-V1.32-PROOF.md` | proof artifact parsing and file read | VERIFIED | Contract test aliases `BrowserEvidence`, reads `@phase_125_proof_path`, parses rows, and validates required rows. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `StressSurface.render/1` | `@proof_matrix`, `@clients`, `@tokens`, `@operations` | `Fixtures.all/0` map passed by component stress tests | Yes - synthetic redaction-safe fixture data | FLOWING |
| `BrowserEvidence.parse!/1` | evidence rows | `125-V1.32-PROOF.md` Markdown table read by contract test | Yes - five parsed rows | PARTIAL: row data flows, but empty-state coverage is absent |
| `docs/operator-admin.md` | proof-boundary text | static docs plus contract source reads | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Quick component/contract proof | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | 80 tests, 0 failures | PASS |
| Full Phase 125 focused route proof | `MIX_ENV=test mix test ...Phase 125 files from 125-VALIDATION.md... --max-failures 1` | 167 tests, 0 failures | PASS |
| Docs verification | `mix docs.verify` | docs generated successfully | PASS |
| Broader suite | `MIX_ENV=test mix test.fast --max-failures 5` | 1199 tests, 4 failures locally; orchestrator reported 5 failures including one JWKS expectation mismatch | FAIL, non-blocking for Phase 125 scope |

### Probe Execution

No `scripts/*/tests/probe-*.sh` files were found. Step 7c: SKIPPED (no probes declared or conventional probe files present for this phase).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PROOF-01 | 125-01, 125-03, 125-04, 125-05 | Redaction-safe fixture/route coverage for hostile states | SATISFIED | Fixture matrix and focused route proof exist and passed. |
| PROOF-02 | 125-02 through 125-06 | Deterministic guardrails for drift, redaction, accessibility, theme, long values, and responsive source claims | SATISFIED WITH WARNINGS | Contract and focused tests passed. Review warnings identify hardening opportunities but no current Phase 125 source/artifact leak or unsupported public surface was observed. |
| PROOF-03 | 125-06 | Maintainer can review browser/manual evidence and docs without public support expansion | BLOCKED BY ROADMAP GAP | Docs and proof artifact boundary are present, but the roadmap-required empty-state browser/manual evidence row is missing. |

No orphaned Phase 125 requirement IDs were found in `.planning/REQUIREMENTS.md`; PROOF-01, PROOF-02, and PROOF-03 are all claimed by plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `test/support/lockspire/web/admin_lab/fixtures.ex` | 135 | `redacted_handle_copy_once_iat_placeholder` | INFO | Synthetic redacted fixture handle, not a runtime placeholder. |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | 58-59 | `placeholder`, `coming soon` sentinel strings | INFO | Negative-test values for scorecard/finality checks, not UI stubs. |
| `125-REVIEW.md` | n/a | Five advisory warnings | WARNING | Redaction helper breadth, generic CTA case sensitivity, browser-evidence route breadth, optional non-pass row allowance, and default planning-artifact dependency should be tracked, but they do not explain the blocking gap. |

No unreferenced `TODO`, `FIXME`, `XXX`, or `TBD` markers were found in the Phase 125 modified/proof files scanned.

### Non-Blocking External Failures

`MIX_ENV=test mix test.fast --max-failures 5` remains red, but the documented failures are outside the Phase 125 proof/docs/admin UI scope:

- `test/lockspire/release_readiness_contract_test.exs`
- `docs/adoption-demo.md`
- `scripts/maintainer/repo_hygiene_check.sh`
- orchestrator-added `test/lockspire/jwks_fetcher_test.exs` timeout expectation mismatch

These are recorded in `deferred-items.md`; they do not name Phase 125 files and do not block this verification decision. The missing empty-state evidence row does block.

### Gaps Summary

Phase 125 is close but not complete against the roadmap contract. The codebase proves the deterministic fixture, route, docs, parser, and adversarial-review lanes, and the focused Phase 125 tests are green. The remaining blocker is specific: the maintainer browser/manual evidence matrix does not include an empty-state row even though the roadmap success criterion requires browser/manual evidence across empty, dense, and long-data states.

**Next action:** add the missing empty/no-match browser/manual evidence row, extend the proof artifact contract to require empty-state coverage, then rerun:

```bash
MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/index_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1
```

---

_Verified: 2026-06-30T18:18:21Z_  
_Verifier: the agent (gsd-verifier)_
