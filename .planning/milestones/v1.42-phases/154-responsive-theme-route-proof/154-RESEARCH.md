# Phase 154: Responsive, Theme & Route Proof - Research

**Researched:** 2026-10-15
**Domain:** Admin UI (Phoenix LiveView) responsive/theme/a11y proof, rendered-evidence capture, and security-regression gating. No new product features.
**Confidence:** HIGH on repo facts (all read or run this session); MEDIUM on WCAG interpretation (cited W3C pages); capture-tool behavior at 200% zoom emulation is MEDIUM (reasoned, see A1).

## User Constraints (from CONTEXT.md)

No `154-CONTEXT.md` exists (no discuss-phase was run). Constraints come from `REQUIREMENTS.md`, `ROADMAP.md`, `AGENTS.md`, and the Phase 153 decisions this phase inherits (`153-CONTEXT.md` D-05, D-09, D-10, D-11, D-12).

### Locked (inherited, treat as locked)
- No new dependencies (SAFE-01). Keep Signal Cyan identity, native controls, semantic tokens (153 D-05).
- Browser evidence uses synthetic Billingo demo data only. Never capture one-time credentials, user/device codes, private key material (153 D-11, SAFE-01).
- Interaction, device-authorization, logout queues stay read-only; confirmation semantics and distinct revocation scopes unchanged (SAFE-01, 153 D-10).
- Phase 154 owns: final 30-path captures, viewport/zoom/theme/keyboard proof, comparison with the 153 baseline. Browser automation joins CI "only for reliable recurring value" (153 D-12, PROOF-01).
- Admin UI copy: read `PRODUCT.md` vocabulary map before changing any text; new wording must be added to the map, retired wording to the retired table (`AGENTS.md`, enforced by `test/lockspire/web/live/admin/vocabulary_contract_test.exs`).
- Host app keeps account, login, layout, branding, policy ownership; Lockspire stays an embedded library (`AGENTS.md`).

### Claude's Discretion
Everything else: matrix shape, tooling inside existing tools, which deterministic contracts to add.

### Deferred Ideas (OUT OF SCOPE)
- Lifetime-expiry enforcement semantics (pending protocol todo, `153-LIFETIME-TRUTH.md`).
- CR-01 signing-key-at-rest issue (separate, unresolved; do not touch, do not screenshot private key material).
- WR-03 (demo smoke seed assertions) deferred in `153-REVIEW-DISPOSITION.md`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-07 | Changed views usable at narrow widths and 200% zoom; light/dark/system parity; contrast; keyboard focus; labeled controls; reduced motion; no clipped content/actions | Existing CSS contract coverage and gaps (below); contrast numbers computed this session; viewport matrix and DOM-sweep method; one real gap found (text-input border contrast) |
| PROOF-01 | 30 paths x baseline + final redaction-safe captures; section captures when too tall; focused tests/browser checks; CI only if reliable | Baseline set inventory and what it predates; capture tooling (`agent-browser`); `BrowserEvidence` schema; reserved `154-FINAL-01..30` IDs |
| SAFE-01 | Protocol/security defaults, redaction, copy-once, revocation scopes, read-only queues, host ownership unchanged; no deps; no private key in evidence | 515-test gate command verified green in ~7s; git-diff gates; existing assertions identified |
</phase_requirements>

## Summary

Almost all machinery for this phase already exists; the work is (1) closing a few deterministic-contract gaps, (2) running one disciplined rendered sweep against the current source, and (3) producing a final capture set and evidence manifest *after* the last source edit. There is no Playwright/Wallaby in the repo. The browser harness is the globally installed `agent-browser` CLI (v0.27.0, ran `agent-browser --version`), used by `test/browser/admin_theme_storage_failure_test.mjs` and by all of Phase 153's captures. It is local maintainer tooling, not a repo dependency, and CI has no real browser (the CI "Adoption Demo Smoke" job is a Python `http.client` black-box script, `scripts/demo/adoption_smoke.py`). So real-browser captures and zoom/theme sweeps are one-off *evidence*; only pure-Elixir/Node deterministic contracts are CI-eligible.

The 153 baseline (`tmp/admin-ui-polish/v1.42/before/`, 30 full-page PNGs, 2522 px wide, ignored by git) was taken after Phases 151/152 and before any Phase 153 edit. It therefore does **not** show 153's changes, the later #123/#124/#128 changes, or the caret fix. No existing "after" set is final: `tmp/admin-ui-polish/v1.42/after/` is the first cleanup pass; `autonomous-sweep/after-desktop|after-mobile` pre-date #124, #128, 5ab166a1 and the 153 review fixes. A fresh final set is required and must be taken last.

Two findings the planner must act on: (a) `mix compile --warnings-as-errors` currently fails on this branch (8 warnings under local Elixir 1.20.4; at least one, the ungrouped `filter_device_authorizations/2` clause in a Phase 152 file, is version-independent and will fail CI "Run qa gate"); (b) text inputs use `--ls-border-strong` as their only boundary, which is 1.48:1 (light) and 1.64:1 (dark) against the panel, below the 3:1 non-text contrast bar when the border is what identifies the control.

**Primary recommendation:** Plan four waves: W0 harness and matrix definition (no source edits); W1 deterministic contracts (contrast, focus, reflow, label sweep, evidence-viewport list) plus the compile-warning cleanup; W2 a scripted browser sweep of all 30 paths across widths/themes/motion with fixes for what it finds; W3 (last) final captures, evidence manifest, SAFE-01 gate, requirement flips. Do not add dependencies, and do not wire real-browser checks into CI.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Responsive layout, reflow, zoom behavior | Browser / Client (CSS in `admin_css.ex`) | Host app layout (viewport meta) | Layout is pure CSS; the host root layout supplies `<meta name="viewport">` (demo: `examples/adoption_demo/lib/adoption_demo_web/admin_root/root.html.heex:5`). Lockspire cannot assert it for adopters. |
| Light/dark/system theme | Browser / Client (`data-theme` + `prefers-color-scheme`) | LiveView shell script in `admin_layout_live.ex` | Theme choice persists in `localStorage["lockspire-admin-theme"]`; `system` removes the `data-theme` attribute. |
| Focus visibility, reduced motion | Browser / Client (CSS) | — | `:focus-visible` rules and a `prefers-reduced-motion: reduce` block in `admin_css.ex`. |
| Labeled controls, headings, ARIA wiring | Frontend Server (LiveView/HEEx render) | — | Server-rendered markup; checkable with `LiveViewTest` + `LazyHTML` without a browser. |
| Redaction, copy-once, revocation scope, read-only queues | API / Backend (Lockspire admin contexts + LiveView handlers) | — | Behavior lives in server code; protect with existing ExUnit tests. Screenshots can only corroborate. |
| Rendered evidence capture | Local maintainer tooling (`agent-browser` against the demo container) | — | Not shipped, not CI. |
| Host ownership of login/layout/branding | Host app | — | Verified by operator-boundary doc assertions (`RouteAssertions.assert_operator_boundary!`). |

## Standard Stack

No package installs. Everything below is already present.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| ExUnit + `Phoenix.LiveViewTest` + `LazyHTML` | project-locked | Deterministic render/CSS/route contracts | Existing `AdminProof` helpers in `test/support/lockspire/web/admin_proof/` |
| `Lockspire.Web.AdminProof.{CssAssertions,HtmlAssertions,RedactionAssertions,RouteAssertions,RouteScorecards,BrowserEvidence}` | in repo | Reuse and extend | Capability helpers guarded by `inventory_contract_test.exs` (no phase-numbered APIs, no archived-milestone paths, no count thresholds) |
| `agent-browser` | 0.27.0 `[VERIFIED: agent-browser --version]` | Local rendered capture, viewport/media emulation | Already the Phase 153 capture tool; supports `set viewport <w> <h> [scale]`, `set media [dark\|light] [reduced-motion]`, `screenshot --full`, `eval` `[VERIFIED: agent-browser set --help, screenshot --help]` |
| Node | v22.14.0 `[VERIFIED: node --version]`; `.tool-versions` pins `nodejs 22.14.0` | `node --test` for pure-JS checks; capture script runner | Matches existing `test/browser/*.mjs` precedent |
| Docker demo `lockspire-ui-review` | running | Serves current workspace source with synthetic Billingo seed | `scripts/demo/admin-ui --project lockspire-ui-review ...`; mounts repo at `/workspace` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `agent-browser` | `/opt/homebrew/bin/chromium` headless | Present `[VERIFIED: which]`, but needs an authenticated session and has no viewport/media helpers. Fallback only. |
| Playwright/Wallaby | — | Forbidden by SAFE-01 (no dependencies) and absent. |
| Native browser zoom | viewport emulation | Phase 147-07 halted because native-zoom screenshot export was unavailable (`STATE.md` line 271). Viewport emulation is the reliable path (see A1). |

**Installation:** none.

## Package Legitimacy Audit

No external packages are installed or recommended in this phase. `agent-browser` is an already-installed local CLI, not a project dependency, and nothing is added to `mix.exs`, `mix.lock`, or any `package.json` (none exists at the repo root). Packages removed (SLOP): none. Packages flagged (SUS): none.

## Existing Evidence Inventory (answers the capture questions)

| Artifact | Location | What it is | Predates |
|----------|----------|------------|----------|
| **Official 153 baseline**, 30 full-page PNGs | `tmp/admin-ui-polish/v1.42/before/*.png` (manifest `.planning/phases/153-configure-support-page-refinement/153-BASELINE-SCREENSHOTS.md`) | Pre-153-edit, post-151/152 source. Browser default desktop settings, Chrome full-page, 2522 px wide, heights 1512 to 6142 px. Isolated demo project `lockspire-ui-review`, Billingo seed, read-only navigation. All 30 redaction-reviewed. Filename for `/admin/clients/new` is `clients-new-routing-error.png` (shows the "Client not found" defect). | Everything in 153, #123, #124, #128, 5ab166a1 |
| First cleanup captures | `tmp/admin-ui-polish/v1.42/after/*.png` (30 PNG + `visible-copy-audit.txt`) | Desktop, first cleanup pass | Later follow-ups; not final |
| Autonomous sweep | `tmp/admin-ui-polish/v1.42/autonomous-sweep/{before,after-desktop,after-mobile}`, `confirmation-manifest.json` (60 rendered checks), `source-sha256.json`, `gallery.html`, `interactions/` | 1512x982 desktop and 390x844 mobile, System theme; DOM checks (one H1, doc width == viewport, no dangling ARIA ids). Pre-#124/#128 and pre-review-fixes. | #124 nav collapse, #128 policy tabs, 5ab166a1, 153 review fixes |
| Feedback-pass images | `tmp/admin-ui-polish/v1.42/feedback-pass/` | Targeted screenshots incl. light/dark mobile samples | Not route-complete |
| Route matrix | `.planning/phases/153-configure-support-page-refinement/153-ROUTE-REVIEW.md` | 30 rows; HTTP 200 + one H1 rechecked 2026-10-15; **reserves `154-FINAL-01` to `154-FINAL-30`** and names each baseline image | Source of record for final-ID mapping |

Notes for planning:
- `tmp/` is git-ignored `[VERIFIED: git check-ignore -v tmp/x.png -> .gitignore:15:/tmp/]`. Images stay local; the tracked artifact is the manifest (paths, dimensions, section coverage, redaction check, source SHA).
- 153 recorded that the demo browser used default settings with no emulation; for comparability the final desktop set should use the same viewport scale, then record dimensions beside the baseline's. (Exact baseline CSS width is inferred as 1261 px at DPR 2 from 2522 px physical width; `[ASSUMED]`, A2.)
- Mobile 390x844 final-state captures from 153 exist for the pre-review-fix source; they are not final either.

## Existing Test Contracts vs. Gaps (UI-07)

Read this session: `css_contract_test.exs`, `route_contract_test.exs`, `theme_sync_test.exs`, `inventory_contract_test.exs`, `proof_artifact_contract_test.exs`, and the `AdminProof` helpers. `mix test test/lockspire/web/live/admin/design_system` -> `Result: 26 passed` `[VERIFIED: ran]`.

| Concern | Covered today | Verbatim anchor | Gap for UI-07 |
|---------|---------------|-----------------|---------------|
| Theme choices | `assert_theme_control!` checks `data-lockspire-theme-select` and `<option value="system\|light\|dark">`; `:root[data-theme="light"]`, `:root[data-theme="dark"]`, `@media (prefers-color-scheme: dark)` asserted | `css_assertions.ex` `assert_theme_focus_and_motion!` | Strings only; no parity check that every token remapped in `@dark_vars` has a counterpart, and no computed contrast. |
| Contrast | None computed in tests. Manual numbers in `152-UI-REVIEW.md` (W-8 found 4.34:1 on muted rows; fixed by `--ls-text-muted: #5f6f84`, `admin_css.ex:99`). | — | **Add a pure-Elixir WCAG ratio test over token pairs.** I computed pairs this session (below); all text pairs pass 4.5:1. |
| Focus visible | `assert css =~ ":focus-visible"` and the ring declaration `outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);`. Two `outline: none` rules are compensated (field rule uses border + `--ls-focus-ring-shadow`; overview label uses `::after` outline). `--ls-focus-ring-width: 2px`, offset `3px` (`admin_css.ex:129-130`). | `admin_css.ex:1254-1259`, `2083-2092` | Focus styling is per-selector (nav, buttons, resource-list links, fields, summaries...), not a global rule. A new interactive element without a rule falls back to the UA ring (acceptable). Browser tab-order sweep still needed for visible-focus proof on all 30 pages. |
| Reduced motion | `@media (prefers-reduced-motion: reduce)` plus `transition-duration: 0.01ms !important`, `transform: none;`; `refute ... transition: all` | `admin_css.ex:2960-2975` | Covered by string assertions; browser proof via `set media reduced-motion` is optional evidence. The tooltip/disclosure/nav-toggle behaviors under reduced motion are not exercised. |
| Narrow widths / reflow | `assert_responsive_layout!`: `overflow-wrap: anywhere` on long values, secondary nav `overflow-x: auto` + `white-space: nowrap`, nav collapse at `@media (max-width: 1119px)` with `min-height: 2.75rem`, mobile table-to-list at `@media (max-width: 800px)` | `css_assertions.ex` | No test at 320 CSS px (WCAG 1.4.10), no zoom check. Intentional internal scroll containers exist (secondary nav, line 203 `overflow-x: auto`; tables 943, 1754) and must be documented as allowed, with surrounding content still reflowing. |
| Clipping risks in CSS | — | `admin_css.ex:308-310` nav-toggle current-page label `overflow: hidden; text-overflow: ellipsis; white-space: nowrap`; `:1118` multi-value input `width: 12rem`; `:1738`, `:1766` `white-space: nowrap`; `:564` nowrap | Verify in-browser at 320/640 that the ellipsized nav label does not hide the only name of the current page, and the 12rem input does not overflow its container. |
| Labeled controls | `HtmlAssertions.assert_label_targets_exist`, `assert_describedby_targets_exist`, `assert_aria_targets_exist`, `assert_no_duplicate_ids`, `assert_links_have_hrefs` exist but are called only from some suites (e.g. `iat_live_test.exs` lines 56-58, 310-312, 523-527) | `html_assertions.ex:24-160` | **No sweep applies them to every one of the 30 routes.** Add a bundled `assert_page_contract!/1` and call it from each route's existing render test. |
| One H1 per page | Verified by HTTP/HTML recheck in `153-ROUTE-REVIEW.md` (point-in-time doc, deliberately not test-pinned: commit f0b0bd63 removed a planning-doc matrix test) | — | Put "exactly one h1" in the bundled page contract instead of a planning doc. |
| Route set | `RouteContractTest` + `RouteScorecards.expected_routes/0` -> 30 paths `[VERIFIED: mix run printed 30]` | `route_assertions.ex`, `route_scorecards.ex` | Fine. Do not pin planning docs or a hard-coded count. |
| Browser-evidence schema | `BrowserEvidence.parse!/1` validates columns, themes `light/dark/system`, motion `default/reduced-motion`, journeys, **viewports limited to 320/390/768/799/800/801/1024/1440px**, no document-level overflow on `pass`, and a sensitive-pattern denylist | `browser_evidence.ex:1-30` | Allowed viewports omit the widths this phase needs: 640 (200% of 1280), 720 (200% of 1440), 1119/1120 (nav-collapse boundary at `max-width: 1119px`), 1512/1261 (desktop). Extend `@allowed_viewports` and the unit test in `proof_artifact_contract_test.exs`. Only synthetic fixtures are parsed today; no real evidence file is validated. |
| Non-text contrast (1.4.11) | None | — | **Real gap, see Pitfall 1.** |

### Contrast, computed this session (WCAG relative-luminance formula, `node -e`)
Token values read from `admin_css.ex:28-125` and `2985-3000`. `[VERIFIED: computed]`

| Pair | Light | Dark |
|------|-------|------|
| `--ls-text-body` on panel / page / muted | 10.35 / 9.90 / 9.45 | 11.36 / 12.49 / 9.79 |
| `--ls-text-muted` (`#5f6f84` light, `#8a99ad` dark) on panel / page / muted | 5.13 / 4.90 / 4.68 | 5.87 / 6.46 / 5.06 |
| accent text on panel / muted | 5.36 / 4.89 | 9.42 / 8.12 |
| success / warning / danger / info text on its bg | 6.49 / 6.38 / 6.80 / 6.49 | 10.24 / 8.68 / 8.95 / 11.15 |
| Primary button label on accent | 5.36 (white on `#0e7490`) | 10.36 (`#0b1220` on `#22d3ee`) |
| Focus ring vs panel (non-text, needs 3:1) | 5.36 | 9.42 |
| **Input border (`--ls-border-strong`) vs panel (non-text, needs 3:1)** | **1.48** | **1.64** |

The muted-text margin on muted surfaces is thin (4.68 light). Any future token tweak regresses silently, which is why a computed test earns its place.

## Browser Capture Plan

### Environment
- Demo: `lockspire-ui-review-web-1` is up and serves `http://lockspire-ui-review.localhost/lockspire/admin` (302 to `/login?return_to=...` unauthenticated `[VERIFIED: curl]`). `http://127.0.0.1:4112` returned `000` (not reachable on that port now), so use the `.localhost` host. Sign in with the synthetic account `ops` (pattern in `adoption_smoke.py:188` and the `.mjs` precedent).
- The container bind-mounts the repo at `/workspace`; **code changes need `docker restart lockspire-ui-review-web-1`** before capture (memory note and `153-ROUTE-REVIEW.md` method). Run `scripts/demo/admin-ui --project lockspire-ui-review smoke` after restart; the 153 notes warn that a smoke run immediately after restart once saw an empty JWKS, so wait for settle.
- Record `git rev-parse HEAD`, dirty state, and sha256 of changed source files into the manifest (precedent: `autonomous-sweep/source-sha256.json`).

### Path list and fixtures (30 paths)
Source of truth: `RouteScorecards.expected_routes/0` (`test/support/lockspire/web/admin_proof/route_scorecards.ex`). Synthetic substitutions proven in `153-ROUTE-REVIEW.md`: client `billingo-reports-backend`, registration-token route client `northstar-payables-portal`, key `1`, consent `1`, token `3`. Prefix with `/lockspire` in the demo.

```
/admin   /admin/overview   /admin/clients   /admin/clients/new   /admin/clients/:client_id
/admin/clients/:client_id/{edit,redirects,logout-uris,par-policy,security-profile,rotate-secret}
/admin/clients/:client_id/edit?workflow=logout-propagation
/admin/clients/:client_id/rotate-registration-access-token   (use northstar-payables-portal)
/admin/policies   /admin/policies/{par,security-profile,dpop,dcr}
/admin/keys   /admin/keys/:id   /admin/dcr   /admin/iats   /admin/iats/new
/admin/consents   /admin/consents/:id   /admin/tokens   /admin/tokens/:id
/admin/interactions   /admin/device_authorizations   /admin/logouts
```
That is 30 (`/admin` and `/admin/overview` both count).

### Matrix (recommended, prescriptive)
| Layer | Scope | Method | Artifact |
|-------|-------|--------|----------|
| Final desktop capture (PROOF-01) | 30 paths, System theme, same viewport scale as baseline | `screenshot --full`; if a page exceeds ~4000 CSS px or text becomes unreadable at the saved size, capture meaningful sections (viewport-height scroll slices, one per H2 group) | `tmp/admin-ui-polish/v1.42/final/desktop/` + manifest keyed `154-FINAL-NN` |
| Responsive DOM sweep (UI-07) | 30 paths x widths {320, 390, 640, 768, 1119, 1120, 1280} x themes {light, dark, system} | `set viewport`, localStorage theme + `set media`, then one `eval` returning `scrollWidth`, `clientWidth`, clipped-element list, unlabeled controls, small targets | JSON rows -> evidence table (`BrowserEvidence` columns) |
| Zoom-equivalent screenshots | 30 paths at 640 (200% of 1280) light, and 30 at 320 (400% reflow floor) dark; sections when tall | `set viewport 640 900`, `set viewport 320 800` | `final/zoom200/`, `final/reflow320/` |
| Mobile 390 | 30 paths, one theme each alternating dark/light, or a representative 12 if time-boxed | same | `final/mobile/` |
| Theme parity screenshots | 8 representative pages (overview, clients, client edit, policies/dcr, keys detail, consent detail, token detail, a queue) x {light, dark, system} at 1280 | `localStorage` + `set media` | `final/themes/` |
| Reduced motion | 6 pages (nav toggle at 390, overview info tooltips, policies tabs, confirmation panels, token details disclosure, client radios) with `set media reduced-motion`; assert no running animations/transitions via `eval` on `getAnimations()` | `eval` | evidence rows with Motion=`reduced-motion` |
| Keyboard | Tab-order sweep on each page type (list, form, detail, confirmation): record `document.activeElement` outline width/offset and that the focused element is inside the viewport; Escape/Enter on disclosures, info triggers, suggestions | `press Tab`, `eval` | evidence rows with a Focus path |

Why viewport emulation stands in for zoom: CSS layout depends on the viewport width in CSS px, so a 1280 px window at 200% zoom lays out like a 640 px viewport, and WCAG defines 320 CSS px as 1280 px at 400% `[CITED: https://www.w3.org/WAI/WCAG22/Understanding/reflow.html]`. One native-zoom spot check (Chrome UI zoom on 3 pages) is a worthwhile supplement but must not block the phase; Phase 147-07 could not export screenshots at native zoom (`STATE.md:271`). Browser text-only zoom and `rem` scaling are not reproduced by viewport emulation (A1).

### Redaction handling
- Navigate only; never submit forms, rotate, reveal, revoke, or generate (153 Plan 00 rule). The rotate-secret and rotate-registration-token pages are confirmation-only until submitted; do not click the confirm control.
- Before saving any image, `eval` the page text through the same denylist `BrowserEvidence.assert_redaction_safe!` uses (patterns in `browser_evidence.ex` `sensitive_patterns/0`: JWT-looking, `client_secret=`, `device_code=`, private-key header, bearer, etc.). Note its "production-looking hostname" pattern would flag real `.com/.io/...` hosts but demo fixtures use `*.localhost`/`example` style hosts; confirm on the first pass.
- Copy-once secret *rendering* cannot be captured safely in the demo (it requires creating a credential). Prove it with LiveView tests that use synthetic values (`iat_live_test.exs`, `clients_live_test.exs`, `clients_live/show_test.exs`, `keys_live_test.exs`, `design_system_component_stress_test.exs` already cover `copy_once`). The component-lab stress surface (`AdminLab.StressSurface`) is a test-support module, not served; do not expose it.
- Review every saved image by eye (as 153 did) and record "Pass" per row. Do not capture key detail pages' JWK material: `/admin/keys/:id` shows public metadata only per the 153 manifest; confirm again.

### Capture script
Add one maintainer-run Node script following the `test/browser/*.mjs` precedent (`execFileSync("agent-browser", ["--session", name, ...])`, `eval` returns JSON). Suggested `test/browser/admin_route_proof.mjs`, parameterized by `LOCKSPIRE_PROOF_BASE_URL`, writing images under `tmp/` and printing an evidence-table markdown. It must not be added to `.github/workflows/ci.yml` (needs a running demo and a global CLI). Keep the pure parsing/summary functions importable so `node --test` can unit-test them without a browser, as `admin_multi_value_test.mjs` does for `admin_controls.ex`.

## Architecture Patterns

### Evidence and gate flow
```
current source (HEAD, clean tree)
   |
   +--> docker restart lockspire-ui-review-web-1 --> demo smoke (HTTP)
   |                                                   |
   |                                      agent-browser session (ops login, read-only)
   |                                                   |
   |      for each of 30 paths x width x theme x motion:
   |         set viewport / set media / localStorage theme -> open -> eval(DOM sweep + redaction scan)
   |                                                   |
   |                          screenshot --full or per-section slices -> tmp/.../final/...
   |                                                   v
   |                 evidence table (BrowserEvidence columns) + 154-FINAL-NN manifest
   |                                                   |
   +--> ExUnit contracts (CSS/contrast/page contract/route/redaction) --> SAFE-01 gate commands
                                                       v
                             REQUIREMENTS.md / ROADMAP.md flips (orchestrator)
```

### Recommended deliverables (files)
```
.planning/phases/154-responsive-theme-route-proof/
├── 154-BROWSER-EVIDENCE.md      # BrowserEvidence-schema table (viewport/theme/motion/focus rows)
├── 154-FINAL-CAPTURES.md        # 154-FINAL-01..30 -> image paths, dims, sections, redaction check, source SHA
├── 154-SAFE-GATE.md             # command outputs for SAFE-01
test/lockspire/web/live/admin/design_system/  # contrast + extended CSS assertions (in existing files)
test/support/lockspire/web/admin_proof/       # assert_page_contract!, contrast helper, viewport list
test/browser/admin_route_proof.mjs            # local-only capture script
```

### Pattern: bundled page contract applied inside existing route tests
**What:** one helper that runs h1-count, duplicate ids, label targets, describedby/aria targets, link hrefs, token-like-text and rendered-safe checks, called from each route's existing "renders" test.
**Why not a new 30-route fixture sweep:** each LiveView test file owns its own seeded fixtures; a central sweep would duplicate heavy setup.
**Skeleton** (helper names are the ones read in `html_assertions.ex` and `redaction_assertions.ex` this session; `h1` count is new):
```elixir
# test/support/lockspire/web/admin_proof/html_assertions.ex (new function)
def assert_page_contract!(html) do
  assert_no_duplicate_ids(html)
  assert_describedby_targets_exist(html)
  assert_label_targets_exist(html)
  assert_links_have_hrefs(html)
  assert_no_token_like_text(html)
  assert length(LazyHTML.query(document(html), "h1") |> Enum.to_list()) == 1
  html
end
```
Executor must confirm the exact `LazyHTML` API used in this file before relying on the h1 line.

### Pattern: computed contrast test
```elixir
# CssAssertions: parse "--ls-*: #rrggbb;" declarations from the :root block and the @dark_vars block,
# resolve var(--ls-color-*) aliases, then assert ratio >= 4.5 for text pairs and >= 3.0 for the focus ring.
# WCAG: L = 0.2126*R + 0.7152*G + 0.0722*B (linearized sRGB); ratio = (L1+0.05)/(L2+0.05).
```
Pairs to pin: body/muted/accent/status text on panel, page and muted surfaces in both themes (table above). The dark block is built from `@dark_vars` interpolated into two selectors, so assert against the compiled `Lockspire.Web.Admin.CSS.get()` output as `css_contract_test.exs` already does.

### Anti-Patterns to Avoid
- **Pinning planning docs or counts in tests** (removed in f0b0bd63; `inventory_contract_test.exs` forbids `phase_numbered_api`, `archived_milestone`, `quantity_threshold`). Validate the 154 evidence doc once with a command, not a recurring test.
- **Taking final captures before the last source edit.** Any CSS fix found in W2 invalidates earlier captures.
- **Submitting a form to "prove" a state.** Use LiveView tests for state transitions.
- **Per-page patches for shared problems** (153 sweep rule): fix in `admin_css.ex` / `admin_components.ex`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Evidence table validation | New parser | `BrowserEvidence.parse!/1` (extend allowed viewports) | Already enforces overflow, redaction, uniqueness |
| Redaction scanning | New regex set | `BrowserEvidence.assert_redaction_safe!/1`, `RedactionAssertions.assert_rendered_safe!/1` | Single denylist, already tested |
| Label/ARIA checks | Ad hoc selectors | `HtmlAssertions.*` | Already implemented and used |
| Route list | Hard-coded 30 | `RouteScorecards.expected_routes/0` | Tracks the router |
| Browser automation | Playwright/Wallaby | `agent-browser` (local) | SAFE-01 forbids deps |
| Contrast math | A library | ~20 lines of Elixir | Formula is fixed |

## Common Pitfalls

### Pitfall 1: Input border contrast (WCAG 1.4.11)
**What goes wrong:** `.lockspire-admin-field input/select/textarea` use `border: 1px solid var(--ls-border-strong)` (`admin_css.ex:1231-1246`), computed at 1.48:1 (light, `#cbd5e1` on `#ffffff`) and 1.64:1 (dark, `#334155` on `#131c2e`).
**Why it matters:** W3C says a control's boundary needs 3:1 when the border is what identifies it, and a text input generally relies on it `[CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html]`. Whether a given page needs a fix is an interpretation call; the planner should treat it as a likely UI-07 defect and decide with the user-visible evidence (A3).
**How to avoid:** introduce one shared token (e.g. a control-border alias at >=3:1 in both themes) and use it for field controls and the multi-value container; keep decorative card borders on `--ls-border-subtle/strong`. Add the contrast test for it. Re-capture affected pages.
**Warning signs:** screenshots where empty inputs nearly vanish on the panel.

### Pitfall 2: Compile warnings break the CI qa gate
**What goes wrong:** `mix compile --force --warnings-as-errors` exits 1 locally `[VERIFIED: ran]`. Admin-web warnings: `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:220` (clauses of `filter_device_authorizations/2` not grouped; on `main` they are grouped at lines 191/200, so this arrived on this unmerged branch, 43 commits ahead of main `[VERIFIED: git rev-list]`) and `lib/lockspire/web/live/admin/keys_live/index.ex:269` (`key_next_action_summary(%{next_actions: []})` clause never used). Others are outside the admin UI: `redaction.ex:269-270`, `authorization_request.ex:688,727`, `client_auth.ex:187`, `admin/clients.ex:671`; these come from Elixir 1.20.4's stricter type checker, while CI pins Elixir 1.19.5 (`ci.yml:18`), so they may not reproduce in CI (A4, unverified).
**How to avoid:** fix the two admin-web warnings as a behavior-preserving W1 task (group the clauses; remove or justify the dead clause with its test). Do **not** edit protocol/redaction/client_auth code in this phase (SAFE-01); report them. Run `mix compile --warnings-as-errors` under 1.19.5 if available, else note as unverified.

### Pitfall 3: Stale demo or stale baseline
Captures from a container that was not restarted show old code. Always restart, smoke, then record HEAD + file hashes. The baseline predates #123/#124/#128, so a side-by-side will legitimately differ in nav, tabs, wording, and caret inset; that is the 153 improvement, not a regression (`153-ROUTE-REVIEW.md` notes).

### Pitfall 4: Treating intentional scroll containers as failures
Secondary nav (`overflow-x: auto`, `admin_css.ex:203`) and tables scroll horizontally by design; the 1.4.10 exception covers data tables, but surrounding content must still reflow `[CITED: reflow.html]`. The DOM sweep must flag only *document-level* overflow (`documentElement.scrollWidth > clientWidth`, same rule `BrowserEvidence` enforces for `pass`) and *unintended* clipping, with allow-listed selectors.

### Pitfall 5: Full-page images too tall or tiny
Baseline pages reach 6142 physical px (DCR policy). At 320-390 px widths pages can be many screens tall. Use section slices; record each slice with its heading in the manifest so every section is present exactly once.

### Pitfall 6: Theme state leakage between runs
Theme persists in `localStorage["lockspire-admin-theme"]` (`admin_layout_live.ex:79`). Use a fresh `--session` per theme, set storage before navigation, and restore `System` at the end (153 sweep did this). `system` means *no* `data-theme` attribute plus `set media dark|light`.

### Pitfall 7: Vocabulary contract
Any copy touched while fixing responsive issues must follow `PRODUCT.md`; add retired phrases to its table (`vocabulary_contract_test.exs` enforces). Prefer CSS-only fixes.

## SAFE-01 Regression Gate

### Minimal automated gate (run and verified green this session)
```bash
export HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1
mix test test/lockspire/web/live/admin test/lockspire/web/admin_router_test.exs \
  test/lockspire/redaction test/lockspire/protocol/refresh_exchange_test.exs \
  test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/authorization_request_test.exs \
  test/lockspire/clients_test.exs test/lockspire/admin test/lockspire/architecture_fitness_test.exs \
  test/lockspire/adoption_demo_docker_contract_test.exs test/lockspire/web/revocation_controller_test.exs \
  test/lockspire/web/token_controller_test.exs test/lockspire/ci_workflow_evidence_contract_test.exs
# Result: 515 passed, finished in ~6 s [VERIFIED: ran]
```
Then the full fast suite `mix test.fast` (alias in `mix.exs:93`: `test.setup` + `test test/lockspire test/mix test/integration`), `mix format --check-formatted`, `git diff --check`, and `node --test test/browser/admin_multi_value_test.mjs` (the one Node check already in CI, `ci.yml:160-161`).

### What each invariant is asserted by
| Invariant | Existing assertion |
|-----------|--------------------|
| PKCE S256 default / `code_challenge_method` | `test/lockspire/protocol/authorization_request_test.exs` (`:S256` at line 78; `"S256"` at 730, 1063, 1106) |
| Client secrets hashed at rest | `test/lockspire/clients_test.exs`, `test/lockspire/admin/clients_test.exs` (both match "hash") |
| Refresh rotation / family revoke on reuse | `test/lockspire/protocol/refresh_exchange_test.exs`, `revocation_test.exs`, `tokens_live_test.exs` family tests (lines 288, 428, 624) |
| Distinct revocation scopes | `tokens_live_test.exs:428` ("kind-specific single-record confirmations and revokes only the selected record"), `consents_live_test.exs` |
| Copy-once handling | `RouteAssertions.assert_redaction_boundary!` (`copy_once_secret_panel`), `iat_live_test.exs` (`.lockspire-admin-copy-once-secret` presence/absence), `clients_live/show_test.exs`, `keys_live_test.exs` |
| Queues read-only | `RouteAssertions.assert_read_only_operate_surfaces!` (no `def handle_event`, no `phx-click|submit`, no `<table`, no Retry/Discard/Approve/Deny/Logout now) for `/interactions`, `/device_authorizations`, `/logouts` |
| No raw storage fields rendered | `RedactionAssertions.assert_source_boundaries!` (`device_code_hash`, `user_code_hash`, `client_secret_hash`, `authorization_code`, `refresh_token`, `access_token`, `private_key`, `verifier_material` absent from queue sources) |
| Host ownership | `RouteAssertions.assert_operator_boundary!` against `docs/operator-admin.md` |
| Public package ceiling | `assert_public_package_ceiling!` (no `component_lab`, `browser_proof`, `storybook`, `design_system`, `theme_lab` in router/supported-surface/mix) |

### Diff-based "unchanged" proofs (cheap, add to `154-SAFE-GATE.md`)
- `git diff --exit-code 701efa17 -- mix.exs mix.lock` (no dependency change during this phase; `701efa17` is HEAD at research time). For context, `v1.41..HEAD` already shows `bandit` removed from `mix.exs` and a `decimal` bump, which predate Phase 154 and are not this phase's.
- `git diff --stat 701efa17..HEAD -- lib/lockspire/protocol lib/lockspire/storage lib/lockspire/security lib/lockspire/domain` is empty at phase end. Context: outside admin UI, `v1.41..HEAD` touched only `lib/lockspire/admin/tokens.ex` (-1 line, an unreachable `{:error, reason}` clause) and one remediation string in `lib/lockspire/protocol/message_signing_profile.ex` ("issuer" -> "Lockspire"); both are from earlier phases/PRs, not 154.
- `rg -n "BEGIN [A-Z ]*PRIVATE KEY"` over the final capture text dumps and evidence docs returns nothing.

### CI posture (answers "what is reliable enough")
| Check | CI-eligible | Reason |
|-------|-------------|--------|
| Computed contrast ExUnit test | Yes (inside `test.fast`) | Deterministic, no browser, recurring value |
| Extended CSS contract (reflow breakpoints, focus, reduced motion, input border token) | Yes | Same |
| `assert_page_contract!` inside route tests | Yes | Same |
| `BrowserEvidence` viewport list extension + unit test | Yes | Same |
| `node --test` for pure helpers of the capture script | Yes, if it adds recurring value, via the existing Release Hygiene step pattern | Single-command step convention |
| `agent-browser` captures, zoom/theme/keyboard sweeps | **No** | Needs running demo, global CLI, flaky timing; one-off evidence |
| Screenshot pixel diff | **No** | Fonts/timestamps vary; no baseline in CI |

## Code Examples

### Capture one path at one width/theme (shape only; verify flags with `agent-browser <cmd> --help`)
```bash
S=l154-1; B=http://lockspire-ui-review.localhost/lockspire
agent-browser --session $S set viewport 640 900
agent-browser --session $S set media light            # also: dark ; add reduced-motion as a separate call
agent-browser --session $S open "$B/admin/clients"    # sign in as ops first if redirected to /login
agent-browser --session $S eval 'localStorage.setItem("lockspire-admin-theme","light"); location.reload()'
agent-browser --session $S eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1:document.querySelectorAll("h1").length})'
agent-browser --session $S screenshot --full tmp/admin-ui-polish/v1.42/final/zoom200/clients.png
```
Source for flags: `agent-browser set --help` and `screenshot --help` run this session. Theme storage key quoted from `admin_layout_live.ex:79`: `const storageKey = "lockspire-admin-theme";`.

### Evidence row (columns required by `BrowserEvidence`)
```
| Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
```
Journeys must be one of `Orient|Configure|Support|Operate|Internal lab` and routes must start `/admin` (`browser_evidence.ex`).

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| Native browser zoom screenshots (Phase 147) | Viewport-width emulation at 640/320 CSS px | Reproducible, exportable images |
| Manual contrast measurement in UI reviews (`152-UI-REVIEW.md` W-8) | Computed ExUnit assertion | Prevents silent token regressions |
| Per-suite ARIA/label checks | Bundled page contract in every route test | Whole-admin coverage without new fixtures |

## Open carry-overs from 151-153 touching this phase
- Light muted token `#5f6f84` (W-8 fix) is in place (`admin_css.ex:99`, comment "Slightly darker than gray-500 so muted text keeps 4.5:1 on --ls-surface-muted") and verified 4.68:1 on muted. Pin it with the new contrast test.
- 152 UI review's W-10 (700 weight on summary values) and W-11 (12px padding off scale) are cosmetic spec deviations; check `152-UI-REVIEW.md` status before treating as UI-07 scope. They are not responsive/theme issues (not re-verified here).
- Source detector note: the shared decision-summary 3px side border was reduced to 1px in the autonomous sweep; the older gallery `overused-font=inter` finding is an intentional ignore in `.impeccable/config.json`.
- `153-REVIEW-DISPOSITION.md` WR-03 deferred: `adoption_smoke.py` asserts against synthetic seed data; do not change the seed in this phase or the smoke may need updating.
- Demo router shadowing of `/clients/new` was fixed in 153 and is covered by the adoption demo router contract test; final capture of `/admin/clients/new` must show the "New app" form, not "Client not found".
- Non-admin 1.20 compiler warnings (Pitfall 2) are observations only.

## Runtime State Inventory

Not a rename/refactor/migration phase. Omitted.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Viewport-width emulation reproduces browser zoom layout for CSS-px-driven rules (media queries, wrapping). Text-only zoom and OS font scaling are not reproduced. | Capture Plan | A zoom-only bug (e.g. fixed `px` heights) could slip; mitigate with one native 200% spot check on 3 pages |
| A2 | Baseline CSS width was 1261 px at DPR 2 (2522 physical). Inferred from the recorded 2522 px width and the 153 notes mentioning 1261 px. | Evidence Inventory | Final set at a different scale makes visual comparison harder, not invalid |
| A3 | Text-input border contrast below 3:1 counts as a 1.4.11 failure for these controls (no other identifier such as a fill). | Pitfall 1 | If the team judges fill/labels sufficient, skip the token change; low cost either way |
| A4 | The five non-admin compile warnings are Elixir 1.20-only and absent under CI's 1.19.5. Not run under 1.19.5. | Pitfall 2 | If they reproduce in CI, `mix qa` fails and needs separate non-UI fixes outside SAFE-01 scope |
| A5 | `lockspire-ui-review` is reachable on `.localhost` host from the browser used for capture (curl worked; browser not tried in this session). | Capture Plan | Fall back to `scripts/demo/admin-ui --project lockspire-ui-review up` and its printed URL |

## Open Questions

1. **Should the input-border change (Pitfall 1) ship in this phase?**
   - Known: ratios computed; W3C wording quoted.
   - Unclear: whether the user regards it as in scope (it changes the visual look of every form).
   - Recommendation: include it as a single shared-token change gated by the computed test; it is the one concrete UI-07 contrast defect found. Flag in the plan for quick user confirmation only if the visual change is judged large after the first capture.
2. **Native 200% zoom spot check.** Worth 3 pages if the browser can export screenshots; otherwise record as "not observed" and rely on emulation.
3. **How many mobile/theme screenshots versus DOM-only rows?** Recommendation above; adjust to time, but all 30 final desktop images are mandatory.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Erlang (asdf) | ExUnit gate | yes | 1.20.4-otp-29 (CI uses 1.19.5) | — |
| `mix test` env | tests | yes (`HEX_HOME=/private/tmp/lockspire-hex`) | — | — |
| `agent-browser` | captures | yes | 0.27.0 | `/opt/homebrew/bin/chromium` headless (limited) |
| Node | `node --test`, capture script | yes | v22.14.0 | — |
| Docker + `lockspire-ui-review` | demo | yes, container up | — | `scripts/demo/admin-ui --project lockspire-ui-review up` |
| Playwright | — | no | — | Not needed; forbidden |
| actionlint | workflow lint if CI edited | not checked | — | skip if `ci.yml` untouched |

Missing with no fallback: none.

## Validation Architecture

(`workflow.nyquist_validation` is `true` in `.planning/config.json`.)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest + LazyHTML (`AdminProof` helpers); Node `node --test` for pure JS |
| Config file | `mix.exs` (aliases at lines 90-160; `elixirc_paths(:test)` includes `test/support`) |
| Env prefix | `HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1` |
| Quick run command | `mix test test/lockspire/web/live/admin/design_system` (26 tests, <1 s `[VERIFIED]`) |
| Full suite command | `mix test.fast` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-07 | Text/status/accent contrast >= 4.5:1 and focus ring >= 3:1 in light and dark | unit (CSS) | `mix test test/lockspire/web/live/admin/design_system/css_contract_test.exs` | extend (test exists; add contrast cases) |
| UI-07 | Form control boundary token >= 3:1 (if Pitfall 1 adopted) | unit (CSS) | same | Wave 0/1 add |
| UI-07 | Nav collapse, mobile table-to-list, long-value wrap, secondary-nav scroll, 320 px safety | unit (CSS) | same | exists (extend) |
| UI-07 | Focus-visible rule present; reduced-motion block; no `transition: all` | unit (CSS) | same | exists |
| UI-07 | Light/dark/system selector, saved preference, storage-failure messaging | unit | `mix test test/lockspire/web/live/admin/design_system/theme_sync_test.exs` | exists |
| UI-07 | Every route renders exactly one H1, labeled controls, resolvable describedby, unique ids | LiveView | `mix test test/lockspire/web/live/admin` | add `assert_page_contract!` calls (Wave 1) |
| UI-07 | No document-level horizontal overflow, no clipped actions at 320/390/640/768/1119/1120/1280 in 3 themes | browser sweep (one-off) | `node test/browser/admin_route_proof.mjs` (local) | Wave 0 create |
| UI-07 | Keyboard/focus path and reduced motion on each page type | browser sweep (one-off) | same script | Wave 0 create |
| PROOF-01 | 30 current paths == router + workflow exception | contract | `mix test test/lockspire/web/live/admin/design_system/route_contract_test.exs` | exists |
| PROOF-01 | Evidence table well-formed, redaction-safe, viewports/themes/motion valid | unit + one-off parse | `mix test test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs`; then `MIX_ENV=test mix run --no-start -e 'IO.inspect(length(Lockspire.Web.AdminProof.BrowserEvidence.parse!(File.read!(".planning/phases/154-responsive-theme-route-proof/154-BROWSER-EVIDENCE.md"))))'` | parser exists; extend viewport list; evidence doc Wave 3 |
| PROOF-01 | 30 baseline + 30 final images exist, final IDs 154-FINAL-01..30 unique, manifest paths readable | one-off script | `ls tmp/admin-ui-polish/v1.42/before/*.png \| wc -l` (30) and `ls tmp/admin-ui-polish/v1.42/final/desktop/*.png \| wc -l` (30) plus manifest cross-check in the capture script | Wave 3 |
| PROOF-01 | Captures free of sensitive values | one-off | in-script `assert_redaction_safe` over page text + manual image review recorded per row | Wave 3 |
| SAFE-01 | Protocol/security/redaction/copy-once/revocation/read-only/host-boundary unchanged | ExUnit | the 515-test command in "SAFE-01 Regression Gate" | exists (green) |
| SAFE-01 | Full regression | ExUnit | `mix test.fast` | exists |
| SAFE-01 | No dependency or protocol-source change | git | `git diff --exit-code 701efa17 -- mix.exs mix.lock` and the empty-stat protocol diff | Wave 3 |
| SAFE-01 | Lint/compile hygiene | static | `mix format --check-formatted && mix compile --force --warnings-as-errors` | currently failing (Pitfall 2), fix in Wave 1 |
| SAFE-01 | Existing CI Node check still passes | node | `node --test test/browser/admin_multi_value_test.mjs` | exists |

### Sampling Rate
- **Per task commit:** `mix test test/lockspire/web/live/admin/design_system <touched route test>` (seconds).
- **Per wave merge:** the 515-test SAFE-01 command plus `mix format --check-formatted`.
- **Phase gate:** `mix test.fast` green, `mix compile --warnings-as-errors` clean for admin-web files, evidence doc parses, 30/30 final images and manifest complete, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/browser/admin_route_proof.mjs` - local capture/sweep script (UI-07, PROOF-01)
- [ ] Extend `@allowed_viewports` in `test/support/lockspire/web/admin_proof/browser_evidence.ex` (add 640, 720, 1119, 1120, 1280/1512 as chosen) and its unit test
- [ ] Contrast helper + token-pair assertions in `CssAssertions` / `css_contract_test.exs`
- [ ] `HtmlAssertions.assert_page_contract!/1` and wiring into route tests
- [ ] Framework install: none

## Security Domain

`security_enforcement` is not set to false in `.planning/config.json` (absent = enabled).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (host owns login; capture signs in as synthetic `ops`) | Host-owned |
| V3 Session Management | no change | Host-owned; capture session is disposable |
| V4 Access Control | no change | Existing admin guard (`adoption_demo_operator_guard_test.exs`) |
| V5 Input Validation | no change (read-only navigation; no forms submitted) | Existing LiveView validation |
| V6 Cryptography | no change; private key material must not appear in evidence | No code changes under `lib/lockspire/security|protocol` |
| V7/V8 Logging & data protection | yes (evidence artifacts) | Redaction scan + manual image review; `tmp/` ignored by git |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Screenshot leaks secret/token/code/key | Information Disclosure | Navigate-only; denylist scan of page text before save; per-image review; only confirmation-state pages; no copy-once capture |
| Capture session mutates demo state | Tampering | No form submit, no confirm-button clicks; smoke run is the only write path |
| Evidence doc committed with real hostnames | Information Disclosure | `BrowserEvidence` production-hostname pattern; `*.localhost` only |
| New dependency or script introduces supply-chain risk | Tampering | Zero new packages; script uses only Node stdlib and installed CLI |
| CSS change regresses focus/contrast silently | Repudiation (of accessibility) | Computed contrast + focus CSS contracts in `test.fast` |

## Sources

### Primary (HIGH confidence, read or run this session)
- Repo files: `.planning/REQUIREMENTS.md`, `ROADMAP.md` (Phase 154 section), `STATE.md`, `PRODUCT.md`, `AGENTS.md`; Phase 153: `153-BASELINE-SCREENSHOTS.md`, `153-00-PLAN.md`, `153-00-SUMMARY.md`, `153-ROUTE-REVIEW.md`, `153-AUTOMATED-UX-SWEEP.md`, `153-UI-REVIEW-SNAPSHOT.md`, `153-VERIFICATION.md`, `153-VALIDATION.md`, `153-CONTEXT.md`, `153-UI-SPEC.md` (open-checks paragraph); `152-UI-REVIEW.md` (W-8 etc.).
- Code: `lib/lockspire/web/admin_css.ex` (tokens, focus, reduced-motion, media queries, field rules), `admin_layout_live.ex` (theme storage), `test/lockspire/web/live/admin/design_system/*.exs`, `test/support/lockspire/web/admin_proof/*.ex`, `mix.exs` aliases, `.github/workflows/ci.yml`, `scripts/demo/admin-ui`, `scripts/demo/adoption_smoke.py`, `test/browser/*.mjs`.
- Commands run: `mix test` (design_system: 26 passed; SAFE-01 set: 515 passed), `mix compile --force --warnings-as-errors` (exit 1), `agent-browser --version/--help`, `curl`, `docker ps/inspect`, `git diff/log/rev-list`, node contrast computation.

### Secondary (MEDIUM confidence)
- W3C WCAG 2.2 Understanding 1.4.10 Reflow: https://www.w3.org/WAI/WCAG22/Understanding/reflow.html (320 CSS px = 1280 px at 400%; data-table exception)
- W3C WCAG 2.2 Understanding 1.4.11 Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html (3:1 for boundaries that identify a control; focus indicator 3:1)

### Tertiary (LOW)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack / tooling: HIGH - versions and flags run this session.
- Architecture / evidence inventory: HIGH - read directly; "predates" claims derive from the 153 manifests and git dates.
- Pitfalls: MEDIUM-HIGH - contrast and compile results computed/run; WCAG interpretation (A3) and CI-vs-local compiler difference (A4) unverified.

**Research date:** 2026-10-15
**Valid until:** 2026-11-14 (stable; invalidated by any change to `admin_css.ex` tokens or the demo container).
