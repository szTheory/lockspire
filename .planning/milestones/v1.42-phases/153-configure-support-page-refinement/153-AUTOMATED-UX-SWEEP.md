# Phase 153 autonomous UX sweep

Verified 2026-10-14T00:34:01Z (October 13 evening EDT). Phase 153 remains active; this closes this feedback batch, not the whole phase or milestone.

## User intent and standing method

The user asked us to extrapolate their feedback, find low-hanging issues across screens, and reduce repeated manual feedback. Future UI work defaults to a bounded autonomous pass: inspect routes and relevant states, group findings by the shared component or workflow, implement one coherent batch, confirm it in desktop/mobile, and preserve evidence. Do not ask the user to rediscover consistency, spacing, useful-copy, control-choice, validation, or terminal-state defects that source review, rendered inspection, or deterministic checks can establish. Subjective preferences remain optional feedback, not a required acceptance checkpoint. Avoid endless cosmetic iterations, extra dependencies, or per-page patches to shared problems.

This pass used Impeccable Operate/clarify/distill/layout/harden guidance and the two previously authorized isolated reviewers. The reviewers covered interaction/error truth and content/design hierarchy. Billingo is synthetic demo data. No browser policy save, credential generation/rotation, key transition, or revocation was performed. Existing worktree changes were preserved.

## Changes and durable regression coverage

| Finding | Resolution | Evidence |
|---|---|---|
| Lifetime errors sound like changeset output | Inline errors now tell the user what to enter, including whole-second examples. Summaries retain the field label; inline messages do not repeat it. | DCR invalid-submit/edit tests; negative, fractional, overflow browser proof with values/focus retained |
| Lifetime fields offer no useful decision guidance | Explain seconds examples, new-registration scope, when to leave fields blank, and match a positive secret duration to the app team's replacement schedule. State actual enforcement limits. | DCR rendered tests, desktop/mobile screenshots, source trace in `153-LIFETIME-TRUTH.md` |
| Small fixed single-choice client settings are hidden behind selects | Client type, authentication method, token proof/format, PAR and security requirements now use the shared native radio group. Preserve original values, inheritance, save events and effective preview. | Client LiveView save/validation/inheritance tests; keyboard ArrowUp and live preview browser proof |
| Repeated selected/default/status summaries | Remove repeated selected-setting lines and duplicate client status/provenance badges. Preserve the one entity status and meaningful default/result differences. | Client detail/edit regression suite and captures |
| Broken relative repository-document help link | Replace it with concise inline JWT/opaque guidance beside token format. | All 60 final route checks report no unserved `docs/*.md` links |
| Help/error text disconnected from client URL fields | Associate both instruction and error IDs and use explicit ARIA invalid values; show the same translated error as the summary. | Client field error tests and final rendered reference checks |
| Revoke UI remains on already-revoked consent | Hide the unavailable form and checkbox; keep a concise outcome and real success notice. Remove duplicate badge rows, absent revocation fields, and stale pre-revocation instructions. | Consent active/revoked/missing/error/repeat-action tests; revoked fixture browser capture |
| Nested and repeated confirmation headings | Shared confirmation panels support embedded composition and omit duplicate headings. Secret rotation retains consequence and copy-once guidance. | Consent/key/secret-rotation tests and captures |
| Key detail falsely speaks as if every key signs tokens | Name the page Key details; branch publishing, activation, errors and next steps by signing/encryption use. Omit missing dates, unavailable next steps and empty action cards. | Key lifecycle tests include an encryption fixture; active/upcoming signing fixtures rendered in browser |
| Setup-token error appears on unrelated rows | Tie unchecked confirmation errors to one known active token; malformed/unknown/read failures stay global. Clear target errors after reload/success. | Two-active-token regression proves row scope and no mutation; IAT suite |
| Adjacent task cards and mobile empty-state actions crowd each other | Give direct entity-header/task-section siblings the shared 24px separation; mobile empty-state actions stack. Consent detail uses the shared detail-stack rhythm. | Final desktop/mobile task captures and source layout checks |
| Thick side accent on shared summaries | Reduce the existing 3px side border to 1px without changing status meanings. This was found in existing source, not asserted to be a session regression. | Final Impeccable source detector `[]`; no border-rule ignore added |

## Rendered and executable evidence

- **305 Elixir tests, 0 failures**: `mix test test/lockspire/web/live/admin test/lockspire/web/admin_router_test.exs test/lockspire/adoption_demo_docker_contract_test.exs test/lockspire/admin/server_policy_test.exs` under Elixir 1.19.5/OTP 28.4.1.
- **6 Node tests, 0 failures**: `node --test test/browser/admin_multi_value_test.mjs`, covering list parsing/deduplication, pending request acknowledgements and exhausted suggestions. This exact command now runs in the existing CI Release Hygiene Drift job with no added action/dependency. Local `actionlint -no-color .github/workflows/ci.yml` passed; no hosted CI run was triggered. The workflow uses the existing single-command step convention, checked against [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsrun).
- Final demo dependency compiled; web container restarted; **adoption demo smoke passed** on `http://lockspire-ui-review.localhost`.
- Final source formatting check and `git diff --check` passed. Existing root-suite warnings about unloaded adoption-demo controller modules remain outside this batch; do not describe the whole suite as warning-free.
- Impeccable detector on the changed source returned **`[]`** after the shared-border adjustment. The older gallery’s `overused-font=inter` finding was triaged as intentional incumbent typography. Persisted that narrow value ignore in `.impeccable/config.json` with an agent-decided scope/identity reason, not a claim that the user separately confirmed the font. No file/rule suppression or new dependency.
- All **30 routes** captured before and after on desktop (1512×982); final **30 mobile** captures at 390×844. Each final rendered check has one H1, document width equal to viewport, no dangling help/error IDs, valid ARIA-invalid strings, and no relative repository-document links.
- Live interactions: DPoP/opaque radio selection updates effective previews without saving; ArrowUp changes a native radio and its preview; focused Escape → click reopens suggestions; exhausting known scope suggestions yields **Add a custom value…** while custom values remain allowed; all three lifetime errors retain entered values and focus; shared setup-token timestamps honor Local then restore UTC.
- Representative full images were inspected for client forms, client PAR/rotation, active/revoked consent, active/upcoming keys, DCR guidance/errors and dark mobile DCR. Route-wide DOM/geometry checks supplement this review; screenshots alone do not prove every keyboard sequence or screen-reader announcement.
- Browser edits were limited to unsaved QA drafts. UTC/System preferences and viewport were restored. The user's previously edited tab was not reloaded.

Evidence directory: `tmp/admin-ui-polish/v1.42/autonomous-sweep/`. `gallery.html` compares each screen; `confirmation-manifest.json` contains the 60 final rendered checks; `interactions/` contains state and interaction proof. These local proof images are not a new production UI or public publication.

## Source truth and remaining scope

**Lifetime expiry is not implemented as the labels previously implied.** App lifetime and app-management-token lifetime are stored/resolved without built-in expiry enforcement. Client-secret lifetime sets reported expiry metadata, but authentication does not enforce it; blank/zero currently report the registration instant. The UI states these limits and does not promise automatic expiry. The trace is in `153-LIFETIME-TRUTH.md`; implementation/semantics work remains in the existing pending protocol todo. No backend/security behavior was silently changed.

This batch is accepted by executable/rendered evidence. Do not reopen it as manual UAT or repeat the user interview. Finish outstanding Phase 153 plan reviews/summaries and phase verification with **`$gsd-execute-phase 153`**. Phase 154 retains whole-milestone zoom, screen-reader and broader adverse-state acceptance; this artifact does not claim that work completed. CR-01 remains a separate unresolved signing-key-at-rest issue.

## Route coverage

Both final desktop and mobile capture/check cover each row below. The two Overview entry routes are deliberately included separately.

| Screen | Path |
|---|---|
| Edit client settings | `/lockspire/admin/clients/billingo-reports-backend/edit` |
| Set authorization request rules | `/lockspire/admin/clients/billingo-reports-backend/par-policy` |
| Update client security profile | `/lockspire/admin/clients/billingo-reports-backend/security-profile` |
| Rotate client secret | `/lockspire/admin/clients/billingo-reports-backend/rotate-secret` |
| Update sign-in return URLs | `/lockspire/admin/clients/billingo-reports-backend/redirects` |
| Update sign-out return URLs | `/lockspire/admin/clients/billingo-reports-backend/logout-uris` |
| Update sign-out notifications | `/lockspire/admin/clients/billingo-reports-backend/edit?workflow=logout-propagation` |
| Overview | `/lockspire/admin/` |
| Overview | `/lockspire/admin/overview` |
| Clients | `/lockspire/admin/clients` |
| Create client | `/lockspire/admin/clients/new` |
| Security settings | `/lockspire/admin/policies` |
| Keys | `/lockspire/admin/keys` |
| App registration | `/lockspire/admin/dcr` |
| Consent grants | `/lockspire/admin/consents` |
| Tokens | `/lockspire/admin/tokens` |
| Sign-in requests | `/lockspire/admin/interactions` |
| Device authorization requests | `/lockspire/admin/device_authorizations` |
| App sign-out notices | `/lockspire/admin/logouts` |
| Authorization request settings | `/lockspire/admin/policies/par` |
| Default security settings | `/lockspire/admin/policies/security-profile` |
| Token proof settings | `/lockspire/admin/policies/dpop` |
| App registration settings | `/lockspire/admin/policies/dcr` |
| Client details | `/lockspire/admin/clients/billingo-reports-backend` |
| Key details | `/lockspire/admin/keys/1` |
| Consent grant details | `/lockspire/admin/consents/1` |
| Token details | `/lockspire/admin/tokens/3` |
| App setup tokens | `/lockspire/admin/iats` |
| Create app setup token | `/lockspire/admin/iats/new` |
| Rotate registration token | `/lockspire/admin/clients/northstar-payables-portal/rotate-registration-access-token` |
