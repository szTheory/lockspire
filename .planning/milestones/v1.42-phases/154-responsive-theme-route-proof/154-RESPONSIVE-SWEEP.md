# Phase 154 Responsive, Theme, Motion, and Keyboard Sweep

## Method

- Harness: `test/browser/admin_route_proof.mjs` (local-only, not in CI), driving `agent-browser` through a fresh session per theme; synthetic user `ops`; navigate-only (login form is the sole submit; keyboard sweeps use Tab and Escape only).
- Tooling: agent-browser 0.27.0, node v22.14.0.
- Source HEAD at sweep start: `b932385be37b7d42ada0ddc2c4b001ae91496b84`; `git status --porcelain` empty (clean) at that point.
- Demo: container `lockspire-ui-review-web-1` restarted 2026-10-15T21:56:41Z, readiness polled until the site answered, `scripts/demo/admin-ui --project lockspire-ui-review smoke` passed (after a 10 s settle).
- Widths: 320, 390, 640, 768, 1119, 1120, 1280 CSS px. Themes: light, dark, system. Motion: default, plus reduced-motion passes at 390.
- "system" in this sweep means system-light: every `system` row was captured under `prefers-color-scheme: light` (code review IN-06). The harness now also runs `system` under dark media; see the system-dark section of `154-BROWSER-EVIDENCE.md`.
- Zoom (D-02, WCAG 1.4.10 Reflow): 200% zoom at a 1280 px window equals a 640 px CSS viewport, and 400% equals 320 px, so the 640 and 320 columns are the 200% and 400% zoom proof. A native-zoom spot check is recorded separately below.
- Allowed intentional scroll containers: `.lockspire-admin-secondary-nav` (overflow-x auto) and `.lockspire-admin-table-wrap` (data tables). Visually hidden helper text (`.lockspire-admin-sr-only`, 1x1 px by design) is not a clipped control.
- Full rows and observation JSON live under git-ignored `tmp/admin-ui-polish/v1.42/sweep/`.

## Tracer: /admin/clients/new

Screenshots at 320 dark and 640 light show a visible boundary on empty inputs (control-border token). Rows below: 21 matrix rows (7 widths x 3 themes), one reduced-motion row, two keyboard rows.

## Findings and dispositions

Pre-fix sweep: 630 of 630 matrix rows (30 paths x 7 widths x 3 themes) reported no document overflow, no clipped content, and no unlabeled controls. The keyboard sweep found two focus-visibility defects, both fixed in shared CSS.

- **F-01 (fail, fixed):** At 390 px on policy pages the secondary nav is a hidden-scrollbar horizontal scroller. Tabbing to "Security requirements" (box 272-418 px in a 390 px viewport, nav scrollLeft 0) left the link and its focus ring partly clipped, because Chrome only scrolls a focused element into view when it is fully hidden. Shared selector: `.lockspire-admin-secondary-nav`. Disposition: fixed in the `@media (max-width: 800px)` block (`flex-wrap: wrap; overflow-x: visible`) so every link is visible without scrolling. Guarded by `CssAssertions.assert_responsive_layout!/0` (narrow secondary nav wraps). The base rule keeps `overflow-x: auto` for widths above 800 px, so the scroller allowance is unchanged there. Fix commit `677c1430386a861b27a397d52b7110d8bb5b1e6c`.
- **F-02 (fail, fixed):** A focused radio on `/admin/policies/dcr` at 390 px sat flush against the viewport bottom (box 882-900 of 900), leaving its 2 px ring plus 3 px offset below the fold. Shared selector: `:root`. Disposition: fixed with `scroll-padding-block: var(--ls-space-6)`, guarded by `CssAssertions.assert_theme_focus_and_motion!/0`. Fix commit `677c1430386a861b27a397d52b7110d8bb5b1e6c`.
- **F-03 (allowed):** Native checkbox and radio inputs of 16-18 px report as "small targets" (336 of 630 pre-fix rows). Each sits inside its label, so the whole label row is the target; recorded as an informational note, not a failure. `/admin/tokens/:id` also notes one inline 18 px link, covered by the inline-text exception.
- **Plan 07 final-capture finding (fail, fixed; called F-03 in `154-FINAL-CAPTURES.md`, which is a different item from the small-target F-03 above):** on `/admin/clients` at 320 px, the "Registered through API" provenance badge ran past its card edge (badge right edge at 318 px, card edge at 304 px). This sweep did not catch it because the badge overflowed its card but not the document: `scrollWidth` equalled `clientWidth` and no ancestor clipped it. Plan 07 found it by eye in the final 320 px capture. Fixed in `d3b2fec2`: the app inventory status cluster wraps at 640 px and below, guarded by `CssAssertions.assert_responsive_layout!/0`. Re-verified with a card-edge scan of all 30 paths at every width: 0 instances. See `154-FINAL-CAPTURES.md`.
- **Harness defects fixed during the sweep (not product defects):** sr-only helper text and long values scrolling inside text inputs were flagged as clipped; reserved `example.com` demo hosts tripped the production-hostname denylist on `/admin/logouts` and `/admin/policies/dcr` (42 rows were first blocked, then re-run clean); keyboard measurement read focus transitions at their start value in headless Chrome and did not wait for scroll to settle. See commits `123d4551` and `4a85ad9b`.

No admin copy changed, so PRODUCT.md and its retired-wording table are untouched. No protocol, storage, security, or domain files were edited.

## Counts (pass / rows)

Pre-fix, source `123d4551` (all 30 paths, default motion):

| Width | light | dark | system |
|---|---|---|---|
| 320px | 30/30 | 30/30 | 30/30 |
| 390px | 30/30 | 30/30 | 30/30 |
| 640px | 30/30 | 30/30 | 30/30 |
| 768px | 30/30 | 30/30 | 30/30 |
| 1119px | 30/30 | 30/30 | 30/30 |
| 1120px | 30/30 | 30/30 | 30/30 |
| 1280px | 30/30 | 30/30 | 30/30 |

Post-fix, container restarted 2026-10-15T22:44:48Z on source `677c1430386a861b27a397d52b7110d8bb5b1e6c` (all 30 paths, default motion):

| Width | light | dark | system |
|---|---|---|---|
| 320px | 30/30 | 30/30 | 30/30 |
| 390px | 30/30 | 30/30 | 30/30 |
| 640px | 30/30 | 30/30 | 30/30 |
| 768px | 30/30 | 30/30 | 30/30 |
| 1119px | 30/30 | 30/30 | 30/30 |
| 1120px | 30/30 | 30/30 | 30/30 |
| 1280px | 30/30 | 30/30 | 30/30 |

Spot check at 1100 px (the extra `max-width: 1100px` breakpoint in the CSS that is not in the width list): all 30 paths, light theme, post-fix: 30/30 pass, no document overflow, no clipped content (rows kept in `tmp/admin-ui-polish/v1.42/sweep/post/w1100/`; 1100px is not an accepted BrowserEvidence viewport, so they are summarized here instead of tabled).

## Reduced motion

With `prefers-reduced-motion: reduce` emulated at 390 px, the computed `transition-duration` and `animation-duration` of every element (and its `::before`/`::after`) is at most 0.01 ms on `/admin/overview` (info tooltips), `/admin/policies` (tabs), `/admin/clients/:client_id/rotate-secret` (confirmation panel), `/admin/tokens/:id` (details disclosure), `/admin/clients/new` (radios), and `/admin/policies/dcr`; every page shares the nav toggle. Control run with default motion shows 150 ms transitions, so the check is not vacuous. Any CSSTransition objects still listed by `document.getAnimations()` have a duration of at most 0.01 ms (headless Chrome does not advance the animation clock). Raw data: `tmp/admin-ui-polish/v1.42/sweep/post/motion.json`.

## Native zoom spot check

Native browser zoom at 200% on `/admin/clients/new`, `/admin/overview`, and `/admin/tokens/:id`: **not observed**. The agent-browser CLI drives Chrome over CDP and exposes only viewport size and deviceScaleFactor; Control+Equal and Meta+Equal key presses did not change `innerWidth` (stayed 1280) or `devicePixelRatio`. Per D-02, 200% zoom is proven by the 640 px viewport column and 400% by the 320 px column of the matrix above.

## Results

### Tracer: /admin/clients/new, width x theme matrix (21 rows; its reduced-motion and keyboard rows are in the sections below)

| Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
| `/admin/clients/new` | Configure | 320px | light | default | page load | synthetic default data | 320 | 320 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 390px | light | default | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 640px | light | default | page load | synthetic default data | 640 | 640 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 768px | light | default | page load | synthetic default data | 768 | 768 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1119px | light | default | page load | synthetic default data | 1119 | 1119 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1120px | light | default | page load | synthetic default data | 1120 | 1120 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1280px | light | default | page load | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 320px | dark | default | page load | synthetic default data | 320 | 320 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 390px | dark | default | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 640px | dark | default | page load | synthetic default data | 640 | 640 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 768px | dark | default | page load | synthetic default data | 768 | 768 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1119px | dark | default | page load | synthetic default data | 1119 | 1119 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1120px | dark | default | page load | synthetic default data | 1120 | 1120 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1280px | dark | default | page load | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 320px | system | default | page load | synthetic default data | 320 | 320 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 390px | system | default | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 640px | system | default | page load | synthetic default data | 640 | 640 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 768px | system | default | page load | synthetic default data | 768 | 768 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1119px | system | default | page load | synthetic default data | 1119 | 1119 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1120px | system | default | page load | synthetic default data | 1120 | 1120 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1280px | system | default | page load | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |

### Keyboard sweep before the fix (Tab and Escape only; only the rows with partly hidden focus, marked fail; the other 10 pre-fix rows matched the post-fix rows)

| Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
| `/admin/clients/:client_id/edit` | Configure | 390px | light | default | tab x14; indicator 14/14; offscreen 1 | synthetic default data | 390 | 390 | fail | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | focus ring partly outside viewport (F-01 secondary-nav link, F-02 viewport edge) | local route proof capture |
| `/admin/policies/dcr` | Configure | 390px | light | default | tab x29; indicator 29/29; offscreen 2 | synthetic default data | 390 | 390 | fail | h1=1; clipped=0; unlabeled=0; small-targets=13 | passed denylist | focus ring partly outside viewport (F-01 secondary-nav link, F-02 viewport edge) | local route proof capture |

### Keyboard sweep after the fix

| Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
| `/admin/clients` | Configure | 1280px | light | default | tab x22; indicator 22/22; offscreen 0 | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/clients` | Configure | 390px | light | default | tab x13; indicator 13/13; offscreen 0 | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/clients/:client_id/edit` | Configure | 1280px | light | default | tab x23; indicator 23/23; offscreen 0 | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/:client_id/edit` | Configure | 390px | light | default | tab x14; indicator 14/14; offscreen 0 | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/keys/:id` | Operate | 1280px | light | default | tab x14; indicator 14/14; offscreen 0 | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/keys/:id` | Operate | 390px | light | default | tab x5; indicator 5/5; offscreen 0 | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/clients/:client_id/rotate-secret` | Configure | 1280px | light | default | tab x15; indicator 15/15; offscreen 0 | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=1 | passed denylist | none | local route proof capture |
| `/admin/clients/:client_id/rotate-secret` | Configure | 390px | light | default | tab x6; indicator 6/6; offscreen 0 | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=1 | passed denylist | none | local route proof capture |
| `/admin/device_authorizations` | Support | 1280px | light | default | tab x30; indicator 30/30; offscreen 0 | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/device_authorizations` | Support | 390px | light | default | tab x21; indicator 21/21; offscreen 0 | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/policies/dcr` | Configure | 1280px | light | default | tab x38; indicator 38/38; offscreen 0 | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=13 | passed denylist | none | local route proof capture |
| `/admin/policies/dcr` | Configure | 390px | light | default | tab x29; indicator 29/29; offscreen 0 | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=13 | passed denylist | none | local route proof capture |

### Reduced motion after the fix (390 px, system theme)

| Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
| `/admin` | Orient | 390px | system | reduced-motion | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/overview` | Orient | 390px | system | reduced-motion | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/policies` | Configure | 390px | system | reduced-motion | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=0 | passed denylist | none | local route proof capture |
| `/admin/clients/:client_id/rotate-secret` | Configure | 390px | system | reduced-motion | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=1 | passed denylist | none | local route proof capture |
| `/admin/tokens/:id` | Operate | 390px | system | reduced-motion | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=1 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 390px | system | reduced-motion | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/policies/dcr` | Configure | 390px | system | reduced-motion | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=13 | passed denylist | none | local route proof capture |

## Evidence locations and final source

Full 630-row matrices: `tmp/admin-ui-polish/v1.42/sweep/full/` (pre-fix) and `tmp/admin-ui-polish/v1.42/sweep/post/full/` (post-fix), git-ignored. This is the last source edit of the phase; the final source commit for Plan 07 capture is `677c1430386a861b27a397d52b7110d8bb5b1e6c` (`lib/lockspire/web/admin_css.ex`).

## Superseded by the final matrix after the review fixes

This sweep ran on Plan 06 source. The code review and UI review then changed CSS, copy and the harness: `e427f3af`, `53ce5423`, `d653d963`, `8776458a`..`078fcc68`, `bbeabdbd`, and `3e31d401` (chip fields capped at 600 px, F-04). The final matrix in `154-BROWSER-EVIDENCE.md` was re-run on the frozen post-review source `3e31d401` with the hardened harness: 840 rows, with `system` under both light and dark media. It supersedes the counts above for the shipped UI. This document stays as the record of the Plan 06 sweep, its fixes, and its dispositions; the allowed dispositions above still apply.
