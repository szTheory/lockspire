---
phase: 131
slug: executable-installation
status: approved
shadcn_initialized: false
preset: none
created: 2026-08-26
---

# Phase 131 — UI Design Contract

> This is an integration contract, not a Lockspire visual system. The generated consent LiveView
> must deliberately inherit the host application's layout, tokens, copy tone, and components.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — Phoenix HEEx generated host code |
| Preset | not applicable |
| Component library | host application choice |
| Icon library | host application choice; no icon is required by this template |
| Font | host application font stack |

The repository has no shared frontend token system to adopt. Generated Lockspire code must use
semantic host classes or host components, never introduce a Lockspire palette, font, asset, or
third-party UI dependency.

---

## Spacing Scale

The generated example uses the host's spacing scale. If the host has no scale, use these
multiples of four as conservative defaults:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline icon/text gap where the host adds an icon |
| sm | 8px | Label-to-control and compact list gaps |
| md | 16px | Form controls and default content gaps |
| lg | 24px | Consent-card sections and action groups |
| xl | 32px | Page-shell padding on narrow screens |

Exceptions: controls must retain the host's accessible touch-target policy; no fixed desktop-only
width is required.

---

## Typography

Use the host typography system. The generated fallback may use only the following roles, so it
does not compete with host branding:

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.5 |
| Label | 14px | 400 | 1.5 |
| Heading | 28px | 600 | 1.2 |

Do not display opaque interaction IDs, raw authorization request objects, tokens, client secrets,
or other protocol values as visual identifiers. The client display name is the primary identity;
the host may add an approved logo or verified publisher detail from its own metadata.

---

## Color

Colors are inherited from the host theme. The generated template must use host semantic tokens
or components rather than hard-coded Lockspire colors.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | host surface token | Page background and readable content surface |
| Secondary (30%) | host muted/surface token | Scope list, metadata, and informational grouping |
| Accent (10%) | host primary-action token | **Approve access** only |
| Destructive | host destructive-action token | **Deny access** only |

Accent reserved for: the affirmative consent submission control and its focus/active states. It
is not a signal of protocol validity, account identity, or a client trust level. Meet the host's
normal contrast and visible keyboard-focus requirements; do not rely on color alone for approve,
deny, warning, or error meaning.

---

## Copywriting Contract

The host may change wording and framing, but must preserve the intent of these states and keep
the two decision actions unambiguous.

| Element | Copy |
|---------|------|
| Page heading | `Authorize access` (host may use its equivalent) |
| Context | `{client name} wants access to your account.` |
| Primary CTA | `Approve access` |
| Secondary/destructive CTA | `Deny access` |
| Remember choice | `Remember this consent for future matching requests` |
| Empty scopes | `This application did not request any additional permissions.` Do not invent a scope label. |
| Missing client metadata | `Application details are unavailable. You can deny this request.` Do not expose the raw client ID. |
| Invalid/expired interaction | `This authorization request is no longer available. Return to the application and start again.` |
| Generic loading failure | `We could not load this authorization request. Return to the application and try again.` |
| Destructive confirmation | `Deny access`: the submit action itself is sufficient; do not add a second modal or silently submit. |

Error copy is a first-party host page. It may show a stable, non-sensitive support reference only
when the host already has such a mechanism; it must not reveal raw errors, redirect URIs, account
identifiers, interaction IDs, tokens, or secrets.

---

## Interaction and Accessibility Contract

- `mount/3` loads a supported Lockspire consent context using the route interaction identifier;
  it never trusts client name, scopes, subject, completion URL, or decision data from query
  parameters.
- Normal state presents client name, requested scopes, optional authorization-detail types, the
  remember checkbox, and clearly distinct approve/deny POST forms targeting the context-provided
  completion path. Completion remains owned by the existing Lockspire interaction endpoint.
- Before context resolves, render a host-standard non-interactive loading status (`role="status"`
  or equivalent), with no decision controls. Do not attempt a second protocol request from the
  browser to synthesize state.
- On either form submission, disable both decision controls, retain the chosen action label as
  progress text (for example, `Approving access…`), and prevent duplicate submission. The host
  should preserve normal form/CSRF behavior.
- Validation or completion errors are rendered in a host-standard alert region (`role="alert"` or
  equivalent), retain focus context, and do not erase the original review data when it remains
  valid. A terminal invalid/expired/subject-mismatch state shows no approve or deny controls.
- A remembered-consent redirect is terminal: render no intermediate success page and do not leak
  the redirect destination. The same applies after approve or deny completion.
- Scope and authorization-detail collections must be semantic lists. Long client names, scopes,
  and authorization-detail types wrap without horizontal scrolling; raw `authorization_details`
  JSON is not part of the generated host UI.
- The host owns page layout and responsive behavior. The generated section must remain usable at
  narrow viewport widths without a minimum fixed card width.

---

## UI Considerations

Applicable state considerations resolved: 7 covered, 0 backstop, 0 unresolved.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| populated | Client and requested scopes | ✅ covered | Context supplies authoritative display data; semantic list and clear actions render only after it is available. |
| empty | Requested scopes / optional client metadata | ✅ covered | Render the specified empty-scopes or unavailable-details copy without raw identifiers. |
| loading | Context lookup | ✅ covered | Host-standard status is non-interactive; decision controls wait for a valid context. |
| submitting | Approve and deny forms | ✅ covered | Disable both actions and show the chosen action's progress text to prevent duplicate decisions. |
| error | Lookup, expiry, invalid, and subject mismatch | ✅ covered | Render safe first-party copy in an alert; terminal invalid context has no action controls. |
| zero-one-many | Scopes and authorization-detail types | ✅ covered | Use semantic lists; omission of authorization details removes that section rather than producing an empty heading. |
| long-text / overflow | Client/scopes/details | ✅ covered | Wrap text responsively and never render raw JSON or opaque protocol identifiers. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable — no third-party UI code is introduced |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-08-26
