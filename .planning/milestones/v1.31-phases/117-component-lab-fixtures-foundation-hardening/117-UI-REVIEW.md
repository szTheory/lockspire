# Phase 117 - UI Review

**Audited:** 2026-06-25
**Baseline:** `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md`
**Screenshots:** not captured (Phase 117 is a source-proof component lab and CSS foundation hardening phase; dev server detection attempted on 3000, 5173, 8080)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Required contract strings are only partially rendered and partially asserted. |
| 2. Visuals | 3/4 | Real components are exercised, but the lab matrix/header contract is represented as source evidence rather than a complete matrix surface. |
| 3. Color | 4/4 | Light, dark, system, semantic aliases, and registry/color safety are strongly source-proven. |
| 4. Typography | 2/4 | CSS still uses extra sizes and weights outside the four-size/two-weight contract. |
| 5. Spacing | 3/4 | Spacing mostly uses `--ls-space-*`, but small hardcoded values remain in component CSS. |
| 6. Experience Design | 3/4 | State, redaction, motion, and boundary tests pass, but fixture records do not cover every required fixture-area state. |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Render and assert the exact UI-SPEC copy** - Operators and maintainers lose the approved consequence-oriented language - Update `StressSurface.render/1` and `design_system_component_stress_test.exs` to assert the full empty, error, and destructive confirmation strings from UI-SPEC lines 113-117.
2. **Bring typography back inside the declared contract** - The CSS foundation cannot be treated as hardened while it uses undeclared type sizes/weights - Replace direct sizes/weights such as `1.875rem`, `1.25rem`, `1.125rem`, `0.9375rem`, `0.6875rem`, `500`, `650`, and `700` with the four declared type tokens and two weight tokens or explicitly revise the contract.
3. **Complete fixture-area records, not just scenario labels** - Future browser proof can falsely pass on labels while missing actual scenarios - Add fixture records for required DCR/IAT, keys, consents, clients, and operations states, then assert those records by fixture area.

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

**WARNING:** UI-SPEC requires exact empty body, error state, and destructive confirmation language at lines 113-117, but `StressSurface.render/1` renders shortened/substitute strings. The hero body at `test/support/lockspire/web/admin_lab/stress_surface.ex:38` only says proof drifted when states are missing, omitting the required re-render instruction. The empty state body at `test/support/lockspire/web/admin_lab/stress_surface.ex:150` replaces the required browser-proof/source-fixture body. The destructive panel body at `test/support/lockspire/web/admin_lab/stress_surface.ex:133` omits "Type the client ID before continuing"; a similar but non-contract error string appears at line 131.

**WARNING:** The stress test only asserts partial copy substrings at `test/lockspire/web/live/admin/design_system_component_stress_test.exs:59`, so copy drift can pass. It does not assert the full UI-SPEC empty state body, full error state, or full destructive confirmation body.

Positive evidence: the primary CTA/title `Render stress surface`, empty heading `No lab scenarios rendered`, and destructive title `Revoke token family` are present at `test/support/lockspire/web/admin_lab/stress_surface.ex:37`, `:129`, and `:149`. Generic-label scan found no rendered `Submit`, `OK`, `Cancel`, `Click Here`, or fear-language labels in the Phase 117 implementation files.

### Pillar 2: Visuals (3/4)

**WARNING:** The visual contract says the stress-surface matrix header must show active component group, theme, motion mode, and fixture set before preview content, and the active scenario preview should be the second focal point (`117-UI-SPEC.md:141`). The implementation provides lab metadata as `data-theme-mode` and `data-motion-mode` attributes at `test/support/lockspire/web/admin_lab/stress_surface.ex:30`, but the required visible matrix/header structure is not fully represented.

**WARNING:** Required state names are rendered as a plain paragraph at `test/support/lockspire/web/admin_lab/stress_surface.ex:55`, which proves strings but is not the same as compact matrix controls or an active scenario preview hierarchy.

Positive evidence: the surface uses real `AdminComponents` for hero, badges, metric grid, section cards, resource list/items, long values, error summary, form fields, copy-once panel, confirmation panel, action group, buttons, and empty state at `test/support/lockspire/web/admin_lab/stress_surface.ex:35-150`. The stress test verifies representative `lockspire-admin-*` classes at `test/lockspire/web/live/admin/design_system_component_stress_test.exs:96-110`.

### Pillar 3: Color (4/4)

**WARNING:** This pillar still carries a finding because every scored pillar must justify its score: dark-mode alias blocks include hardcoded semantic alias values such as `#131c2e`, `#c9d4e3`, `#8a99ad`, and border aliases at `lib/lockspire/web/admin_css.ex:1515-1524`. This is acceptable under the current source tests because primitive token redeclaration is prevented, but the token model should stay watched if the brandbook later moves all aliases into canonical token files.

Positive evidence: root light mode, Deep Cyan light accent, and semantic alias declarations are present at `lib/lockspire/web/admin_css.ex:6-130`. Dark/system remapping is isolated in `@dark_vars` and data/media selectors at `lib/lockspire/web/admin_css.ex:1512-1567`. Contract tests assert primitive token stability and explicit light/dark/system behavior at `test/lockspire/web/live/admin/design_system_contract_test.exs:220-255`.

Source scan: raw hex colors appear only in token/semantic alias declarations in `lib/lockspire/web/admin_css.ex`; the contract test at `test/lockspire/web/live/admin/design_system_contract_test.exs:320` enforces no non-token raw hex. No `components.json` exists, and UI-SPEC lines 192-199 list no third-party registries, so registry audit is skipped.

### Pillar 4: Typography (2/4)

**WARNING:** UI-SPEC limits Phase 117 typography to four sizes and two weights at lines 58-75. The CSS declares the expected tokens at `lib/lockspire/web/admin_css.ex:117-126`, but many direct values remain outside that scale: `1.875rem`/`700` at `lib/lockspire/web/admin_css.ex:183-184`, `0.6875rem`/`700` at `:209-210`, `1.25rem` at `:375`, `1.125rem` at `:486` and `:1300`, `0.9375rem` at `:344`, `500` at `:225`, and `650` at `:1207` and `:1214`.

**WARNING:** There is no Phase 117 test that rejects undeclared font sizes or weights. Existing tests assert that token names exist, but they do not enforce the four-size/two-weight distribution.

Positive evidence: font families follow the contract: display, sans, and mono stacks are declared at `lib/lockspire/web/admin_css.ex:22-24`; identifiers and long values use mono classes at `lib/lockspire/web/admin_css.ex:1177-1179` and `:1317-1327`.

### Pillar 5: Spacing (3/4)

**WARNING:** The foundation mostly uses declared `--ls-space-*` tokens, but several small hardcoded spacing/sizing values remain outside the Phase 117 spacing guidance. Examples include badge padding `0.125rem 0.625rem` at `lib/lockspire/web/admin_css.ex:401`, badge dot `0.45rem` at `:414-415`, checkbox `margin-top: 0.2rem` at `:747`, and icon height `22px` at `:175`.

**WARNING:** The contract reserves `3xl`/64px but does not add a token for it (`117-UI-SPEC.md:46`); the current CSS does not introduce it, which is fine, but there is also no source test that rejects arbitrary spacing values if future changes add them.

Positive evidence: the declared 4px scale is present at `lib/lockspire/web/admin_css.ex:9-18`, and most layout spacing uses `var(--ls-space-*)` across headers, cards, forms, resource lists, confirmation panels, and mobile rules. Responsive/min-width safeguards for long values and mobile layouts are present at `lib/lockspire/web/admin_css.ex:1169-1188`, `:1241-1248`, and `:1374-1488`, with regression assertions in `test/lockspire/web/live/admin/design_system_contract_test.exs:832-861`.

### Pillar 6: Experience Design (3/4)

**WARNING:** `Fixtures.scenario_states/0` lists all high-level states at `test/support/lockspire/web/admin_lab/fixtures.ex:4-23`, but `Fixtures.all/0` does not provide all required fixture-area records from UI-SPEC lines 160-167. Missing or thin areas include client no-redirect empty state/logout propagation URI, consent revoked/long identifiers, key upcoming/retiring/retired states, DCR disabled/open/active/expired IAT states, and operation pending/expired/logout delivery failed/retryable/discarded read-only rows.

**WARNING:** The test at `test/lockspire/web/live/admin/design_system_component_stress_test.exs:25-47` verifies state labels in `scenario_states/0`, not that each fixture area contains concrete rows for every required state. Future proof could pass while fixture data remains under-covered.

Positive evidence: redaction and boundary posture are strong. Forbidden substrings are centralized at `test/support/lockspire/web/admin_lab/fixtures.ex:37-48`; tests reject them in fixtures and rendered HTML at `test/lockspire/web/live/admin/design_system_component_stress_test.exs:49-52` and `:114-115`. Lab package/router/docs boundaries are tested at `test/lockspire/web/live/admin/design_system_component_stress_test.exs:136-149` and `test/lockspire/web/live/admin/design_system_contract_test.exs:300-317`. Motion and reduced-motion contracts are enforced at `test/lockspire/web/live/admin/design_system_contract_test.exs:258-298`.

---

## Registry Safety

Registry audit: 0 third-party blocks checked, no flags. `components.json` is absent, `117-UI-SPEC.md:192-199` declares no shadcn or third-party registries, and Phase 117 added no package-manager dependency.

---

## Verification

- `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` - passed, 4 tests, 0 failures. A pre-test KeyCache refresh log was emitted, matching existing verification notes.
- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - passed, 32 tests, 0 failures. A pre-test KeyCache refresh log was emitted, matching existing verification notes.

---

## Files Audited

- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-01-SUMMARY.md`
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-02-SUMMARY.md`
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-01-PLAN.md`
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-02-PLAN.md`
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md`
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-VERIFICATION.md`
- `test/support/lockspire/web/admin_lab/fixtures.ex`
- `test/support/lockspire/web/admin_lab/stress_surface.ex`
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs`
- `lib/lockspire/web/admin_css.ex`
- `test/lockspire/web/live/admin/design_system_contract_test.exs`
