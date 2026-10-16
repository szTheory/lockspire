# Phase 152 — UI Review

**Audited:** 2026-10-15
**Baseline:** `152-UI-SPEC.md` (approval pending), `152-CONTEXT.md`, `PRODUCT.md` personas, vocabulary map and retired-wording table, `AGENTS.md` "Admin UI Copy"
**Source state:** HEAD `8f29754b`, plus uncommitted working-tree edits present at audit time (listed under "Working-tree state"). Findings say which state they apply to.
**Screenshots:** not captured (code-only audit requested; no dev server check performed)
**Interaction captures:** off (`interaction_capture: false`)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Overview labels miss the spec's required phrases; row explanations claim remote behavior; expired-but-pending rows read as waiting; "Succeeded" badge reads as confirmed sign-out |
| 2. Visuals | 3/4 | Calm hierarchy with attention signals first; no `Review clients` primary CTA and no overview intro sentence; review-row counts sit outside the link's accessible name |
| 3. Color | 2/4 | Light-theme muted text on muted row surface measures 4.34:1 (spec prohibits); status tone for "Succeeded" implies success |
| 4. Typography | 3/4 | Sizes stay on 12/14/16/24; summary values and overview counts render at 700 weight, outside the 400/600 rule |
| 5. Spacing | 3/4 | Gaps mostly on token scale; 12px row padding in overview sits off the normative scale |
| 6. Experience Design | 2/4 | Read-only boundary and load/empty/unavailable separation hold; key consequence copy lives only in hover tooltips; `interaction_id` shown in full; expired pending rows not reconciled; no reload control on overview failures |

**Overall: 15/24**

---

## Working-tree state (uncommitted at audit time)

Someone is actively changing these files. Items below are marked by state.

- **Known example, `logout_deliveries_live/index.ex`:** At HEAD line 171 read `"1 logout delivery recorded"` and line 179 read `"1 logout delivery needs review"`. Working tree now reads `"1 app sign-out notice recorded"` and `"1 app sign-out notice needs review"`. **Fixed in working tree, not committed.** The plural forms already said "app sign-out notices", so the singular/plural mismatch is resolved.
- **Overview line 77:** HEAD said `"Could not load logout delivery records."`; working tree says `"app sign-out notices"`. Fixed in working tree.
- **`PRODUCT.md`:** working tree adds the retired-wording row `logout delivery → app sign-out notice`. I mirrored `vocabulary_contract_test.exs` against all admin sources (34 phrases): no hits in working tree.
- **Expiry-aware pending counts:** `interactions_live/index.ex` (`count_waiting`, `waiting?`) and `device_authorizations_live/index.ex` (`count_waiting`, `waiting?`) now count only non-expired pending records, matching the overview and the `status=pending` filters. Row titles were not changed (see finding W-2).
- **Logouts `load_deliveries/0`:** `_other -> {:unavailable, []}` clause added (line 157); the old `case` had no fallback.

---

## Spec and Product Conflicts (reconcile before scoring is final)

The UI-SPEC contains copy that `PRODUCT.md` retires. The implementation follows `PRODUCT.md`, which is correct. The spec should be updated, not the code. Adopting the spec wording would fail `vocabulary_contract_test.exs` for these phrases:

| UI-SPEC copy | Retired phrase | Implemented (correct per PRODUCT) |
|---|---|---|
| `Authorization interactions` (page/queue title) | `authorization interaction` | `Sign-in requests` / `Sign-in request history` (`interactions_live/index.ex:15,30,207`) |
| `No authorization interactions recorded.` | `authorization interaction` | `No sign-in requests recorded` (`interactions_live/index.ex` empty title) |
| `Logout deliveries needing review` | `logout deliveries` | Should become `App sign-out notices needing review` (not yet done; see W-1) |
| `Reload logout deliveries` | `logout deliveries` | `Reload app sign-out notices` (`logout_deliveries_live/index.ex:86`) |
| `Interactions waiting for login or consent` | `login or consent` | `Sign-in or consent request(s)` (`overview_live/index.ex:86`) |
| `Reload interaction records` | — | `Reload sign-in requests` (`interactions_live/index.ex:91`) |

Two spec items are not conflicts and are plain deviations:
- `Refresh tokens flagged for reuse` is not retired and is not used (see W-1).
- The overview intro sentence `See what needs review and open the related records.` is required by the spec (Overview Information Contract item 1) but removed, and `overview_live_test.exs:186` and `:281` assert it is absent. This needs a decision; see W-4.

---

## Top 3 Priority Fixes

1. **Redact the interaction ID on the staff queue** — The interactions page prints the full `interaction.interaction_id` as "Request ID" (`interactions_live/index.ex:125`). That value is 32 random bytes (`authorization_flow.ex:716-719`) and is the path segment for the end-user consent page (`/consent/:interaction_id`, `authorize_controller.ex:68`, `interaction_controller.ex:25`). Subject binding in `consent_context.ex:35-36` limits what an operator can do with it, but AGENTS.md requires "strong redaction in logs and operator surfaces," and the spec forbids exposing session-like values. Fix: render `Redaction.handle(:interaction, id)` (or a similar handle) like the account column does. **Blocker** (see B-1).

2. **Make row state match the saved record** — In full history, a pending request past its `expires_at` still renders its badge and title as "Waiting for sign-in" (`interactions_live/index.ex:220-221`) or "Waiting for user confirmation" (`device_authorizations_live/index.ex:179`), while the adjacent "Waiting" metric and the overview now exclude it. Rows must derive an "Expired" state from `expires_at`. In logouts, the `:succeeded` status renders the badge "Succeeded" (generic `status_label`, `admin_components.ex:1006`, tone `:completed` at `admin_components.ex:967`), which reads as a confirmed sign-out, while the adjacent metric says "Endpoint accepted". Use the metric's wording for the badge. Also replace the device consumed-row claim "The app received the result after the user approved it" (`device_authorizations_live/index.ex:254`) and the approved-row claim "The app is waiting to receive the result" (`:245`) with what the record proves.

3. **Bring overview copy to the contract and align the Keys pivot** — The two attention labels are not the spec's: "Refresh tokens used more than once" (`overview_live/index.ex:34`) should be `Refresh tokens flagged for reuse`; "Unconfirmed app sign-outs" (`:60`) should be `App sign-out notices needing review` (a vocabulary-safe form of the spec's `Logout deliveries needing review`). The reuse and sign-out consequences currently live only in hover tooltips (`:35-43`, `:61-70`); the spec requires them in place. The `Active token-signing keys` count (`:126`) links to `/keys`, which has no status filter, so the count describes a subset while the destination shows every key. Either add a read-only `status=active` view or label the complete list (spec Overview item 4).

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

**Passing:** Unavailable and empty states are present and distinct on all three queues (`interactions_live/index.ex:85-97,99-116`; `device_authorizations_live/index.ex:90-103`; `logout_deliveries_live/index.ex:81-91,94-111`). Vocabulary contract mirror passes against working tree. Singular/plural count copy for logouts is consistent in working tree.

- **B-1 (Blocker, security redaction) — Full interaction ID on operator surface.** `interactions_live/index.ex:125`: `safe_identifier(interaction.interaction_id)`. Not a copy issue, but listed here because it is the only value on these pages that the spec's redaction rule covers and that is shown unredacted. Downgrade only if the maintainer confirms the value cannot be used to reach the consent page.
- **W-1 (Warning) — Overview labels miss the spec and `PRODUCT.md`.** `overview_live/index.ex:34` and `:60` (see Priority Fix 3). Also `:93`: "Device sign-in waiting for approval" introduces a third name for the same records. The device page is titled "Device authorization requests" (`device_authorizations_live/index.ex:15`), and PRODUCT does not map "device authorization". Pick one name for the overview row and the page.
- **W-2 (Warning) — Expired pending rows contradict the saved record.** `interactions_live/index.ex:220-221`; `device_authorizations_live/index.ex:179`. Overview and filtered views exclude these records; full history still labels them waiting.
- **W-3 (Warning) — Consequence copy claims remote behavior.** `device_authorizations_live/index.ex:245` ("The app is waiting to receive the result") and `:254` ("The app received the result after the user approved it"). The saved record proves an approval or token consumption, not app receipt. The spec forbids guessing relying-party behavior (UI-SPEC Logout/Device sections; PRODUCT "must not imply"). `logout_deliveries_live/index.ex:282-283` ("The app accepted the server request. This does not confirm the person was signed out.") is correct and is the model to follow.
- **W-4 (Warning) — Required overview intro removed and enforced by test.** UI-SPEC Overview item 1 and Copywriting table require `See what needs review and open the related records.` Implementation omits it, and `test/lockspire/web/live/admin/overview_live_test.exs:186` and `:281` assert absence. Decide whether the spec or the test wins; the current state is an unrecorded deviation. The spec also requires the primary CTA `Review clients` (copy table); no such text exists in `lib/`.
- **W-5 (Warning) — Logout channel never explained once.** UI-SPEC Logouts item 1 requires a single user-language explanation that back-channel is a server request and front-channel is a best-effort browser page. `logout_deliveries_live/index.ex:46-48` page hero says only "See which apps Lockspire notified during sign-out and what response it recorded." Channels appear only as row labels (`:123`, `:248-249`).
- **I-1 (Info) — Minor copy drift.** `interactions_live/index.ex:214` body "There are no recorded authorization requests to review." uses "authorization requests" while the title uses "sign-in requests". `device_authorizations_live/index.ex:202-208` "Showing …" count copy differs from the other pages' "… recorded" form.

### Pillar 2: Visuals (3/4)

**Passing:** One `<h1>Overview` (rendered from `admin_layout_live.ex:290`). Attention signals (token reuse, sign-out problems) are first (`overview_live/index.ex:30,56`), ahead of totals. Info buttons carry `aria-label` and `aria-describedby` (`admin_components.ex:57-63`). No duplicate counts; the self-registered-client metric is absent.

- **W-6 (Warning) — Review-row accessible name excludes the count.** Spec Interaction rules: "The clickable overview row has one accessible name that includes its record type and count." Waiting and Apps rows wrap the count inside the `<a>` (`overview_live/index.ex:85-91`, `:92-98`, `:104-110`). The review rows do not: the link text is only the label (`:34`, `:60`, `:113`, `:126`) and the count is a sibling `<strong>` (`:45`, `:72`). A screen reader hears "Refresh tokens used more than once" with no count.
- **W-7 (Warning) — Overview missing primary CTA.** Spec Copywriting table: primary overview CTA `Review clients`. None present.

### Pillar 3: Color (2/4)

**Measured contrast (WCAG 2.x, from `admin_css.ex` tokens):**

| Pair | Light | Dark |
|---|---|---|
| `--ls-text-muted` (#64748b) on `--ls-surface-panel` (#fff) | 4.76:1 pass | 5.87:1 pass |
| `--ls-text-muted` on `--ls-surface-muted` (#f1f5f9, light) / gray-800 (#1f2937, dark) | **4.34:1 FAIL** | 5.06:1 pass |

- **W-8 (Warning) — Light-theme muted text on muted row fails 4.5:1.** The queue rows are `.lockspire-admin-resource-list > .lockspire-admin-dense-resource-row` with `background: var(--ls-surface-muted)` (`admin_css.ex:718-719`). Their status-consequence line (`.lockspire-admin-dense-resource-row__main span`, `admin_css.ex:738-742`, `color: var(--ls-text-muted)`) and the meta row (`__meta`, `admin_css.ex:745-752`, `color: var(--ls-text-muted)`) render at 4.34:1 in light theme. The spec states this exact case must not occur: "Do not use the current muted gray token on the muted gray surface where it falls below this threshold." Fix: use `--ls-text-body` for the row's consequence and meta text in the light theme, or change the surface.
- **W-9 (Warning) — Badge tone implies success it does not prove.** `status_metadata` for `:succeeded` uses tone `:completed` (`admin_components.ex:967`), and the generic `status_label` renders "Succeeded" (`admin_components.ex:1006`). The adjacent metric is "Endpoint accepted" (`logout_deliveries_live/index.ex:68`), and PRODUCT says an accepted endpoint response does not prove session termination. Use the metric's wording for the badge.
- **I-2 (Info) — `:enqueued` badge is internal.** Generic `status_label` renders "Enqueued" (`admin_components.ex:1006`) for the logout queued state. Use "Queued" to match the metric (`logout_deliveries_live/index.ex:197`).

### Pillar 4: Typography (3/4)

**Passing:** Phase content sizes use `--ls-type-label-size` 0.75rem, `--ls-type-body-size` 0.875rem, `--ls-type-heading-size` 1rem, `--ls-type-display-size` 1.5rem (`admin_css.ex:117-120`). Weights 400/600 are declared as tokens (`:121-122`). Long identifiers wrap (`admin_css.ex:2590-2597`, `overflow-wrap: anywhere`).

- **W-10 (Warning) — 700 weight on counts and summary values.** `.lockspire-admin-summary-value` sets `font-weight: 700` (`admin_css.ex:1616-1619`); every queue metric (`interactions_live` lines 58-74, `device_authorizations_live` lines 57-75, `logout_deliveries_live` lines 63-69) uses `summary_stat`. The overview's `<strong>` counts (`overview_live/index.ex:45,72,87,94,106,119,132`) have no weight rule and fall back to the browser default bold (700); `admin_css.ex:2047-2052` sets none. Spec: "Use only regular (400) and semibold (600)… Page / summary value 24px 600."
- **I-3 (Info) — Shell nav label at 700 / 11px** (`admin_css.ex:215-220`). Outside this phase's scope (spec excludes persistent shell branding), recorded only.

### Pillar 5: Spacing (3/4)

**Passing:** Dashboard grid gap uses `--ls-space-6` (24px) (`admin_css.ex:1787-1791`); review-row gap uses `--ls-space-2`/`--ls-space-4` (8/16px); dense rows use `--ls-space-4` (16px).

- **W-11 (Warning) — 12px row padding off the normative scale.** Spec Spacing Scale lists 4/8/16/24/32/48/64 and says not to introduce other layout-gap values. The overview rows use `padding: var(--ls-space-3) 0` (`admin_css.ex:1810`); `--ls-space-3` is 0.75rem = 12px (`admin_css.ex:12`). Use `--ls-space-2` or `--ls-space-4`.
- **I-4 (Info) — Inline 2-row meta spacing** on queue rows uses `--ls-space-3` (`admin_css.ex:752` gap). Pre-existing component; recorded only.

### Pillar 6: Experience Design (2/4)

**Passing:**
- Read-only boundary holds: queues expose only `admin_button` links; no retry, discard, approve or deny controls exist in the three LiveViews.
- Load, unavailable and loaded-zero are distinct per source. Overview unavailable shows `Unavailable` in place of the count and a status note, and independent sources stay independent (`overview_live/index.ex:218-225`).
- Filter allowlists are strict: unknown `status` values fall back to full history (`interactions_live/index.ex:163-164`, `device_authorizations_live/index.ex:188-189`, `logout_deliveries_live/index.ex:162-163`).
- Reuse pivot resolves: tokens page accepts `status=reuse_detected` (`tokens_live/index.ex:67,205`).
- Pending overview counts and their destinations now use the same predicate (working tree).

**Findings:**
- **W-12 (Warning) — Key consequences exist only in hover tooltips.** Reuse explanation (`overview_live/index.ex:35-43`, including "Lockspire revoked every token in its family") and sign-out explanation (`:61-70`) are inside `info_tooltip`. Spec Overview item 5 and UI-SPEC Copywriting require the event and consequence "plainly" beside the count; tooltip copy should be "removed or expressed in place." The tooltip also depends on pointer hover and a script (`admin_components.ex:54-75`); keyboard and no-JS paths were not verified.
- **W-13 (Warning) — Keys count does not match its destination.** `overview_live/index.ex:126` counts `active` signing keys (`count_label` on `:active`); `/keys` has no status filter (`lib/lockspire/web/live/admin/keys_live/index.ex`, no `status` param handling). Spec Overview item 4: a subset count needs a matching read-only filtered view, or the count must label the full list.
- **W-14 (Warning) — No reload or inspect control on overview failures beyond the row link.** Spec Overview item 7 asks for `Reload token records` or `Reload logout deliveries` on a failed source. Failed sources show only `role="status"` text (`overview_live/index.ex:49-51`, `:76-78`). The row link still gives a route to inspect, so this is partial.
- **W-15 (Warning) — Pending-but-expired rows not reconciled in full history.** Restated from W-2 for the UX pillar: a user cannot tell from the full history why the overview count differs from the "Waiting" badge on the same page.
- **I-5 (Info) — Logout `:frontchannel` rendered rows** say "Lockspire showed a sign-out page in the browser. This does not confirm the app signed the person out." (`logout_deliveries_live/index.ex:285-286`). Correct; recorded as a model for the back-channel and device rows.
- **I-6 (Info) — Registry audit:** not applicable. `components.json` absent; UI-SPEC lists no third-party registry.

---

## Requirement Checklist (UI-SPEC)

| Spec item | Status |
|---|---|
| Overview single title and one intro sentence | Title pass; intro missing (W-4) |
| Attention signals first with pivots | Pass (order); labels fail (W-1) |
| Self-registered-client metric removed | Pass |
| Preferred labels | Fail for reuse and sign-out overview labels (W-1); conflicts for queue titles (see Spec Conflicts) |
| Counts match destination subset | Pass for tokens, interactions, devices, logouts (working tree); fail for keys (W-13) |
| Failed source shows Unavailable with a route | Partial (W-14) |
| Successful zero distinct from failed read | Pass |
| Interactions neutral title and states | Fail for expired pending rows (W-2); title conflicts with spec but matches PRODUCT |
| Device neutral title and states | Pass title; fail for expired pending rows and consumed/approved claims (W-2, W-3) |
| Logouts channel explained once | Fail (W-5) |
| Logouts `Retryable`/`Discarded` read-only, no controls | Pass |
| Empty/read-failure copy | Pass with PRODUCT-compliant wording (see Spec Conflicts) |
| Redaction of credential-class values | Fail for `interaction_id` (B-1) |
| 4.5:1 contrast, both themes | Fail in light theme on queue rows (W-8) |
| Weights 400/600 only | Fail for counts and summary values (W-10) |
| Spacing scale | Mostly pass; 12px padding (W-11) |
| Vocabulary contract (PRODUCT retired table) | Pass in working tree (mirror check) |

---

## Recommendation Count

- Blockers: 1 (B-1)
- Priority fixes: 3 (see Top 3)
- Warnings: 15 (W-1 through W-15)
- Info: 6 (I-1 through I-6)

---

## Files Audited

- `lib/lockspire/web/live/admin/overview_live/index.ex` (HEAD and working tree)
- `lib/lockspire/web/live/admin/interactions_live/index.ex` (HEAD and working tree)
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` (HEAD and working tree)
- `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` (HEAD and working tree)
- `lib/lockspire/web/live/admin/tokens_live/index.ex` (filter contract only)
- `lib/lockspire/web/components/admin_components.ex` (status tones, labels, dense row, info tooltip, summary stat)
- `lib/lockspire/web/admin_css.ex` (tokens, contrast, weights, spacing, overview and dense-row rules)
- `lib/lockspire/web/live/admin_layout_live.ex` (page title render)
- `lib/lockspire/protocol/authorization_flow.ex`, `lib/lockspire/web/controllers/authorize_controller.ex`, `lib/lockspire/web/consent_context.ex`, `lib/lockspire/web/controllers/interaction_controller.ex` (interaction ID generation and consent path, B-1 context)
- `test/lockspire/web/live/admin/vocabulary_contract_test.exs` (mirrored, not executed)
- `test/lockspire/web/live/admin/overview_live_test.exs` (W-4, W-12 assertions)
- `PRODUCT.md`, `AGENTS.md`, `152-UI-SPEC.md`, `152-CONTEXT.md`, `152-01` through `152-05` SUMMARY and PLAN files

**Not verified (code-only audit):** rendered layout at 375/768/1440, focus order, tooltip keyboard operation, reduced-motion behavior, and whether the test suite passes on the working tree. Run the overview, interactions, device and logout LiveView tests before acting on the working-tree items.
