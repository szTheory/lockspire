# Lockspire Brand Book

Self-contained brand + design-system package for **Lockspire** — the embedded
OAuth/OIDC authorization server for Phoenix. Vector/text only, no build step, no
font files. This folder is **excluded from the published Hex package** (it lives at
repo root, outside the `mix.exs` `:files` allowlist).

## Open it

Double-click **`index.html`** — it's a standalone document that opens from
`file://` with no server. Toggle light/dark in the top-right.

## What's here

```
index.html              The brand book (logo, color, type, tokens, components, voice)
tokens/
  tokens.json           Canonical machine-readable tokens (light + dark + states)
  tokens.css            CSS custom properties — implementation-ready, --ls-* names
logo/                   Optimized SVG logo variants (transparent, currentColor-aware)
examples/               Component gallery, a landing section, a README header
notes/                  research · decision-log · accessibility-checks · logo-options
```

## How it maps to the product

`tokens/tokens.css` uses the **same `--ls-*` variable names** as the live admin
stylesheet (`lib/lockspire/web/admin_css.ex`). It is not a parallel design system —
it is the same token vocabulary, so brand and product stay in lockstep.

Dark mode is implemented by remapping **semantic aliases only**
(`--ls-surface-*`, `--ls-text-*`, `--ls-status-*`); primitives are theme-agnostic.

## Shipped vs aspirational

- **Shipped:** the token system, the color split, dark mode, the admin re-skin to
  Signal Cyan + Inter/JetBrains stacks.
- **Aspirational / illustrative:** the `examples/landing-page-section.html` is a
  demonstration fragment, not a marketing site; Inter/JetBrains are *named* in the
  stacks but not packaged as font files.

See `notes/decision-log.md` for the reasoning behind every choice.
