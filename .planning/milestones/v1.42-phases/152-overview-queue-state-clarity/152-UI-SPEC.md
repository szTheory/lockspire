---
phase: "152"
slug: "overview-queue-state-clarity"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-12"
---

# Phase 152 — UI Design Contract

> Visual and interaction contract for Phase 152: Overview & Queue State Clarity.

This phase refines `/admin` and `/admin/overview`, `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts`. Staff need a quick, trustworthy read of provider activity and a clear route to the records behind an attention signal. Keep these pages calm and observational. Explain what the saved record proves, avoid guessing about remote user or relying-party behavior, and keep every queue read-only.

Sources: `AGENTS.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md` (UI-03), `.planning/ROADMAP.md` (Phase 152), `.planning/STATE.md`, `.planning/phases/151-focused-client-registration-settings/151-CONTEXT.md` (action hierarchy), `.planning/milestones/v1.32-phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` (overview and queue jobs), `brandbook/notes/decision-log.md` (D5 typography), `lib/lockspire/web/live/admin/overview_live/index.ex`, queue LiveViews and their tests, `lib/lockspire/web/admin_css.ex`, and `lib/lockspire/web/components/admin_components.ex`.

## Design System

| Property | Value |
|----------|-------|
| Tool | manual; Phoenix LiveView with Lockspire-owned function components and embedded CSS |
| Preset | not applicable |
| Component library | `Lockspire.Web.Components.AdminComponents`; existing `AdminLayoutLive` shell |
| Icon library | none; use text labels and status badges, never color or icon alone |
| Font | `--ls-font-display` Familjen Grotesk stack for display headings; `--ls-font-sans` Inter stack for UI/body; `--ls-font-mono` JetBrains Mono stack only for redacted identifiers, timestamps, and endpoint values |
| CSS architecture | Existing BEM-style `lockspire-admin-*` classes and semantic `--ls-*` tokens; no Tailwind, shadcn, public theming API, or one-off design system |

Reuse the existing `page_hero`, `pane`, `section_card`, `metric_grid`, `summary_stat`, `resource_list`, `dense_resource_row`, `status_badge`, `long_value`, `empty_state`, and `admin_button` components. Preserve established status tones and semantic HTML. Avoid adding a generalized queue component unless implementation evidence shows the repeated markup is error-prone; keep labels and meaning explicit at each call site.

## Component Inventory

Enumerated by `rg -c '^  def [a-zA-Z_]+\(assigns\) do' lib/lockspire/web/components/admin_components.ex` — 32 components — `lockspire`@1.5.1 — 2026-10-12. This is a non-exhaustive list of known-good components, not an allowlist.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `page_hero` | `Lockspire.Web.Components.AdminComponents` | Use one concise overview heading and task-oriented context; do not repeat a shell heading or generic intro. |
| `section_card` | `Lockspire.Web.Components.AdminComponents` | Group overview pivots by user task; omit repeated source/provenance notes. |
| `pane` | `Lockspire.Web.Components.AdminComponents` | Frame a queue as a read-only record list with a concise title and only useful context. |
| `metric_grid` | `Lockspire.Web.Components.AdminComponents` | Reserve for a few decision-relevant summary counts; do not repeat the same counts below. |
| `summary_stat` | `Lockspire.Web.Components.AdminComponents` | Pair each value with a plain, exact noun phrase; never render failed reads as zero. |
| `resource_list` | `Lockspire.Web.Components.AdminComponents` | Render loaded records and overview pivots with exact state/filter correspondence. |
| `dense_resource_row` | `Lockspire.Web.Components.AdminComponents` | Lead with record state and useful consequence; keep identifiers secondary and redacted. |
| `status_badge` | `Lockspire.Web.Components.AdminComponents` | Retain a visible text label and existing status domain; never rely on color alone. |
| `long_value` | `Lockspire.Web.Components.AdminComponents` | Wrap long IDs/URLs without exposing secrets or causing page overflow. |
| `empty_state` | `Lockspire.Web.Components.AdminComponents` | Distinguish a successful zero-result read from an unavailable read and provide a safe next step. |
| `admin_button` | `Lockspire.Web.Components.AdminComponents` | Primary for the page's principal safe task; secondary for return/recovery navigation; no destructive queue actions. |

## Route Contract

| Route | User job | First question answered | Contract title |
|-------|----------|-------------------------|----------------|
| `/admin` and `/admin/overview` | Regain provider-wide context and choose where to look next. | Is anything recorded that needs review, and where can I inspect it? | `Overview` |
| `/admin/interactions` | Review recorded authorization requests and their outcomes. | Which requests are waiting, completed, denied, or expired? | `Authorization interactions` |
| `/admin/device_authorizations` | Review device-flow requests and their recorded state/expiry. | Which requests are pending, approved, denied, consumed, or expired? | `Device authorization requests` |
| `/admin/logouts` | Review server-to-server and browser logout delivery records. | What delivery was attempted, what response was recorded, and what remains unconfirmed? | `Logout deliveries` |

The two overview routes remain equivalent. Queue headings must describe the records actually displayed, including completed/denied/expired history; do not call a mixed-history list “active” or imply a queue contains only pending work.

## Overview Information Contract

1. Start with the single title `Overview` and one short sentence that explains its job. Remove a repeated “Overview” eyebrow, duplicate provider title, generic navigation instructions, and “Measured from … inventory” provenance notes. Do not move low-value provenance into a tooltip.
2. Make the visual anchor the strongest factual attention signals: refresh-token reuse records and logout deliveries needing review, each with a direct pivot to the matching records. Keep this calm and proportional to the recorded state; do not elevate a count into a severity claim. Place generic provider totals and setup context after these signals. Remove the self-registered-client metric unless it has a clear user-relevant action and exact matching destination. Avoid repeating a count in both a summary tile and linked resource list.
3. Use plain, record-centered labels. Preferred terms are `Refresh tokens flagged for reuse`, `Logout deliveries needing review`, `Interactions waiting for login or consent`, and `Device requests waiting for a user`. Avoid `reuse incident`, `logout failure`, `open interaction`, `issuer-wide`, and backend inventory language when a clearer user-facing phrase is accurate.
4. Each overview count and link must represent the same set of records. For subset counts, link to a matching read-only filtered view. If a destination has no matching subset view, either add a read-only query/filter view over the existing list data or count and label the complete list. Do not add mutation, worker, retry, discard, approve, deny, or logout-now controls.
5. Token reuse means a refresh token was presented again after use and Lockspire revoked the refresh-token family. Explain that recorded event and consequence plainly without saying the account or user was compromised. Link to the matching reuse-detected token records. Count token records if that is what the list/filter returns; do not call the count “incidents” unless a distinct incident record exists.
6. Logout attention means a delivery is `retryable` or `discarded`, matching the current overview calculation. Label it as deliveries needing review, not generic logout failures. A retryable status records a retryable delivery failure; a discarded delivery is stopped. Neither status proves whether a relying-party session ended.
7. A zero is shown only after a successful read. A failed source shows `Unavailable` (or equivalent concise failure state) with a route to inspect or reload that source; it never displays zero, an empty result, or reassuring healthy language. Use precise read-only labels such as `Reload token records` or `Reload logout deliveries`. Loading, unavailable, and loaded-zero states remain distinct for each independent source.
8. Keep policy/key summaries secondary to actionable records. Use familiar language; do not expose storage/provenance implementation details. This phase may adjust overview wording needed to understand state but must leave broader Configure copy review to Phase 153.

## Queue Outcome Contract

### Interactions

- Use the neutral title `Authorization interactions`; the list contains pending login/consent as well as completed, denied, and expired records.
- State labels and row summaries must say what happened: waiting for login, waiting for consent, completed, denied, or expired. Do not imply the page can approve, deny, finish, or retry a request.
- Keep status and request age/expiry ahead of technical identifiers. Keep account/subject redaction and existing prompt/client context. Never expose authorization codes, cookies, session tokens, or raw sensitive return values.
- A successful empty read says `No authorization interactions recorded.` A failed read says the records could not be loaded, that results are unavailable, and provides a safe same-route read reload (`Reload interaction records`) or overview link. Never conflate these states.

### Device authorizations

- Use the neutral title `Device authorization requests` because the list includes historical approved, denied, consumed, and expired records as well as pending requests.
- Lead with visible request status and expiry; keep client context available. Never expose user-code or device-code plaintext, tokens, cookies, authorization codes, or secrets.
- Preserve the existing read-only boundary. Row pivots may navigate to relevant client details; no approval, denial, or mutation affordance is allowed.
- A successful empty read says `No device authorization requests recorded.` A failed read says the records could not be loaded and the current results are unavailable, with a safe read reload (`Reload device authorization requests`) or overview link.

### Logout deliveries

- Keep delivery channel visible and explain it once in user language: back-channel is a server request to the client's endpoint; front-channel is a best-effort browser page. Do not make protocol terms the only explanation.
- Use saved delivery facts in the row summary. Examples: a queued back-channel has no endpoint response yet; a retryable record has a retryable failure; a discarded delivery was stopped; an accepted endpoint response does not prove session termination; a rendered browser page does not prove browser delivery or session termination.
- Avoid repeated “Support note” prose and repeated implementation disclaimers. State the consequence once, beside the relevant record/status. Keep the endpoint/client pivot and the recorded failure context when it changes the user's next investigation.
- `Retryable` and `Discarded` are data states, not controls. The page remains read-only and exposes no retry/discard/worker action. Route pivots to client logout settings are navigation only.
- A successful empty read says `No logout deliveries recorded.` A failed read says the records could not be loaded and current results are unavailable; provide a safe read reload (`Reload logout deliveries`) or overview link.
- Keep enough status information to distinguish queued, attempted, retryable, discarded, skipped, endpoint-accepted, and front-channel-rendered records. Remove a status metric only when the same decision-relevant state remains visible in the corresponding rows and it reduces clutter.

## Interaction and State Rules

- Status text is always visible and perceivable without color; loaded values use tabular numerals. Announce loading and read failures through the existing status/live-region pattern without moving keyboard focus unexpectedly.
- Link labels name the destination/task, not “Open” alone. The clickable overview row has one accessible name that includes its record type and count; nested links are not allowed.
- Retry affordances retry only the read. They must not imply that a protocol request, logout delivery, token, or user session was changed.
- Overview source failures remain independent: a failed token read must not hide a successfully read client, key, policy, or queue value. Display unavailable beside only the failed signal.
- Preserve all queue record data semantics and status distinctions. Keep account, token, device code, client secret, cookie, auth code, and private key redaction intact. CR-01 remains a separate unresolved security issue.
- Do not change OAuth/OIDC behavior, security defaults, host ownership, storage schemas, or protocol controls. Do not add dependencies or new motion.

## Spacing Scale

Use this normative layout-gap scale and the existing `--ls-space-*` tokens. Do not introduce other values as layout gaps in this phase.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon/label gaps and compact inline spacing |
| sm | 8px | Related inline labels and compact groups |
| md | 16px | Default row and component gap |
| lg | 24px | Card/section internal padding and section separation |
| xl | 32px | Page/major group spacing |
| 2xl | 48px | Major page breaks only |
| 3xl | 64px | No routine use in the dense admin console |

Legacy component insets and control dimensions may retain their existing component-specific values. They are existing component dimensions, not additional layout-gap values or new spacing exceptions.

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Label / metadata | 12px | 600 | 1.2 |
| Body / queue row | 14px | 400 | 1.5 |
| Section heading | 16px | 600 | 1.25 |
| Page / summary value | 24px | 600 | 1.2 |

Use only regular (400) and semibold (600) within the phase content; preserve existing display, body, and monospace font stacks and do not shrink text to fit. Long identifiers and URLs wrap or break safely rather than clipping. Existing persistent shell branding remains outside this phase's typography changes.

## Color

Use the established semantic color tokens without imposing a numeric surface ratio; status colors are sparse signals, not decoration.

| Role | Value | Usage |
|------|-------|-------|
| Page surface | `--ls-surface-page` (`#f8fafc` light; existing dark token in dark mode) | Overall canvas and open space |
| Panel surface | `--ls-surface-panel` (`#ffffff` light), `--ls-surface-muted` (`#f1f5f9` light) | Cards, grouped records, form/control surfaces |
| Accent | `--ls-text-accent` (`#0e7490` light; `#22d3ee` dark) | Primary action, current navigation, and concise informational links only |
| Destructive | Existing danger semantic tokens | No destructive queue action is introduced in this phase |

Accent reserved for: principal safe CTA, active navigation state, and a small number of relevant links or informational state markers. Success/warning/danger tokens are reserved for truthful record states and must include text. Maintain at least 4.5:1 contrast for normal-size text, including muted labels, in light and dark themes. Do not use the current muted gray token on the muted gray surface where it falls below this threshold.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary overview CTA | `Review clients` (the existing primary safe route from the overview) |
| Overview title and description | `Overview`; `See what needs review and open the related records.` |
| Reuse signal | `Refresh tokens flagged for reuse`; explain that a refresh token was presented again after use and its family was revoked; do not imply compromise. |
| Logout signal | `Logout deliveries needing review`; explain retryable failure or stopped delivery and direct staff to the record/client settings. |
| Interaction empty state | `No authorization interactions recorded.` |
| Device authorization empty state | `No device authorization requests recorded.` |
| Logout delivery empty state | `No logout deliveries recorded.` |
| Error state | `Could not load {records}. The current results are unavailable.` Offer a precise read-only label such as `Reload interaction records`, `Reload device authorization requests`, or `Reload logout deliveries`, and/or `Return to overview`. |
| Destructive confirmation | None; this phase adds no destructive action or confirmation. |

Use plain sentence case for user-facing copy. Do not use “operator” as audience copy; do not use backend inventory provenance, “posture,” “incident,” “issuer-wide,” or “measured from” unless the exact term is needed and explained for a user decision. No tooltips for copy that should simply be removed or expressed in place.

## UI Considerations

Applicable state considerations resolved: 8 covered, 0 backstop, 0 unresolved.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Overview source summaries; three read-only queues | ✅ covered | Successful zero is explicit and distinct: the queue has no records; overview shows zero only after that source loaded successfully. |
| loading | Overview source summaries; three queues | ✅ covered | Show a concise loading status; do not flash a zero or stale value. Keep independent overview sources independent. |
| error | Overview source summaries; three queues | ✅ covered | Say the records/results are unavailable, preserve navigation, and offer only a read retry or safe route pivot. |
| populated | Overview pivots; interaction/device/logout lists | ✅ covered | Place state and useful consequence before redacted identifiers; keep rows scannable and links tied to the records shown. |
| partial | Overview with one failed source; queue rows with absent optional fields | ✅ covered | Failed overview sources show unavailable while successful sources remain visible; optional absent row values say `Not recorded`, never fabricate defaults. |
| overflow | Queue rows, long endpoint URLs, identifiers, timestamps | ✅ covered | Wrap/break within the row at narrow widths; no horizontal page overflow or clipped status/action. |
| zero-one-many | Overview counts and each queue collection | ✅ covered | Use exact loaded counts, singular/plural language, and a true empty state at zero; a failed read is not a zero. |
| long-text | Client identifiers, endpoint URLs, failure details, timestamps | ✅ covered | Keep body size; wrap long values; keep failure detail bounded and redacted by existing source rules. |

Open accessibility and preference checks remain prose-owned: support keyboard navigation and visible focus, meaningful heading order, screen-reader status announcements, reduced motion, high contrast, and light/dark/system theme parity. Do not require animation to understand state. Confirm exact rendered contrast in the existing supported theme styles.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | Not applicable; this Elixir/Phoenix project has no shadcn or third-party component registry. |

No dependency is added.

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS — no registry or dependency is used.
- [x] Dimension 7 Inventory Provenance: PASS — command and resolved project version recorded.

**Approval:** pending
