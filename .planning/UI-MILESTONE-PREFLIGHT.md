# Lockspire admin/operator UI refinement — preflight

Captured: 2026-10-09 UTC. Source inspected: `fd047a29b2fa247ab8d68a76cd9f57f00fe43feb`.

Status: Preflight complete; v1.40 milestone kickoff is complete and Phase 144 planning is complete (2026-10-09). Impeccable init completed on 2026-10-09 after the user confirmed the recommended audience and code-first default. Durable product context is in [PRODUCT.md](../PRODUCT.md), and the workflow preference is in [.impeccable/config.json](../.impeccable/config.json). The user has invoked `$gsd-new-milestone Admin Operator UI Refinement`; the subsequent `$gsd-plan-phase 144` instruction confirms the requirements and roadmap in the canonical GSD files. No implementation or fresh browser proof is claimed, and the phase UI contract is approved in phases/144-working-preview-and-representative-journeys/144-UI-SPEC.md. This direction supersedes the conversation's proposed promotion of repository/docs polish. Phase 999.1 remains in the backlog. v1.39 and its acknowledged historical verification gap remain archived; neither needs to be reopened for UI work.

## User intent

Refine the existing embedded operator UI into a calm, conventional, coherent interface that helps people complete real tasks. Improve whole-page information hierarchy, readable typography, spacing, forms, controls, responsive layout, domain language, and appropriate state feedback. Use shared tokens and components consistently without forcing every surface into columns, tables, or nested cards. Support common tasks and expert investigation, including realistic error and boundary states.

Use Impeccable and Emil Kowalski's installed skills to bring the implementation to a strong baseline with bounded automated review. The user can inspect the result and provide optional aesthetic feedback afterward; routine verification should not require their babysitting. Do not create a paid visual-judge service or an open-ended critic/rewrite loop.

## What already exists

Lockspire has a real Phoenix LiveView operator UI: 28 router entries plus a logout-propagation query workflow, represented by 29 existing route scorecards. Reuse and refresh that inventory.

| Journey | Existing surfaces and jobs |
| --- | --- |
| Orient | Overview; determine provider state and the next useful investigation. |
| Configure | Client inventory/detail/edit, redirect/logout configuration, security policy, credential rotation, signing keys, dynamic registration and initial access tokens. |
| Support | Find a token or consent grant, understand lifecycle and family context, inspect the relevant client, and revoke the appropriate authorization. |
| Operate | Inspect authorization interactions, pending device requests, logout delivery state, and client-specific logout propagation. These queues have intentionally read-only boundaries. |

Primary audiences already represented in the scorecards are provider operators, platform/security owners, partner-onboarding operators, and support investigators. During Impeccable init, the user confirmed Phoenix app teams as adopters, authorized technical provider operators as the primary admin audience, and support/security teammates as additional users. Do not repeat this audience confirmation without new conflicting context.

Existing implementation and proof:

- [Admin router](../lib/lockspire/web/admin_router.ex), [shell](../lib/lockspire/web/live/admin_layout_live.ex), and [29 route scorecards](milestones/v1.32-phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md).
- [Shared components](../lib/lockspire/web/components/admin_components.ex) already supply page/workflow/entity structures, summaries, forms/errors, filters, resource rows, responsive tables, long values, copy-once panels, and confirmations.
- [Admin CSS](../lib/lockspire/web/admin_css.ex) has `--ls-*` spacing, type, semantic color, radius, shadow, focus, layering and motion tokens. Signal Cyan identity, system/light/dark preference, narrow-screen reflow and reduced motion already exist. Named font stacks deliberately do not download fonts.
- [Internal fixtures](../test/support/lockspire/web/admin_lab/fixtures.ex) and [stress surface](../test/support/lockspire/web/admin_lab/stress_surface.ex) render real components with difficult data. Keep this maintainer/test infrastructure outside the supported runtime surface.
- ExUnit/LiveViewTest/LazyHTML tests cover routes, actions, redaction, components, source/CSS contracts and package boundaries. The [browser evidence parser](../test/support/lockspire/web/admin_proof/browser_evidence.ex) validates evidence records; it does not itself inspect a browser.
- Prior UI work: [v1.29 audit](milestones/v1.29-MILESTONE-AUDIT.md), [v1.31 audit](milestones/v1.31-MILESTONE-AUDIT.md), [v1.32 audit](milestones/v1.32-MILESTONE-AUDIT.md). Reuse their valid results; identify current defects before reopening completed work.

## Current findings and unknowns

Source-confirmed candidates:

1. Operator copy sometimes describes implementation: token filters say “Raw URL filters stay editable below while summaries use redacted handles”; consent copy explains how scope values wrap; logout copy says “without adding worker controls.” Replace this with useful domain language and consequence/help text. See [token index](../lib/lockspire/web/live/admin/tokens_live/index.ex), [consent index](../lib/lockspire/web/live/admin/consents_live/index.ex), and [logout queue](../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex).
2. Some token, consent, and device list errors become empty lists, and overview loading uses fallback values. A failed observation must not look like a successful empty inventory or healthy zero. Investigate and fix within the affected UI journey if included in the eventual scope. See [device queue](../lib/lockspire/web/live/admin/device_authorizations_live/index.ex) and [overview](../lib/lockspire/web/live/admin/overview_live/index.ex).
3. Existing type tokens include 14px body and 12px labels. Assess readability in the actual mounted UI, zoom and dense data before deciding changes; these values alone are not a demonstrated defect.

Visual/runtime unknowns:

- The documented demo address returned HTTP 404 during this preflight, and no containers existed under the default `lockspire-adoption-demo` project. No demo was started and no fresh screenshot was captured.
- Historical PNGs under `tmp/admin-ui-polish/` include Phase 110/v1.28 images. They are not a current baseline.
- Phase 125's [proof record](milestones/v1.32-phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md) explicitly distinguishes rendered-HTML measurements from optional live-demo checks, records a working-tree caveat, and notes historical HTTP 500s on some demo routes. These are reasons to establish a fresh, working browser baseline, not claims that current routes still fail.
- Old audit commentary about direct Repository calls is stale for current interaction/logout LiveViews, which now use Admin delegates. Do not repeat that completed boundary refactor.
- No tests were rerun for this preparation-only assessment. Existing passing reports describe their recorded source and coverage.

## Transferable lessons from sibling projects

The sibling records below were inspected read-only. Their product naming and visual choices are not Lockspire requirements.

| Evidence | Lesson to carry forward |
| --- | --- |
| Scrypath v1.42 recorded 38/38 truths and 104 browser cases, then received composition complaints and follow-up fixes. `~/projects/scrypath/.planning/reference/OPERATOR-UI-REFINEMENT.md` records redundant nested panels, sentence-length links and preview wrappers disrupting spacing. Its v1.43 is planned, not implemented. | Judge the whole page and task sequence as well as individual components. Prefer headings, proximity and quiet dividers before adding containers. Remove preview scaffolding from production code. |
| Scrypath `da2843a` repaired stale served assets; `961ecf4` fixed toast layer precedence. Accrue's v1.53 retrospective records CSS changes without rebuilding the shipped asset; current Phase 233 verifies served bytes. | Verify the mounted page's actual CSS and current source identity. Lockspire's inline Elixir CSS has a different delivery path; inspect that path rather than copying a sibling build system. |
| Scrypath `b10ba7d` fixed refresh icons destroyed by `phx-disable-with`; `698013c` fixed simultaneous pointer and keyboard selection. | Exercise busy → success/error → repeat-action cycles, DOM patches, dialog errors, focus restoration and mixed input methods. A static screenshot misses these failures. |
| Scrypath `2977c92` / `6881d76` refined operational naming. Mailglass `5bdc1098` separated command outcome from delivery evidence. | Establish a small domain vocabulary across nav, headings, fields, actions and feedback. Keep requested, accepted, complete, expired, failed and unknown meanings distinct. |
| Accrue quick task `261008-cjc` repaired tests overwriting saved screenshots and a journey that had not actually completed step-up. Mailglass `5c42d563` corrected a CI allowlist omitting 325 of 510 Admin tests. | Check that verification exercises the complete user job and actually runs in its claimed lane. Keep baseline capture explicit; ordinary verification must not silently regenerate the expected result. |
| Mailglass Phase 168 records actual 200% browser zoom, long identifiers, accessible exact timestamps, preference-versus-effective-theme and reduced-motion/LiveView patch checks. Its spacing gap is now closed. | Test real zoom separately from viewport width. Preserve complete authorized diagnostic values and one clear selected theme preference. Avoid restarting announcements or motion on patches. |
| Accrue's v1.56 model-scored ratchet failed to converge on information architecture and remains parked; its Oct 7 scope note favors bounded review. Threadline's v1.46 is planned with no implementation. | Prefer complete user journeys and a named finding list. Reuse cheap deterministic checks and direct visual inspection; do not import another scoring framework or claim planned work as shipped evidence. |

Useful sibling references: `~/projects/accrue/.planning/notes/2026-10-07-accrue-ui-refinement-scope.md`, `~/projects/accrue/.planning/phases/233-shared-direction-portal-contract/233-VERIFICATION.md`, `~/projects/mailglass/.planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md`, and `~/projects/threadline/.planning/UI-MILESTONE-PREFLIGHT.md`.

## Preflight delivery recommendation

This recommendation informs the approved milestone. The canonical phase list and approval status live in ROADMAP.md and STATE.md.

1. **Current baseline and representative pages.** Bring up the actual mounted demo, confirm working routes and served styles, refresh the existing inventory, and inspect representative client configuration and token/consent investigation journeys. Include realistic adverse data. Identify named visual and behavioral defects before broad token changes.
2. **Shared foundation proven in those journeys.** Resolve reading order, type/spacing, form/action hierarchy, theme states and component grouping in representative whole pages. Consolidate repeated solutions into the existing component/token system and remove superseded rules.
3. **Propagate by connected operator job.** Carry the demonstrated patterns through onboarding/configuration, support investigation and operational queues. Keep navigation context, correct state distinctions and discoverable common actions; choose the right structure per task rather than prescribing tables or cards everywhere.
4. **Bounded finish and optional feedback.** Inspect one batched desktop/mobile and light/dark round, fix the observed findings together, and confirm once more. Use intermediate widths, zoom and state combinations where affected. Finish with a working preview, representative before/after evidence, relevant automated checks and explicit remaining limits. The user can provide a later taste/priority pass without repeating mechanical UAT.

Cover every route in the inventory, but choose representative state/theme/viewport combinations by risk instead of multiplying every dimension indiscriminately. Keep existing behavior and security checks; use actual browser inspection for computed layout, clipping, focus, zoom and visual hierarchy. Screenshot existence or source-string assertions alone cannot prove these properties. Do not add testing bureaucracy for every cosmetic change.

Motion should clarify a real state change or interaction. Existing 150/220ms tokens and reduced-motion rules are the base. Avoid page-load choreography, delayed keyboard workflows, unnecessary animation libraries, or motion added merely to consume a skill. Use installed `emil-design-eng`, `find-animation-opportunities`, `animate`, and `review-animations` selectively.

## Lockspire boundaries

- Preserve Phoenix LiveView and the embedded-library architecture. Host apps retain accounts, staff authentication/MFA/roles, tenancy and product policy, login/consent UX, and outer branding/layout ownership.
- Keep CSS and behavior scoped to Lockspire's admin surface. Do not require a host-wide CSS reset, frontend-stack replacement, external fonts, or a new app service.
- Preserve redaction, copy-once credential semantics, accurate consequences, confirmation behavior, and the distinction between token/grant/family revocation. Full authorized diagnostic identifiers may remain accessible; credentials must not leak into screenshots, traces or retained evidence.
- Preserve intentionally read-only interaction/device/logout queues. Do not invent approve/deny/retry/discard controls or change protocol/security policy through a visual-polish task.
- Keep fixture/lab/browser tooling maintainer-only and outside package/public support promises. Use synthetic, redaction-safe data for retained captures. Existing browser-tooling limitations should be considered explicitly if the future milestone needs a small new check; do not automatically build a platform.
- Repository/docs backlog work, protocol expansion, release ceremonies, historic approval-gap repair and broad backend refactors are separate scope.

## Adapted kickoff prompt

> Prepare a Lockspire admin/operator UI refinement milestone using Impeccable in Operate mode and Emil Kowalski's design-engineering/motion guidance. Build on the existing Phoenix LiveView admin UI, shared `--ls-*` tokens, component lab and Orient/Configure/Support/Operate journeys. Begin with current rendered pages and actual task/state coverage; reuse existing route scorecards and previous valid proof. Improve readable typography, spacing, information hierarchy, native-feeling controls, domain vocabulary, responsive behavior and truthful feedback. Demonstrate shared changes on complete client-configuration and support-investigation pages before propagating. Preserve host ownership, read-only queues, credential redaction, copy-once and confirmation semantics. Treat failed/unknown observations honestly. Automate useful checks and visually inspect representative results in bounded passes, without paid critic loops or routine human verification handoffs. Finish with a coherent, working preview for optional feedback. Read this preflight and the initialized Impeccable product context before defining requirements; do not reopen finished release bookkeeping.

## Next step and continuity

Impeccable init is complete. The user confirmed the recommended audience and chose code-first for future new UI surfaces. Honor the recorded preference in `.impeccable/config.json`; it is a default, not a prohibition on a later explicitly requested image comp. `PRODUCT.md` records product truth. Init did not create `DESIGN.md` or a surface brief and does not authorize replacement of the existing identity.

Impeccable's launcher reported `hasVisualImplementation: false` when targeting an Elixir router despite the real UI above; that heuristic must not trigger a greenfield redesign. The optional live picker has not been configured: the library renders through Phoenix/Elixir and the current mounted demo has not been verified. Establish an actual injection target and working development preview before configuring it; a generic HTML/JavaScript-framework config is not evidence of Phoenix compatibility.

Phase 144 planning is complete; next execution command: `$gsd-execute-phase 144`.

Completed command:

```text
$gsd-plan-phase 144
```

Read this preflight and root `PRODUCT.md` when resuming. Product initialization and its two choices are settled; execute the checked Phase 144 plans without repeating init, scope questions or planning.

The milestone kickoff targets v1.40, with phase numbering continuing after 143. The canonical roadmap owns the phase decomposition and STATE.md records its approval status. The earlier docs-focused scope confirmation is superseded by the user's UI direction.

GSD owns requirements, sequencing and completion. Impeccable supplies design reasoning and scoped refinement. When a UI phase is actually planned, carry confirmed choices into its UI contract and delegated required reading rather than assuming subagents inherit this conversation.

Documented preview startup: `make demo`, then `http://lockspire-demo.localhost/lockspire/admin`, login `ops`. See [adoption demo guide](../docs/adoption-demo.md). This command was not run during preflight and the URL is not currently a verified working preview. Keep a future feedback preview stable and run mutating fixture verification in a separate disposable instance.
