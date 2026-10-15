# Phase 154 Final Captures

Final rendered evidence for the 30 admin paths reserved as `154-FINAL-01..30` in
`.planning/phases/153-configure-support-page-refinement/153-ROUTE-REVIEW.md`.

## Method

- **Source SHA:** `768b3a61b6aab032705f511e07ad86e7c95cf9c3` (`git rev-parse HEAD` at capture time; working tree clean).
- **Source freeze:** the last source commit is `677c1430` (Plan 06 shared CSS fix). `git diff --stat 677c1430 HEAD -- lib test` is empty; only planning docs changed after it. Per-file sha256 of `lib/lockspire/web/admin_css.ex`, `lib/lockspire/web/components/admin_components.ex`, and every `lib/` file changed since `e67a4898` is in `tmp/admin-ui-polish/v1.42/final/source-sha256.json` (34 files).
- **Container restart:** `docker restart lockspire-ui-review-web-1` at 2026-10-15T23:06:41Z (container StartedAt `2026-10-15T23:06:41.406Z`), after the last source commit. `scripts/demo/admin-ui --project lockspire-ui-review smoke` passed. The container bind-mounts the repo; every capture confirmed the served stylesheet contains both Plan 06 fixes (`scroll-padding-block` and the wrapping secondary nav), so the demo serves current code.
- **Browser:** local `agent-browser` 0.27.0 (Chrome for Testing 149), navigate only. The only form submitted is the synthetic `ops` sign-in. Rotate pages are captured in their confirmation state; no confirm control is pressed. Not run in CI (D-05).
- **Browser launch flags:** `AGENT_BROWSER_ARGS=--disable-gpu-vsync,--disable-frame-rate-limit`. The console was locked during capture, which stalls the compositor's vsync clock (no `requestAnimationFrame`, `Page.captureScreenshot` times out). These flags only change frame pacing; they do not affect layout, color, or fonts.
- **Desktop viewport:** baselines measure 2522 px physical width (`sips`: `clients.png` 2522x2468, `policies.png` 2522x2280), which is 1261 CSS px at DPR 2. Final desktop captures use `set viewport 1261 900 2`; `clients-new.png` measures 2522x2378, matching the baseline width. Desktop captures use the system theme with a light color-scheme preference.
- **Mobile, reflow, zoom, theme captures (changed pages only):** DPR 1 so image width equals CSS width. 390x844 light, 320x800 dark, 640x900 light (200% zoom equivalent of 1280, D-02), and 1280x900 in light, dark, and system.
- **Sections:** full-page capture always; pages taller than 2700 CSS px also get one viewport slice per H2 group (`<name>--NN-<heading>.png`).

## Redaction rules

1. **First control (DOM attribute scan):** before saving each image, the capture reads visible text, every `input`/`textarea`/`select` value, and every `data-*` attribute value, and runs them through the harness `scanSensitive` denylist (mirror of `BrowserEvidence.sensitive_patterns/0`: cookies, auth codes, JWT-looking values, token parameters, plaintext credentials, private key headers, authorization headers, verifier material, device/user codes, copy-once secrets, production hostnames). A hit aborts the save.
2. **Second control (eye review):** every saved image is opened and reviewed by eye for keys, secrets, codes, tokens, cookies, emails beyond synthetic demo data, and production hostnames. "Pass" means nothing sensitive is visible; any crop or recapture is documented in Notes.

Images live under the git-ignored `tmp/admin-ui-polish/v1.42/final/`.

## Desktop captures

| Final ID | Path | Baseline image | Final image(s) | CSS size | Sections | Redaction review | Notes |
|---|---|---|---|---|---|---|---|
| 154-FINAL-12 | `/admin/clients/new` | `tmp/admin-ui-polish/v1.42/before/clients-new-routing-error.png` | `tmp/admin-ui-polish/v1.42/final/desktop/clients-new.png` | 1261x1189 | full page | Pass | Baseline showed "Client not found" (routing error, file named `clients-new-routing-error.png`); final shows the New app form and is saved as `clients-new.png`. The filename mapping is intentional, not a rename of the baseline. |

## Blocking finding (capture stopped, no source edited)

**F-03: provenance badge escapes its card on `/admin/clients` at 320 px.** Found during the second-control eye review of `tmp/admin-ui-polish/v1.42/final/reflow320/clients.png` (dark), then confirmed in the DOM in light and dark:

- Element: `span.lockspire-admin-badge.lockspire-admin-badge-provenance` ("Registered through API", Northstar Payables Portal row), `white-space: nowrap`.
- Geometry at 320x800: badge x=144 to 318; its `.lockspire-admin-status-cluster` ends at 280; the enclosing `.lockspire-admin-card` ends at 304. The badge crosses the card edge by 14 px and sits 2 px from the viewport edge.
- Cause: `lib/lockspire/web/admin_css.ex` sets `.lockspire-admin-client-inventory__results .lockspire-admin-status-cluster { display: grid; grid-template-columns: 6rem minmax(0, 1fr); }` (added in `d44b95dd`, PR #123). At 320 px the second column is about 136 px, narrower than the unwrappable badge.
- Why the harness passed it: there is no document overflow (`scrollWidth` 320 = `clientWidth` 320) and no `overflow: hidden` ancestor, so neither the overflow check nor the clipped check fires. It is visible overflow past a card boundary, not lost content.
- Scope: a read-only scan of all 30 paths for any element extending past its card found this single instance. It appears at 320 px (light and dark) and at no other width (390, 640, 768, 1119, 1120, 1280 light).

Per the plan, Plan 07 edits no source. The fix belongs under Plan 06 rules (shared CSS plus a `CssAssertions` guard). After the fix, the container must be restarted and every capture in this plan retaken. The manifest rows above stay valid for redaction review only.

### Capture state when stopped

- Desktop (1261x900 at DPR 2, system theme): 30 paths, 44 images including section slices. Every image eye-reviewed; no sensitive values (Pass). Record references (`token_…`, `iat_…`, `interaction_…`, `device_authorization_…`, `kid_…`) are public record identifiers, not credential values. Endpoint hosts are RFC 2606 `example.com` demo hosts.
- Changed pages: mobile390 12, reflow320 12, zoom200 12, themes 36 captured. The DOM denylist scan passed on all 72. Eye review covered mobile390 (12) and reflow320 up to `clients` before stopping.
- Full matrix run: stopped at 234 of 630 rows (log `tmp/admin-ui-polish/v1.42/final/matrix-full.log`). It must be rerun on the fixed source.
- Observations (not blocking, pre-existing in the 153 baseline): on `/admin/clients/:client_id` the "Secret and signing keys" card stretches to its row partner's height and leaves large internal gaps. Dates render as "15 oct. 2026" because of the headless browser locale.
