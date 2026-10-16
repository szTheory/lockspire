---
phase: 154-responsive-theme-route-proof
plan: "06"
subsystem: admin-ui-proof
tags: [responsive, theme, keyboard, reduced-motion, focus, css-contract]
requires: ["154-01", "154-02", "154-04", "154-05"]
provides:
  - "154-RESPONSIVE-SWEEP.md: 30-path x 7-width x 3-theme sweep on restarted current source, plus reduced-motion, keyboard, 1100px and native-zoom results"
  - "Shared CSS fixes for partly hidden keyboard focus (secondary nav, viewport edge) with CSS contract assertions"
affects: [154-07]
tech-stack:
  added: []
  patterns: ["Local agent-browser sweep, results copied into a tracked BrowserEvidence doc", "One CssAssertions check per shared fix"]
key-files:
  created:
    - .planning/phases/154-responsive-theme-route-proof/154-RESPONSIVE-SWEEP.md
  modified:
    - lib/lockspire/web/admin_css.ex
    - test/support/lockspire/web/admin_proof/css_assertions.ex
    - test/browser/admin_route_proof.mjs
    - test/browser/admin_route_proof_test.mjs
key-decisions:
  - "Secondary nav wraps at 800px and below instead of scrolling, because Chrome only scrolls a focused link into view when fully hidden"
  - "Root scroll-padding-block keeps a focused control and its ring off the viewport edge"
  - "1100px spot check is summarized in prose: BrowserEvidence does not accept 1100px as a viewport, and widening the validator was out of scope"
requirements-completed: []
status: complete
duration: 115 min
completed: 2026-10-15
commits: 4
plan_head_before: b932385be37b7d42ada0ddc2c4b001ae91496b84
plan_head_after: 8efc8463cf48ea3442307a69fd0f6ffc757166d2
actuals:
  tokens: 42000
  tasks: 3
  commits: 4
---

# Phase 154 Plan 06: Responsive, Theme, Motion and Keyboard Sweep Summary

All 630 matrix cells (30 admin paths x 320/390/640/768/1119/1120/1280 px x light/dark/system) pass before and after the fix, and the keyboard sweep found two real focus-visibility defects that are now fixed in shared CSS with contract guards.

## Accomplishments

- Tracer (`/admin/clients/new`, 21 cells) then the full matrix on a restarted container: no document overflow, clipped content, or unlabeled control at any width or theme; screenshots at 320 dark and 640 light show a visible empty-input boundary.
- Reduced motion (390 px, 6 pages): every element computes transition and animation durations of at most 0.01 ms; default-motion control shows 150 ms, so the check is not vacuous.
- Keyboard (Tab and Escape only) on list, form, detail, confirmation, queue, and tabbed settings pages at 1280 and 390 px: every stop has a visible indicator and sits inside the viewport after the fix.
- F-01: secondary nav at 390 px left a focused link partly clipped; fixed by wrapping at 800px and below. F-02: focused radio flush with the viewport bottom; fixed with `:root` scroll-padding. Both guarded in `CssAssertions`.
- 1100 px spot check: 30/30 pass. Native browser zoom: not observed (CDP-driven Chrome ignores zoom keys); 640 px and 320 px columns carry the 200% and 400% proof per D-02.

## Verification

- `mix test test/lockspire/web/live/admin`: 258 passed. `mix test.fast`: 1554 passed, 6 skipped. `mix format --check-formatted`: clean. `node --test test/browser/admin_route_proof_test.mjs`: 9 pass.
- Sweep doc parses with `BrowserEvidence.parse!/1` (42 rows); 630 full-matrix rows exist under `tmp/admin-ui-polish/v1.42/sweep/full/`.
- Protocol/storage/security/domain/dependency diff vs `ef6043ec` is empty; the v1.42 diff vs `e67a4898` equals the known PR #123 allowlist.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Harness reported sr-only helper text as clipped content**
- **Found during:** Task 1 tracer (all 21 rows failed on `span.lockspire-admin-sr-only`)
- **Fix:** skip 1x1 visually hidden elements in the clipped check
- **Files modified:** test/browser/admin_route_proof.mjs
- **Commit:** 123d4551

**2. [Rule 1 - Bug] Harness false positives and measurement artifacts**
- **Found during:** Task 2 (42 rows on `/admin/logouts` and `/admin/policies/dcr` blocked by the hostname denylist on reserved `example.com` demo hosts; text inputs with long values flagged as clipped; focus transitions read at their start value because headless Chrome does not advance the animation clock; scroll not settled before measuring)
- **Fix:** exempt RFC 2606 example domains (with a node test), skip text fields in the clipped check, finish animations and wait for scroll before measuring, honor focus-within rings, record each stop's rect
- **Files modified:** test/browser/admin_route_proof.mjs, test/browser/admin_route_proof_test.mjs
- **Commit:** 4a85ad9b

**2 deviations, 0 requiring a decision.** Impact: the harness now measures end-state focus rings, so earlier ad hoc keyboard numbers are not comparable; both pre- and post-fix numbers in the sweep doc use the final harness.

The plan allowed `.planning` doc and shared CSS edits only in the listed files; the harness edits (test/browser) were added files outside `files_modified` but were required to produce valid evidence.

## Known Stubs

None.

## Threat Flags

None. No admin copy changed; no action, confirmation, consequence text, or redaction marker was hidden or removed.

## Self-Check: PASSED

154-RESPONSIVE-SWEEP.md exists; commits 123d4551, 4a85ad9b, 677c1430, 8efc8463 are on HEAD.
