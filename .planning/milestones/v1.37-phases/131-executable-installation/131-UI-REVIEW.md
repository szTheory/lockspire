# Phase 131 — UI Review

**Audited:** 2026-08-26  
**Baseline:** `131-UI-SPEC.md`  
**Re-audited:** after `85b79ee` (`fix(131): polish generated consent semantics`)  
**Screenshots:** not captured (code-only audit; browser/Playwright capability was unavailable). A service responded on port 3000, but this audit could not establish it as the generated-host fixture or safely capture an authenticated consent interaction.

---

## Scope and Evidence

This review covers only the generated host consent LiveView and its exact executable fixture. The admin/operator surface is explicitly out of scope.

The installer template is byte-identical to the executable fixture under `test/integration/install_generator_test.exs:449-462`. The re-audit ran:

- `mix test test/integration/install_generator_test.exs` — 12 tests passed.
- `mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` — 4 tests passed.

Those tests execute loading, resolved populated/empty states, native approve completion and token exchange, redacted error/terminal states, and the new unavailable-client/semantic-hook/long-text assertions. Visual token, contrast, and viewport conclusions remain limited by the unavailable host stylesheet and browser capture.

---

## Re-audit Disposition

| Previous warning | Status | Evidence |
|---|---|---|
| Unavailable client wording did not preserve the safe-deny copy. | **CLOSED** | `priv/templates/lockspire.install/consent_live.ex:102-106` now renders the approved standalone sentence; the generated-host test asserts it at `test/integration/phase6_onboarding_e2e_test.exs:385-386`. |
| Primary/destructive actions and UI states had no stable host-semantic styling hooks. | **CLOSED** | Host-owned status, alert, header, sections, lists, action-group, and primary/destructive action classes are emitted at `consent_live.ex:70-177`; the fixture test asserts the key hooks at `phase6_onboarding_e2e_test.exs:387-391`. |
| Long client/scope/detail values had no wrapping guarantee. | **CLOSED** | The generated template applies `overflow-wrap: anywhere` to each rendered long-text value at `consent_live.ex:97-99`, `:115-117`, and `:126-128`; the fixture test renders long unbroken values at `phase6_onboarding_e2e_test.exs:362-394`. |
| Actual host CSS, contrast, focus presentation, and narrow-viewport rendering were unproven. | **OPEN — WARNING** | No installed host stylesheet or browser capture was available to evaluate the host-owned implementation of the generated semantic hooks. |
| Hosts needed a documented mapping contract for the new semantic hooks. | **CLOSED** | `docs/install-and-onboard.md` now maps shell/state/hierarchy/action/wrapping hooks to host-owned roles and calls out focus, touch-target, contrast, and wrapping obligations. |

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | The formerly misleading unavailable-client fallback is corrected and covered by a rendered-fixture test. |
| 2. Visuals | 3/4 | The structural hierarchy and host hooks are now clear; actual hierarchy, focus treatment, and rendering remain unobservable without host CSS/screenshots. |
| 3. Color | 3/4 | Primary/destructive semantic hooks correctly separate approve and deny without a Lockspire palette; contrast and the host 60/30/10 implementation are not measurable here. |
| 4. Typography | 3/4 | Semantic heading/body/list structure and long-text wrapping are present; real host font roles and line-height are not observable. |
| 5. Spacing | 3/4 | Header, section, list, action-group, and remember-choice hooks let the host apply the approved scale; actual spacing/touch target measurements are not observable. |
| 6. Experience Design | 4/4 | Executed state coverage shows safe loading, populated/empty, submitting, error, terminal redirect, redaction, and controller-owned completion behavior. |

**Overall: 20/24**

---

## Top 3 Priority Follow-ups

1. **Run a rendered generated-host audit at 375px, 768px, and 1440px** — validates the now-present long-text and grouping seams under real host CSS — capture the consent review, unavailable-client, error, and submission states.
2. **Verify host token mapping and visible focus states** — semantic class names do not by themselves establish contrast or keyboard focus — map `host-consent-action--primary` and `--destructive` to the host's accessible action components/tokens and check contrast.
3. **Keep custom consent edits within the supported seam** — map or replace the documented host-semantic hooks in the generated host file without moving protocol lookup, subject binding, or completion authority out of Lockspire.

These are validation and integration follow-ups, not shipping blockers in the generated consent flow.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

**CLOSED — unavailable client metadata now follows the contract.** The template branches on `@client_name`: named clients retain the normal account-access framing, while missing metadata renders `Application details are unavailable. You can deny this request.` without a raw client ID (`priv/templates/lockspire.install/consent_live.ex:95-106`). The new fixture test proves both the approved copy and absence of the former malformed phrase (`test/integration/phase6_onboarding_e2e_test.exs:385-386`).

Loading, empty-scope, error, and decision copy remain specific and safe (`consent_live.ex:71-74`, `:109-110`, `:182-191`, `:148-175`).

### Pillar 2: Visuals (3/4)

**CLOSED — hierarchy has stable host-owned hooks.** Loading/error shells and regions have explicit variants (`priv/templates/lockspire.install/consent_live.ex:70-86`); the review has header, summary, empty, section, list, and grouped-action seams (`:92-177`). Text-labelled controls and semantic headings/lists maintain a useful document outline without icon-only controls.

**WARNING — visual execution remains unverified.** The source cannot prove focal hierarchy, layout rhythm, focus rings, or rendering against a real host theme. This is the reason for a 3 rather than 4.

### Pillar 3: Color (3/4)

**CLOSED — action semantics now encode the approved distinction without introducing Lockspire colors.** Approve uses `host-consent-action--primary` and deny uses `host-consent-action--destructive` (`priv/templates/lockspire.install/consent_live.ex:148-175`). This keeps token choice in the host while supplying an unambiguous mapping seam.

**WARNING — token application and contrast are host-owned and unobserved.** The source intentionally contains no hard-coded color; therefore the 60/30/10 distribution, destructive/action contrast, and disabled/focus colors require a rendered host audit.

### Pillar 4: Typography (3/4)

**CLOSED — long text has a real rendering safeguard.** Client name, scope, and authorization-detail values use `overflow-wrap: anywhere` (`priv/templates/lockspire.install/consent_live.ex:97-99`, `:115-117`, `:126-128`), and the generated fixture renders long unbroken scope/detail inputs in the new behavioral test (`test/integration/phase6_onboarding_e2e_test.exs:362-394`). Semantic `h1`, `h2`, paragraph, and list elements preserve the intended roles.

**WARNING — actual font sizes, weights, and line heights are host-owned and unobserved.** No visual capture can prove the approved host typography roles are applied.

### Pillar 5: Spacing (3/4)

**CLOSED — the required groupings now have host styling seams.** The header, sections, lists, action group, action forms, and remember choice each have semantic classes (`priv/templates/lockspire.install/consent_live.ex:93-177`). This lets the host apply the approved compact-list, control, section, and page-shell spacing without brittle element selectors; no fixed widths or arbitrary spacing values were introduced.

**WARNING — actual spacing and touch-target measurements are unobserved.** A host CSS/browser audit is still required to prove the stated four-point scale and accessible controls in a real install.

### Pillar 6: Experience Design (4/4)

**PASS — authoritative state and narrow host ownership are preserved.** `mount/3` receives only the route interaction identifier and defers to `ConsentContext.load/2` (`priv/templates/lockspire.install/consent_live.ex:15-33`). The context excludes IDs, redirect URIs, raw authorization details, tokens, and protocol errors (`lib/lockspire/web/consent_context.ex:3-13`). Host code owns presentation; Lockspire retains subject binding, expiry/reuse handling, and completion authority.

**PASS — core state coverage is executable.** Loading is a non-interactive `role="status"` state (`consent_live.ex:68-77`); valid contexts render semantic review/forms (`:90-178`); errors are `role="alert"` and terminal views have no controls (`:79-88`); remembered consent redirects without an intermediate destination page (`:45-47`). Both controls disable during submission and retain the selected progress label (`:133-176`). The focused integration run passed and covers static/connected loading, empty, expiry, subject mismatch, missing interaction, task exit, terminal redirect, redaction, and approval-to-token flow (`test/integration/phase6_onboarding_e2e_test.exs:143-358`).

---

## Registry Safety

Registry audit: skipped — `components.json` is absent and `131-UI-SPEC.md` declares no third-party registry blocks.

---

## Files Audited

- `priv/templates/lockspire.install/consent_live.ex`
- `test/support/generated_host_app_web/live/lockspire_consent_live.ex`
- `lib/lockspire/web/consent_context.ex`
- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`
- `.planning/phases/131-executable-installation/131-UI-SPEC.md`
- `.planning/phases/131-executable-installation/131-03-PLAN.md`
- `.planning/phases/131-executable-installation/131-03-SUMMARY.md`
- `.planning/phases/131-executable-installation/131-07-PLAN.md`
- `.planning/phases/131-executable-installation/131-07-SUMMARY.md`
