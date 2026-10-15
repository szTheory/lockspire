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
