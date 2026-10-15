# Phase 154 Responsive, Theme, Motion, and Keyboard Sweep

## Method

- Harness: `test/browser/admin_route_proof.mjs` (local-only, not in CI), driving `agent-browser` through a fresh session per theme; synthetic user `ops`; navigate-only (login form is the sole submit; keyboard sweeps use Tab and Escape only).
- Tooling: agent-browser 0.27.0, node v22.14.0.
- Source HEAD at sweep start: `b932385be37b7d42ada0ddc2c4b001ae91496b84`; `git status --porcelain` empty (clean) at that point.
- Demo: container `lockspire-ui-review-web-1` restarted 2026-10-15T21:56:41Z, readiness polled until the site answered, `scripts/demo/admin-ui --project lockspire-ui-review smoke` passed (after a 10 s settle).
- Widths: 320, 390, 640, 768, 1119, 1120, 1280 CSS px. Themes: light, dark, system. Motion: default, plus reduced-motion passes at 390.
- Zoom (D-02, WCAG 1.4.10 Reflow): 200% zoom at a 1280 px window equals a 640 px CSS viewport, and 400% equals 320 px, so the 640 and 320 columns are the 200% and 400% zoom proof. A native-zoom spot check is recorded separately below.
- Allowed intentional scroll containers: `.lockspire-admin-secondary-nav` (overflow-x auto) and `.lockspire-admin-table-wrap` (data tables). Visually hidden helper text (`.lockspire-admin-sr-only`, 1x1 px by design) is not a clipped control.
- Full rows and observation JSON live under git-ignored `tmp/admin-ui-polish/v1.42/sweep/`.

## Tracer: /admin/clients/new

Screenshots at 320 dark and 640 light show a visible boundary on empty inputs (control-border token). Rows below: 21 matrix rows (7 widths x 3 themes), one reduced-motion row, two keyboard rows.

## Results

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
| `/admin/clients/new` | Configure | 390px | system | reduced-motion | page load | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 1280px | light | default | tab x19; indicator 18/19; offscreen 0 | synthetic default data | 1280 | 1280 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
| `/admin/clients/new` | Configure | 390px | light | default | tab x10; indicator 9/10; offscreen 0 | synthetic default data | 390 | 390 | pass | h1=1; clipped=0; unlabeled=0; small-targets=6 | passed denylist | none | local route proof capture |
