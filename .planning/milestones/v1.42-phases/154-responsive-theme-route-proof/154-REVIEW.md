---
phase: 154-responsive-theme-route-proof
reviewed: 2026-10-15T00:00:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - lib/lockspire/web/admin_css.ex
  - lib/lockspire/web/components/admin_components.ex
  - lib/lockspire/web/live/admin/device_authorizations_live/index.ex
  - lib/lockspire/web/live/admin/keys_live/index.ex
  - test/browser/admin_route_proof.mjs
  - test/browser/admin_route_proof_test.mjs
  - test/support/lockspire/web/admin_proof/browser_evidence.ex
  - test/support/lockspire/web/admin_proof/css_assertions.ex
  - test/support/lockspire/web/admin_proof/html_assertions.ex
  - test/lockspire/web/live/admin/design_system/css_contract_test.exs
  - test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs
  - test/lockspire/web/live/admin/clients_live/show_test.exs
  - test/lockspire/web/live/admin/clients_live_test.exs
  - test/lockspire/web/live/admin/consents_live_test.exs
  - test/lockspire/web/live/admin/dcr_live_test.exs
  - test/lockspire/web/live/admin/device_authorizations_live_test.exs
  - test/lockspire/web/live/admin/iat_live_test.exs
  - test/lockspire/web/live/admin/interactions_live_test.exs
  - test/lockspire/web/live/admin/keys_live_test.exs
  - test/lockspire/web/live/admin/logout_deliveries_live_test.exs
  - test/lockspire/web/live/admin/overview_live_test.exs
  - test/lockspire/web/live/admin/policies_live/dcr_test.exs
  - test/lockspire/web/live/admin/policies_live/dpop_test.exs
  - test/lockspire/web/live/admin/policies_live/index_test.exs
  - test/lockspire/web/live/admin/policies_live/par_test.exs
  - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
  - test/lockspire/web/live/admin/tokens_live_test.exs
findings:
  critical: 1
  warning: 6
  info: 7
  total: 14
status: issues_found
---

# Phase 154: Code Review Report

**Reviewed:** 2026-10-15T00:00:00Z
**Depth:** standard
**Files Reviewed:** 27 (the 11 named files, plus a skim of the 16 LiveView test files that gained `assert_page_contract!` calls)
**Status:** issues_found

## Summary

Scope: `git diff ef6043ec HEAD` for the listed files. Protocol, storage, security and domain code are unchanged. The two `lib/` LiveView edits are behavior-neutral:
- `device_authorizations_live/index.ex`: only regroups a function clause.
- `keys_live/index.ex`: removes a `next_actions: []` clause that `:if={entry.next_actions != []}` already makes unreachable.

The `radio_option_described_by/3` fix in `admin_components.ex` is correct. It now omits `aria-describedby` when there are no ids, where it used to render `aria-describedby=""`. Its `:if` handling of help text matches the `<small>` element it points to.

Key concerns:

1. **Focus visibility regression (blocker).** The new `--ls-border-control` token raises the resting border of text inputs, selects and textareas to `gray-500`. The focus style for those fields keeps `outline: none` and still relies on a border-color change to `brand-600` plus a `brand-100` halo. In the light theme the focused and resting states now differ by only about 1.13:1, down from 3.61:1. The new contrast contract does not check this, and the harness's focus-indicator check would still report "pass".
2. **Harness safety scan.** The RFC 2606 exemption can be bypassed by any hyphenated label ending in `-example.com/.net/.org`. The scan reads only `innerText`, and it runs before the keyboard sweep and screenshots. The login submit targets the first `<form>` on the page rather than the `#login` field's form.
3. **Vacuous assertions.** `assert_page_contract!` (default `:when_present`) skips the label check entirely when a page has form controls but no labels at all. The harness reports `pass` even when focus indicators are missing, focus stops are off screen, or the h1 count is wrong.

Verified by running: `node --test test/browser/admin_route_proof_test.mjs` (10/10 pass); `scanSensitive` probes (see WR-01); WCAG contrast computations (see CR-01, WR-06, IN-04).

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Field focus indicator nearly disappears in light theme after the control-border change

**File:** `lib/lockspire/web/admin_css.ex:104`, `:1247`, `:1257-1263` (dark: `:3009`)
**Issue:** The phase changed `.lockspire-admin-field input/select/textarea` from `--ls-border-strong` (`gray-300` `#cbd5e1`) to `--ls-border-control` (`gray-500` `#64748b`). The focus rule for those same fields was left unchanged:

```css
.lockspire-admin-field input:focus-visible, ... {
  outline: none;
  border-color: var(--ls-focus-ring-color);   /* brand-600 #0e7490 */
  box-shadow: var(--ls-focus-ring-shadow);    /* 3px brand-100 #cffafe */
}
```

Computed contrast between the focused and unfocused states:

| Theme | Before (resting border → focus border) | After |
|---|---|---|
| Light | 3.61:1 (`#cbd5e1` → `#0e7490`) | 1.13:1 (`#64748b` → `#0e7490`) |
| Dark | 5.73:1 | 1.94:1 |

The only remaining cue in light is the `brand-100` halo, which is 1.12:1 against the white panel. A keyboard user in the light theme effectively can't see which form field has focus (WCAG 2.4.7, plus the 2.4.11/2.4.13 change-of-state intent). This regresses a phase goal (focus visibility).

`assert_contrast_pairs!` checks `--ls-focus-ring-color` against surfaces, but not focused against unfocused state. The harness's `hasRing` counts any non-`none` `box-shadow` as an indicator, so neither proof catches the regression.

**Fix:** Give these fields the same outline ring every other control uses. Keep the border change as a secondary cue:

```css
.lockspire-admin-field input:focus-visible,
.lockspire-admin-field select:focus-visible,
.lockspire-admin-field textarea:focus-visible {
  border-color: var(--ls-focus-ring-color);
  outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);
  outline-offset: var(--ls-focus-ring-offset);
}
```

Then add a contract assertion in `CssAssertions` that the field `:focus-visible` rule carries `outline: var(--ls-focus-ring-width)`. Optionally also add a contrast pair `{"--ls-focus-ring-color", "--ls-border-control", 3.0}`.

## Warnings

### WR-01: RFC 2606 exemption is bypassed by any hyphenated `*-example.com/.net/.org` host

**File:** `test/browser/admin_route_proof.mjs:203`
**Issue:** `/\b(?:[a-z0-9-]+\.)*example\.(?:com|net|org)\b/gi` can start a match at the word boundary between `-` and `e`. A registrable production domain such as `acme-example.com` or `my-example.org` is therefore rewritten to `acme-reserved-host`, and the hostname rule never sees it. Verified:

```
scanSensitive("https://auth.acme-example.com/cb")  -> []
scanSensitive("https://login.my-example.org")      -> []
```

The only test (`admin_route_proof_test.mjs:130-133`) covers one reserved host and one plain `.com` host.

**Fix:** Anchor the exemption to a real label boundary, and add regression cases for `acme-example.com` and `notexample.com`:

```js
const withoutReserved = text.replace(
  /(?<![A-Za-z0-9.-])(?:[a-z0-9-]+\.)*example\.(?:com|net|org)\b/gi,
  "reserved-host"
);
```

### WR-02: The sensitive scan misses hidden and attribute content, and runs before the state that is screenshotted

**File:** `test/browser/admin_route_proof.mjs:350`, `:482-486`, `:498-520`
**Issue:** The scan covers three inputs:
- `document.body.innerText`, which excludes `display:none`/`visibility:hidden` content such as closed tooltips and collapsed panels.
- Form field values.
- `data-*` attributes.

It does not cover `title`, `aria-label`, `alt` or `href`. It also runs once, right after `open`. The keyboard sweep (40 × Tab, which shows focus-triggered tooltips and popovers) and the full-page and section screenshots happen afterwards. Content hidden at scan time can therefore appear in a screenshot unscanned. The focus-stop `name` stored in the observation JSON (`textContent`/`title`) is never scanned either. This weakens the "never capture secrets" rule.

**Fix:**
- Scan `document.body.textContent` plus `title`/`aria-label`/`alt`/`href` values.
- Re-run the sweep-and-scan after `keyboardSweep()` and immediately before each `screenshot` call.
- Abort the capture on any hit.

### WR-03: Login submit targets the first `<form>` in the document, not the login field's form

**File:** `test/browser/admin_route_proof.mjs:418`
**Issue:** `document.querySelector("form").requestSubmit()` submits whichever form comes first in DOM order. Today the demo login page has one form (`examples/adoption_demo/.../session_controller.ex:43`), so this works. But the rule "the only form ever submitted is the synthetic login form" depends on layout order, not on the code. A header, theme or sign-out form added to the demo layout would be submitted instead. The harness also never checks that `LOCKSPIRE_PROOF_BASE_URL` points at the synthetic demo before typing the account and submitting.

**Fix:**

```js
'const f = document.querySelector("#login")?.form; if (!f || !f.matches(\'form[action$="/login"]\')) throw new Error("no login form"); f.querySelector("#login").value = "ops"; f.requestSubmit(); "submitted"'
```

Optionally also refuse to run when `baseUrl()`'s hostname does not end in `.localhost` (or another explicit allowlist).

### WR-04: Harness reports `pass` without checking focus, h1 or disclosure failures, and its indicator check can pass vacuously

**File:** `test/browser/admin_route_proof.mjs:367-377`, `:470-475`, `:508-512`
**Issue:** `result` is `fail` only for document overflow, clipped elements, or unlabeled controls. The following are recorded only in notes or gaps and never fail the row:
- `keyboard.indicated < stops.length`
- `keyboard.offscreen > 0`
- `h1Count !== 1`
- an Escape press that leaves disclosures open (`disclosuresBefore`/`disclosuresAfter` are captured and then ignored)

`hasRing` also treats any non-transparent `box-shadow` (for example `--ls-shadow-sm` on cards and buttons), or a transparent outline, as a focus indicator. It also checks up to 3 `:focus-within` ancestors, so a card shadow satisfies the check. The focus-visibility evidence rows can therefore be green even with no visible focus style (see CR-01).

**Fix:**
- Set `result = "fail"` when `indicated !== stops.length`, `offscreen > 0` or `h1Count !== 1`.
- Compare computed outline/box-shadow on focus against the same element blurred, rather than testing "has any shadow".
- Ignore `outline-color: transparent`.

### WR-05: `assert_page_contract!` (default `:when_present`) skips label checks on pages with unlabeled controls

**File:** `test/support/lockspire/web/admin_proof/html_assertions.ex:137-146`
**Issue:** `has_labels?` counts only `<label>` elements. A page that renders `<input>`/`<select>` controls with no label at all (the worst case) gets `has_labels? == false`, and the label check is silently skipped. Many new call sites use the default, including `/admin/clients` (filters), `/admin/iats`, keys, interactions, device authorizations, logouts, and the `rotate-*` confirmation pages. On those pages the contract cannot detect a newly unlabeled control.

**Fix:** Decide based on rendered controls, not labels:

```elixir
has_controls? =
  html |> document()
  |> LazyHTML.query("input:not([type=hidden]), select, textarea")
  |> Enum.count() > 0

:when_present -> if has_controls?, do: assert_label_targets_exist(html)
```

### WR-06: Invalid-field boundary drops to 1.45:1, below the control boundary this phase introduced

**File:** `lib/lockspire/web/admin_css.ex:1299-1307` (token `:55`, `:113`)
**Issue:** Valid fields now have a 3:1+ boundary (`--ls-border-control`). Invalid fields override `border-color` with `--ls-status-danger-border` (`#fecaca`, 1.45:1 on white in light). The 1px `box-shadow` uses the same pale color. The error state is now visually weaker than the normal state, and its boundary falls below WCAG 1.4.11. `assert_contrast_pairs!` does not include `--ls-status-*-border`.

**Fix:** Use a 3:1 danger color for the invalid boundary (for example `--ls-color-danger-text` or a new `--ls-status-danger-control` token). Then add `{"--ls-status-danger-border-or-control", "--ls-surface-panel", 3.0}` to `contrast_pairs/1` for both themes.

## Info

### IN-01: CSS responsive assertions aren't scoped to their media block

**File:** `test/support/lockspire/web/admin_proof/css_assertions.ex:128-147`, `:288-291`
**Issue:**
- `media_rule/2` and the new 640px regex capture everything from the first match to the end of the file (`(.*)\z`).
- `rule/2` then returns the first matching selector anywhere after that point.
- The new `.lockspire-admin-secondary-nav` and `.status-cluster` assertions would still pass if the rule moved out of its media query, or into a different, later media block.

**Fix:** Extract the balanced body of the specific `@media` block (brace-counting) before calling `rule/2`.

### IN-02: Wrapped-label exemption compares whole attribute lists and accepts empty labels

**File:** `test/support/lockspire/web/admin_proof/html_assertions.ex:84-105`
**Issue:**
- `attrs in wrapped` exempts any control whose attribute list equals a wrapped control's, for example two identical `[{"type","checkbox"},{"name","x[]"}]` inputs where only one sits inside a label.
- A `<label>` with no text still counts as labelling.
- The failure message still says "explicit label[for] targets" even though wrapped labels now satisfy it.

**Fix:** Identify wrapped controls by node identity (query `label` and collect its descendants' ids), require non-blank label text, and update the message.

### IN-03: JS sensitive patterns no longer mirror the Elixir list, and the hostname TLD list is narrow

**File:** `test/browser/admin_route_proof.mjs:82-113`, `:203-205`; `test/support/lockspire/web/admin_proof/browser_evidence.ex:69-90`
**Issue:**
- The comment says the JS list "Mirrors ... sensitive_patterns/0", but only the JS side has the example-domain exemption. A gap note naming an `example.com` host passes the harness but raises in `BrowserEvidence.parse!`.
- Both lists only treat `com|net|org|io|dev|app|cloud` as production TLDs, so `.co`, `.ai`, `.us` and ccTLD hosts pass (`scanSensitive("https://api.acme.co/x") -> []`).

**Fix:** Document the divergence or apply the same exemption in Elixir. Consider a generic `[a-z]{2,}` TLD with an allowlist (`localhost`, `test`, `example`, `invalid`).

### IN-04: Theme-select hover no longer changes the border noticeably

**File:** `lib/lockspire/web/admin_css.ex:445-447`
**Issue:** The hover state sets `border-color: var(--ls-text-muted)` (`#5f6f84`). The new resting `--ls-border-control` is `#64748b`, a 1.08:1 difference, so hover feedback is effectively gone.

**Fix:** Use `--ls-text-strong` or `--ls-focus-ring-color` for the hover border.

### IN-05: Dead and no-op code in the harness

**File:** `test/browser/admin_route_proof.mjs:453-455`, `:683`, `:643`
**Issue:**
- `pad()` returns `String(value)` and does nothing else.
- `if (error.sensitive) continue;` is the last statement in the loop body, so it has no effect.
- A bare `--width` makes `Number(true) === 1`, which produces a 1px viewport and an evidence row that `BrowserEvidence` rejects.

**Fix:** Remove `pad`, remove the no-op `continue` (or make sensitive hits abort the whole run), and validate `--width` against the allowed viewport list.

### IN-06: "system" theme rows are always captured under light media by default

**File:** `test/browser/admin_route_proof.mjs:429-431`, `:613`
**Issue:** `mediaScheme("system", undefined)` falls back to `"light"`, so every default matrix row labelled `system` duplicates `light`. The `prefers-color-scheme: dark` path (`admin_css.ex:3041-3047`) is never exercised unless `--media dark` is passed. Explicit `dark` rows also set dark media, so the `:root[data-theme="dark"]` path is never proven independently of the media-query path.

**Fix:** Expand `system` into `system` with light media and `system` with dark media in `buildMatrix`. Run explicit `dark` rows under light media so the `data-theme` override is what gets proven.

### IN-07: The aria-describedby fix has no direct regression test

**File:** `lib/lockspire/web/components/admin_components.ex:429`, `:882-889`
**Issue:** The fix is only covered indirectly, by `assert_page_contract!` on policy pages that happen to render radio groups. No component test renders a `radio_group` whose options have no help text and no group help or errors, then asserts that `aria-describedby` is absent. Option values containing whitespace would also yield ids that split into broken describedby tokens; this behavior predates the phase.

**Fix:** Add a component test covering:
- no help: the attribute is absent;
- option help only;
- group help plus errors: ids are ordered and space-joined.

## Fix Status

All 14 findings are fixed.

| Finding | Status | Commit | Notes |
|---|---|---|---|
| CR-01 | fixed | `e427f3af` | Field `:focus-visible` uses the shared outline ring. A CSS contract assertion checks it. |
| WR-01 | fixed | `8776458a` | The example-domain exemption is anchored to a whole DNS label. Node tests cover `acme-example.com`, `my-example.org`, `notexample.com` and `example.com.attacker.io`. |
| WR-02 | fixed | `7e68d87f` | The scan now covers hidden text (a text-node walk that skips `<script>`/`<style>`) and the `title`, `aria-label`, `alt` and `href` values. It re-runs after the keyboard sweep, before every full-page and section screenshot, over the focus-stop names, and over the evidence row and observation JSON before they are written. |
| WR-03 | fixed | `3b3cffc6` | Submits `document.querySelector("#login").form` after checking it posts to `/login`. Refuses to run or sign in unless the host is `localhost`, `127.0.0.1`, `*.localhost` or `*.test`. |
| WR-04 | fixed | `143f6918` | A row fails on a missing focus indicator, an offscreen focus stop, an h1 count other than 1, or a disclosure still open after Escape. A ring counts only when painted on the focused element, or drawn on an ancestor by a matching `:focus-within` rule. Transparent outlines and shadows do not count. No pass row in `154-BROWSER-EVIDENCE.md` or `154-RESPONSIVE-SWEEP.md` would fail under these rules (see below). |
| WR-05 | fixed | `4f2538ff` | `:when_present` now runs the label check whenever a visible form control renders. New negative tests are in `page_contract_test.exs`. |
| WR-06 | fixed | `e427f3af` | Invalid fields use `--ls-border-control-invalid`, and the contrast contract checks it at 3:1. |
| IN-01 | fixed | `833e377e` | `media_block/3` extracts the balanced block of the media-query occurrence that holds a given selector. `block_rule!/2` matches the whole selector only. |
| IN-02 | fixed | `f5b7be61` | Labels are checked in one walk over the parsed tree, so each control is judged by its own node. Empty labels do not count, a wrapping label with a `for` labels only the control that `for` names, and the failure messages name both label forms. |
| IN-03 | fixed | `33cda6d7` | The JS and Elixir pattern lists are identical source for source, and a node test fails on any drift. Elixir applies the same exemption. The hostname rule adds `.co`, `.ai` and other common TLDs. `.localhost`, `.test`, `.example` and `.invalid` stay exempt. |
| IN-04 | fixed | `e427f3af` | The theme-select hover border now uses `--ls-text-strong`. |
| IN-05 | fixed | `cfd8517a` | Removed `pad()` and the no-op `continue`. A sensitive hit now aborts the whole run. A bare `--width` or `--height`, or a width `BrowserEvidence` rejects, exits with code 2. |
| IN-06 | fixed | `078fcc68` | Matrix `system` rows run under both light and dark media, and the State cell names the media. Older `system` rows are documented as system-light. A 12-row system-dark run of the changed pages at 390 px is recorded in `154-BROWSER-EVIDENCE.md`, and all 12 rows pass. The full matrix was not re-run. |
| IN-07 | fixed | `6a073af8` | Component tests cover four cases: no help (attribute absent), option help only, error only, and group help plus errors (ordered, space-joined). |

**WR-04 check against recorded evidence.** I re-read the stored keyboard observations (`tmp/admin-ui-polish/v1.42/final/keyboard/`, `sweep/kb`, `sweep/post/kb`).
- Every final keyboard row reports `indicator N/N`, `offscreen 0`, `h1=1`, and no disclosure open after Escape.
- The only ancestor-drawn indicators are the three multi-value inputs. Their ring comes from `.lockspire-admin-multi-value--enhanced:focus-within`.
- The two `offscreen 1`/`offscreen 2` rows in `154-RESPONSIVE-SWEEP.md` are pre-fix rows, already marked `fail`.
- Every row in both files has `h1=1`.
- A re-run with the tightened harness on `/admin/policies/dcr` and `/admin/clients/:client_id/edit` at 1280 px still reports 40/40 and 28/28.

**Verification (main checkout, `workflow.use_worktrees: false`):**
- `mix format --check-formatted` passes.
- `mix test test/lockspire/web/live/admin`: 277 passed.
- `mix test.fast`: 1573 passed, 6 skipped. That is the baseline of 1563 plus 10 new tests.
- `node --test test/browser/admin_route_proof_test.mjs test/browser/admin_multi_value_test.mjs`: 27 passed.
- Local harness smoke runs against `http://lockspire-ui-review.localhost/lockspire/admin`, all pass:
  - `--matrix --width 390 --route /admin/clients,/admin/policies/dcr --screenshot`: 8 rows, including system under light and dark media.
  - `--route /admin/clients/new --width 390 --keyboard --screenshot`: 10/10 focus stops have an indicator, 0 offscreen.

---

_Reviewed: 2026-10-15T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
