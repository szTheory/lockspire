<!--
  Copy-paste README header for Lockspire.

  Why <picture>: GitHub renders README images via <img>, where SVG `currentColor`
  always resolves to black — so a single currentColor logo would vanish in dark mode.
  The <picture> + prefers-color-scheme swap below shows the inverse (frost) logo in
  dark mode and the default (ink) logo in light mode. Paths assume the logos live at
  brandbook/logo/ — adjust if you copy them elsewhere (e.g. .github/assets/).
-->

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="brandbook/logo/lockspire-horizontal-inverse.svg">
    <img alt="Lockspire" src="brandbook/logo/lockspire-horizontal.svg" height="40">
  </picture>
</p>

<p align="center">
  <strong>The embedded OAuth/OIDC authorization server for Phoenix.</strong><br>
  Structured trust, without friction.
</p>

<p align="center">
  <a href="https://hex.pm/packages/lockspire"><img alt="Hex.pm" src="https://img.shields.io/hexpm/v/lockspire?color=0E7490&labelColor=0B1220"></a>
  <a href="https://hexdocs.pm/lockspire"><img alt="HexDocs" src="https://img.shields.io/badge/hexdocs-lockspire-0E7490?labelColor=0B1220"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/hexpm/l/lockspire?color=0E7490&labelColor=0B1220"></a>
</p>

---

## Notes

- **Badge colors** use the brand: Deep Cyan `#0E7490` foreground on Obsidian `#0B1220`
  labels — readable in both GitHub themes.
- For a **social / OpenGraph card**, render `brandbook/logo/lockspire-horizontal-inverse.svg`
  centered on an Obsidian `#0B1220` background at 1200×630.
- For the **repo avatar / favicon**, use `brandbook/logo/lockspire-favicon.svg`
  (square, centered, holds at 16px).
- Prefer the **mark alone** (`lockspire-mark.svg`) only where the name appears nearby;
  otherwise use a lockup so the brand reads.
