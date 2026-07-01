# Phase 116 Maintainer Lab Contract

The component lab is maintainer/demo/test-only. It is a repo-local proof tool for real admin components, recurring groups, route/workflow states, and hostile but redaction-safe data. It is not public runtime behavior, not a supported admin route, and not a public API.

## Purpose

This lab exists to test Lockspire's admin design system against real route/component states and hostile data shapes without creating a new supported surface.

## Boundary Rules

| Rule | Contract |
|------|----------|
| Mounting | The lab must not mount through Lockspire.Web.AdminRouter and must not add any route string such as `component_lab` or `design_system_lab` to `AdminRouter`. |
| Support surface | The lab is not a supported admin route, not a public API, and not public support truth in `docs/supported-surface.md`. |
| Classification | Lab, demo, and test evidence may use `internal_lab`, `test_only`, or `demo_only`; it is never `admin_supported`. |
| Tooling | PhoenixStorybook is rejected/default-deferred for Phase 116. Do not add a React/JS Storybook shell. |
| Theming | Do not create public theming, a host-editable component registry, or a host-owned override layer. |
| Runtime behavior | Do not add protocol behavior, storage schemas, migrations, routes, or production LiveViews for the lab in Phase 116. |

## Allowed Evidence

- ExUnit-rendered HEEx and Phoenix function components.
- Repo-local fixture modules in later phases.
- Demo-only fixture data with safe placeholders.
- Maintainer screenshots and browser evidence in later CSS/component/page proof phases.
- Source-derived route/component inventory tests.

Allowed classifications are `internal_lab`, `test_only`, and `demo_only`; the lab is never `admin_supported`.

## Fixture And Evidence Safety

Fixtures, screenshots, logs, docs, tests, and lab states must not expose:

- client secrets
- registration access token plaintext
- initial access token plaintext after creation
- refresh/access token plaintext
- authorization codes
- cookies
- private keys
- verifier material
- user codes
- unredacted sensitive values

Hostile data is encouraged when redaction-safe: long URLs, long client IDs, dense scopes, disabled actions, destructive confirmations, empty/error states, status clusters, copy-once panels with safe placeholders, light/dark/system themes, reduced-motion states, focus paths, and narrow mobile widths.

## Proof Shape

ExUnit/source contracts are the primary Phase 116 proof shape. Browser and screenshot evidence belongs to later phases after CSS, component, fixture, or page changes create something visual to prove.

## Rejected Or Deferred

PhoenixStorybook is rejected/default-deferred for Phase 116. React/JS Storybook, a public route, a public API, public theming, and a host-editable component registry are also rejected for this phase.
