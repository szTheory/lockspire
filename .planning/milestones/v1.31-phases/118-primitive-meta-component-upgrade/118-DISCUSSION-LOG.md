# Phase 118: Primitive & Meta-Component Upgrade - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-25
**Phase:** 118-primitive-meta-component-upgrade
**Mode:** assumptions with expanded subagent research
**Areas analyzed:** Component Architecture, Status Semantics, Form Primitives, Stress Proof

## Assumptions Presented

### Component Architecture

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Extend `AdminComponents` with backward-compatible attrs/slots and reusable meta-components while keeping Phoenix function components and avoiding domain-specific LiveComponents. | Confident | `.planning/ROADMAP.md`, `116-COMPONENT-GROUP-INVENTORY.md`, `lib/lockspire/web/components/admin_components.ex` |

### Status Semantics

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `status_badge` should intentionally classify every real Configure, Support, and Operate status atom currently rendered through it, with fallback only for unknown values. | Confident | `lib/lockspire/web/components/admin_components.ex`, admin LiveView status call sites, domain/storage status records |

### Form Primitives

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Production forms should migrate practical label/help/error field markup to shared primitives, while complex confirmation and lifecycle forms may remain documented/tested exceptions. | Likely | `AdminComponents.form_field`, `error_summary`, `error_list`, repeated `lockspire-admin-field` production markup, destructive confirmation workflows |

### Stress Proof

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 118 proof should extend the existing test-only admin lab fixtures and component stress tests rather than adding a public route or browser/storybook dependency. | Confident | Phase 117 lab files, `design_system_component_stress_test.exs`, Phase 116 lab contract |

## Research Expansion Requested

The user requested a deeper one-shot recommendation pass for each assumption using subagents, covering:

- pros, cons, and tradeoffs for each approach;
- idiomatic Elixir, Plug, Ecto, Phoenix, and LiveView patterns;
- lessons from successful libraries/apps in adjacent ecosystems;
- developer ergonomics and library DX;
- UI/UX, JTBD, accessibility, performance, light/dark/system behavior, brandbook consistency, and user psychology where applicable;
- prompt corpus guidance under `prompts/`, with `brandbook/` treated as newer visual truth.

## Subagent Research Results

### Component Architecture

Recommendation: use slot-based structural meta-components layered over existing thin primitives. Keep LiveViews responsible for URL state, filtering, loading, mutation, and policy. Keep LiveComponents out unless local state plus event handling is genuinely required.

Alternatives reviewed:

- Thin primitives only: lowest API weight but does not solve architectural pane/entity/workflow/table-list drift.
- Slot-based structural meta-components: best fit for Phase 118 because it standardizes scanning/layout while preserving page behavior and Phoenix `attr`/`slot` validation.
- Domain workflow function components: useful only for stable, purely presentational workflow display; risky if they hide policy or mutation semantics.
- Stateful LiveComponents: appropriate only for reusable local state/event loops; otherwise heavier and contrary to current LiveView guidance.

Captured decision impact: D-01 through D-06 in CONTEXT.md.

### Status Semantics

Recommendation: keep `status_badge` as a function component but make it domain-aware via a `:domain` or `:context` attr and one explicit status metadata mapping that returns label, tone, cue, and optional title.

Alternatives reviewed:

- Generic `variant` prop: easy escape hatch but duplicates semantic decisions across call sites.
- Central global atom mapping: simple and idiomatic, but ambiguous atoms such as `:pending`, `:revoked`, and `:expired` differ by domain.
- Domain-aware status metadata: best fit for operator comprehension and DS-03 coverage.
- Per-domain badge components: precise but creates component sprawl and inconsistent visual grammar.

Captured decision impact: D-07 through D-11 in CONTEXT.md.

### Form Primitives

Recommendation: make slot-based `form_field` the default for routine configuration and filter fields, add narrow workflow primitives for confirmation/copy-once/lifecycle actions, and require documented tested exceptions where wrapping harms clarity.

Alternatives reviewed:

- Wrap every input: consistent but high migration risk and awkward with Phoenix form recovery and confirmation flows.
- Slot-based field chrome: preserves explicit HEEx inputs and existing form semantics while improving label/help/error consistency.
- Small workflow primitives: useful for destructive and copy-once flows if they stay structural and do not own domain behavior.
- Document page-local exceptions: necessary but must be bounded by tests to prevent drift.

Captured decision impact: D-12 through D-18 in CONTEXT.md.

### Stress Proof

Recommendation: extend the existing ExUnit-rendered `test/support` stress surface for Phase 118 component/API/state proof. Defer route-mounted browser proof, axe, screenshots, and PhoenixStorybook.

Alternatives reviewed:

- ExUnit-rendered stress surface: fastest, safest, test-only, redaction-friendly, and aligned with existing Phase 116/117 contracts.
- Private/internal lab route: closer to browser proof but risks support-surface creep unless isolated in a test-only endpoint.
- PhoenixStorybook: strong future option but currently heavier than needed and conflicts with deferred FUTURE-01 posture.
- Browser screenshots/Playwright/axe now: valuable, but belongs after primitives and page application stabilize.

Captured decision impact: D-19 through D-23 in CONTEXT.md.

## Corrections Made

No corrections were made. The user requested deeper research and a one-shot recommendation set rather than choosing among assumptions.

## External Research

- Phoenix function components and `attr`/`slot` API: `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html`
- Phoenix LiveComponent guidance: `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html`
- Phoenix LiveView form bindings: `https://hexdocs.pm/phoenix_live_view/form-bindings.html`
- W3C WCAG Use of Color: `https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html`
- GOV.UK error summary and field error patterns: `https://design-system.service.gov.uk/components/error-summary/`, `https://design-system.service.gov.uk/components/error-message/`
- Cloudscape status indicator precedent: `https://cloudscape.design/components/status-indicator/`
- Carbon status indicator precedent: `https://carbondesignsystem.com/patterns/status-indicator-pattern/`
- Twilio Paste status badge precedent: `https://paste.twilio.design/components/status-badge`
- Atlassian badge precedent: `https://atlassian.design/components/badge/badge/usage`
- PhoenixStorybook future-option tradeoff: `https://github.com/phenixdigital/phoenix_storybook`
