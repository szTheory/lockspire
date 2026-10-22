# Phase 165 — UI Review

**Audited:** 2026-10-22 (current source refresh)
**Baseline:** PRODUCT.md personas and vocabulary; Phase 165 UI scope; no UI-SPEC.md
**Scope:** Host recovery confirmation and one-time disclosure, plus DCR management-token expiry policy copy and duration hint
**Screenshots:** Not captured — source and mounted LiveView tests reviewed; no rendered visual inspection claimed
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Recovery and expiry guidance is accurate and operator-oriented; the unconfirmed submission still reports the generic detail “confirmation required.” |
| 2. Visuals | N/A | Source shows a danger action, task shell, and one-time panel, but no screenshot was captured to assess hierarchy or fit. |
| 3. Color | N/A | Semantic danger styling is visible in source; rendered colors and contrast were not inspected. |
| 4. Typography | N/A | Shared components define the affected type, but rendered scale and hierarchy were not inspected. |
| 5. Spacing | N/A | Existing shared layout components are used; responsive and zoom behavior were not inspected. |
| 6. Experience Design | 4/4 | Mounted LiveView coverage exercises confirmation, committed one-time disclosure, clearing, failed/stale recovery, and app-lifecycle preservation. |

**Overall:** 7/8 across the two scoped, scored pillars. Visual pillars are unscored because no current rendering was captured.

---

## Top 3 Recommendations

1. **Replace “confirmation required” with a direct instruction** — when an operator submits without checking the box, the message does not explain what to confirm — say “Confirm that the previous app management token should stop working immediately.” This is a copy-quality recommendation, not a recovery-flow blocker.
2. **Inspect the one-time token panel at narrow widths and zoom** — long registration URLs and credentials need to remain visible and copyable — capture the recovery page at mobile width and high zoom when visual capture is available.
3. **Inspect the duration hint announcement during typing** — the hint uses `aria-live="polite"` and invalid input removes it while validation owns the error — check announcement behavior with a screen reader and rendered form states. No current failure is established by the available evidence.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- The recovery page tells the provider operator that the old token stops working immediately, identifies the registration URL, explains provider-team recovery after a lost update response, and says rotation does not enable the app or extend app/secret expiry ([show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:767)). This states the operational consequences plainly.
- The one-time panel says the new token is shown once and Lockspire stores only a hash; the checkbox also names the immediate consequence ([show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:795)). The provider operator can understand why the token must be copied before leaving.
- The no-confirmation branch still sets `detail: "confirmation required"` ([show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:232)). The mounted recovery test expects this exact message and verifies no credential is disclosed ([management_token_recovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs:98)). This is the sole copy finding; it is understandable but less actionable than the checkbox's own consequence wording.
- DCR policy guidance now says app, client secret, and app management-token expiry are enforced; it explains prospective settings, blank/zero no-expiry behavior, recovery after access loss or a lost update response, and that recovery does not renew the app or secret ([dcr.html.heex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/dcr.html.heex:121), [dcr.html.heex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/dcr.html.heex:166)). Current behavior and copy agree.
- PRODUCT maps the operator-facing term “app management token” and includes replaced expiry/recovery phrases in the retired-wording table ([PRODUCT.md](/Users/jon/projects/lockspire/PRODUCT.md:126), [PRODUCT.md](/Users/jon/projects/lockspire/PRODUCT.md:172)). No stale deferred-enforcement claim was found in the audited DCR copy.
- The fresh Phase 165 validation receipt reports the mounted UI, routes, copy, vocabulary, guidance, and compatibility selection passed with **70 tests, 0 failures**. It separately reports **84 lifecycle/PostgreSQL/conformance tests, 0 failures**. This review reused that receipt and did not rerun tests.

### Pillars 2–5: Visuals, Color, Typography, and Spacing (N/A)

The source uses the existing section card, danger button, shared action bar, error list, and copy-once panel ([show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:767)). The DCR inputs use shared workflow/form components. These source patterns establish intended structure only; the current rendered hierarchy, contrast, line wrapping, narrow-width fit, and zoom behavior were not captured. The earlier 3/4 source-only estimates are not carried forward as visual scores.

### Pillar 6: Experience Design (4/4)

- The mounted recovery test submits without confirmation, confirms the old credential remains and the new token stays hidden, then verifies the confirmed committed replacement and its expiry ([management_token_recovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs:75)).
- The suite covers one-time disclosure, repeat-submit behavior, acknowledgement and route-departure clearing, and recovery for an expired enabled app without changing app or secret lifecycle state. Disabled state remains preserved ([management_token_recovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs:145)).
- Stale or failed recovery shows no replacement token and retains enough app context to recover safely; tests also preserve the host-only authority boundary ([management_token_recovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs:200)).
- The DCR duration hint distinguishes blank/zero unlimited policies and positive durations; the policy fields retain their existing validation and `aria-live="polite"` hint wiring ([lifetime_hint.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex:10), [dcr.html.heex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/dcr.html.heex:141)). Browser-level announcement behavior was not tested here.

---

## Files Audited

- `AGENTS.md` — admin copy constraints
- `PRODUCT.md` — personas, vocabulary, and retired wording
- `.planning/phases/165-management-token-lifecycle-recovery/165-CONTEXT.md`
- `.planning/phases/165-management-token-lifecycle-recovery/165-01-PLAN.md` through `165-07-PLAN.md` and corresponding summaries
- `.planning/phases/165-management-token-lifecycle-recovery/165-UI-REVIEW.md` — prior review and current refresh baseline
- `lib/lockspire/web/live/admin/clients_live/show.ex`
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`
- `lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex`
- `test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs`
- `test/lockspire/web/live/admin/clients_live/show_test.exs`
- `test/lockspire/web/live/admin/policies_live/dcr_test.exs`
- `test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs`
- `test/lockspire/web/live/admin/vocabulary_contract_test.exs`
- `/tmp/phase165-validation-refresh-20261022.md` — fresh focused validation receipt
