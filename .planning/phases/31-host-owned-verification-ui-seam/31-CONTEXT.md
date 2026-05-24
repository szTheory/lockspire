# Phase 31: Host-Owned Verification UI Seam - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Give the host Phoenix app a secure, ergonomic verification seam for OAuth 2.0 Device Authorization Grant user approval. This phase does not finish token polling or issuance; it defines the durable lookup/approve/deny seams, generated host-owned browser surface, and documentation contract that let a host app build a trustworthy `/verify` flow without widening Lockspire into a library-owned auth UI product.

After this phase: a host app has generated verification routes/files to edit, narrow library APIs to resolve a pending device authorization by `user_code` and approve or deny it with an explicit signed-in actor, and concrete documentation for rate-limiting the verification endpoints.

**Explicitly out of scope this phase:**
- Device polling and token issuance (`authorization_pending`, `slow_down`, token minting) — Phase 32
- Lockspire-owned generic verification HTML as the primary supported path
- Built-in runtime rate-limiting Plug/helper shipped by Lockspire
- QR-code rendering, device branding catalogues, or advanced theming hooks
- Broadening Lockspire into a hosted auth service or non-Phoenix-first surface

Requirements covered by this phase: **DEV-04, DEV-05, DEV-06**.
</domain>

<decisions>
## Implementation Decisions

### Verification Seam Shape

- **D-01:** Phase 31 follows Lockspire's existing seam pattern: **generated, host-owned verification files and routes backed by narrow protocol/context functions**. The primary supported shape is not docs-only scratch integration and not a Lockspire-owned generic browser UI.
- **D-02:** `mix lockspire.install` should generate a host-owned verification seam alongside the existing router/account/interaction/consent files. The generated surface should be editable Phoenix code in the host app, and reruns must continue the current refusal-to-overwrite-modified-files behavior.
- **D-03:** The generated host seam should include at minimum a host-owned verification route entrypoint (`GET /verify` and `POST /verify` or equivalent), plus starter controller and/or LiveView code that demonstrates the approved secure flow.
- **D-04:** Lockspire owns the durable protocol/state transitions and validation rules; the host owns browser routing, layout, copy, account pipeline, session handling, and product-specific framing.
- **D-05:** Do **not** make `Lockspire.Web.Router` the primary mounted owner of `/verify` browser UX. A library-owned verification controller/UI with override hooks is explicitly rejected for v1 because it widens the product shape in the wrong direction.

### Prefill and `verification_uri_complete`

- **D-06:** Lockspire should ship `verification_uri_complete` in the device authorization response for this slice.
- **D-07:** `verification_uri_complete` is a **prefill optimization only**. It may populate the `user_code` into the host-owned verification form, but it must never auto-submit, auto-look-up, auto-approve, or auto-advance the authorization on page load.
- **D-08:** The host verification page must visibly show the `user_code` again and prompt the user to confirm it matches what is displayed on the requesting device. This remains required even when `verification_uri_complete` is used.
- **D-09:** Generated code and docs must explicitly warn against logging raw verification query strings, hiding the code-match confirmation, or treating a GET request to `verification_uri_complete` as an approval signal.

### Approval Surface and State Transitions

- **D-10:** Lockspire should model the verification flow as a **two-step library API** even if the host renders it as a streamlined one-page UX. Lookup and mutation remain separate operations.
- **D-11:** The library should expose a narrow lookup seam shaped like `lookup_pending_device_authorization(user_code, opts)` or equivalent, returning either a pending verification context or typed non-success states that distinguish internal semantics such as `:not_found`, `:expired`, and `:not_active`.
- **D-12:** Host-facing default UX copy may collapse `:not_found` and `:expired` to a neutral message like "invalid or expired code" to avoid building an existence oracle.
- **D-13:** Approval and denial must be **separate explicit mutations** on an opaque library-owned verification handle or durable record id, not on the raw `user_code` again. The mutation step must require explicit signed-in actor context from the host app so authorization binds to the host account/subject at approval time.
- **D-14:** The verification surface must show enough request context before mutation for possession checking and user comprehension: at minimum the `user_code`, client identity/name, and requested scopes; planner/research may add safe device-facing context fields if the storage shape supports them without widening scope.
- **D-15:** Pending device authorizations need explicit durable lifecycle state beyond the current bare pending record. The working target shape is at least `:pending | :approved | :denied | :consumed | :expired`, with expected-state transitions enforced in Lockspire, not in host controllers.
- **D-16:** Approval/denial transitions must be race-safe and idempotency-aware using the repository/transaction style already established elsewhere in Lockspire (`SELECT ... FOR UPDATE` or equivalent expected-state update discipline). Planner should treat stale retries, duplicate submits, and poll/approve races as first-class cases.

### Rate-Limit Documentation Contract

- **D-17:** Keep the prior milestone decision: **no built-in runtime rate-limiting helper ships in Lockspire for this seam**. Phase 31 delivers a documentation contract and generated comments, not a reusable enforcement dependency.
- **D-18:** Documentation must be concrete, not principle-only. Provide an idiomatic Phoenix/Plug example and guidance for both `GET /verify` and `POST /verify`, while keeping the implementation host-owned.
- **D-19:** The documented baseline should include:
  - trusted client IP guidance, including proxy-awareness
  - normalization of `user_code` (strip separators, uppercase) before limit keys
  - a primary limit dimension by IP
  - a secondary limit dimension by normalized `user_code`
  - a tighter failed-submission guard keyed by `{normalized_user_code, IP}`
  - an optional softer per-session or per-account limit once the user is signed in
- **D-20:** Recommended limit-breach behavior: 429 with short `Retry-After`; no code-existence oracle; neutral error copy where practical; stepped or exponential backoff on repeated POST failures; redacted security logging/audit keyed by fingerprints rather than raw codes.
- **D-21:** The docs should mention idiomatic Phoenix/Plug options without making Lockspire depend on them. `Hammer` and `PlugAttack` are acceptable example points because they match common Plug middleware patterns, but the contract is behavioral rather than package-specific.
- **D-22:** The verification rate-limit guidance should live in a dedicated device-flow host guide and be linked from onboarding, supported-surface docs, install-generator next steps, and generated seam comments so hosts see the contract during setup.

### Workflow Preference

- **D-23:** Shift decision pressure left in GSD for this project: for low- to medium-impact implementation details, downstream agents should prefer coherent recommendations and proceed without re-asking. Escalate back to the user only for materially high-impact product-boundary, protocol-safety, or support-contract choices.

### the agent's Discretion

- Exact controller vs LiveView split for the generated verification seam may be chosen during planning as long as the generated surface remains host-owned and the locked security/interaction rules above are preserved.
- Exact naming of the protocol modules/functions/structs may be chosen during planning if the resource shape stays narrow and Phoenix-native.
- Exact presentation details, copy tone, and layout of the generated verification page may be chosen during planning as long as they keep the code confirmation, explicit approve/deny action, and neutral invalid-or-expired failure posture.
- Planner may decide whether the host starter seam is one page or two pages, but the underlying library contract must remain separate lookup plus approve/deny operations.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and carry-forward constraints

- `.planning/ROADMAP.md` — Phase 31 goal, dependency on Phase 30, and success criteria for host lookup seam, explicit user action, and rate-limit documentation
- `.planning/REQUIREMENTS.md` — DEV-04, DEV-05, DEV-06
- `.planning/PROJECT.md` — embedded-library shape, host-owned UX boundary, secure defaults, and generator-first product posture
- `.planning/STATE.md` — already-locked device-flow decisions: host-owned verification UI, no built-in rate limiting, anti-phishing focus

### Existing install and host seam pattern

- `docs/install-and-onboard.md` — canonical onboarding flow and generated host-owned integration model
- `lib/lockspire/generators/install.ex` — generator behavior, next-step guidance, and refusal to overwrite modified files
- `priv/templates/lockspire.install/router.ex` — host-owned route mounting precedent
- `priv/templates/lockspire.install/account_resolver.ex` — host-owned account seam precedent
- `priv/templates/lockspire.install/interaction_handler.ex` — generated host-owned interaction helper precedent
- `priv/templates/lockspire.install/consent_live.ex` — generated host-owned browser UX precedent

### Existing browser/protocol split

- `lib/lockspire/web/interaction_controller.ex` — thin browser adapter pattern with host account resolution and library-owned state transitions
- `lib/lockspire/web/live/consent_live.ex` — reference consent surface and current host-owned/Lockspire-owned responsibility split
- `lib/lockspire/host/account_resolver.ex` — explicit host seam contract for signed-in subject resolution

### Current device-flow slice

- `lib/lockspire/protocol/device_authorization.ex` — current device authorization response shape and `verification_uri` handling
- `lib/lockspire/domain/device_authorization.ex` — current device authorization durable model to extend with lifecycle state
- `lib/lockspire/storage/device_authorization_store.ex` — current storage behavior boundary
- `lib/lockspire/storage/ecto/repository.ex` — transaction/expected-state patterns to mirror for race-safe approval transitions
- `test/lockspire/protocol/device_authorization_test.exs` — current protocol behavior proof for the device request side
- `test/lockspire/web/controllers/device_authorization_controller_test.exs` — current HTTP proof for device authorization response fields

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Generators.Install` and the install templates already provide the exact product pattern this phase should reuse: safe generated host-owned files instead of library-owned UI.
- `Lockspire.Host.AccountResolver` is the natural seam for binding approval to the signed-in host account/subject.
- `Lockspire.Web.InteractionController` and `Lockspire.Web.ConsentLive` are the best precedents for thin browser adapters over library-owned durable protocol state.
- `Lockspire.Protocol.DeviceAuthorization` already emits `verification_uri` and has a `verification_uri_complete` field in its success struct, so Phase 31 should use that existing response surface rather than inventing a separate prefill mechanism.
- `Lockspire.Storage.Ecto.Repository` already has transaction and expected-state patterns used elsewhere for single-use/token-like lifecycle changes; planner should reuse that style for verify/approve transitions.

### Established Patterns

- Lockspire keeps browser UX host-editable while preserving protocol correctness in library-owned modules.
- Generators are part of the product surface; the install path is expected to scaffold real host code, not just docs.
- Secure defaults are enforced in protocol/storage layers, while host seams remain explicit and narrow.
- Existing browser interactions already separate read context from approval/denial mutation; Phase 31 should stay aligned with that mental model.

### Integration Points

- The generated verification seam should plug into the host router alongside the existing generated authorized-apps and consent surfaces.
- Approval should consume signed-in host account context through `Lockspire.account_resolver!/0` or an equivalent host seam, then pass explicit actor/subject context into library approval APIs.
- The device authorization storage/domain layer needs extension for lookup-by-user-code, lifecycle state, and approval/denial writes that Phase 32 can later consume from the polling/token path.
- Documentation updates should connect onboarding, supported-surface, and generated comments so the security contract is visible at install time.

</code_context>

<specifics>
## Specific Ideas

- The coherent target is **generated host-owned verification UX over a two-step library API**: host may render one page or two, but lookup and approve/deny remain distinct under the hood.
- `verification_uri_complete` should be treated like Auth0/Okta-style QR/prefill ergonomics, not like an auto-approval shortcut.
- Manual-code-only ecosystems such as Microsoft/GitHub are useful cautionary examples: they avoid some phishing risk, but they also leave UX value on the table. Lockspire should keep the optimization while preserving explicit user intent.
- Successful companion-library patterns in this space consistently keep user interactions implementer-owned or generated into the host app rather than making the core protocol library own all browser UX.
- Footguns to avoid:
  - GET requests with side effects
  - approval by raw `user_code` without a second durable handle
  - invalid-vs-expired oracle leakage
  - rate-limiting guidance that ignores proxy IP correctness or code normalization
  - generated code that implies "secure by default" while omitting the rate-limit requirement

</specifics>

<deferred>
## Deferred Ideas

- Built-in rate-limiting Plug/helper with distributed backend semantics — rejected for this phase; reconsider only if a later milestone intentionally widens Lockspire's support surface.
- Library-owned generic verification HTML/controller with theming hooks — rejected for v1 embedded-library shape.
- QR-code rendering helpers, device metadata enrichment, or branded device catalogues — separate future enhancement if the narrow verification seam proves insufficient.
- Broader cross-device hardening beyond the current explicit-user-action and possession-confirmation posture — consider in future milestone if support contract expands.

</deferred>

---

*Phase: 31-host-owned-verification-ui-seam*
*Context gathered: 2026-04-28*
