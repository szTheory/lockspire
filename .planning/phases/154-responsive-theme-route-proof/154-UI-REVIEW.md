# Phase 154 — UI Review

**Audited:** 2026-10-15
**Baseline:** `154-UI-SPEC.md`. Where it is silent, the inherited 153/152 contracts and the `PRODUCT.md` personas and vocabulary map apply.
**Screenshots:** reviewed the Plan 07 final set (`tmp/admin-ui-polish/v1.42/final/`). Sampled `desktop/clients`, `desktop/client-edit`, `desktop/iats-new`, `desktop/policy-dcr--03-expiry-limits`, `reflow320/clients`, `reflow320/client-detail`, `mobile390/overview-route`, `zoom200/policies` and `themes/client-detail-1280-dark`. The final set was captured at `d3b2fec2`. It predates `e427f3af` (field focus ring and invalid border) and the theme-select hover change.
**Interaction captures:** the `workflow.ui_interaction_capture` key was off or not supplied. I did manual navigate-only checks on the live demo with agent-browser (session `uirev154`, signed in as `ops`), and saved 3 images to `tmp/ui-review-154/`. These cover: text-field focus in light at 1280, text-field focus in dark at 390, the bottom of the overview in dark at 390, the theme-select hover border, and form-control widths on 7 routes. I submitted no form other than sign-in and pressed no action control. The invalid-field state was not rendered, because rendering it needs a submit. Findings about the invalid state come from the code only.
**Gitignore gate:** the caller said to edit no file except this one, so I left `.planning/ui-reviews/.gitignore` alone. It already ignores image extensions but lacks `interaction/`. All new images are under the git-ignored `tmp/`.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | The phase changed no copy, but the pages it signs off break the inherited vocabulary map. One auth method has two names, one security profile has two names, PAR is not explained, and raw `false` values are shown. |
| 2. Visuals | 3/4 | Reflow and clipping are clean. Several visible flaws remain: a stretched "Secret and signing keys" card, a bullet split from its URL, an unattached "Filter apps" button, and a 38px unpainted band at the page bottom. |
| 3. Color | 3/4 | The control-border and invalid-border tokens meet 3:1 and are tested. Gaps: `--ls-border-control-invalid` is a token the spec does not declare, the system theme with a dark OS setting was never browser-proven, and native radio/checkbox boundaries in dark are not in the contrast contract. |
| 4. Typography | 3/4 | The phase added no sizes or weights and never shrinks text. The New app page puts its only lead sentence in 12px muted help text. |
| 5. Spacing | 2/4 | Breaks the spec rule "Forms keep the 600px maximum readable width": the DCR policy inputs are 832px and the setup-token expiry input is 1086px. The sweep did not check this rule. |
| 6. Experience Design | 3/4 | Keyboard, reduced-motion and focus fixes are real and proven, and the field focus ring is confirmed live. However, the final evidence predates the focus and invalid-border fixes, the error state was never rendered, and the harness cannot fail a row on focus or H1. |

**Overall: 16/24**

---

## Top 3 Priority Fixes

1. **Form controls ignore the 600px readable-width rule on two routes (WARNING)**
   - Measured live at 1280px:
     - `/admin/policies/dcr`: text inputs are 832px wide.
     - `/admin/iats/new`: the "Expires in days" input is 1086px wide and holds a two-digit number (see `final/desktop/iats-new.png`).
   - Cause: the `max-width: 600px` rule lives only on `.lockspire-admin-form-shell` (`lib/lockspire/web/admin_css.ex:977-979`), and these templates do not use that shell.
   - Impact: very long lines of help text, and number fields that look as if they expect long values. This breaks the spec's Responsive Contract and the 153 form layout.
   - Fix (shared CSS): cap form controls in one place. For example, add `.lockspire-admin-field > input:not([type=checkbox]):not([type=radio]), .lockspire-admin-field > select, .lockspire-admin-field > textarea { max-width: 600px; }` (or `37.5rem`), or wrap both templates in `form_shell`.
   - Guard: add a `CssAssertions` check, and a harness check that fails a row when a text control is wider than 600px.

2. **One concept has several names across the admin pages, against the PRODUCT.md vocabulary map (WARNING)**
   - Fix in one change:
     - Pick one label per auth method and use it in `policies_live/dcr.html.heex:195`, `clients_live/form_component.ex:86` and `clients_live/show.ex:1250`. "Client secret over HTTP Basic" should become "Client secret in the request header", and "Client secret in request body" should become "Client secret in the request body".
     - Replace "Public app (no secret)" with the map's "Browser or mobile app (no client secret)".
     - Use one name for the `:none` profile. `policies_live/index.ex:155` and `form_component.ex:278` say "Standard OAuth and OpenID Connect"; `show.ex:1181` and `:1204` say "Standard OpenID Connect".
     - Explain PAR in plain words next to `policies_live/index.ex:173`.
     - Render `boolean_label` at `show.ex:609` and `:619` as plain "Yes"/"No" text, not `<code>false</code>`.
     - Add the replaced phrases to the retired-wording table.

3. **Closed info tooltips stretch the page and leave an unpainted band at the bottom (WARNING)**
   - Where: `.lockspire-admin-info-tooltip` (`admin_css.ex:2157-2173`).
   - Cause: a closed tooltip is hidden with `visibility: hidden` but stays `position: absolute` below its trigger. On `/admin/overview` at 390px, the last tooltip ("Active token-signing key") ends at y=1408. The admin shell ends at y=1370.
   - Impact: the document gains 38px that the admin page background does not cover. It shows as a white strip in light theme (visible in the final `mobile390/overview-route.png`) and as a near-black UA-canvas strip in dark theme (`tmp/ui-review-154/overview-dark-390-bottom.png`). This breaks theme parity, and the eye review and the sweep both passed it.
   - Fix: use `display: none` when closed and `display: block` under `[data-open="true"]`. `aria-describedby` still resolves to content hidden with `display: none`. As a further option, open upward when near the end of the page.

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

**Phase contract met:** no copy changed, `PRODUCT.md` and the retired-wording table are untouched, and the vocabulary contract test is green. The spec also inherits PRODUCT.md, so the pages this phase signed off as final (`154-FINAL-01..30`) are held to the map as well.

- **WARNING — the same auth method has different names on different pages.**
  - The New app form (`clients_live/form_component.ex:86`) and app details (`clients_live/show.ex:1250`) say "Client secret in the request header".
  - The DCR policy (`policies_live/dcr.html.heex:195`) says "Client secret over HTTP Basic" and "Client secret in request body".
  - Impact: the least-technical persona (Support teammate, Partner-onboarding operator) cannot tell that these mean the same thing.
- **WARNING — the same security profile has different names.**
  - "Standard OAuth and OpenID Connect" appears at `policies_live/index.ex:155` and `clients_live/form_component.ex:278`.
  - "Standard OpenID Connect" appears at `clients_live/show.ex:1181` and `:1204`.
  - Both versions are visible in the final captures (`zoom200/policies.png` and `themes/client-detail-1280-dark.png`).
- **WARNING — "Public app (no secret)" (`dcr.html.heex:195`).** The map says a public client is shown as "browser or mobile app". This label is not on the retired list, but it contradicts the map.
- **WARNING — PAR is not explained.** The Security summary says "1 app requires PAR explicitly; 0 apps choose optional PAR." (`policies_live/index.ex:173`). The map requires PAR to be "explained in plain words beside it".
- **WARNING — raw booleans.** "Include session in server/browser notification" renders `<code>false</code>` (`clients_live/show.ex:609`, `:619`), in monospace, as if it were an identifier. It should be "Yes"/"No" in body text.
- **Minor — inconsistent back labels on one page.** The edit page header says "Back to app" (`clients_live/show.ex:343`, shared header). The footer says "Back to app details" (`clients_live/form_component.ex:447`).
- **Minor — help text reads like an error.** Under an empty "Client secret lifetime" field, the policy page shows "Apps will be told their secret has already expired" (`policies_live/dcr/lifetime_hint.ex:11`). It is correct, but it reads as an error when nothing is wrong. Lead with what to do, for example: "Leave blank only if apps should treat their secret as expired."
- **Minor — two placeholders for the multi-value input.** It shows "Add a value…" when empty and "Add another…" once it has values (`web/admin_controls.ex:9-11`). This is intended, but the empty field on the New app form looks unlike the edit form.
- Generic-label grep: no "Submit", "Click here" or "OK" CTAs. CTAs name the action ("Create app setup token", "Save app changes", "Disable app").

### Pillar 2: Visuals (3/4)

- Every page has a clear focal point: an H1 at the top left, one accent primary action, and a calm card hierarchy. All final images pass the no-clipping and no-overflow checks, and the F-03 badge fix shows correctly in `reflow320/clients.png`.
- **WARNING — the "Secret and signing keys" card stretches to its row partner's height.** At 1280 (`themes/client-detail-1280-dark.png`), "Current secret" floats in the middle of a mostly empty card and "Rotate client secret" sits at the bottom.
  - Cause: the grid `.lockspire-admin-client-workspace` (`admin_css.ex:2615-2620`) stretches items by default.
  - Fix: `align-items: start` on that grid.
  - `154-FINAL-CAPTURES.md` listed this as "non-blocking, present in baseline". It is still a visible defect on the page operators use to rotate secrets.
- **WARNING — the sign-in return URL bullet is split from its URL.** At 1280 the bullet sits alone and the URL starts on the next line (client detail, "Sign-in return URLs", `clients_live/show.ex:584`).
  - Cause: `.lockspire-admin-long-value { display: inline-block }` (`admin_css.ex:2602-2608`). An inline-block that cannot fit beside the marker wraps as a whole.
  - Fix: `display: inline` for list items, or a block value with `list-style-position: outside`.
- **WARNING — the "Filter apps" button is cut off from its filters.** At desktop (`desktop/clients.png`) the button sits alone at the far right, about 60px below the filter row and the count text. The submit action reads as part of the results, not the form. Place it inline with the three filters, after "Registration source".
- **WARNING — 38px unpainted band at the bottom of tall pages with info tooltips.** See Top fix 3. Confirmed live in dark at 390px.
- **Minor — the New app page has no header card.** `/admin/clients/new` opens with a full-width "Back to apps" button and a 12px muted sentence, with no title card. Edit, detail and the policy pages all use the header card or hero (live capture `tmp/ui-review-154/clients-new-focus-light.png`). The page looks unfinished next to Edit app settings.
- **Minor — wide desktop row gap on the Apps list.** In the Apps rows at 1280, about 650 CSS px separate the app name from its status badges. The eye has to cross the whole row to link a name to its state.
- No icon-only buttons. The info triggers are labeled ("About client secret lifetime"), and the multi-value chip removers carry labels (from earlier phases).

### Pillar 3: Color (3/4)

- **Pass — control boundary.**
  - `--ls-border-control` is gray-500 `#64748b` in light and `#7c8aa0` in dark (`admin_css.ex:104`, `:3011`). It is used only on inputs, selects, textareas, the theme and time-zone selects, and the enhanced multi-value field (`:419`, `:1095`, `:1248`). No decorative card border uses it.
  - Computed 3:1 is enforced by `assert_contrast_pairs!`.
- **Pass — post-capture fixes confirmed live.**
  - Field focus in light: 2px `rgb(14,116,144)` outline at 3px offset, a teal border, and a `brand-100` halo.
  - Field focus in dark: `rgb(34,211,238)` outline, border and 35% halo.
  - Theme-select hover changes the border from `rgb(100,116,139)` to `rgb(11,18,32)`. This fixes the 1.08:1 hover from review IN-04.
- **Pass — invalid border.** `--ls-border-control-invalid` is `#991b1b` in light and `#e35d6a` in dark (`admin_css.ex:105`, `:3012`), with a 3:1 contrast pair at `css_assertions.ex:230`. This fixes review WR-06, where the old `#fecaca` was 1.45:1. From the code: the invalid rule (`:1302-1309`) comes after the focus rule and has the same specificity, so a focused invalid field keeps a red border and shadow plus the teal outline. That is acceptable and stays distinguishable.
- **WARNING — contract drift.** The spec says "no new design tokens beyond the shipped `--ls-border-control`". `e427f3af` added `--ls-border-control-invalid` without updating `154-UI-SPEC.md` or recording it in the Color table. Add it to the Color table and to `brandbook/tokens/tokens.json`, as was done for `border-control`.
- **WARNING — "system" with a dark OS setting is not proven in a browser.** Review IN-06: harness rows labeled `system` run with light media. The final "1280 system" images and all 247 `system` rows in `154-BROWSER-EVIDENCE.md` therefore duplicate light. The `prefers-color-scheme: dark` path is covered only by the shared `@dark_vars` in the CSS contract test. The spec's theme parity rule requires the two paths to match; that is asserted, not observed.
- **WARNING — native radio and checkbox boundaries in dark are outside the contrast contract.** Unchecked radios at 390 in dark render as dim gray discs on `#131c2e` (`tmp/ui-review-154/clients-new-focus-dark-390.png`). They are probably above 3:1, but no pair in `assert_contrast_pairs!` covers them. Either set `accent-color` and a border token, or record the UA rendering as the accepted boundary.
- Accent use matches the declared roles: the primary button, current nav item, secondary-nav current page, and the selected tab underline. The "Added directly" and "Registered through API" provenance badges use the info status tokens, not accent. No hard-coded hex appears in component rules in this diff.

### Pillar 4: Typography (3/4)

- **Pass for phase scope.** The diff (`git diff ef6043ec HEAD -- lib/`) adds no `font-size` or `font-weight` declarations. No rule shrinks text at narrow widths. Long values use `overflow-wrap: anywhere` (`admin_css.ex:2606`). The 320 and 640 captures show wrapping, not truncation.
- File-wide distribution, which predates this phase and is out of scope per the spec:
  - 11 distinct font sizes, including 0.6875rem (11px), 0.9375rem, 1.125rem, 1.25rem and 1.875rem.
  - Weights 500, 650 and 700 alongside the token 400 and 600.
- **WARNING — the New app lead sentence is 12px muted help text.** "Add an app that will use this service." uses `lockspire-admin-help` (`clients_live/index.ex:118`) and is the only page-level description. At 390 it is the smallest text on the screen (`tmp/ui-review-154/clients-new-focus-dark-390.png`). Other pages put their lead in body size (14px) inside a header card.
- **Minor — label weight drift.** "Provider default:" and "Result if saved:" on the edit form render bolder than the 600 label role (`desktop/client-edit.png`). Spot-check whether they inherit 700 from `strong`.

### Pillar 5: Spacing (2/4)

- **Pass — phase spacing changes stay on the token scale.**
  - Secondary-nav wrap: `gap: var(--ls-space-1) var(--ls-space-4)` (`admin_css.ex:2844-2848`).
  - Status-cluster wrap: `gap: var(--ls-space-2)` (`:2583-2587`).
  - Root `scroll-padding-block: var(--ls-space-6)` (`:143`).
  - None of these adds an arbitrary px value.
- **WARNING — breaks "Forms keep the 600px maximum readable width" (154-UI-SPEC Responsive Contract).** Widths measured live at 1280:

  | Route | Form | Widest text control |
  |---|---|---|
  | `/admin/policies/dcr` | 832 | 832 |
  | `/admin/iats/new` | 1086 | 1086 |
  | `/admin/clients/new` | 522 | 522 |
  | `/admin/clients/:id/edit` | — | 600 (pass) |

  The only cap is `.lockspire-admin-form-shell { max-width: 600px }` (`admin_css.ex:977`). The 681-row sweep never measured it, so the contract stated this rule but never verified it. See Top fix 1.
- **WARNING — stretched card height.** The client-detail grid leaves large internal gaps (Pillar 2). The value and its action sit about 200px apart inside one card.
- **Minor — form width differs between New app (522px) and Edit app (600px)** for the same fields.
- Mobile rhythm is consistent: 16px gutters, 24px panel padding, and about 48px between overview cards at 390. Target sizes:
  - The collapsed nav toggle and its links keep `min-height: 2.75rem`.
  - The native 16-18px radios and checkboxes are accepted, because the whole label row is the target (sweep F-03).

### Pillar 6: Experience Design (3/4)

- **Pass — real defects found and fixed in shared code, with guards.**
  - F-01: the secondary nav wraps at 800px and below (`admin_css.ex:2844-2848`).
  - F-02: root scroll-padding.
  - F-03: the status cluster wraps at 640px and below.
  - The field focus ring was restored in `e427f3af` (`admin_css.ex:1258-1265`). Live, the field matches `:focus-visible` with a 2px outline at 3px offset in both themes, and the ring stays inside a 390px viewport.
  - Reduced motion is verified at 0.01ms on 6 pages, with a non-vacuous control run.
  - Keyboard: 14 of 14 rows, every stop with an indicator, 0 offscreen.
- **WARNING — the final evidence predates the last visual fix.**
  - All 102 final images and 681 rows come from `d3b2fec2`. `e427f3af` then changed the focus and invalid styles on every form field.
  - The spec's Fix Rule 4 says "Any CSS change after the first final capture invalidates earlier captures."
  - The keyboard rows marked text fields "indicator present" while CR-01 (focus 1.13:1 against rest) was still live. That shows the indicator check cannot tell a weak ring from a good one (review WR-04).
  - Fix: restart the container, rerun the 14 keyboard rows, and recapture at least `clients-new` and `client-edit` at 1280 light/dark and 390.
- **WARNING — the error state is not rendered anywhere in the evidence.** The navigate-only rule rules out submits. The spec's "error" consideration (error summary visible, associated, not clipped at 320) therefore rests on LiveView tests and CSS alone. Add a LiveView-rendered fixture route, or a component-lab page with `aria-invalid="true"` fields, so the sweep can capture the invalid boundary at 320 dark without a submit.
- **WARNING — the harness cannot fail on focus or H1.** Review WR-04: a row is `fail` only for overflow, clipping or unlabeled controls. Focus offscreen, missing indicator and H1 count end up in notes only. The badge escape (F-03) was also found by eye, not by the harness. The card-edge scan used in Plan 07 should become a standing check.
- **WARNING — hidden tooltips change the document height** (Top fix 3). This is an interaction-layer element affecting page layout while it is closed.
- **Minor — control hover is inconsistent.** Only `.lockspire-admin-theme-control select:hover` (`admin_css.ex:446`) has a hover border. Form inputs, selects and textareas have none. Either drop the header-only hover or apply the same `--ls-text-strong` hover to all controls.
- Destructive actions keep the confirmation panel ("Confirm disabling app" with a checkbox naming the Client ID), and the rotate pages were captured unconfirmed.

### Registry Safety

There is no `components.json`, and the spec lists no third-party registry. The registry audit was skipped as not applicable. `git diff --exit-code` on `mix.exs` and `mix.lock` is recorded clean in `154-SAFE-GATE.md`.

---

## Files Audited

- `.planning/phases/154-responsive-theme-route-proof/154-UI-SPEC.md`, `154-01..07-SUMMARY.md`, `154-RESPONSIVE-SWEEP.md`, `154-FINAL-CAPTURES.md`, `154-BROWSER-EVIDENCE.md` (grep), `154-REVIEW.md`
- `PRODUCT.md` (personas, vocabulary map, retired wording), `AGENTS.md`
- `lib/lockspire/web/admin_css.ex` (diff `ef6043ec..HEAD`, plus the form-shell, tooltip, long-value and client-workspace rules)
- `lib/lockspire/web/components/admin_components.ex` (diff: `radio_option_described_by/3`)
- `lib/lockspire/web/live/admin/clients_live/show.ex`, `clients_live/form_component.ex`, `clients_live/index.ex`, `policies_live/index.ex`, `policies_live/dcr.html.heex`, `policies_live/dcr/lifetime_hint.ex`, `lib/lockspire/web/admin_controls.ex` (copy lookups)
- `test/support/lockspire/web/admin_proof/css_assertions.ex` (contrast pairs)
- Screenshots: `tmp/admin-ui-polish/v1.42/final/{desktop/clients,desktop/client-edit,desktop/iats-new,desktop/policy-dcr--03-expiry-limits,reflow320/clients,reflow320/client-detail,mobile390/overview-route,zoom200/policies,themes/client-detail-1280-dark}.png`
- Live checks: `tmp/ui-review-154/clients-new-focus-light.png`, `clients-new-focus-dark-390.png`, `overview-dark-390-bottom.png`

## Fixes Applied (orchestrator, 2026-10-15)

| Item | Outcome | Commit |
|------|---------|--------|
| Top fix 1: text fields wider than 600px on `/admin/policies/dcr` and `/admin/iats/new` | Fixed: shared field controls cap at `min(100%, 600px)`; CSS contract guard added | 53ce5423, guard in follow-up test commit |
| Top fix 2: one concept, different names | Fixed: auth method labels unified with the app form, "Standard OAuth and OpenID Connect" used on app details, Yes/No instead of raw true/false, PAR explained in plain words; replaced phrases retired in PRODUCT.md | d653d963 |
| Top fix 3: closed tooltips extend the page | Fixed: closed tooltips use `display: none`; the script opens before measuring; guard added | 53ce5423 |
| Card stretch on app details | Fixed: `.lockspire-admin-client-workspace { align-items: start }` | 53ce5423 |
| Invalid-border token missing from spec | Fixed: added to 154-UI-SPEC.md color and contrast tables and brandbook tokens | e427f3af, this commit |
| System theme with dark OS never browser-tested | Fixed by code-review IN-06 (system rows run under both schemes) | 078fcc68 |
| Final evidence predates later CSS changes | Addressed by re-running the final captures and matrix on the frozen post-review source | see 154-FINAL-CAPTURES.md |
| Split bullet beside long URLs, detached "Filter apps" button, new-app page header, uneven hover | Deferred: layout polish outside this phase's responsive/theme scope; recorded for the next admin UI pass | — |
