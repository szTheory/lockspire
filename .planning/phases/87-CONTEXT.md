# Phase 87: Support Truth And Milestone Closure - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Close milestone `v1.23 DCR Logout Metadata` by updating support-surface, DCR, operator, and release-truth documentation so the public and operator-facing contract matches the shipped behavior already proven in Phase 85 and Phase 86. This phase does not add new logout runtime, new DCR features beyond the four shipped logout propagation metadata fields, or any stronger front-channel reliability claim.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- Exact section titles, example values, and doc ordering inside the affected guides
- Whether release-truth wording lands in `docs/maintainer-release.md`, milestone-close proof docs, or both, provided `docs/supported-surface.md` remains the canonical source
- The exact amount of cross-linking between the DCR guide, operator guide, and support-contract page

</decisions>

<specifics>
## Specific Ideas

- The recommended documentation shape is intentionally borrowed from mature auth libraries that keep a canonical feature/support contract plus targeted scenario guides, rather than letting every guide redefine support truth.
- The strongest ecosystem lesson to preserve is: support claims should be centralized, but the dangerous operational semantics should be demonstrated where integrators actually work.
- Good precedents to learn from:
  - Doorkeeper: strong install and guide DX, but extension split and historical footguns show why support truth must stay explicit and narrow.
  - `node-oidc-provider`: clear implemented-features matrix plus configuration/feature scoping.
  - OpenIddict: embedded-library shape with strong separation between core capability and host/framework integration guidance.
  - Keycloak and similar platforms: useful reminder that front-channel logout must not be described as equally reliable with back-channel logout.
- Anti-patterns to avoid:
  - Saying “Lockspire supports logout via DCR” without clarifying this is metadata management for an already-shipped runtime
  - Treating RFC 7592 `PUT` like patch semantics
  - Burying RAT rotation and replacement semantics in incidental prose
  - Writing repeated warning banners everywhere until the docs become noisy and defensive

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase boundary
- `.planning/PROJECT.md` — current milestone goal, support-truth posture, and product boundary for v1.23
- `.planning/REQUIREMENTS.md` — `PROOF-02` milestone requirement and explicit out-of-scope guardrails
- `.planning/ROADMAP.md` — Phase 87 scope and milestone-close intent
- `.planning/STATE.md` — current repo state and next-action framing for Phase 87

### Prior phase truth
- `.planning/phases/85-03-SUMMARY.md` — DCR create/read response truth for persisted logout metadata
- `.planning/phases/86-03-SUMMARY.md` — lifecycle proof for RFC 7592 update success/failure and shared reason-code truth

### Product and methodology guidance
- `.planning/METHODOLOGY.md` — assumption-first recommendation mode, research-first decisive defaults, and high-threshold escalation
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` — product thesis, ecosystem lessons, and narrow embedded-library positioning
- `prompts/lockspire-elixir-oss-library-practices.md` — Elixir-native library DX and documentation expectations
- `prompts/lockspire-host-app-integration-seam.md` — least-surprise host/library boundary
- `prompts/lockspire-operator-admin-ia-and-workflows.md` — operator UX expectations and calm admin-surface tone
- `prompts/lockspire-operator-ux-liveview.md` — LiveView UX and information-architecture principles
- `prompts/lockspire-release-readiness-and-conformance.md` — docs-as-contract and release-truth expectations
- `prompts/lockspire-security-posture-and-threat-model.md` — security and overclaiming boundaries relevant to logout/DCR wording

### Docs and code surfaces to update against
- `docs/supported-surface.md` — canonical public support contract
- `docs/dynamic-registration.md` — partner/integrator DCR guide
- `docs/operator-admin.md` — operator workflow guide
- `docs/maintainer-release.md` — maintainer-only release truth that must defer to canonical support truth
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — existing inline operator truth wording for logout propagation editing
- `lib/lockspire/web/live/admin/clients_live/show.ex` — existing client detail truth wording for logout propagation
- `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex` — runtime front-channel best-effort wording that docs must not contradict
- `test/lockspire/web/controllers/registration_controller_test.exs` — controller proof for DCR create/show/update logout metadata behavior and RAT rotation
- `test/lockspire/protocol/registration_management_test.exs` — protocol proof for management-read/update semantics and persisted truth

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/support/fixtures/dcr_fixtures.ex`: existing DCR/logout metadata fixtures can anchor documentation examples so examples stay aligned with proven shapes.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex`: already contains concise operator-facing truth text for front-channel best-effort semantics.
- `lib/lockspire/web/live/admin/clients_live/show.ex`: already separates logout propagation from other client metadata and states the front-channel caveat clearly.
- `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`: already expresses the runtime truth model in user-facing wording.

### Established Patterns
- Lockspire already treats `docs/supported-surface.md` as the canonical support contract and expects other public/maintainer docs to defer to it.
- Prior phases favored repo-native proof and narrow truthful claims over broad marketing-style capability language.
- The project’s methodology explicitly prefers decisive defaults and high-threshold user escalation for medium-value implementation/documentation choices.

### Integration Points
- Phase 87 work should connect proven DCR behavior from controller/protocol tests to user-facing docs without introducing any new runtime surface.
- Milestone-close/release-truth wording must align with the support-contract edits but not create a second support matrix.

</code_context>

<deferred>
## Deferred Ideas

- A broader docs architecture sweep or README refresh for all DCR capabilities
- Richer partner-portal or hosted-style DCR walkthroughs beyond the narrow embedded-library guide
- Additional automated doc-verification tests for support-surface wording drift, if support burden later justifies them

</deferred>

---

*Phase: 87-support-truth-and-milestone-closure*
*Context gathered: 2026-05-24*
