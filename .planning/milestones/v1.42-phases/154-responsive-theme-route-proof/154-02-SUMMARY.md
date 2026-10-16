---
phase: 154-responsive-theme-route-proof
plan: "02"
subsystem: admin-ui-contrast
tags: [wcag, contrast, css-tokens, brandbook]
requires: []
provides:
  - "--ls-border-control token (3:1 control boundary) in light and dark"
  - "CssAssertions.assert_contrast_pairs!/0 computed WCAG contrast contract"
affects: [154-07]
tech-stack:
  added: []
  patterns: ["Local Elixir WCAG math over compiled Lockspire.Web.Admin.CSS.get(), no color library"]
key-files:
  created: []
  modified:
    - lib/lockspire/web/admin_css.ex
    - test/support/lockspire/web/admin_proof/css_assertions.ex
    - test/lockspire/web/live/admin/design_system/css_contract_test.exs
    - brandbook/tokens/tokens.json
key-decisions:
  - "Control boundary token: light gray-500 (#64748b), dark #7c8aa0; decorative card/divider borders keep subtle/strong tokens"
requirements-completed: [UI-07]
status: complete
duration: 12 min
completed: 2026-10-15
commits: 3
plan_head_before: b13af3dde9dfe9da7c799da45493a7d777bc7822
plan_head_after: cbe6d147d8680be721246138c8a06184a6f96b69
actuals:
  tokens: 6000
  tasks: 2
  commits: 3
---

# Phase 154 Plan 02: Control Boundary Contrast Summary

Form controls (inputs, selects, textareas, theme selector, enhanced multi-value field) now use a shared `--ls-border-control` token that meets 3:1 in light, dark, and system themes, guarded by a computed WCAG contrast test that runs in `mix test.fast`.

## Accomplishments

- RED then GREEN: the test first failed with "token --ls-border-control is not defined", then passed once the token landed. Reverting the light token to gray-300 reports "light theme: --ls-border-control on --ls-surface-panel is 1.48:1, needs at least 3.0:1".
- `--ls-border-control` added to `:root` (gray-500) and `@dark_vars` (#7c8aa0, so it also covers the `prefers-color-scheme: dark` system path). Three control rules switched to it.
- `assert_contrast_pairs!/0` pins, in both themes: body and muted text on panel/page/muted surfaces (4.5), accent text on panel/muted (4.5), success/warning/danger/info status text on status bg (4.5), primary button label (4.5), focus ring on panel (3.0), control border on panel/page/muted (3.0). All text pairs passed without token changes.
- Brandbook `border-control` entries added (light `{color.neutral.500}`, dark `#7c8aa0`); `assert_semantic_tokens!` now requires `--ls-border-control`.

## Verification

- design_system suite: 28 passed. `mix test.fast`: 1553 passed, 6 skipped.
- Acceptance greps: 3 control rules use the token, 2 declarations, 1 `def assert_contrast_pairs!`, 2 brandbook entries; PRODUCT.md unchanged since ef6043ec.

## Deviations from Plan

None - plan executed exactly as written. (Commit count is 3: the TDD RED test commit is separate from the token commit.)

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Modified files exist; commits 1c185874, 5507c7ee, cbe6d147 are on HEAD.
