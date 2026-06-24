# Research & Rationale

## Category & competitive read

Lockspire sits in **developer auth/identity infrastructure** for the Elixir/Phoenix
ecosystem — adjacent to OAuth/OIDC providers (Auth0/Okta/Ory/Keycloak/Logto) but
positioned as *embedded* (a library inside the host app), not a hosted service.

Visual conventions in this space, and how Lockspire diverges:

| Convention in the space | Lockspire's move |
|---|---|
| Blue / indigo / purple accents (Auth0, Okta, Ory) | Cyan — adjacent enough to read "trust/tech," distinct enough to stand out |
| Padlock / shield / key iconography | Banned. Spire/beacon/gate geometry instead |
| Light SaaS marketing | Dark-first "midnight infrastructure + signal light" |
| Generic geometric monogram | Integrated typemark where the motif lives in the letterforms |

The Elixir ecosystem itself (Phoenix's flame/orange, Elixir's purple drop) is warm
and organic; a cool, architectural, precise identity differentiates Lockspire as the
*serious infrastructure* layer without clashing — cyan is a cousin of Phoenix's
cooler UI chrome and reads as "signal."

## Color rationale

- **Dark-first** because the brand metaphor is "light passing through strong structure."
  Signal Cyan only achieves its beacon quality against Obsidian; on white it's washed out.
- **Cyan over blue** for distinctiveness (see table). Over teal/green because green
  skews toward "success/eco" and muddies semantic status colors.
- **Surface-split accent** (`#22d3ee` dark / `#0e7490` light) resolves the one real
  weakness of luminous cyan — its light-mode contrast. See `accessibility-checks.md`.
- **Slate-blue neutrals** (not pure gray) so neutrals harmonize with Obsidian/Slate
  rather than reading as a separate gray system.
- **Support accents** Trust Teal / Beacon Amber / Alert Rose map to success / warning /
  danger so semantic state stays on-brand instead of generic.

## Typography rationale

- **Inter** — screen-native, open-source, neutral-but-warm, the de facto modern UI
  sans; trustworthy and unfussy, matching the "senior infra engineer with product
  taste" voice.
- **JetBrains Mono** — developer-credible monospace with disconfusable glyphs
  (0/O, 1/l/I), correct for an audience that reads tokens, scopes, and config.
- Both are *named, not shipped* — no font files, no CDN fetch from the auth server.
  The brand book HTML loads them for accurate preview only.

## Logo rationale

The brief's hard constraints (no rectangular cage, no subtitle on primary, mark+type
unified and close, at least one integrated typemark) point away from the default
"icon left of text." See `logo-options.md` for the four directions explored and the
recommendation. Name semiotics drive the geometry: **Lock** (gate/boundary/control)
+ **Spire** (rising structure/beacon/signal) → an upward, architectural mark with
load-bearing negative space, never a literal padlock.

## Wordmark outlining method

The wordmark and tagline SVGs are not live text — they are **outlined to vector paths** so
they render identically everywhere with no font dependency. Method: shape the string in
Familjen Grotesk 600 with HarfBuzz (`uharfbuzz`, kerning + ligatures on), pull each glyph's
outline via `fontTools` `SVGPathPen`, composite with correct advances, replace the dotted
"i" with a hand-authored faceted diamond over a dotless-i stem, then SVGO. The tower and
diamond are hand-authored geometry on a shared facet grid. **No font file is committed**;
the TTF is fetched only at generation time.

## Font licensing (OFL-1.1)

Familjen Grotesk, Inter, and JetBrains Mono are all SIL Open Font License 1.1. OFL permits
using a font to create outlined logo artwork; the resulting paths are unrestricted artwork
(OFL governs the font files, which we do not ship). The brand book HTML loads the webfonts
from Google Fonts for accurate local preview only — the product and logo never fetch them.

## SVG optimization settings

All logo SVGs are hand-authored, then minified with SVGO (transient `npx svgo`, no
committed toolchain). Settings: `removeViewBox: false`, `removeDimensions: true`
(scalable), path precision 2 decimals, `convertColors` (shorten hex), strip editor
metadata/`<title>`-bloat, keep `currentColor` for mono/inverse variants. Target:
every file ≤ 4 KB.

## Sources

- WCAG 2.1 contrast (1.4.3 / 1.4.11) — W3C.
- WebAIM contrast methodology (sRGB relative luminance).
- Inter (rsms.me/inter), JetBrains Mono (jetbrains.com/lp/mono) — license + metrics.
- Design-token format — Design Tokens Community Group draft.
- Ecosystem reference: Auth0, Okta, Ory, Logto, Keycloak brand surfaces (category read).
