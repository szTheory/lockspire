# Phase 116 Visual And UX Rubric

`brandbook/` is the canonical visual, token, and identity source for this milestone. Older prompt guidance is subordinate when it conflicts with `brandbook/`, and can only inform voice or workflow judgment where it agrees with the brandbook.

This rubric is a pass/fail contract for Phase 117-120 work. Phase 116 records the gates; it does not change CSS, install packages, add runtime routes, or redesign production pages.

## Pass/Fail Gates

| Gate | Pass condition | Fail condition |
|------|----------------|----------------|
| Architectural structure | Admin screens read as structured trust: clear panes, rows, lifecycle groups, entity headers, status/action clusters, and workflow shells. | Decorative security-console tropes, random panels, threat maps, or novelty layouts obscure the operator job. |
| Restrained Signal Cyan `#22d3ee` | Signal Cyan is role-bound to dark/hero/focus/non-text accents and large non-text emphasis. | Signal Cyan is used as normal light-mode body text, small controls, generic decoration, or neon-cyan overload. |
| Deep Cyan `#0e7490` | Light-mode text links, action text, and primary button fills use contrast-safe Deep Cyan or darker cyan tokens. | White or body text is placed on low-contrast cyan, or `#22d3ee` becomes light-mode text. |
| Semantic alias dark-mode remapping | Dark mode remaps semantic aliases such as surfaces, text, border, status, focus, and shadow while primitive colors remain stable. | Component-specific primitive inversion or one-off dark-mode fixes replace token discipline. |
| Light/dark/system parity | System is default, Light and Dark are first-class, and routes remain legible and operable in each mode. | A route works only in one theme, hides focus, loses status contrast, or changes layout meaning by theme. |
| Visible focus | Keyboard focus is visible, offset, and contrast-safe on controls, links, destructive actions, copy-once panels, and long-value affordances. | Focus is removed, color-only, clipped, or invisible on either light or dark surfaces. |
| Reduced-motion safety | Motion respects reduced-motion preferences and is used only for orientation, feedback, or state continuity. | Auto-playing, parallax, decorative, or required motion appears; reduced-motion users still receive movement. |
| Non-color status cues | Status badges and state clusters include text labels, icons/shape where useful, and semantic copy. | Color alone communicates success, warning, danger, disabled, pending, expired, revoked, or reuse-detected states. |
| No generic security tropes | Copy and visuals use Lockspire's faceted/architectural identity and OAuth/OIDC nouns. | Generic shields, locks, military language, threat-center metaphors, or fear-led copy lead the interface. |
| Accessibility floor | AA contrast, keyboard reachability, accessible labels/descriptions, no duplicate IDs, and screen-reader-usable errors are present. | An operator cannot complete or understand a route by keyboard and assistive technology. |
| Responsive floor | No page-level overflow at narrow widths; long URLs, scopes, identifiers, hashes, handles, and token-like values wrap or use `long_value`. | Horizontal page scrolling, clipped identifiers, or unreadable dense rows appear at mobile widths. |
| Redaction floor | No secret evidence appears in fixtures, docs, tests, screenshots, logs, or lab states. | Client secrets, token plaintext, authorization codes, cookies, private keys, verifier material, user codes, or unredacted sensitive values appear outside copy-once safe placeholders. |
| Destructive floor | Destructive actions name the durable consequence and use existing confirmation patterns. | A new destructive runtime action is introduced by design-system polish, or consequence copy is vague. |

## Journey-Specific Gates

| Journey | Job | Pass condition |
|---------|-----|----------------|
| Orient | What needs attention? | Overview surfaces attention, posture, live work, and next workflow without alarmist copy. |
| Configure | What posture should change? | Client, policy, key, DCR, IAT, endpoint, credential, and logout-propagation routes make the current posture and next safe action explicit. |
| Support | What happened to an account, client, token, or grant? | Consents and tokens prioritize investigation context, filters, long values, revocation consequence, and redaction. |
| Operate | What live protocol work is waiting or failing? | Interactions, device authorizations, and logouts show queue state and read-only support truth without inventing unbacked controls. |

## Brandbook Translation

- `brandbook/tokens/tokens.json` and `lib/lockspire/web/admin_css.ex` should keep the same `--ls-*` vocabulary.
- Signal Cyan `#22d3ee` is the dark/hero/focus/non-text signal accent.
- Deep Cyan `#0e7490` is the light-mode action and text accent.
- Dark mode uses semantic alias dark-mode remapping, not primitive color inversion.
- Light/dark/system parity is a product requirement, not a visual preference.
- Visible focus, reduced-motion safety, non-color status cues, and contrast-safe status tokens are hard gates.
- Contract keywords for later proof: light/dark/system parity, visible focus, reduced-motion safety, non-color status cues, no generic security tropes, no secret evidence, and no page-level overflow.

## Security And Evidence Floors

Later lab, screenshot, and browser proof must avoid secret evidence. Banned plaintext evidence includes client secrets, registration access token plaintext, initial access token plaintext after creation, refresh/access token plaintext, authorization codes, cookies, private keys, verifier material, user codes, and unredacted sensitive values.

No page-level overflow is allowed in later proof. Long protocol values should wrap through layout, `long_value`, code-block, table/list alternative, or resource-row patterns rather than font scaling.

## Tooling Boundary

PhoenixStorybook is rejected/default-deferred for Phase 116. It may be reconsidered only if a later lab grows beyond the lightweight Lockspire-owned proof surface. Phase 116 does not add package-install instructions, a React/JS Storybook shell, public theming, or a host-editable registry.
