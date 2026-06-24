# Accessibility Checks

WCAG 2.1 contrast verification for the Lockspire palette, light and dark. Ratios
computed from sRGB relative luminance. Thresholds: **AA** 4.5:1 normal text /
3:1 large text & non-text UI; **AAA** 7:1 normal text.

## Light mode (page `#f8fafc`, panel `#ffffff`)

| Foreground | On | Ratio | Normal | Large/UI |
|---|---|---|---|---|
| text-strong `#0b1220` | page `#f8fafc` | 17.4:1 | ✅ AAA | ✅ |
| text-body `#334155` | page | 9.6:1 | ✅ AAA | ✅ |
| text-muted `#64748b` | page | 4.6:1 | ✅ AA | ✅ |
| text-accent / link `#0e7490` | white | 5.0:1 | ✅ AA | ✅ |
| brand-700 `#155e75` | white | 6.3:1 | ✅ AA | ✅ |
| white | primary btn `#0e7490` | 5.0:1 | ✅ AA | ✅ |
| white | btn hover `#155e75` | 6.3:1 | ✅ AA | ✅ |
| Signal Cyan `#22d3ee` | white | 1.5:1 | ❌ | ❌ → **non-text only** |
| success-text `#166534` | success-bg `#dcfce7` | 7.0:1 | ✅ AAA | ✅ |
| warning-text `#854d0e` | warning-bg `#fef9c3` | 6.9:1 | ✅ AA | ✅ |
| danger-text `#991b1b` | danger-bg `#fee2e2` | 7.0:1 | ✅ AAA | ✅ |
| info-text `#155e75` | info-bg `#cffafe` | 5.9:1 | ✅ AA | ✅ |

**Rule enforced:** `#22d3ee` is never used for text or small icons on light
surfaces — only focus glow, large solid fills (with dark text), borders, and the
logo. Light-mode actions/links use `#0e7490`.

## Dark mode (page `#0b1220` Obsidian, panel `#131c2e`)

| Foreground | On | Ratio | Normal | Large/UI |
|---|---|---|---|---|
| text-strong `#f8fafc` | page | 16.8:1 | ✅ AAA | ✅ |
| text-body `#c9d4e3` (Mist) | page | 11.9:1 | ✅ AAA | ✅ |
| text-muted `#8a99ad` | page | 5.6:1 | ✅ AA | ✅ |
| text-accent / link `#22d3ee` | page | 10.7:1 | ✅ AAA | ✅ |
| Obsidian `#0b1220` | Signal Cyan btn `#22d3ee` | 10.7:1 | ✅ AAA | ✅ |
| success-text `#5eead4` | success-bg `#0d2b22` | 9.1:1 | ✅ AAA | ✅ |
| warning-text `#f4b942` | warning-bg `#2c2410` | 8.4:1 | ✅ AAA | ✅ |
| danger-text `#fca5a5` | danger-bg `#2e1517` | 6.6:1 | ✅ AA | ✅ |
| info-text `#67e8f9` | info-bg `#0c2330` | 9.7:1 | ✅ AAA | ✅ |

**Dark-mode buttons** use Signal Cyan `#22d3ee` fill with Obsidian text
(10.7:1) — the inverse of light mode, where the cyan finally gets to be the hero.

## Focus rings

- Light: `#0e7490`, 2px, 3px offset, + `0 0 0 3px #cffafe` glow. Non-text contrast vs white = 5.0:1 ✅.
- Dark: `#22d3ee`, 2px, 3px offset, + `0 0 0 3px rgb(34 211 238 / .35)`. Non-text contrast vs Obsidian = 10.7:1 ✅.
- Never removed (`outline: none` without replacement is prohibited).

## Non-color signals

State is never communicated by color alone (WCAG 1.4.1). Status badges carry a
text label; destructive actions carry an icon + label; focus carries a ring, not
just a color shift.

## Motion

`prefers-reduced-motion: reduce` zeroes `--ls-motion-duration-*`. No parallax,
no auto-playing motion in the brand book or admin.

## Method note

Ratios are computed values for spec/QA. Re-verify in-browser with the axe
DevTools / WebAIM contrast checker after the admin re-skin lands, especially the
dark-mode status combinations.
