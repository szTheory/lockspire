# Phase 160 — UI Review

**Audited:** 2026-10-19
**Baseline:** Abstract 6-pillar standards (no UI-SPEC), plus PRODUCT.md vocabulary map and personas, AGENTS.md Admin UI Copy rules, and the sibling page `policies_live/security_profile.ex`
**Screenshots:** Not captured (no dev server on 3000, 5173 or 8080; embedded library). This is a code-level audit, so visual claims come from reading CSS and markup and were not seen rendered.
**Interaction captures:** off (workflow.ui_interaction_capture is false). Interaction findings are code-derived.
**Tests run:** vocabulary_contract_test, keys_live_test and keys_live/ on 1.19.5-otp-28: 38 tests, 0 failures.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Vocabulary-compliant and honest. "Unknown" never reads healthy. Gaps: no consequence line for danger or invalid-config states, ambiguous "those keys", and command text in the refusal error is not marked as a command |
| 2. Visuals | 2/4 | `<code>` commands inside `decision_summary` have no style rule. The only status cue besides text is a 1px left border. First in-product use of the component |
| 3. Color | 3/4 | Tones map sensibly (success, info, warning, danger). Neutral for Unknown is correct. Border-only tone is weak, and there are no hardcoded colors |
| 4. Typography | 3/4 | All type uses design tokens. Long state names render at display-heading size and wrap awkwardly |
| 5. Spacing | 3/4 | Token-based and consistent. No new spacing values. The single item stretches full width |
| 6. Experience Design | 3/4 | Failure isolation is good and fail-closed. No in-page retry for Unknown, and Generate stays enabled in Not set up (deliberate, D-09) |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Command pointers are unstyled** (WARNING) — `index.ex:60` renders `<code>{command}</code>` inside `.lockspire-admin-decision-summary__extra`, but the only `code` rules in admin_css.ex (lines 549-551, 1515) are scoped to `.lockspire-admin-card`, `-detail-section`, `-form-shell` and `-secret-reveal`. The commands operators must copy (`mix lockspire.gen.kek`, `mix lockspire.keys.reencrypt`, `mix lockspire.doctor.key_encryption`) are likely to look like body text — add a `.lockspire-admin-decision-summary code` rule using the existing mono-code tokens, or reuse `.lockspire-admin-code-block` (admin_css.ex:2759).
2. **Danger and invalid-config copy states no consequence** (WARNING) — "Some keys cannot be read" (`protection.ex:97-100`) and "The key-encryption key setup is not valid" (`protection.ex:120`) do not say what is affected (signing, token verification, new keys). PRODUCT.md principle 3 and the "Rotate" row require consequences in plain words. Add one sentence, for example "Tokens signed with those keys may stop verifying," only if true, otherwise "Lockspire cannot use those keys." Also say what to do for invalid config beyond "run doctor."
3. **Refusal error shows the command as plain text and lacks structure** (WARNING) — `index.ex:276-286` puts "mix lockspire.gen.kek" in a single prose sentence inside `<li>`, while the Key protection line shows commands in `<code>`. The same fix, two presentations. Either render the command via a `<code>` span in the template (move the copy into HEEx) or split into two list items: the fact, then the action. Also: the sentence "Lockspire will not store private keys unencrypted" appears in both the signing and encryption variants, so the two functions can collapse into one with an interpolated key label.

Further minor items are listed under each pillar.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

What passes:
- Every user-visible term matches the PRODUCT.md vocabulary map. "key-encryption key" is used consistently, bare "encryption key" is never used for the KEK, and "KEK" appears only inside command names (`protection.ex`, `index.ex:276-286`). The seven state labels match the map row at PRODUCT.md:142 exactly.
- Could-not-check (`protection.ex:125-133`) is the strongest copy here: value "Unknown", and detail "This does not mean your keys are protected or unprotected." It cannot be read as healthy.
- Not-set-up copy follows D-03: it does not promise existing keys keep working, which contradicts the boot-time log warning ("Existing signing keys keep working") and is the more honest of the two.
- Disclosure is limited to the current key-encryption key id; no counts, env var names or config text.
- Generic-label scan: no "Submit", "OK", "Click here" or "Something went wrong" in the touched code. The catch-all error ("The signing key could not be generated.") is pre-existing and deliberately unchanged.

Findings:
- WARNING `protection.ex:97-100` (unreadable): "Lockspire cannot open some stored private keys with the key-encryption keys it has." says the cause but not what the operator loses. The least technical persona on this page cannot tell whether sign-in is broken. "Do not delete them" is good and should stay.
- WARNING `protection.ex:120` (invalid config): "The key-encryption key setup is not valid." names no object, no effect and no hint (no hint is deliberate for disclosure, but a consequence line such as "Lockspire cannot use it until it is fixed" is safe).
- WARNING `protection.ex:77`: "Lockspire can still read those keys." — "those keys" has no antecedent because the value label is the only context ("Encrypted, some with an older key-encryption key"). Say "Lockspire can still read the keys that use an older one."
- WARNING `protection.ex:88`: "usually because an older Lockspire version created them" asserts a cause the code cannot know. PRODUCT.md says "describe what Lockspire actually does". Drop the cause or say "for example, keys created before key encryption was added."
- WARNING `protection.ex:110` / `index.ex:279`: "add it to your app's configuration" omits that the key must be stored as a secret and the app restarted with it available; the `gen.kek` task prints that snippet, so "follow the printed instructions" would be more accurate than a vague "configuration." Minor.
- Minor: dd values "Encrypted" vs "Unknown" vs "Not set up" are short noun-like states, but "Some keys are stored unencrypted" is a sentence. Mixed register; acceptable.
- Minor: the Not-set-up detail says "with the command below" but the command is only shown when the `<code>` renders (it does). Fine, but a 'no-CSS/text-only' reader depends on that adjacency.
- Not-set-up copy on the Keys page is repeated across three surfaces (state line, refusal error, hero text silent). The refusal error and the state line say nearly the same thing; once set up is missing, an operator sees both. Acceptable but repetitive (PRODUCT.md: "avoid repeated explanations").

### Pillar 2: Visuals (2/4)

- WARNING (main defect): `<code>` in `.lockspire-admin-decision-summary__extra` has no admin style (admin_css.ex code rules are scoped to card/detail/form-shell/secret-reveal, lines 549-551 and 1515). The command, which is the single actionable element in four states, has no visual affordance. Not verified by screenshot; if the host's CSS styles `code` globally it may look different, but Lockspire scopes its styling to the embedded surface, so it cannot rely on that.
- WARNING: This is the first use of `decision_summary` anywhere in `lib/` (`grep` finds only `index.ex:58`). The sibling security page uses `section_card` with a title and bold "Status:" / "What we checked:" lines. The two are inconsistent: Keys gets an uppercase tiny label ("KEY PROTECTION") plus a display-size value, and no card. It is defensible and arguably stronger as a glance line, but it is a new pattern with no CSS hook of its own (`.lockspire-admin-key-protection` has no rule in admin_css.ex).
- Markup: `decision_summary` puts `<p>` and `<div>` as siblings of `dt`/`dd` inside the `<div>` within `<dl>`. This is invalid HTML (pre-existing component, first exercised here), and screen readers may read the detail and command outside the definition. Not introduced by this phase but exposed by it.
- Focal point: the protection line sits directly under `page_hero` and above the inventory. Hierarchy is clear. For an Unknown state with a neutral border it blends with the page, which is arguably intended but gives it less salience than the warning states.
- No icon-only controls were added; no aria-label gaps. `section aria-label="Key protection"` duplicates the dt label (harmless).

### Pillar 3: Color (3/4)

- Tone mapping (`protection.ex`): encrypted success, older key info, unencrypted warning, unreadable danger, not set up warning, invalid config warning, could-not-check neutral. This is coherent. Neutral for Unknown meets the "never healthy" requirement because the `-success` class is never applied.
- WARNING: The sole color signal is `border-left: 1px` (admin_css.ex:1658-1672). Color is not the only cue (the text carries meaning, which meets the non-color-only rule), but the tone is so thin that warning/danger/info look nearly identical at a glance, and the surface is the shared `--ls-surface-muted` for all of them. Compare to `alert` variants (`alert_class`) which tint the whole box. A danger state ("Some keys cannot be read") deserves a more visible treatment than a 1px border.
- Judgement call: "Not set up" is `:warning` even though the app cannot create keys at all. Defensible (nothing is broken, a step is missing), and consistent with the sibling pattern.
- No hardcoded colors (hex/rgb) in the touched files; all through tokens.
- Accent distribution: no accent colors are added by this phase.

### Pillar 4: Typography (3/4)

- No new font sizes or weights. The line uses the existing decision_summary tokens: `--ls-type-label-size` uppercase semibold label, `--ls-type-heading-size` display value, label-size muted detail.
- WARNING: The value slot is display-heading size, so "Encrypted, some with an older key-encryption key" (48 chars) and "Some keys are stored unencrypted" are rendered as large headings, wrap with `overflow-wrap: anywhere`, and compete with the page title. The detail paragraph is label-size (small) for the most important instructional text, including the "Do not delete them" warning. Consider shortening the value labels, or moving the long qualifier into the detail.
- The key-encryption key id is interpolated in straight quotes into prose, not in a mono style, so long ids (operator-chosen) blend into the text. Minor.

### Pillar 5: Spacing (3/4)

- No arbitrary spacing values; no new CSS added by the phase. Spacing comes from `--ls-space-3/4/5` tokens in the existing component (admin_css.ex:1638-1700).
- `margin: 0 0 var(--ls-space-5)` on the summary places the line consistently above the inventory section.
- Minor: `grid-template-columns: repeat(auto-fit, minmax(180px, 1fr))` makes the single item stretch the full width, so it reads as a banner rather than a stat tile; fine, but the detail text is then a long line at wide viewports (no max-width). On narrow screens it collapses to one column cleanly.
- Not verified at 375/768/1440 widths because no screenshots were captured.

### Pillar 6: Experience Design (3/4)

- Strong: Protection loading is independent of inventory (`index.ex:57`, `index.ex:187`): a failed check never hides the key list, and a failed inventory never hides protection. Every error, raise or exit collapses to Unknown (`index.ex:192-198`), the presenter is total (`summarize(_other)`), and the raw status map never reaches the assign.
- Refresh after a successful generate (`index.ex:223`), so the line cannot go stale on the same page.
- Refusal error uses the existing `ul.lockspire-admin-errors[role=alert]`, not a flash, so it is announced and persists next to the button that caused it. The clear-on-next-action behavior reuses existing assigns.
- WARNING: Unknown offers "Reload the page to try again" but no control, while the inventory error state has a "Try loading signing keys again" button wired to the same `retry_inventory` event (which already reloads protection). Asymmetric, though read-only was a deliberate constraint (D-07).
- WARNING: In Not set up, Generate signing key / Generate encryption key stay enabled and the operator learns of the problem only after clicking (D-09 chose this). The state line above already explains it, so the flow is recoverable. A disabled button with a reason would be better for a first-time adopter, but it was ruled out of scope.
- Minor: while `inventory_state == :loading` the protection line is already loaded (loading is synchronous in `handle_params`), so no flicker.
- Minor: `key_protection: nil` hides the section when mount has not yet assigned. Because `handle_params` always loads it, nil only occurs in the bare-socket tests.

---

## Files Audited

- /Users/jon/projects/lockspire/lib/lockspire/web/live/admin/keys_live/index.ex
- /Users/jon/projects/lockspire/lib/lockspire/web/live/admin/keys_live/protection.ex
- /Users/jon/projects/lockspire/lib/lockspire/web/components/admin_components.ex (decision_summary, tone classes)
- /Users/jon/projects/lockspire/lib/lockspire/web/admin_css.ex (decision-summary, errors, code rules)
- /Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/security_profile.ex (sibling pattern)
- /Users/jon/projects/lockspire/lib/mix/tasks/lockspire.gen.kek.ex (command accuracy)
- /Users/jon/projects/lockspire/PRODUCT.md, /Users/jon/projects/lockspire/AGENTS.md
- Phase 160 CONTEXT, PLAN and SUMMARY files
