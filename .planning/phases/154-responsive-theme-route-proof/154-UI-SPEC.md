---
phase: "154"
slug: "responsive-theme-route-proof"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-15"
---

# Phase 154 — UI Design Contract

> Responsive, theme, accessibility, and rendered-evidence contract for the existing 30 admin paths. This is a proof and hardening phase: it adds no screens, no new design tokens beyond the shipped `--ls-border-control`, and no new copy unless a sweep finding forces it. Spacing, typography, color roles, and copy are inherited unchanged from `153-UI-SPEC.md` and `152-UI-SPEC.md`; where this file is silent, those contracts govern.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — Lockspire's Phoenix components and tokenized BEM CSS (no shadcn; no `components.json`) |
| Preset | Not applicable |
| Component library | `Phoenix.Component` with `Lockspire.Web.Components.AdminComponents` |
| Icon library | None; visible text labels carry meaning |
| Font | Familjen Grotesk (headings), Inter (UI/body), JetBrains Mono (identifiers); system fallbacks; no bundled or externally fetched fonts |

Visual source of truth: `brandbook/tokens/tokens.json` and the shipped equivalent `Lockspire.Web.Admin.CSS` (`lib/lockspire/web/admin_css.ex`). No component library, parallel token set, font, or dependency is added (SAFE-01, D-04/D-06).

## Component Inventory

Enumerated by `rg -c '^  def [a-z0-9_]+\(assigns\) do$' lib/lockspire/web/components/admin_components.ex && rg -n 'version:' mix.exs | head -1` — 37 components — `Lockspire.Web.Components.AdminComponents` (internal)@1.5.1 — 2026-10-15.

Non-exhaustive list of known-good components, not an allowlist. This phase introduces no component; it may adjust the shared CSS or shared component markup behind these when a sweep finding requires it.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `page_hero/1`, `entity_header/1` | `Lockspire.Web.Components.AdminComponents` | Title blocks; must reflow at 320px without truncating the only name of the resource. |
| `pane/1`, `section_card/1`, `workflow_shell/1` | `Lockspire.Web.Components.AdminComponents` | Containers; single column at narrow widths, no nested-card clipping. |
| `form_field/1`, `radio_group/1`, `checkbox_group/1`, `multi_value_control/1`, `error_summary/1` | `Lockspire.Web.Components.AdminComponents` | Controls use `--ls-border-control`; labels, descriptions, and errors stay programmatically associated. |
| `admin_button/1`, `action_bar/1`, `action_group/1` | `Lockspire.Web.Components.AdminComponents` | Actions stack in task order on narrow widths and meet target size. |
| `responsive_table/1`, `resource_list/1`, `dense_resource_row/1`, `lifecycle_row/1`, `long_value/1` | `Lockspire.Web.Components.AdminComponents` | Table-to-list reflow; long values wrap in their own container. |
| `status_badge/1`, `status_cluster/1`, `alert/1`, `empty_state/1`, `confirmation_panel/1`, `copy_once_secret_panel/1`, `policy_nav/1` | `Lockspire.Web.Components.AdminComponents` | State always has text; copy-once and confirmation behavior unchanged. |

## Spacing Scale

Inherited from 153 without change.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon/label gaps, compact inline spacing |
| sm | 8px | Related inline controls |
| md | 16px | Default field/row gap and control padding |
| lg | 24px | Section spacing, panel padding |
| xl | 32px | Major group separation |
| 2xl | 48px | Page-level separation only |
| 3xl | 64px | No routine use |

Exceptions (phase-specific, all for accessibility):
- Interactive targets: minimum 24x24 CSS px (WCAG 2.2 SC 2.5.8) everywhere; the collapsed-navigation toggle and nav links keep the existing `min-height: 2.75rem` (44px). Any control found under 24px is fixed in shared CSS, with 44px preferred for touch-width layouts.
- Theme select keeps at least 16px between the chevron and the right border (153).
- Existing proven component insets and control dimensions may remain; do not introduce off-scale layout gaps while fixing overflow.

## Typography

Inherited from 153 without change: two weights only (400, 600), four sizes, for selectors this phase adds or changes. Pre-existing off-scale sizes (11/15/18/20/30px) and weights (500/650/700) in `admin_css.ex` predate this phase, are known (see 152-UI-REVIEW), and are out of scope here.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body / row | 14px | 400 | 1.5 |
| Label / metadata | 12px | 600 | 1.2 |
| Section heading | 16px | 600 | 1.25 |
| Page title / key value | 24px | 600 | 1.2 |

Responsive rules: never shrink text to fit a narrow viewport; reflow, wrap, or stack instead. Text must remain usable at 200% zoom (640 CSS px layout) and 400% (320 CSS px). Long URLs, scopes, IDs, key IDs, and error details use `overflow-wrap: anywhere` inside their own container. Do not set fixed pixel heights on text-bearing containers (a zoom-only clipping risk not reproduced by viewport emulation).

## Color

Inherited from 153. No new roles. The only token change this phase relies on is the shipped control boundary.

| Role | Value | Usage |
|------|-------|-------|
| Dominant surface | `--ls-surface-page` | Page canvas |
| Supporting surface | `--ls-surface-panel`, `--ls-surface-muted` | Panels and field surfaces where grouping helps |
| Accent | `--ls-text-accent` (`#0e7490` light; `#22d3ee` dark) | Principal safe action, current navigation, few meaningful links |
| Destructive | Existing danger tokens | Confirmed consequential action and its state only |
| Control boundary | `--ls-border-control` (gray-500 light; `#7c8aa0` dark) | Border of inputs, selects, textareas, multi-value container; never decorative card borders |

Accent reserved for: primary safe action, current navigation item, current-page markers in the secondary nav (`.lockspire-admin-secondary-nav a[aria-current="page"]`), the selected multi-value suggestion, and the hovered overview review-row label. No 60/30/10 split is declared; 153 disclaims a literal split and this phase inherits that. Not applied to every interactive element.

### Contrast thresholds (enforced by computed ExUnit test against compiled `Lockspire.Web.Admin.CSS.get()`)

| Pair | Threshold | Themes |
|------|-----------|--------|
| Body, muted (`#5f6f84` light / `#8a99ad` dark), accent, and status (success/warning/danger/info) text on panel, page, and muted surfaces | 4.5:1 (WCAG 1.4.3) | light, dark |
| Primary button label on accent fill | 4.5:1 | light, dark |
| Form control boundary `--ls-border-control` on panel surface | 3:1 (WCAG 1.4.11) | light, dark; system resolves to one of these via `prefers-color-scheme` |
| Focus ring (2px, 3px offset) on panel/page | 3:1 | light, dark |
| State badges and icons conveying status | 3:1 and always paired with text | light, dark |

Known floor to protect: muted text on muted surface is 4.68:1 in light; any token edit that lowers it fails the test.

### Theme parity rules

- Three choices: System, Light, Dark. Preference persists in `localStorage["lockspire-admin-theme"]`; `system` removes `data-theme` and follows `prefers-color-scheme`.
- Every token remapped for dark must also resolve identically through `:root[data-theme="dark"]` and the `prefers-color-scheme: dark` system path. A page must not differ in layout, content, or available actions between themes; only color values change.
- No hard-coded hex in component rules outside the token blocks. State is never conveyed by color alone.
- `forced-colors: active` keeps controls and focus visible (existing block must not regress).

## Responsive Contract

Evidence viewports (CSS px): **320, 390, 640, 768, 1119, 1120, 1280**. Behavior at each is defined by the existing breakpoints; fixes go in shared CSS.

| Viewport | Meaning | Required behavior |
|----------|---------|-------------------|
| 320 | WCAG reflow floor (1280 at 400%) | One column; no document-level horizontal scroll; all labels and actions reachable; nothing clipped |
| 390 | Common phone | Same as 320; collapsed navigation shows a usable current-page name |
| 640 | 200% zoom of 1280 | Passes at/under the `max-width: 640px` rules; forms keep readable width; actions stack in task order |
| 768 | Tablet portrait | Single or two-column per component rule; secondary nav scrolls internally if needed |
| 1119 | Last collapsed-nav width (`max-width: 1119px`) | Collapsed navigation, 44px toggle and links |
| 1120 | First expanded-nav width | Expanded sidebar/nav with no overlap of main content |
| 1280 | Desktop baseline | Full layout; matches 153 comparison scale |

Layout rules (all viewports):
- `document.documentElement.scrollWidth <= clientWidth`. This is the pass test and the same rule `BrowserEvidence` enforces.
- Allowed internal scroll containers (documented, not failures): the secondary navigation (`overflow-x: auto`), and genuinely tabular data in `responsive_table` where it has not yet converted to a list. Content surrounding them still reflows.
- The mobile table-to-list conversion (`max-width: 800px`) preserves readable column labels.
- The ellipsized current-page label in the collapsed nav toggle must not be the only place the current page name appears (the page H1 carries it) and must show the full name on focus/activation of the opened menu.
- The multi-value input (12rem) must stay within its container at 320px.
- Forms keep the 600px maximum readable width; inventories and details may use the wider shell.
- Intentional `white-space: nowrap` is limited to short labels and badges; it never applies to values, URLs, or error text.
- The host layout owns `<meta name="viewport">`; the demo layout includes it. Lockspire does not claim to assert it for adopters.

## Interaction and Accessibility Contract

- **Keyboard:** every control reachable by Tab in a logical order matching visual order; no keyboard trap; Escape closes disclosures, info triggers, and suggestion menus where they already do; focus does not jump on LiveView read refresh. Verified on one page of each type: list, form, detail, confirmation.
- **Focus visible:** every interactive element shows the 2px ring with 3px offset (`--ls-focus-ring-*`) at 3:1 minimum; `outline: none` is allowed only with an equally visible replacement (field border plus `--ls-focus-ring-shadow`, overview-label `::after` outline). A new interactive element with no rule keeps the UA ring, never none. The focused element must be scrolled into the viewport and not hidden behind sticky chrome.
- **Target size:** 24x24 CSS px minimum, 44px for collapsed-nav controls.
- **Labeled controls:** every form control has a programmatically associated label; `aria-describedby` and `aria-*` targets resolve; ids are unique; links have hrefs; exactly one H1 per page. Enforced by `assert_page_contract!/2` inside the existing route render tests; plans 03–05 together wire it into all 30 routes.
- **Reduced motion:** `prefers-reduced-motion: reduce` sets transitions to `0.01ms`, removes transforms, and leaves no running `getAnimations()` on checked pages (nav toggle, overview info tooltips, policy tabs, confirmation panels, token-detail disclosure, client radios). No `transition: all`. No new animation unless it gives real feedback.
- **No clipped content or actions:** no element whose content is cut off by `overflow: hidden` without an accessible full-value path; no primary, secondary, or danger action off-screen or beyond the right edge at any evidence viewport.
- **State without color:** badges, errors, and alerts always carry text.
- **Forms during proof:** capture is navigate-only. Never submit a form, click a confirmation, rotate, revoke, reveal, or generate during evidence capture.

## Fix Rule

Fix findings once, in shared code, not per page.

1. Prefer `lib/lockspire/web/admin_css.ex` token or component rules; second choice is shared markup in `admin_components.ex`.
2. A per-route patch is permitted only when the cause is route-specific markup, and the plan records why shared code does not apply.
3. Every fix adds or extends a deterministic contract (CSS assertion, computed contrast, or `assert_page_contract!`) when the regression is recurring and checkable without a browser.
4. Any CSS change after the first final capture invalidates earlier captures; final captures are taken last, from a clean tree, after `docker restart lockspire-ui-review-web-1` and a smoke run.
5. Do not edit protocol, storage, security, or domain code (`lib/lockspire/protocol|storage|security|domain`). Non-admin compiler warnings are reported, not fixed. Admin-web warnings (`device_authorizations_live/index.ex` clause grouping, `keys_live/index.ex` dead clause) are fixed behavior-preservingly.

## Evidence Contract

| Layer | Scope | Method |
|-------|-------|--------|
| Final desktop (D-03) | All 30 paths, 1280 (same scale as the 153 baseline), System theme | Full-page capture; when a page is too tall or illegible, one capture per meaningful section (each section exactly once). IDs `154-FINAL-01` to `154-FINAL-30`. |
| Changed pages (12) | 1280 light, dark, system; 390 light; 320 dark; 640 light | Screenshots |
| Remaining pages | All widths and themes in the matrix | DOM-only rows (scroll/client width, H1 count, clipped elements, unlabeled controls, small targets) |
| 200% zoom (D-02) | 640 CSS px ≈ 200% of 1280; 320 ≈ 400% | Viewport emulation; native zoom spot check on 3 pages, or record "not observed" |
| Reduced motion, keyboard | One page per type, six motion pages | `set media reduced-motion`, Tab sweep recording focus outline and in-viewport check |

Evidence rules: synthetic Billingo demo data only; text is scanned with the `BrowserEvidence` denylist before any image is saved; no secrets, one-time credentials, user/device codes, or private-key material (`rg "BEGIN [A-Z ]*PRIVATE KEY"` over evidence returns nothing); each image reviewed by eye and recorded; images stay under git-ignored `tmp/`, with a tracked manifest (path, dimensions, sections, redaction result, source SHA). `/admin/clients/new` must show the "New app" form, never "Client not found". Real-browser sweeps are local maintainer evidence and are not added to CI; only the deterministic contracts join `test.fast`.

## Copywriting Contract

No new copy is planned. Inherited from 153/152 and PRODUCT.md.

| Element | Copy |
|---------|------|
| Primary CTA | Unchanged per route (e.g. `Create client`, `Save client settings`). Never renamed by this phase. |
| Empty state heading | `No {resource} found` (unchanged) |
| Empty state body | Unchanged; filtered-empty is distinct from globally empty |
| Error state | `Could not load {resource}. The current results are unavailable.` (unchanged) |
| Destructive confirmation | Existing action name + affected object + exact scope + supported consequence (unchanged); revocation scopes stay distinct |

If a sweep finding forces a wording change (for example a truncated label needing a shorter accessible name): read `PRODUCT.md` first, use the "UI says" term, add any new term to the vocabulary map and any replaced phrase to the retired-wording table in the same change (`vocabulary_contract_test.exs` enforces). Prefer CSS-only fixes. Never use "operator" as visible audience copy.

## UI Considerations

Applicable state considerations resolved: 8 covered, 0 backstop, 0 unresolved. Empty/error copy lives in the Copywriting Contract above and in 153; this table covers the layout and accessibility behavior of each state across viewports and themes.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Collection pages, filtered-empty results, unfilled forms | ✅ covered | Empty states reflow at 320px, remain legible in light/dark/system, and keep their one next-step action visible. |
| loading | Route data, inherited defaults, navigation shell | ✅ covered | Loading states cause no horizontal overflow and the shell remains operable; no layout shift hides actions. |
| error | Read failures, submit errors, lifecycle errors | ✅ covered | Error summary and field errors stay visible, associated by `aria-describedby`, perceivable without color, and not clipped at 320px. |
| populated | Inventories, details, policy forms, queues | ✅ covered | Pass the bundled page contract (one H1, labeled controls, unique ids) and the viewport/theme matrix. |
| partial | Optional metadata, inherited settings | ✅ covered | Absent values keep their label; layout does not collapse or overflow when a value is missing. |
| overflow | Rows, nav, forms, action groups, tables, multi-value input | ✅ covered | Document `scrollWidth <= clientWidth` at all seven viewports; allowed internal scroll containers are limited to secondary nav and data tables. |
| zero-one-many | Collections, counts | ✅ covered | Singular/plural text and counts stay correct; one row and many rows both reflow at 320px. |
| long-text | Client names/IDs, URLs, scopes, key IDs, errors | ✅ covered | Values wrap with `overflow-wrap: anywhere` at 14px; no truncation without a full-value path; nav-toggle ellipsis never hides the sole page name. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | Not applicable. No shadcn or third-party registry; no dependency added (verified by `git diff --exit-code <start-sha> -- mix.exs mix.lock` at phase end). |

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS — no registry or dependency is used.
- [x] Dimension 7 Inventory Provenance: PASS — re-runnable command, count, resolved internal package version, and date recorded.

**Approval:** pending
