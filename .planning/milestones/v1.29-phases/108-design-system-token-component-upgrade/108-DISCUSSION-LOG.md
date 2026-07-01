# Phase 108: Design-System Token & Component Upgrade - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 108-design-system-token-component-upgrade
**Mode:** assumptions with user-requested sub-agent research
**Areas analyzed:** token architecture, component API, migration strategy, verification fences, motion/mobile/readability

## User Direction

The user asked for deep research using sub-agents across each surfaced assumption, including:

- pros, cons, and tradeoffs for each approach;
- examples for each approach;
- Elixir/Plug/Ecto/Phoenix idioms for a library/admin surface;
- lessons from popular successful libraries and applications in other ecosystems;
- DX, least surprise, software architecture, UI/UX, and project vision fit;
- use of relevant `prompts/` corpus;
- a final coherent recommendation set selected by the agent.

This was treated as approval to decide rather than ask another confirmation question.

## Assumptions Presented

### Token Architecture

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep `Lockspire.Web.Admin.CSS` as the single embedded CSS/token source and upgrade semantic `--ls-*` tokens in place. | Confident | `lib/lockspire/web/admin_css.ex`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `prompts/lockspire-operator-ux-liveview.md`, `prompts/lockspire_brand_book.md` |

Research compared:

- single embedded CSS module;
- split library CSS files;
- generated host CSS asset;
- host theme system.

Selected: one embedded stylesheet, semantic CSS custom properties, namespaced `lockspire-admin-*` classes, deterministic drift tests.

Key tradeoff: this maximizes install DX and avoids host asset-pipeline coupling, but keeps a future CSP/inline-style delivery concern.

### Component API

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Expand `Lockspire.Web.Components.AdminComponents` with repeated Phoenix function-component primitives while preserving current APIs. | Confident | `lib/lockspire/web/components/admin_components.ex`, `overview_live/index.ex`, `dcr_live/index.ex`, `clients_live/index.ex`, `tokens_live/index.ex`, Phase 103 and 107 context |

Research compared:

- larger shared Phoenix.Component API;
- local markup conventions only;
- generated host-editable components.

Selected: a moderately larger library-owned component API using attrs/slots for layout and safety primitives.

Key tradeoff: component API growth is justified for repeated structural primitives, but domain workflow components and generated host-editable components are deferred/rejected.

### Migration Strategy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Use foundation-first migration with narrow opportunistic cleanup; do not rewrite every LiveView. | Confident | Phase 108/109 roadmap split, Phase 107 route audit, current strong vs weak route classifications |

Research compared:

- foundation-first plus narrow migration;
- full admin rewrite;
- page-by-page opportunistic cleanup.

Selected: foundation-first. Upgrade primitives and replace repeated markup only where behavior-neutral.

Key tradeoff: some weak pages remain uneven until Phase 109, but the phase boundary stays clean and implementation risk stays low.

### Verification Fences

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Extend `design_system_contract_test.exs` with deterministic source/static fences and small rendered component checks. | Confident | Existing `design_system_contract_test.exs`, Phase 106 proof decisions, Phase 110 screenshot/browser scope |

Research compared:

- static regex/source tests;
- rendered component assertions;
- rendered LiveView assertions;
- browser screenshots;
- CSS parsing.

Selected: layered proof. Phase 108 owns cheap deterministic fences and structural component checks; Phase 110 owns visual/browser/mobile proof.

Key tradeoff: source tests are fast and repo-native, but they should not be overclaimed as visual proof.

### Motion And Mobile Readability

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Ship a small CSS-only motion contract plus reusable long-value/mobile/readability primitives; defer page-specific weak-route IA. | Confident | `admin_css.ex` motion tokens/reduced-motion block, Phase 108/109 scope split, weak raw table/list pages, operator UX prompt |

Research compared:

- semantic motion tokens;
- no motion;
- Phoenix.LiveView.JS transitions;
- page-specific animation.

Selected: tokenized CSS-only feedback/orientation motion with reduced-motion guardrails. No broad JS animation layer.

Key tradeoff: keeps accessible state feedback without introducing decorative animation or a second interaction layer.

## Corrections Made

No corrections were requested. The user explicitly asked the agent to research deeply, use sub-agents, and decide.

## External Research

- Phoenix.Component official docs: function components with `attr` and `slot` provide compile-time validation and documentation. Applied to component API decision.
  - https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html
- Phoenix.LiveView.JS official docs: targeted JS transitions/commands exist, but should be selective rather than a custom animation layer. Applied to motion decision.
  - https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html
- Django admin docs: admin is powerful but not intended as an entire front end; theming uses CSS variables and template hooks. Applied as a caution around host theming/customization becoming a support contract.
  - https://docs.djangoproject.com/en/dev/ref/contrib/admin/
- Rails Engines docs: engine assets should be namespaced; admin-only engine assets have precompile/delivery concerns. Applied to namespaced embedded-library CSS and future asset-delivery thinking.
  - https://guides.rubyonrails.org/v7.2/engines.html#assets
- MDN `prefers-reduced-motion`: non-essential motion should be reducible for users who request it. Applied to reduced-motion token/fence decisions.
  - https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion

## Ecosystem Lessons Applied

- Doorkeeper: strong install DX and embedded host integration are worth copying; view/customization drift and accidental secret exposure are cautionary tales.
- node-oidc-provider and Ory/Hydra: keep protocol/interaction seams explicit; copy the boundary discipline, not a lack of Lockspire-owned operator UI.
- OpenIddict: modular architecture and host-owned authentication reinforce Lockspire's explicit seam between core, web integration, storage, and operator UI.
- Django admin: CSS variables and constrained customization can work, but deep template/theme override surfaces become long-term compatibility contracts.
- Rails engines: mounted-library assets need namespacing and delivery discipline; avoid making host apps solve unnecessary asset-pipeline work.
- Phoenix LiveDashboard/Phoenix idioms: mounted LiveView library surfaces should be namespaced, self-contained, and function-component-first where possible.

## Auto-Resolved

Not applicable.
