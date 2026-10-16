# Phase 153 user feedback checklist

This is the durable checklist for the user's October 13 follow-up. Phase 153 remains active. Do not repeat already verified work; update each item with evidence before marking addressed. Billingo is the synthetic adoption demo, not the Lockspire product.

## Latest feedback — autonomous cleanup and practical guidance, October 13 evening

- [x] Replace changeset-style lifetime errors with actionable inline sentences, with examples and field context only in the separated summary.
- [x] Explain when/how to set lifetimes, illustrate seconds, and state the actual protection each setting provides. Completed source trace disproves automatic app/management-token expiry and client-secret authentication enforcement; do not repeat “blank means unlimited/default lifetime.”
- [x] Extrapolate prior feedback across all admin routes using Impeccable and the approved reviewers; fix shared control choice, duplicate status/headings, unavailable actions, field help/error association, task spacing and row-scoped errors. Add repeatable regressions to existing CI rather than handing routine checks back to the user.

Verified at **2026-10-14T00:34:01Z** with **305 Elixir tests / 6 Node tests**, rebuilt demo smoke, format/diff checks, final source detector `[]`, and **30 desktop + 30 mobile** final route captures/checks. Native interaction checks covered radio keyboard/previews, focused-click suggestion reopening, exhausted hints, all three lifetime error cases with retained focus, and shared Local/UTC timestamps. The six dependency-free control tests are now wired into the existing CI Release Hygiene Drift job; `actionlint` and the exact step command passed locally. No hosted CI run was triggered.

Detailed findings, evidence and limits: [153-AUTOMATED-UX-SWEEP.md](153-AUTOMATED-UX-SWEEP.md). Lifetime source truth: [153-LIFETIME-TRUTH.md](153-LIFETIME-TRUTH.md). The existing protocol todo retains the enforcement gap; UI copy does not resolve it. The live review URL is unchanged. Phase 153 reviews/summaries and phase verification remain; resume with **`$gsd-execute-phase 153`**, not a new milestone or another interview of these verified items.

This entry supersedes the older lifetime wording and preview claims below. Earlier capture/test counts remain historical evidence, not the final build's claims. The old gallery font warning was reviewed: Inter is retained as the established typography with a narrow `overused-font=inter` ignore; the real thick-summary-border finding was fixed. No broad file/rule suppression.

## Current follow-up — registration controls and consistent settings navigation

### New feedback — October 13, 19:13 EDT

- [x] Remove or justify the busy, hidden “Review these settings” summary; do not duplicate the editable settings or relocate noise into another container.
- [x] Shared token suggestions must reopen when the already-focused input or its empty field area is clicked. Exhausted suggestions must stop saying “Add another”; retain support for custom values.
- [x] Validate all three lifetime fields consistently: whole seconds, zero or greater; blank preserves the existing unset/default behavior. Match browser constraints, editing feedback and server-side rejection, preserving input and focus on invalid values. Keep existing policy semantics.

Verified **2026-10-13T23:28:13Z**:

- The hidden summary repeated ten visible fields without an additional decision. Removed it and its unused rendering helpers; retained the concise scope/consequence line, field guidance, errors, and explicit Save. The change handler still preserves the entire draft and now validates it rather than building duplicate prose.
- Shared token input and empty-field clicks reopen suggestions even when focus never left the entry. Selecting a suggestion closes the menu intentionally; the next click reopens the remaining choices. Selecting every suggestion changes the placeholder to **Add a custom value…**, not a disabled field or a false claim that all possible values have been selected. A custom `qa:custom` scope was added successfully after exhausting suggestions. This shared behavior also applies to client scopes/contacts and other token fields.
- All three lifetimes now have `min=0`, `step=1`, numeric input mode and the PostgreSQL integer storage ceiling (`2,147,483,647`). A single PolicyForm validation rule covers all three. Browser typing can contain invalid input while correcting it, but native constraints prevent submission; server validation independently rejects negative, fractional, malformed and overflowing values if browser validation is bypassed. Blank, zero, one and the supported maximum persist correctly in isolated test fixtures. These are existing storage/protocol boundaries, not new arbitrary lifetime restrictions.
- Editing errors appear beside their field with associated help/error IDs and `aria-invalid`. The error summary/focus handoff appears on failed submit, never on each preview. Native browser proof: all three negative values produced range-underflow and inline errors; fractional input produced step mismatch, oversized input range overflow, and zero was valid. Correcting to blank / 60 / the maximum cleared all errors and retained focus. The original policy stayed unchanged in every invalid-submit test. No browser Save action was activated.
- The source reviewer found that the former **No limit set** wording was stronger than the backend guarantees: blank client-secret lifetime currently becomes a zero-second offset in `ClientMetadata.client_secret_expires_at/3`, while storage comments say unset values fall back to defaults. Replaced the new guidance with **Leave blank to keep the default behavior**; blank remains `nil`. This supersedes the earlier summary-copy claim in this file. A separate protocol-semantics audit is captured in `../../todos/pending/2026-10-13-audit-dcr-default-lifetime-semantics.md`; it does not block this UI work or silently alter expiry behavior.
- Fresh verification: **302 Elixir tests, 0 failures** (admin LiveViews/router/demo contract plus ServerPolicy), **6 Node control tests, 0 failures**, rebuilt demo dependency, **adoption demo smoke passed**, source detector `[]`, formatting and diff checks. Desktop at 1512px and mobile at 390px had document width equal to viewport; option tokens, error text and fields wrapped cleanly. No new dependency, suppression, protocol action, settings save, or phase completion.

Proof captures in `tmp/admin-ui-polish/v1.42/feedback-pass/`: `scopes-exhausted-suggestions-desktop.png`, `lifetime-validation-desktop.png`, `registration-validation-mobile.png`. QA used a separate tab and restored its seed values; the user's edited tab was not reloaded. The temporary viewport is reset. Refresh the review page to load the rebuilt client script. Phase 153 remains active.

This is Lockspire feedback forwarded from the Accrue thread; the user confirms no Accrue code was changed.

- [x] **All settings scroll differs:** preserve the policy navigation's viewport anchor across short and long destinations, responsive heading changes and browser history. Make the settings workspace tall enough to sustain it.
- [x] **Registration radio spacing/help:** tighter shared grouping, concise help below Disabled / App setup token required / Open, no comparison disclosure or repeated selected-mode explanation.
- [x] **Multi-value fields and subsequent control-choice feedback:** small fixed sets use native checkboxes (DCR authentication methods, grant types, response types). Open-ended scopes, callback schemes and hosts use shared value tokens with Enter/comma addition, remove controls, pasted lists, exact deduplication, keyboard editing and optional known suggestions. Equivalent client scopes/contacts share the control. Preserve scalar CSV field names, blanks, custom values, required scopes, validation and LiveView preview. Tokens and entry occupy one continuous field border; no nested input box or verbose placeholder.
- [x] **JWT inline guidance:** concise private-key/public-key and shared-secret requirements beside allowed authentication methods; preserve RS256, ES256, PS256, EdDSA and the FAPI restriction; remove the JWT disclosure.

Verified **2026-10-13T19:09:46Z**:

- **Shared controls:** `radio_group/1`, `checkbox_group/1`, and `multi_value_control/1` now express single choice, bounded multiple choice, and open-ended multiple values respectively. Registration radio help is directly below each choice with a 4px group gap. Checkbox labels use readable names, retain native keyboard behavior, and preserve previously stored unknown enum values as explicit choices. Callback schemes stay open-ended because custom app schemes are supported. Exact redirect-URL textareas remain newline-based: a URL may legally contain commas.
- **Token interaction and accessibility:** Enter/comma, synthetic pasted lists, exact duplicate rejection, removal buttons, empty-input Backspace, ArrowLeft to removal controls, suggestion arrows/Enter/Escape, native field labels, combobox/listbox state, and live announcements were exercised. Client-create scopes retain required validation. Each entry has 0px border/padding and 16px text inside the one shared field border. Pending drafts commit on blur/submit. Existing server parsers/handlers remain authoritative; no auto-save or extra dependency.
- **LiveView race review:** the authorized interaction reviewer found that equal/coalesced values could lose request identity and deferred normalization. Local edit revisions are acknowledged by the actual element request lifecycle, so an old echo cannot clear newer edits, including B → C → B. Deferred server values are consumed only after pending edits are acknowledged. The submit listener is scoped to enhanced forms and respects `novalidate` / `formnovalidate`.
- **Live proof:** the scopes add/remove/add cycle left one `qa:final`, and checking Device sign-in appeared in the server-rendered combined preview. Clearing every host produced `Hosts: None`; a custom `lockspire-test` scheme stayed intact. Blank expiry values now correctly preview as `No limit set`, matching existing backend semantics. Reload restored the original scopes, hosts, schemes and unchecked Device sign-in; no security setting was saved and no app was created.
- **Navigation:** native pointer navigation between Registration rules and All settings preserved the section-nav top at 126px (scrollY 111) in both directions, including browser Back/Forward. Short destinations receive enough workspace height to sustain the anchor. Keyboard navigation retains a useful focus target; ordinary href fallback and history remain.
- **Layout/proof:** 1261px desktop and 390px mobile had document widths equal to viewport. Mobile fields span x=24–366px; a long unbroken host stayed within the viewport. Desktop/mobile screenshots show the compact radios, flat checkbox groups, continuous token inputs and inline JWT guidance. Header ends at System / UTC and the temporary viewport is reset. Screen-reader/zoom/adverse-state acceptance remains Phase 154.
- **Fresh checks:** **268 Elixir tests, 0 failures** (admin LiveViews, router, adoption-demo contract), **5 Node control tests, 0 failures**, rebuilt Docker dependency, **adoption demo smoke passed**, source detector `[]`, and `git diff --check` passed. No detector suppression was added. The earlier shared decision-summary finding remains outside this feedback batch.

Captures: `registration-values-desktop.png`, `registration-values-mobile.png`, and `authentication-checkboxes-desktop.png` under `tmp/admin-ui-polish/v1.42/feedback-pass/`. Latest settings form: `http://lockspire-ui-review.localhost/lockspire/admin/policies/dcr`.

Automatic approval review rejected reading the existing clipboard for backup; paste QA used only synthetic text instead. It also rejected the optional browser-tab retention mark; screenshots and the live URL remain available. Neither prevented the requested code or QA work. Phase 153 remains active.

## Earlier follow-up — visible policy choices, duplicate summaries and section navigation

- [x] **Two / few policy options:** use shared native radio groups for PAR, token proof, security requirements and registration access; preserve field names, saved selections, error association and explicit Save behavior. Header preferences / inventory filters retain their compact selects.
- [x] **Repeated current-choice summary:** remove “Current choice: …” subtitles from the policy forms; keep only context that explains effect or scope.
- [x] **Section tabs jump to page top:** use Phoenix LiveView navigation for policy sections and preserve the navigation's viewport anchor; keep browser history, normal link fallback and keyboard focus useful.

Covered by the current follow-up's fresh checks above, native field/error association assertions and explicit save/persistence tests. Do not repeat these changes.

## Verified follow-up — October 13, 13:20 settings alignment and navigation

- [x] **Settings index alignment:** default columns drift between rows; labels/values and headings/descriptions need shared text baselines.
- [x] **Heavy per-row navigation:** replace outlined Review buttons with native linked setting titles, preserving destinations, keyboard focus and responsive reading order.

Verified at **2026-10-13T17:42:25Z**: removed the variable-width action column; all rows use the same two-column proportions and shared baseline-aligned row tracks. Default columns start at x=882.398px at 1512px and x=496.797px at 820px in all four rows. At 390px, each row stacks its title/context before its saved default with 16px group separation; document width equals viewport at all three sizes. Native underlined title links replace all four outlined buttons, preserving destinations. Tab exposed the themed 2px focus ring and Enter opened the authorization-request settings. Links have 28px-high targets. Final source verification: **14 focused tests, 0 failures**, layout detector `[]`, Docker dependency rebuilt, `git diff --check` passed. No policy was saved; no new dependency or suppression. Captures: `policies-linked-titles-desktop.png`, `policies-linked-titles-intermediate.png`, `policies-linked-titles-mobile.png` in `tmp/admin-ui-polish/v1.42/feedback-pass/`. Same live review URL; Phase 153 remains active.

## Earlier batch — October 13, 12:48 onward

- [x] **Overview nested borders and broken arrangement:** Security events / Sign-out problems show an unintended inner bordered link, with consequence text beside the count. Fix shared selector leakage; preserve label/count/optional explanation hierarchy and tooltip access.
- [x] **Client badge alignment:** badge groups drift with name/ID length. Align consistent columns and make responsive stacking intentional. Remove gratuitous nested row cards and preserve clear detail actions.
- [x] **Security index typography/hierarchy:** raw `optional`, `none`, `bearer`, repeated uppercase Provider default and disjointed descriptions/actions. Use readable saved-setting values and consistent title/default/context/navigation hierarchy.
- [x] **App settings cards within cards:** flatten the PAR / token proof / security-requirements counts into a coherent summary; remove inner surfaces and uppercase styling.
- [x] **Security-requirements explanation overload:** make the full option comparison available through an accessible disclosure rather than always-visible paragraphs or a long hover-only tooltip.
- [x] **Registration rules overload:** group the actual editable rules, reduce redundant explanations/preview and excessive containers; retain all fields, validation, saved-state truth, and save behavior.
- [x] **Key-count purpose:** explain Active / Upcoming / Retiring / Retired as key lifecycle states; remove the redundant Total keys metric. Counts must distinguish signing and encryption use where necessary rather than implying every active key signs tokens.
- [x] **Key-row hierarchy and hover:** remove bordered heading within bordered row, normalize metadata typography, show useful dates rather than missing-value clutter, keep one intentional interactive hover style.
- [x] **Readable key timestamps and copy:** Published/Activated times should be easier to read and keyboard-operable to copy an exact timestamp; announce real success/failure.
- [x] **Local / UTC preference beside Theme:** shared timestamp display preference, explicit zone, persistent choice, LiveView patch/navigation consistency; copied exact instant must stay unchanged.
- [x] **Generate encryption key purpose:** explain when needed (encrypted authorization requests), distinguish it from signing, and make the preparation/publish/activate lifecycle understandable before generation.
- [x] **Generate signing key purpose:** explain initial setup / replacing a signing key and why generation produces an Upcoming/prepared key rather than immediately replacing the active key; provide a useful next destination.
- [x] **Generation-result spacing:** success notice needs deliberate spacing from the following inventory; avoid accidental paragraph margins and redundant banners.

- [x] **Queue navigation jargon:** replace visible “Logout deliveries” and “Authorization interactions” with comprehensible sign-out / sign-in language, retaining routes and internal event names.
- [x] **App-registration introduction inconsistency:** use the same unboxed page introduction component as consent and other inventories.
- [x] **App-registration reload spacing:** group Reload status with the introduction and give the following content deliberate separation.

- [x] **Giant key card:** remove the enclosing card, separate lifecycle summary / generation / inventory with consistent spacing and clear headings.

## Earlier October 13 batch — implemented and verified

See `153-UI-REVIEW-SNAPSHOT.md`, section “Token investigation and shared hierarchy follow-up”. Removed token decision cards and consent selected-filter summaries; simplified token metadata/detail/disclosures/back navigation; hid unavailable revoke forms; unified native select chevron spacing; unboxed introductions/filter bars; corrected mobile dense-row gaps. Evidence: 267 tests, demo smoke, desktop/mobile/light/dark captures. These changes are not phase completion.

## Scope bookkeeping

The Accrue mobile timeline “ID”/UUID comment was transferred to the Accrue session and removed from Lockspire's feedback recording at the user's request. Do not reintroduce it here. Prior Overview/tooltip/theme/favicon work and any remaining queue-history follow-up are recorded in the review snapshot. The current feedback supersedes screenshots that previously looked acceptable; do not claim earlier proof verifies a later source change.

## Evidence and boundaries — October 13, 13:17 EDT

All 17 items in this batch are implemented. This marks the feedback batch, not Phase 153 or the milestone complete.

- **Shared container / alignment fixes:** narrowed row-container styles to direct list links; nested links use their own typography. Overview review links retain explicit themed colors and grid layout. Overview inner rows, client rows, key rows, and shared metric stats no longer use nested card surfaces. Client lifecycle and registration-source badges occupy two fixed columns: all five rows start at x=826 / x=930 on desktop and x=48 / x=152 on mobile. Key dates use the same four columns on desktop, two at intermediate widths, one on mobile; optional missing dates are omitted rather than displayed as repeated “Not recorded”.
- **Settings and explanations:** security index is an aligned list of title / saved default / description / destination. Friendly values replace raw atoms; explicit app choices are distinguished from effective protocol enforcement. An active setup token is not advertised as usable when registration is off. PAR/DPoP/security summaries share flat, sentence-case metric styling. Full security requirements, registration options, JWT authentication details, and combined registration preview use native disclosures. All 10 registration fields remain available with the same validation and save handlers. Mobile subnavigation wraps without page overflow.
- **Key generation:** the enclosing giant card and Total keys metric were removed. Prepared/upcoming is explained as not active, with publish/activate as separate steps. Encryption help identifies encrypted authorization-request use and distinguishes it from signing. The generation notice is spaced within a dedicated result group and links to the newly generated key through **Continue key setup** only after its refreshed inventory presence is confirmed. Existing test-fixture generation verified this path; no key was generated, published, activated, or retired through browser QA.
- **Shared time display:** UTC / Local control uses the same native select component as Theme. Readable timestamps display an explicit zone and preserve their exact ISO instant in semantic time attributes / copy buttons. Raw DateTime values reach the shared component so fractional seconds are not lost. The saved Local choice survived full navigation and the app-registration Reload status LiveView patch. Pointer and keyboard activation copied exact UTC ISO text; final clipboard read matched `2026-10-13T17:14:51.691716Z`. Missing and redacted values do not become copy controls. Clipboard rejection has a truthful manual-copy fallback, reviewed in source; permission denial was not simulated in browser QA.
- **Language and introductions:** visible navigation/page titles now use **Sign-in requests** and **App sign-out notices**, preserving internal route/event identifiers and read-only queues. App registration uses the shared unboxed page introduction, groups Reload status with it, and leaves a measured 24px margin before the following content.
- **Independent review:** two authorized existing reviewers checked source semantics/accessibility and layout. Addressed their findings: direct Overview-link specificity, saved-policy versus actual-enforcement copy, and timestamp precision at legacy callers. Reviewers did not edit source; visual proof came from the live demo.
- **Fresh checks after final source changes:** `268 tests, 0 failures` across admin LiveViews/router/adoption-demo contract tests; Docker path dependency compiled; `adoption demo smoke passed`; `git diff --check` passed. Existing demo-module warnings in the standalone test process remain. No new dependency or detector suppression was added. The previously recorded unrelated decision-summary border finding is not part of this batch.
- **Live sizes:** nine affected routes captured at 1512px and 390px with document width equal to viewport. Clients / Keys / Security also checked at 820px. Dark mobile Keys / Clients checked after final alignment updates. Native disclosures opened and closed with Enter; timestamp copying verified with Enter. Header ended at System theme / UTC times with default viewport restored. Review page is still `http://lockspire-ui-review.localhost/lockspire/admin/policies`.

Updated captures in `tmp/admin-ui-polish/v1.42/feedback-pass/`:

- `layout-system-overview-desktop.png`
- `layout-system-clients-desktop.png` / `layout-system-clients-mobile-dark.png`
- `layout-system-policies-desktop.png` / `layout-system-policies-mobile.png`
- `layout-system-keys-desktop.png` / `layout-system-keys-mobile-dark.png`
- `layout-system-registration-rules-desktop.png` / `layout-system-registration-rules-mobile.png`
- `layout-system-security-requirements-desktop.png` / `layout-system-security-requirements-mobile.png`
- `layout-system-app-registration-desktop.png` / `layout-system-app-registration-mobile.png`
- PAR and token-proof captures use `layout-system-request-settings-*` / `layout-system-token-proof-*`.

Phase 153 remains active: finish outstanding plan reviews/summaries and phase verification. Phase 154 owns broader cross-surface zoom/screen-reader/adverse-state acceptance. Resume with `$gsd-execute-phase 153`; do not repeat this verified feedback batch. New feedback should receive its own unchecked entry and evidence before closure.
