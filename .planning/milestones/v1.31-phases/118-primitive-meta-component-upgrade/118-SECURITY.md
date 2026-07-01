---
phase: 118
slug: primitive-meta-component-upgrade
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-26
---

# Phase 118 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Test fixture data -> rendered lab HTML | Fixture values cross into component rendering and must remain redacted/test-only. | Redacted admin fixture values, long identifiers, handles, and copy-once placeholders |
| Admin LiveView call sites -> shared components | Operator-facing values cross into reusable rendering wrappers without transferring mutation or policy ownership. | Client, token, consent, DCR policy, status, form, and workflow display data |
| Component lab -> public support surface | Test-only component proof must not become a route, docs claim, or package artifact. | Internal maintainer proof only |
| Domain status atoms -> rendered badge semantics | Real operational states cross into user-facing status labels and tones. | Configure, Support, Operate, device authorization, logout, and provenance states |
| Badge CSS -> operator interpretation | Visual tone must not be the only carrier of state meaning. | Status meaning, tone class, visible label, and dot/shape cue |
| Operator input -> LiveView form validation | User-correctable validation crosses into field and summary rendering. | Field labels, help, errors, invalid state, and described-by IDs |
| Sensitive workflow -> rendered UI | Secret/token/key/user-code flows must preserve redaction and copy-once boundaries. | Secret handles, token handles, IAT/RAT surfaces, key/user-code material, and destructive consequences |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-118-01 | Information Disclosure | `Fixtures`, `StressSurface`, `long_value`, `copy_once_secret_panel`, copy-once/token workflows | mitigate | `design_system_component_stress_test.exs` rejects forbidden substrings across fixtures/rendered HTML and verifies redacted/copy-once fixture proof; contract tests preserve sensitive workflow exception coverage. | closed |
| T-118-02 | Tampering | `AdminComponents` public component API and form/workflow primitive APIs | mitigate | `design_system_contract_test.exs` preserves legacy component names, verifies additive primitive exports, blocks LiveComponent drift, and requires representative production wrappers to keep explicit Phoenix controls. | closed |
| T-118-03 | Tampering | `status_badge`, `status_metadata` | mitigate | Contract/stress tests enumerate real Configure, Support, and Operate statuses, verify domain-aware `status_metadata/2`, and keep unknown-only fallback isolated. | closed |
| T-118-04 | Spoofing | Badge visual semantics, disabled/destructive actions | mitigate | Rendered assertions verify visible badge labels, semantic tone classes, dot/shape cues, disabled links as non-anchors with `role="link"` and `aria-disabled="true"`, and separated destructive actions. | closed |
| T-118-05 | Spoofing | Internal lab support boundary | mitigate | Source contract assertions keep lab files under `test/support`, absent from router/package/public docs as a supported surface, while docs identify the lab as maintainer proof only. | closed |
| T-118-06 | Tampering | `form_field`, production forms | mitigate | Rendered assertions verify deterministic help/error IDs, `aria-describedby`, and `aria-invalid`; source assertions require explicit Phoenix inputs/selects/textareas remain in production form call sites. | closed |
| T-118-SC | Tampering | Package installs | accept | Phase 118 installed no npm, pip, cargo, Hex, browser, Storybook, PhoenixStorybook, Playwright, or axe dependency; package legitimacy gate was not triggered. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-118-SC | T-118-SC | Package-install supply-chain review is accepted as not applicable because Phase 118 added no package or browser-tooling dependency. | GSD plan-time threat model | 2026-06-26 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-26 | 7 | 7 | 0 | Codex |

Evidence:

- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` - 49 tests, 0 failures.
- `mix test.fast` - 1143 tests, 0 failures, 287 excluded.
- Register source: plan-time `<threat_model>` blocks from `118-01-PLAN.md`, `118-02-PLAN.md`, and `118-03-PLAN.md`.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-26
