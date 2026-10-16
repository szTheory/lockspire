# Phase 154: Responsive, Theme & Route Proof - Pattern Map

**Mapped:** 2026-10-15
**Files analyzed:** 12 new/modified
**Analogs found:** 12 / 12 (all tracked; verified via `git ls-files`)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `test/support/lockspire/web/admin_proof/css_assertions.ex` (add contrast helper, token-pair + 320px/input-border asserts) | test helper | transform (parse CSS) | itself: `assert_theme_focus_and_motion!`, private `rule/2`, `media_rule/2` (lines 74-88, 90-112, 155-165) | exact |
| `test/lockspire/web/live/admin/design_system/css_contract_test.exs` (add contrast cases) | test | request-response | itself (lines 1-38) | exact |
| `test/support/lockspire/web/admin_proof/html_assertions.ex` (add `assert_page_contract!/1`) | test helper | transform | itself: `assert_no_duplicate_ids` etc. (lines 21-107, 145, 184) | exact |
| Existing route render tests (call `assert_page_contract!`), e.g. `test/lockspire/web/live/admin/iat_live_test.exs` | test | request-response | `iat_live_test.exs` lines 56-60 | exact |
| `test/support/lockspire/web/admin_proof/browser_evidence.ex` (extend `@allowed_viewports`) | test helper | transform | itself, line 24 | exact |
| `test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs` (viewport fixture rows) | test | transform | itself: `valid_evidence/0`, lines 129-141 | exact |
| `lib/lockspire/web/admin_css.ex` (control-border token, any W2 fixes) | config/style | n/a | itself: tokens ~28-125, field rule ~1231-1246, dark vars ~2985-3000 | exact |
| `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` (group `filter_device_authorizations/2` clauses) | LiveView | request-response | `main` grouped version lines ~191/200 (same file) | exact |
| `lib/lockspire/web/live/admin/keys_live/index.ex` (dead `next_actions: []` clause, ~269) | LiveView | request-response | same file `key_next_action_summary` lines 262-270 | exact |
| `test/browser/admin_route_proof.mjs` (new local capture/sweep script) | script | request-response / file-I/O | `test/browser/admin_theme_storage_failure_test.mjs` | role-match |
| `test/browser/admin_route_proof_test.mjs` (optional pure-helper unit test) | test | transform | `test/browser/admin_multi_value_test.mjs` | exact |
| `154-BROWSER-EVIDENCE.md`, `154-FINAL-CAPTURES.md`, `154-SAFE-GATE.md` | docs | n/a | table shape: `valid_evidence/0` in `proof_artifact_contract_test.exs`; manifest: 153 `153-BASELINE-SCREENSHOTS.md` | role-match |

## Pattern Assignments

### `css_assertions.ex` contrast helper (test helper, transform)

**Analog:** same file. Use private helpers that read the compiled CSS and slice a rule. Add contrast alongside them, without a phase-numbered name (the inventory contract forbids that).

**Imports / structure** (lines 1-6):
```elixir
defmodule Lockspire.Web.AdminProof.CssAssertions do
  @moduledoc false
  import ExUnit.Assertions
  alias Lockspire.Web.AdminProof.Paths
```

**Existing theme/focus assert to extend** (lines 74-88):
```elixir
def assert_theme_focus_and_motion! do
  css = css()
  for selector <- [":root[data-theme=\"light\"]", ":root[data-theme=\"dark\"]"] do
    assert css =~ selector
  end
  assert css =~ "@media (prefers-color-scheme: dark)"
  assert css =~ ":focus-visible"
  assert css =~ "outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);"
  refute css =~ ~r/transition(?:-property)?\s*:\s*all\b/
  assert css =~ "@media (prefers-reduced-motion: reduce)"
  ...
```

**Responsive assert to extend (add 320/input-border checks)** (lines 90-112):
```elixir
collapsed_nav = media_rule(css, "@media (max-width: 1119px)")
assert rule(collapsed_nav, ".lockspire-admin-nav-toggle") =~ "display: flex"
assert rule(collapsed_nav, ".lockspire-admin-nav-item") =~ "min-height: 2.75rem"
```

**Private helpers to reuse** (lines 155-165):
```elixir
defp css, do: File.read!(Paths.admin_css())
defp media_rule(css, media_query) do
  [_, body] = Regex.run(~r/#{Regex.escape(media_query)}\s*\{(.*)\z/s, css)
  body
end
defp rule(css, selector) do
  [_, body] = Regex.run(~r/#{Regex.escape(selector)}\s*\{([^}]*)\}/s, css)
  body
end
```
Note: `css()` reads the source file (`Paths.admin_css()`). RESEARCH suggests `Lockspire.Web.Admin.CSS.get()` (the compiled output used at css_contract_test.exs line ~27) for dark vars because `@dark_vars` is interpolated; use that for the token parser. Contrast math (about 20 lines): linearize sRGB, `L = 0.2126R + 0.7152G + 0.0722B`, `(L1+0.05)/(L2+0.05)`. Pair values and expectations are in RESEARCH "Contrast, computed this session".

**css_contract_test.exs shape** (one test per contract, delegating to helper):
```elixir
test "responsive layouts preserve long-value safety" do
  CssAssertions.assert_responsive_layout!()
end
```

---

### `html_assertions.ex` `assert_page_contract!/1` (test helper, transform)

**Analog:** same file. Compose the existing asserts; each returns `html` for piping.

**Document/query idiom** (lines 21-33):
```elixir
def document(html) when is_binary(html), do: LazyHTML.from_fragment(html)
def document(%LazyHTML{} = html), do: html

def assert_no_duplicate_ids(html) do
  ids = html |> document() |> LazyHTML.query("[id]") |> LazyHTML.attribute("id") |> Enum.reject(&(&1 == ""))
```
**Gotcha:** `assert_label_targets_exist/1` (line 74-107) fails with "expected rendered HTML to include explicit label[for] targets" when a page has no `label[for]`. Many read-only routes (queues, detail pages) have none, so `assert_page_contract!` must not call it unconditionally (guard with a selector check, or accept an `opts` flag). Also `assert_links_have_hrefs` (145) and `assert_no_token_like_text` (184) exist. For the H1 count, use `LazyHTML.query(document(html), "h1") |> Enum.count()` (confirm `Enum` works on `LazyHTML` results; `LazyHTML.attribute/2` already returns lists).

**Calling pattern in route tests** (`test/lockspire/web/live/admin/iat_live_test.exs` lines 56-60):
```elixir
HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_no_generic_cta_text(html)
HtmlAssertions.assert_has_link(html, "/admin/iats")
```
Replace/augment with `HtmlAssertions.assert_page_contract!(html)` in each route's existing "renders" test; do not build a central 30-route fixture sweep.

---

### `browser_evidence.ex` viewport list (test helper)

**Analog:** same file line 24:
```elixir
@allowed_viewports ["320px", "390px", "768px", "799px", "800px", "801px", "1024px", "1440px"]
```
Add `"640px"`, `"720px"`, `"1119px"`, `"1120px"`, `"1280px"`, and the chosen desktop width (`"1261px"`/`"1512px"`). Update the fixture in `proof_artifact_contract_test.exs`.

**Fixture row pattern** (`proof_artifact_contract_test.exs` lines 129-141): table header with 14 required columns, rows with backticked route, journey from `Orient|Configure|Support|Operate|Internal lab`, `scrollWidth`/`clientWidth` equal on `pass`:
```
| `/admin/clients` | Configure | 800px | light | default | shell nav | synthetic client list | 800 | 800 | pass | boundary viewport fixture | passed denylist | none | parser boundary contract pass |
```
Rows must be unique (duplicate check); vary State/Theme/Motion. The final `length(...) == 6` assertion (line ~121) must be bumped when rows are added.
Evidence doc validation (one-off, not a recurring test), from RESEARCH: `MIX_ENV=test mix run --no-start -e 'IO.inspect(length(Lockspire.Web.AdminProof.BrowserEvidence.parse!(File.read!(".planning/phases/154-responsive-theme-route-proof/154-BROWSER-EVIDENCE.md"))))'`.

---

### `admin_css.ex` shared control-border token (style)

**Analog:** same file. Field rule at ~1231-1246 uses `border: 1px solid var(--ls-border-strong)`; tokens in the `:root` block (~28-125) with dark remap via `@dark_vars` interpolated into `:root[data-theme="dark"]` and `@media (prefers-color-scheme: dark)` (~2985-3000). Add one alias (for example `--ls-border-control`, at >=3:1 on panel in both themes) next to `--ls-border-strong`, add it to `@dark_vars`, use it in `.lockspire-admin-field input/select/textarea` and the multi-value container, and pin with the contrast test. Planner: read these exact line ranges before editing (not excerpted here). Per 153 sweep rule, fix shared CSS, never per-page patches. Preserve existing `--ls-focus-ring-*` tokens (`admin_css.ex:129-130`).

---

### Compile-warning fixes (LiveView, behavior-preserving)

**`device_authorizations_live/index.ex` ~line 215-220**: `filter_device_authorizations/2` clause is separated from its siblings by other defs; move the `:all` clause (line 219) next to the other `filter_device_authorizations` clauses (on `main` they are grouped at ~191/200). Current stray clause:
```elixir
defp filter_device_authorizations(authorizations, :all), do: authorizations
```
**`keys_live/index.ex` lines 262-269**: `key_next_action_summary(%{next_actions: []})` is reported never used:
```elixir
defp key_next_action_summary(%{next_actions: [:activate]}), do: ...
defp key_next_action_summary(%{next_actions: [:retire]}), do: ...
defp key_next_action_summary(%{next_actions: []}), do: nil
```
Remove or justify the dead clause only after checking its caller and tests. Do not touch `redaction.ex`, `authorization_request.ex`, `client_auth.ex`, `admin/clients.ex` (SAFE-01).

---

### `test/browser/admin_route_proof.mjs` (script, request-response + file-I/O)

**Analog:** `test/browser/admin_theme_storage_failure_test.mjs`.

**Imports and constants** (lines 1-22):
```js
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdirSync } from "node:fs";
import { readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const route = new URL(process.env.LOCKSPIRE_THEME_FAILURE_URL || "http://127.0.0.1:4123/lockspire/admin/clients");
```
Use an env var such as `LOCKSPIRE_PROOF_BASE_URL` defaulting to `http://lockspire-ui-review.localhost/lockspire`. Write images under `tmp/admin-ui-polish/v1.42/final/` (git-ignored).

**CLI wrappers** (lines 24-41):
```js
function browser(session, ...args) {
  return execFileSync("agent-browser", ["--session", session, ...args], {
    cwd: repoRoot, encoding: "utf8", timeout: 60_000, maxBuffer: 2 * 1024 * 1024
  }).trim();
}
function browserJson(session, script) {
  const raw = browser(session, "eval", script);
  const first = JSON.parse(raw);
  return typeof first === "string" ? JSON.parse(first) : first;
}
function fingerprint(value) {
  const bytes = Buffer.from(value, "utf8");
  return { bytes: bytes.length, sha256: createHash("sha256").update(bytes).digest("hex") };
}
```

**Synthetic ops sign-in** (lines 60-78):
```js
function ensureOpsSession(session) {
  browser(session, "open", route.href);
  let current = browser(session, "get", "url");
  if (new URL(current).pathname === "/login") {
    browser(session, "eval",
      'document.querySelector("#login").value = "ops"; document.querySelector("form").requestSubmit(); "submitted"');
    browser(session, "wait", "2000");
    current = browser(session, "get", "url");
  }
```
Note this precedent uses `test(...)` blocks from `node:test`; the new script is a maintainer-run CLI, so keep pure functions (matrix building, row formatting, redaction scan) exported and importable. Per RESEARCH, never click confirm controls or submit forms; run denylist regexes (mirror `browser_evidence.ex` `sensitive_patterns/0`) over `document.body.innerText` before saving each image. Do not add to `.github/workflows/ci.yml`. Theme key: `localStorage["lockspire-admin-theme"]`; `system` = no `data-theme` plus `set media`. Path list source of truth: `RouteScorecards.expected_routes/0`.

---

### `test/browser/admin_route_proof_test.mjs` (optional, pure helpers)

**Analog:** `test/browser/admin_multi_value_test.mjs` (CI runs the existing one with `node --test`). Import and test pure helpers; no browser:
```js
import assert from "node:assert/strict";
import test from "node:test";
test("pasted lists trim blanks and deduplicate ...", () => {
  assert.deepEqual(values(" openid, ,profile,openid\nEmail\r\nemail, "), [...]);
});
```
Only add if it gives recurring value; a CI step would follow the existing Release Hygiene single-command convention (`ci.yml` ~160-161).

---

### Evidence docs (`154-BROWSER-EVIDENCE.md`, `154-FINAL-CAPTURES.md`, `154-SAFE-GATE.md`)

- Browser evidence table: exact 14-column header from `proof_artifact_contract_test.exs` `valid_evidence/0` (lines 129-141); routes backticked and starting `/admin`; viewport strings `NNNpx`; themes `light|dark|system`; motion `default|reduced-motion`.
- Final captures manifest: follow `153-BASELINE-SCREENSHOTS.md` and `153-ROUTE-REVIEW.md` (IDs `154-FINAL-01..30`, one per route, image path, dimensions, sections, redaction check, source SHA from `git rev-parse HEAD`).
- Safe gate: command outputs from RESEARCH "SAFE-01 Regression Gate".

## Shared Patterns

### Helper-module conventions
**Source:** `test/lockspire/web/live/admin/design_system/inventory_contract_test.exs`
**Apply to:** every new `AdminProof` helper. Capability-named APIs only: no phase-numbered names, no archived-milestone paths, no count thresholds. Do not pin planning docs or counts in tests.

### Assert helpers return their input
**Source:** `html_assertions.ex` (each function ends with `html`)
**Apply to:** `assert_page_contract!/1` so it can be piped.

### Redaction scanning
**Source:** `BrowserEvidence.assert_redaction_safe!/1` and `RedactionAssertions.assert_rendered_safe!/1`
**Apply to:** capture script, evidence docs. Use one denylist; do not invent a new regex set.

### Admin copy / vocabulary
**Source:** `PRODUCT.md`, enforced by `test/lockspire/web/live/admin/vocabulary_contract_test.exs`
**Apply to:** any text touched while fixing responsive issues. Prefer CSS-only fixes.

### Test command env
```bash
export HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1
mix test test/lockspire/web/live/admin/design_system
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Contrast ratio math (WCAG luminance) | helper | transform | No contrast computation exists in the repo; write about 20 lines of Elixir using `rule/2` and token parsing from `Lockspire.Web.Admin.CSS.get()` |
| 154 manifest tables (`154-FINAL-CAPTURES.md`) | doc | n/a | Only 153 planning-doc precedents; not test-pinned by design |

## Metadata

**Analog search scope:** `test/support/lockspire/web/admin_proof/`, `test/lockspire/web/live/admin/design_system/`, `test/browser/`, `lib/lockspire/web/live/admin/{device_authorizations_live,keys_live}/index.ex`
**Tracked-source check:** `git ls-files` confirmed `test/browser/*.mjs` and all `admin_proof/*.ex` are tracked; no `.gsd` mirror paths used.
**Files scanned:** about 14
**Pattern extraction date:** 2026-10-15
