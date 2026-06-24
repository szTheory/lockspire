# Decision Log

ADR-style record of the brand decisions. Each entry: decision, alternatives, rationale, status.

---

## D1 — Dark-first Signal Cyan is the canonical brand identity

**Decision:** Adopt the AI-research brand book's dark-first identity with Signal Cyan `#22D3EE` as the hero accent. This is the *real* brand, not aspirational.

**Alternatives considered:**
- *Reconcile toward the shipped admin blue (`#3b82f6`)* — safest, instantly implementation-ready, but discards the distinctive cyan identity that was deliberately researched to stand apart in the Elixir/devtool space (which skews blue/purple: Phoenix orange aside, most auth/infra tools default to blue).
- *Full dual system (blue product + cyan marketing)* — two accents to govern, higher long-term maintenance, brand dilution.

**Rationale:** Cyan-on-obsidian is genuinely distinctive for an OAuth/infra tool and reads as "signal light through structure" — on-metaphor. The product should embody the brand, not diverge from it.

**Status:** SHIPPED (drives tokens + admin re-skin).

---

## D2 — Surface-split the accent (cyan fails AA as light-mode text)

**Decision:** Pure `#22D3EE` is the hero on dark surfaces only. Light-mode interactive/text uses **Deep Cyan `#0E7490`** (`brand-600`, ~5:1 on white). `#22D3EE` (`brand-500`) is reserved for dark surfaces, focus glow, large non-text accents, and the logo.

**Alternatives considered:**
- *Use `#22D3EE` everywhere* — fails WCAG AA badly on white (~1.5:1) for text and small UI; non-starter.
- *Darken the hero to one AA-safe value for all surfaces* — kills the luminous signal quality that makes the brand sing on dark.

**Rationale:** The accent's job differs by surface. On dark it's a beacon; on light it's a wayfinding/action color that must clear AA. Splitting by surface keeps both honest.

**Status:** SHIPPED. See `accessibility-checks.md`.

---

## D3 — Dark mode = semantic-alias remap only

**Decision:** Implement dark mode by remapping the semantic aliases (`--ls-surface-*`, `--ls-text-*`, `--ls-status-*`, focus ring, shadows) under `@media (prefers-color-scheme: dark)` and `[data-theme="dark"]`. Primitives stay theme-agnostic. No component CSS changes.

**Rationale:** `admin_css.ex` already separates primitives from semantic aliases, and every component consumes the aliases. So dark mode is one additive block — the lowest-risk way to theme a 1300-line stylesheet without touching components.

**Status:** SHIPPED.

---

## D4 — Admin follows `prefers-color-scheme`; both modes first-class

**Decision:** The admin UI respects the OS preference (light default when none), with dark fully supported. The brand book document itself is dark-first with a manual toggle.

**Alternatives considered:**
- *Force dark in admin (match brand "dark-first")* — jarring for a data-dense operator tool; long-form table/log reading is often better in light. Violates principle of least surprise for existing users.

**Rationale:** Marketing/identity is dark-first; an operator console should respect the user's system choice. Both are first-class, so no one is penalized.

**Status:** SHIPPED.

---

## D5 — Typography: three-tier system, ship no font files

**Decision:** A three-tier type system:
- `--ls-font-display` → **Familjen Grotesk** (logo + headings) — distinctive, architectural grotesk.
- `--ls-font-sans` → **Inter** (UI / body) — maximally legible at small sizes for data-dense admin.
- `--ls-font-mono` → **JetBrains Mono** (code / tokens / identifiers).

Each leads its stack, followed by robust system fallbacks. All three are OFL-1.1. Lockspire ships **no font files** and adds **no external font fetch**.

**Alternatives considered:**
- *Familjen Grotesk for everything* — it's a fine display face but Inter is more legible for long-form tables/logs in the admin UI; using Familjen for body would cost readability.
- *Inter for display too* — safe but generic; the user explicitly wanted a distinctive logotype (Familjen).

**Rationale:** Display face gives brand distinctiveness where it matters (logo, headlines); Inter keeps the product legible; no CDN request matters for an auth server (privacy/CSP). The brand book HTML loads the webfonts for accurate local preview only.

**Status:** SHIPPED.

---

## D6 — Brand book lives at repo-root `brandbook/`, excluded from Hex package

**Decision:** Self-contained `brandbook/` at repo root. Not under `prompts/` (gitignored), not under `lib`/`priv`/`docs` (those are in the Hex `:files` allowlist and would bloat the published tarball).

**Rationale:** Repo-root keeps it tracked in git but out of the package (`mix.exs` allowlist is `lib priv docs .formatter.exs mix.exs README.md CHANGELOG.md LICENSE`). Vector/text only, ≤250 KB budget.

**Status:** SHIPPED.

---

## D7 — Logo: faceted-diamond-tittle wordmark + faceted-tower mark

**Decision:** After a six-round visual tournament (recorded in `logo-options.md`), the chosen identity is:
- **Wordmark (primary):** "Lockspire" in **Familjen Grotesk 600**, with the dot of the "i" replaced by a **two-tone faceted cyan diamond** (a cut "signal" stone) sitting as the tittle. Outlined to vector paths — font-independent.
- **Mark (icon/favicon/avatar):** a **faceted obelisk/tower** with a lit face, plinth, and crystalline apex — "architected trust, light through structure." The diamond and tower share one faceted-crystal language.
- **Lockup:** tower + wordmark, mark locked to ascender height with a tight optical gap.
- **Tagline lockup (secondary):** wordmark over "STRUCTURED TRUST FOR PHOENIX" in spaced caps. Never used as the primary.

**How it satisfies the constraints:** transparent (no rectangular cage); no subtitle on the primary; mark + wordmark unified by the shared facet language; the diamond is a motif worked *into* the letterform (integrated typemark), not an icon floating beside text.

**Variants shipped** (in `../logo/`): wordmark, wordmark-inverse, wordmark-mono; horizontal, horizontal-inverse, horizontal-mono; tagline, tagline-inverse; mark, mark-mono; favicon. Explicit ink/frost color variants exist (not only `currentColor`) so the logo renders correctly in GitHub READMEs (which use `<img>`, where `currentColor` always resolves to black) via `<picture>` + `prefers-color-scheme`.

**Rejected directions:** blocky/Atari rounded-rect marks; the too-tall full-height spire "i"; the L-spire initial (illegible at size); converging-beams (generic triangle read); nested-gateway and arch-beacon (good, but the tower + diamond won on coherence).

**Status:** SHIPPED.

---

## Deferred / explicitly out of scope

- A theming engine or per-tenant admin theming. (Tokens support it; not building it now.)
- Self-hosting Inter/JetBrains as packaged webfonts.
- A marketing website build (the `examples/landing-page-section.html` is a demonstration fragment, not a site).
