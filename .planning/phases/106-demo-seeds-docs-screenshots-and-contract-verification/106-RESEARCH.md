# Phase 106: Demo Seeds, Docs, Screenshots, and Contract Verification - Research

**Date:** 2026-06-03
**Status:** Complete

## Summary

Phase 106 is a closeout phase, not a new admin UI implementation phase. The worktree already contains the core v1.28 admin polish assets: enriched adoption demo seeds, operator admin docs, shared admin components/CSS, broad LiveView tests, design-system contract tests, and a screenshot inventory under `tmp/admin-ui-polish/`.

No external ecosystem research is required. The phase should use repo-native evidence and deterministic tests.

## Findings

### Demo Seeds

`examples/adoption_demo/priv/repo/seeds.exs` already creates a meaningful operator-state matrix:

- Multiple client types: public SPA, device client, confidential backend, self-registered DCR client, disabled legacy client.
- Long/realistic identifiers and partner URIs for screenshot stress.
- Signing key lifecycle states: active, upcoming, retiring, retired.
- Consent states: remembered and revoked.
- Token states: active access, active refresh, refresh reuse detected, revoked, expired.
- Interaction states: pending login, pending consent, denied.
- Device authorization states: pending, approved, expired.
- Initial Access Token states: active, revoked, used.
- Logout delivery states: back-channel succeeded, back-channel retryable, front-channel rendered.

The likely gap is not a new data model; it is checking that every admin journey has enough seeded state to produce useful screenshots and support docs.

### Docs

`docs/operator-admin.md` already presents the correct v1.28 doc shape:

- Admin surface is Lockspire-owned protocol/operator state.
- Host owns staff authentication, authorization, sessions, MFA, layouts, branding, and product policy.
- Admin navigation is organized around operator intent: Overview, Clients, Security, Keys, DCR, Support, Operations.
- The guide is explicitly subordinate to `docs/supported-surface.md`.

The closeout should tighten final journey copy and add any missing screen/journey references without expanding it into a protocol support matrix.

### Screenshot Evidence

`tmp/admin-ui-polish/` contains current browser evidence for overview, clients, client workspace, policies, DCR, and keys, with desktop/mobile coverage for some surfaces. Phase 106 should inventory what exists and fill coverage gaps for the full admin surface using the adoption demo seed state.

Screenshots should remain evidence artifacts. Runtime code should not depend on them.

### Contract Tests

`test/lockspire/web/live/admin/design_system_contract_test.exs` already fences:

- Generic `class="button"` patterns.
- Required shared CSS primitives.
- Raw inline `style=` attributes across admin LiveViews.
- Direct button classes that bypass `lockspire-admin-btn`.
- Raw `<button>` markup without the namespaced button class.

The plan should expand this file rather than create a separate contract harness.

## Validation Strategy

- Run focused admin LiveView tests and design-system contract tests.
- Run `MIX_ENV=test mix compile --warnings-as-errors`.
- Use adoption demo seed data as screenshot fixture state.
- Record screenshot coverage in a phase-local markdown inventory.

## Research Complete

Phase 106 can be planned as one closeout plan covering SEED-01, DOCS-01, VISUAL-01, and CONTRACT-01.
