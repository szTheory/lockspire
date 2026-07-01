# Phase 87: Support Truth And Milestone Closure - Research

**Researched:** 2026-05-24
**Domain:** documentation truth closure for DCR logout metadata
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Support contract architecture
- **D-01:** Keep `docs/supported-surface.md` as the single canonical public support contract. README, maintainer docs, and adjacent guides must defer to it rather than becoming parallel support matrices.
- **D-02:** Phase 87 should use a narrow-but-complete doc closure: update the canonical support contract, then make targeted edits only in adjacent workflow docs whose current wording is now false or misleading (`docs/dynamic-registration.md`, `docs/operator-admin.md`, and any release-truth wording that points back to support truth).
- **D-03:** Do not broaden the milestone into a repo-wide doc sweep. Update only the surfaces that either define support truth or directly instruct users/operators on the changed DCR/logout workflow.

### DCR guide depth and structure
- **D-04:** `docs/dynamic-registration.md` should remain a focused guide, not a hosted-product manual. Add one explicit create/read/update lifecycle section for the four logout propagation metadata fields with concrete request/response examples.
- **D-05:** The DCR guide must state the dangerous semantics plainly: RFC 7592 `PUT` is full-replace, omitted logout metadata fields clear prior values, returned `registration_access_token` replaces the old RAT immediately, and any rotated `client_secret` replaces the old credential immediately.
- **D-06:** Keep the support-contract page terse and capability-oriented; put copy-pasteable examples and lifecycle notes in the DCR guide, not in `docs/supported-surface.md`.

### Logout truth-model emphasis
- **D-07:** Use moderate point-of-truth repetition for the logout asymmetry: one canonical support-truth statement in `docs/supported-surface.md`, one short explanation in `docs/operator-admin.md`, and concise matching wording where DCR examples mention the logout metadata fields.
- **D-08:** Preserve the existing truth model everywhere: back-channel logout is the durable server-to-server path; front-channel logout is best-effort browser choreography only and must never be described as proof of remote success.
- **D-09:** Keep post-logout redirect URIs clearly separate from logout propagation URIs in all docs and operator copy.

### Planning and escalation posture
- **D-10:** Downstream planner/executor should resolve medium-impact wording and documentation-structure choices without re-asking the user, as long as they preserve the phase boundary, current support truth, and least-surprise developer ergonomics.
- **D-11:** Escalate only if a proposed doc change would materially alter the public support contract, widen the product boundary, change the logout reliability claim, or create a new host/operator responsibility.

### Claude's Discretion
- Exact section titles, example values, and doc ordering inside the affected guides
- Whether release-truth wording lands in `docs/maintainer-release.md`, milestone-close proof docs, or both, provided `docs/supported-surface.md` remains the canonical source
- The exact amount of cross-linking between the DCR guide, operator guide, and support-contract page

### Deferred Ideas (OUT OF SCOPE)
- A broader docs architecture sweep or README refresh for all DCR capabilities
- Richer partner-portal or hosted-style DCR walkthroughs beyond the narrow embedded-library guide
- Additional automated doc-verification tests for support-surface wording drift, if support burden later justifies them
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-02 | Public docs and operator guidance state that DCR now manages existing logout propagation metadata while preserving Lockspire's current asymmetry: back-channel logout is durable and front-channel logout is best effort only. | Canonical support-contract correction, DCR lifecycle semantics update, operator wording correction, and release-truth alignment. [VERIFIED: repo grep] |
</phase_requirements>

## Summary

Phase 85 and Phase 86 already shipped the runtime-adjacent truth for this milestone: DCR create, management read, and RFC 7592 update flows now accept, persist, replace, clear, and re-emit the four logout propagation metadata fields, while preserving RAT rotation and existing validator reason codes. That truth is proven in controller and protocol tests, and the operator/runtime UI already states that front-channel logout is best effort only. [VERIFIED: `.planning/phases/85-03-SUMMARY.md`] [VERIFIED: `.planning/phases/86-03-SUMMARY.md`] [VERIFIED: `test/lockspire/web/controllers/registration_controller_test.exs`] [VERIFIED: `test/lockspire/protocol/registration_management_test.exs`] [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`] [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`]

The exact Phase 87 gap is documentation drift: `docs/supported-surface.md` and `docs/operator-admin.md` still say DCR logout propagation metadata is unsupported, while `docs/dynamic-registration.md` omits the newly shipped logout metadata lifecycle and its dangerous `PUT` semantics. `docs/maintainer-release.md` already defers to the support contract, so the release-truth work is narrow: make sure maintainer wording continues to point at the corrected canonical page rather than restating stale scope. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `docs/operator-admin.md`] [VERIFIED: `docs/dynamic-registration.md`] [VERIFIED: `docs/maintainer-release.md`]

**Primary recommendation:** Split Phase 87 into three doc-only slices: canonical support-truth correction, DCR lifecycle guide update, and operator/release alignment pass. [VERIFIED: repo grep]

## Overview Of Current Shipped Truth And Exact Gap

- Lockspire already ships RP-initiated logout plus logout propagation with durable back-channel delivery and best-effort front-channel iframe cleanup. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`]
- Lockspire admin surfaces already separate post-logout redirect URIs from logout propagation URIs and already warn that front-channel logout does not prove remote success. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`] [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`]
- DCR create and subsequent show already expose persisted logout metadata fields, and management update already rotates the RAT while returning the updated persisted logout metadata. [VERIFIED: `test/lockspire/web/controllers/registration_controller_test.exs`]
- Registration management update already enforces full-replace semantics, including clearing previously stored logout metadata when later `PUT` bodies omit those fields. [VERIFIED: `test/lockspire/protocol/registration_management_test.exs`]
- The current public docs still contradict that shipped truth by saying DCR logout propagation metadata remains unsupported and operator admin remains the only configuration path. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `docs/operator-admin.md`]
- The current DCR guide does not yet teach the shipped logout metadata fields, omission-clears behavior, or immediate RAT/client-secret replacement semantics after update. [VERIFIED: `docs/dynamic-registration.md`]

## Current Evidence Already Present And Reusable

- `test/lockspire/web/controllers/registration_controller_test.exs` already contains create/show/update JSON examples and the rotated `registration_access_token` contract that can be mirrored in the DCR guide. [VERIFIED: `test/lockspire/web/controllers/registration_controller_test.exs`]
- `test/lockspire/protocol/registration_management_test.exs` already proves the exact semantics Phase 87 must document: replace-on-`PUT`, omission clears, strict boolean validation, missing-paired-URI failure, and front-channel origin mismatch. [VERIFIED: `test/lockspire/protocol/registration_management_test.exs`]
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` already has the clearest operator-facing wording for separation of concerns and the front-channel best-effort caveat; reuse that tone rather than inventing new copy. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]
- `lib/lockspire/web/live/admin/clients_live/show.ex` already has concise detail-page truth wording for the operator guide. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`]
- `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex` is the strongest runtime truth anchor for the phrase "best effort browser choreography, not verified remote logout". Docs should remain semantically consistent with it. [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`]
- `.planning/phases/85-03-SUMMARY.md` and `.planning/phases/86-03-SUMMARY.md` already summarize the two shipped proof steps and can support milestone-close wording. [VERIFIED: `.planning/phases/85-03-SUMMARY.md`] [VERIFIED: `.planning/phases/86-03-SUMMARY.md`]

## Gray Areas And Risks

### Support truth

- The biggest risk is leaving two contradictory public claims in place: "DCR supports logout metadata" in tests/code reality versus "unsupported" in the canonical support page. The support page must be corrected first because every adjacent document defers to it. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `docs/maintainer-release.md`]
- The support page should say DCR and registration management support the four logout propagation metadata fields, but it should not turn into a lifecycle tutorial. Example-heavy semantics belong in the DCR guide per locked decision D-06. [VERIFIED: `.planning/phases/87-CONTEXT.md`]

### DCR guide semantics

- `docs/dynamic-registration.md` currently says `PUT` uses the full JSON representation and rotates both RAT and client secret, but it does not say omitted logout metadata clears prior values or that the returned RAT replaces the old credential immediately. That omission is a real integration risk for partners. [VERIFIED: `docs/dynamic-registration.md`] [VERIFIED: `test/lockspire/protocol/registration_management_test.exs`]
- The DCR guide should distinguish between "self-service clients can manage existing logout propagation metadata" and "Lockspire added new logout runtime". The former is true; the latter would widen the product claim and violate phase scope. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/phases/87-CONTEXT.md`]

### Release-truth wording

- `docs/maintainer-release.md` already has the right structure because it says public claims defer to `docs/supported-surface.md`. The risk is stale examples or posture wording elsewhere in that file still describing an older narrower DCR surface. A small alignment pass is sufficient; no second support matrix should be added. [VERIFIED: `docs/maintainer-release.md`]

### Operator wording

- `docs/operator-admin.md` currently says operators configure logout propagation explicitly in admin because DCR does not accept those fields. That line is now false, but the operator guide still needs to preserve the admin workflow as a valid explicit path and keep redirect URIs separate from propagation URIs. [VERIFIED: `docs/operator-admin.md`] [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]
- Operator wording must not imply front-channel reliability just because clients can now self-register the URI. The runtime and admin UI both already reject that interpretation. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`] [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`]

## Recommendations For Doc Scope And Plan Split

### Recommended scope

- Update `docs/supported-surface.md` first to remove the explicit "unsupported" claim and replace it with a terse capability statement that DCR/RFC 7592 manage the four existing logout propagation metadata fields while preserving the asymmetry: back-channel durable, front-channel best effort only. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `.planning/phases/87-CONTEXT.md`]
- Add a focused lifecycle section to `docs/dynamic-registration.md` with one create example and one update example covering `backchannel_logout_uri`, `backchannel_logout_session_required`, `frontchannel_logout_uri`, and `frontchannel_logout_session_required`. State plainly that RFC 7592 `PUT` is full-replace, omitted fields clear prior logout metadata, returned RAT replaces the old RAT immediately, and any returned rotated client secret replaces the old secret immediately. [VERIFIED: `docs/dynamic-registration.md`] [VERIFIED: `test/lockspire/web/controllers/registration_controller_test.exs`] [VERIFIED: `test/lockspire/protocol/registration_management_test.exs`]
- Update `docs/operator-admin.md` to say operators can still manage logout propagation in admin, but self-service DCR now manages the same existing metadata for eligible clients. Keep the separation between post-logout redirect URIs and logout propagation. [VERIFIED: `docs/operator-admin.md`] [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]
- Do a narrow release-truth pass in `docs/maintainer-release.md` only where wording would otherwise restate the older narrower DCR support scope. Keep `docs/supported-surface.md` as the only canonical contract. [VERIFIED: `docs/maintainer-release.md`] [VERIFIED: `.planning/phases/87-CONTEXT.md`]

### Recommended plan split

1. Canonical support-truth update: fix the public contract first in `docs/supported-surface.md`. [VERIFIED: `docs/supported-surface.md`]
2. DCR lifecycle guide update: add examples plus `PUT`/RAT/client-secret semantics in `docs/dynamic-registration.md`. [VERIFIED: `docs/dynamic-registration.md`]
3. Operator and release alignment: correct the stale operator line and verify maintainer wording still defers to the canonical support page. [VERIFIED: `docs/operator-admin.md`] [VERIFIED: `docs/maintainer-release.md`]

## Key Files For Planning

- `.planning/phases/87-CONTEXT.md` - locked scope, wording posture, and non-goals. [VERIFIED: `.planning/phases/87-CONTEXT.md`]
- `docs/supported-surface.md` - canonical public support contract and the highest-priority stale claim. [VERIFIED: `docs/supported-surface.md`]
- `docs/dynamic-registration.md` - missing lifecycle semantics and examples for the shipped logout metadata fields. [VERIFIED: `docs/dynamic-registration.md`]
- `docs/operator-admin.md` - stale operator claim that DCR does not accept logout propagation metadata. [VERIFIED: `docs/operator-admin.md`]
- `docs/maintainer-release.md` - release-truth deferral page that may need a narrow wording sync only. [VERIFIED: `docs/maintainer-release.md`]
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - reusable operator wording for concern separation and front-channel caveat. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]
- `lib/lockspire/web/live/admin/clients_live/show.ex` - reusable operator detail wording and RAT terminology. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`]
- `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex` - runtime wording anchor for best-effort front-channel logout. [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`]
- `test/lockspire/web/controllers/registration_controller_test.exs` - create/show/update proof and concrete example shapes. [VERIFIED: `test/lockspire/web/controllers/registration_controller_test.exs`]
- `test/lockspire/protocol/registration_management_test.exs` - full-replace, omission-clears, and validation-failure proof. [VERIFIED: `test/lockspire/protocol/registration_management_test.exs`]

## Sources

### Primary

- `.planning/phases/87-CONTEXT.md` - locked Phase 87 scope and doc-shape decisions.
- `.planning/ROADMAP.md` - milestone/phase scope and `PROOF-02` placement.
- `.planning/REQUIREMENTS.md` - exact milestone truth model and out-of-scope guardrails.
- `.planning/phases/85-03-SUMMARY.md` - shipped create/read/logout metadata proof summary.
- `.planning/phases/86-03-SUMMARY.md` - shipped update/proof summary.
- `docs/supported-surface.md` - canonical public support contract.
- `docs/dynamic-registration.md` - current DCR guide wording.
- `docs/operator-admin.md` - current operator wording.
- `docs/maintainer-release.md` - current release-truth deferral wording.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - operator UI truth copy.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - operator detail truth copy.
- `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex` - runtime front-channel truth copy.
- `test/lockspire/web/controllers/registration_controller_test.exs` - controller proof for create/show/update/logout metadata.
- `test/lockspire/protocol/registration_management_test.exs` - protocol proof for read/update/full-replace semantics.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new stack decision; phase is pure doc closure against existing repo truth. [VERIFIED: repo grep]
- Architecture: HIGH - phase boundary is explicitly documentation-only and constrained by locked decisions. [VERIFIED: `.planning/phases/87-CONTEXT.md`]
- Pitfalls: HIGH - the main risks are directly visible as contradictory wording and already-proven semantics missing from docs. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `docs/operator-admin.md`] [VERIFIED: `docs/dynamic-registration.md`] [VERIFIED: `test/lockspire/protocol/registration_management_test.exs`]

## RESEARCH COMPLETE
