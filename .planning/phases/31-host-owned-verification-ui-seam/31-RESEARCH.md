# Phase 31: Host-Owned Verification UI Seam - Research

**Researched:** 2026-04-28 [VERIFIED: project clock]
**Domain:** Phoenix host-owned verification seam for OAuth 2.0 Device Authorization Grant [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase + RFC 8628 + official Phoenix/Ecto/Hex docs aligned]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

#### Verification Seam Shape

- **D-01:** Phase 31 follows Lockspire's existing seam pattern: **generated, host-owned verification files and routes backed by narrow protocol/context functions**. The primary supported shape is not docs-only scratch integration and not a Lockspire-owned generic browser UI.
- **D-02:** `mix lockspire.install` should generate a host-owned verification seam alongside the existing router/account/interaction/consent files. The generated surface should be editable Phoenix code in the host app, and reruns must continue the current refusal-to-overwrite-modified-files behavior.
- **D-03:** The generated host seam should include at minimum a host-owned verification route entrypoint (`GET /verify` and `POST /verify` or equivalent), plus starter controller and/or LiveView code that demonstrates the approved secure flow.
- **D-04:** Lockspire owns the durable protocol/state transitions and validation rules; the host owns browser routing, layout, copy, account pipeline, session handling, and product-specific framing.
- **D-05:** Do **not** make `Lockspire.Web.Router` the primary mounted owner of `/verify` browser UX. A library-owned verification controller/UI with override hooks is explicitly rejected for v1 because it widens the product shape in the wrong direction.

#### Prefill and `verification_uri_complete`

- **D-06:** Lockspire should ship `verification_uri_complete` in the device authorization response for this slice.
- **D-07:** `verification_uri_complete` is a **prefill optimization only**. It may populate the `user_code` into the host-owned verification form, but it must never auto-submit, auto-look-up, auto-approve, or auto-advance the authorization on page load.
- **D-08:** The host verification page must visibly show the `user_code` again and prompt the user to confirm it matches what is displayed on the requesting device. This remains required even when `verification_uri_complete` is used.
- **D-09:** Generated code and docs must explicitly warn against logging raw verification query strings, hiding the code-match confirmation, or treating a GET request to `verification_uri_complete` as an approval signal.

#### Approval Surface and State Transitions

- **D-10:** Lockspire should model the verification flow as a **two-step library API** even if the host renders it as a streamlined one-page UX. Lookup and mutation remain separate operations.
- **D-11:** The library should expose a narrow lookup seam shaped like `lookup_pending_device_authorization(user_code, opts)` or equivalent, returning either a pending verification context or typed non-success states that distinguish internal semantics such as `:not_found`, `:expired`, and `:not_active`.
- **D-12:** Host-facing default UX copy may collapse `:not_found` and `:expired` to a neutral message like "invalid or expired code" to avoid building an existence oracle.
- **D-13:** Approval and denial must be **separate explicit mutations** on an opaque library-owned verification handle or durable record id, not on the raw `user_code` again. The mutation step must require explicit signed-in actor context from the host app so authorization binds to the host account/subject at approval time.
- **D-14:** The verification surface must show enough request context before mutation for possession checking and user comprehension: at minimum the `user_code`, client identity/name, and requested scopes; planner/research may add safe device-facing context fields if the storage shape supports them without widening scope.
- **D-15:** Pending device authorizations need explicit durable lifecycle state beyond the current bare pending record. The working target shape is at least `:pending | :approved | :denied | :consumed | :expired`, with expected-state transitions enforced in Lockspire, not in host controllers.
- **D-16:** Approval/denial transitions must be race-safe and idempotency-aware using the repository/transaction style already established elsewhere in Lockspire (`SELECT ... FOR UPDATE` or equivalent expected-state update discipline). Planner should treat stale retries, duplicate submits, and poll/approve races as first-class cases.

#### Rate-Limit Documentation Contract

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

#### Workflow Preference

- **D-23:** Shift decision pressure left in GSD for this project: for low- to medium-impact implementation details, downstream agents should prefer coherent recommendations and proceed without re-asking. Escalate back to the user only for materially high-impact product-boundary, protocol-safety, or support-contract choices.

### Claude's Discretion [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

- Exact controller vs LiveView split for the generated verification seam may be chosen during planning as long as the generated surface remains host-owned and the locked security/interaction rules above are preserved.
- Exact naming of the protocol modules/functions/structs may be chosen during planning if the resource shape stays narrow and Phoenix-native.
- Exact presentation details, copy tone, and layout of the generated verification page may be chosen during planning as long as they keep the code confirmation, explicit approve/deny action, and neutral invalid-or-expired failure posture.
- Planner may decide whether the host starter seam is one page or two pages, but the underlying library contract must remain separate lookup plus approve/deny operations.

### Deferred Ideas (OUT OF SCOPE) [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

- Built-in rate-limiting Plug/helper with distributed backend semantics — rejected for this phase; reconsider only if a later milestone intentionally widens Lockspire's support surface.
- Library-owned generic verification HTML/controller with theming hooks — rejected for v1 embedded-library shape.
- QR-code rendering helpers, device metadata enrichment, or branded device catalogues — separate future enhancement if the narrow verification seam proves insufficient.
- Broader cross-device hardening beyond the current explicit-user-action and possession-confirmation posture — consider in future milestone if support contract expands.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEV-04 | Expose `GET /verify` and `POST /verify` integration seams for the host app to render consent/verification UI. [VERIFIED: .planning/REQUIREMENTS.md] | Generated host-owned router/controller or LiveView files should follow the existing install generator pattern and keep Lockspire’s browser role thin. [VERIFIED: lib/lockspire/generators/install.ex] [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: priv/templates/lockspire.install/router.ex] [VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex] |
| DEV-05 | Prevent auto-submit on `verification_uri_complete` to mitigate remote phishing. [VERIFIED: .planning/REQUIREMENTS.md] | RFC 8628 still requires the user interaction sequence and explicit code confirmation even when `verification_uri_complete` is used; the host page must treat the query parameter as prefill only. [CITED: https://www.rfc-editor.org/rfc/rfc8628] |
| DEV-06 | Provide documentation on rate-limiting the `/verify` endpoint for the host app (no built-in rate limiting). [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the existing docs pattern from Dynamic Client Registration: host responsibility, concrete Plug examples, and doc links wired into onboarding and supported-surface docs. [VERIFIED: docs/dynamic-registration.md] [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/supported-surface.md] |
</phase_requirements>

## Summary

Phase 31 should be planned as a **host-owned browser seam over library-owned durable state**, not as a UI feature inside `Lockspire.Web.Router`. That is already Lockspire’s product pattern in the install generator, the router mount helper, the host account resolver seam, and the existing interaction/consent flow. [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/generators/install.ex] [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: priv/templates/lockspire.install/router.ex] [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex]

The main planning gap is **state shape**, not page rendering. Phase 30 persisted only code hashes, client id, scopes, and expiry, with no lifecycle column, no lookup API, and no approval/denial mutation path yet. Phase 31 therefore needs schema/domain/store expansion before the host seam can do anything secure. [VERIFIED: lib/lockspire/domain/device_authorization.ex] [VERIFIED: lib/lockspire/storage/device_authorization_store.ex] [VERIFIED: lib/lockspire/storage/ecto/device_authorization_record.ex] [VERIFIED: priv/repo/migrations/20260427210707_create_lockspire_device_authorizations.exs] [VERIFIED: .planning/phases/30-core-device-authorization-endpoint-and-storage/30-03-SUMMARY.md]

The anti-phishing rule is non-negotiable: RFC 8628 allows `verification_uri_complete` as a shortcut, but the user interaction still has to occur and the user code still has to be shown and confirmed. The current codebase already declares a `verification_uri_complete` field in `Lockspire.Protocol.DeviceAuthorization.Success`, but `authorize/1` does not populate it yet, so this phase should include that response completion alongside the host prefill seam. [CITED: https://www.rfc-editor.org/rfc/rfc8628] [VERIFIED: lib/lockspire/protocol/device_authorization.ex]

**Primary recommendation:** Generate a host-owned Phoenix verification seam that performs a normalized `user_code` lookup on `POST /verify`, renders a review step with explicit code confirmation, and calls separate approve/deny mutations on an opaque verification handle backed by `FOR UPDATE`-style state transitions in `Lockspire.Storage.Ecto.Repository`. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Host route entry (`GET /verify`) | Browser / Client | Frontend Server (SSR) | The host app owns routing, layout, and page framing, while Phoenix dispatches the route into host code. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |
| Verification form lookup (`POST /verify`) | Frontend Server (SSR) | API / Backend | The host endpoint receives browser input, normalizes `user_code`, and delegates lookup to a narrow library API. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex] |
| Approval / denial transition | API / Backend | Database / Storage | Lockspire must own expected-state validation, actor binding, and terminal transitions instead of leaving those rules in host controllers. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Pending verification lookup by `user_code` | Database / Storage | API / Backend | The data is durable device-flow state that Phase 32 polling will later consume, so the lookup contract should come from the storage/protocol boundary. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: lib/lockspire/storage/device_authorization_store.ex] |
| Rate limiting and trusted IP extraction | Frontend Server (SSR) | Browser / Client | Enforcement belongs in the host Plug pipeline around `/verify`, not in Lockspire runtime code. [VERIFIED: docs/dynamic-registration.md] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [CITED: https://hexdocs.pm/plug/Plug.Conn.html] |
| Poll-consumable lifecycle states for Phase 32 | Database / Storage | API / Backend | Polling correctness depends on durable status fields and idempotent transitions that are already stored server-side. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `1.8.5` [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/api/packages/phoenix] | Host-owned `get/3` and `post/3` route generation plus thin controllers around the verification seam. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] | The repo already uses Phoenix routers/controllers for host-facing HTTP seams, and Phoenix documents `get/3` and `post/3` as the standard way to dispatch browser routes. [VERIFIED: lib/lockspire/web/router.ex] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |
| `phoenix_live_view` | `1.1.28` [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/api/packages/phoenix_live_view] | Optional generated review UI using `Phoenix.Component.form/1` and `to_form/1` if the planner chooses a LiveView starter seam. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-UI-SPEC.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] | Lockspire already ships a generated consent LiveView and a library consent LiveView, so LiveView is an established repo-local browser surface rather than a new dependency choice. [VERIFIED: priv/templates/lockspire.install/consent_live.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex] |
| `ecto_sql` | `3.13.5` [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/api/packages/ecto_sql] | Durable lookup and race-safe approval/denial transitions for device authorizations. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] | Ecto’s `lock/3` supports `SELECT ... FOR UPDATE`, which matches the repository pattern Lockspire already uses for single-use or expected-state transitions. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| `Lockspire.Generators.Install` templates | repo-local [VERIFIED: lib/lockspire/generators/install.ex] [VERIFIED: lib/lockspire/generators/templates.ex] | Generates host-owned router and UI seam files with refusal to overwrite modified files. [VERIFIED: test/integration/install_generator_test.exs] | This is already part of Lockspire’s support contract and should remain the primary delivery mechanism for the verification seam. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/supported-surface.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `hammer` | `7.3.0` [VERIFIED: https://hex.pm/api/packages/hammer] | Host-side rate-limit example for IP, normalized-code, and failure-bucket keys using `hit/3`. [CITED: https://hexdocs.pm/hammer/Hammer.html] | Use only in documentation examples when the host wants a small, explicit rate-limiter module with ETS or another Hammer backend. Lockspire should not depend on it directly. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |
| `plug_attack` | `0.4.3` [VERIFIED: https://hex.pm/api/packages/plug_attack] | Host-side Plug example for blocking and throttling abusive `/verify` traffic at the router/pipeline layer. [CITED: https://hexdocs.pm/plug_attack/PlugAttack.html] | Use in documentation when the host already prefers Plug-first abuse controls over an app-specific limiter module. Lockspire should mention it as an option, not as a dependency. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |
| `remote_ip` | `1.2.0` [VERIFIED: https://hex.pm/api/packages/remote_ip] | Optional host-side proxy-aware `remote_ip` rewriting before rate-limit keys are derived. [CITED: https://hexdocs.pm/remote_ip/RemoteIp.html] | Use only in docs as a proxy-awareness example when the host terminates traffic behind load balancers or reverse proxies. [ASSUMED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Generated host-owned verification seam | Library-owned `/verify` controller/UI inside `Lockspire.Web.Router` | Rejected by locked phase decisions because it widens Lockspire into a browser-UI product and breaks the embedded-library seam. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |
| Separate lookup and approve/deny APIs | Single mutation on raw `user_code` | Rejected because it weakens auditability, makes stale retries harder to classify, and violates the locked requirement for opaque-handle mutations. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |
| Host docs with concrete Plug examples | Built-in Lockspire rate-limiter helper | Rejected because the support contract keeps rate limiting host-owned for this phase. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: docs/dynamic-registration.md] |

**Installation:** No new runtime dependency is required for the core phase implementation; only documentation may mention optional host-side examples such as `hammer`, `plug_attack`, or `remote_ip`. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**Version verification:** Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, and Ecto SQL `3.13.5` are both the repo-pinned versions and the latest stable Hex releases as of 2026-04-28. Hammer `7.3.0`, PlugAttack `0.4.3`, and RemoteIp `1.2.0` are the latest stable releases on Hex as of 2026-04-28. [VERIFIED: https://hex.pm/api/packages/phoenix] [VERIFIED: https://hex.pm/api/packages/phoenix_live_view] [VERIFIED: https://hex.pm/api/packages/ecto_sql] [VERIFIED: https://hex.pm/api/packages/hammer] [VERIFIED: https://hex.pm/api/packages/plug_attack] [VERIFIED: https://hex.pm/api/packages/remote_ip]

## Architecture Patterns

### System Architecture Diagram

```text
Browser
  -> GET /verify
Host Phoenix route/controller or LiveView
  -> render code-entry page (prefill only if query has user_code)
User explicit submit
  -> POST /verify with raw user_code
Host seam normalizes code + applies host rate limits
  -> Lockspire lookup API
Lockspire protocol/store
  -> load device authorization by normalized user_code hash
  -> classify :pending | :expired | :not_active | :not_found
Host seam renders review step
  -> show user_code + client name + scopes + signed-in account context
User explicit approve or deny
  -> POST approve/deny with opaque verification handle
Lockspire protocol/store transaction
  -> lock row FOR UPDATE
  -> enforce expected state
  -> persist approved/denied terminal state + actor binding
Phase 32 poll/token path
  -> reads durable state and returns authorization_pending / slow_down / tokens later
```
[VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: .planning/ROADMAP.md]

### Recommended Project Structure

```text
lib/lockspire/protocol/
├── device_verification.ex          # Lookup + approve/deny protocol API
lib/lockspire/storage/
├── device_authorization_store.ex   # Extend with lookup/transition callbacks
lib/lockspire/storage/ecto/
├── device_authorization_record.ex  # Add lifecycle + actor-binding fields
lib/lockspire/generators/
├── install.ex                      # Extend assigns/instructions
lib/lockspire/generators/templates.ex
priv/templates/lockspire.install/
├── router.ex                       # Add host-owned /verify routes
├── verification_controller.ex      # or verification_live.ex starter seam
├── verification_html.ex            # if controller path is chosen
├── verification/index.html.heex    # if controller path is chosen
└── verification_live.ex            # if LiveView path is chosen
docs/
├── device-flow-host-guide.md       # rate-limit + phishing guidance
```
[VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: priv/templates/lockspire.install/router.ex] [VERIFIED: docs/dynamic-registration.md] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

### Pattern 1: Generated Host-Owned Browser Seam

**What:** Extend `mix lockspire.install` to generate editable host files for `/verify`, just like today’s router, account resolver, interaction handler, and consent LiveView stubs. [VERIFIED: lib/lockspire/generators/install.ex] [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: test/integration/install_generator_test.exs]

**When to use:** Always for the primary supported verification path in v1. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**Example:**
```elixir
# Source: priv/templates/lockspire.install/router.ex
defmodule MyAppWeb.Router.Lockspire do
  def lockspire_routes do
    """
    scope "/", MyAppWeb do
      pipe_through [:browser]

      get "/verify", LockspireVerificationController, :show
      post "/verify", LockspireVerificationController, :lookup
      post "/verify/:handle/approve", LockspireVerificationController, :approve
      post "/verify/:handle/deny", LockspireVerificationController, :deny
    end

    scope "/" do
      forward "/lockspire", Lockspire.Web.Router
    end
    """
  end
end
```
[VERIFIED: priv/templates/lockspire.install/router.ex] [ASSUMED]

### Pattern 2: Two-Step Verification API over Durable State

**What:** Separate lookup from mutation, and perform approval/denial on a verification handle or record id instead of the raw `user_code`. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**When to use:** For every host verification flow, even if the host renders the steps on one page. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**Example:**
```elixir
# Source: recommended shape derived from AuthorizationFlow + Repository patterns
case DeviceVerification.lookup_pending_device_authorization(user_code,
       device_authorization_store: Repository,
       client_store: Repository,
       now: DateTime.utc_now()
     ) do
  {:ok, verification} ->
    # render user_code, client, scopes, and hidden opaque handle

  {:error, :not_found} ->
    # collapse to neutral invalid-or-expired copy

  {:error, :expired} ->
    # collapse to neutral invalid-or-expired copy

  {:error, :not_active} ->
    # tell the user to restart on the device
end
```
[VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [ASSUMED]

### Pattern 3: Expected-State Mutation with Row Locking

**What:** Use the repository’s existing transaction style to guarantee one terminal transition wins and stale retries become typed `:invalid_state` outcomes. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex]

**When to use:** Approval, denial, and future Phase 32 poll consumption. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**Example:**
```elixir
# Source: lib/lockspire/protocol/authorization_flow.ex + lib/lockspire/storage/ecto/repository.ex
with {:ok, completed} <-
       interaction_store(opts).transition_interaction(
         interaction_id,
         [:pending_consent],
         %{status: :completed, completed_at: now(opts)}
       ) do
  {:ok, completed}
end
```
[VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

### Anti-Patterns to Avoid

- **GET with side effects:** RFC 8628 still requires user interaction after `verification_uri_complete`; a GET request must never approve, deny, or auto-look-up in a way that mutates durable state. [CITED: https://www.rfc-editor.org/rfc/rfc8628] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]
- **Mutation by raw `user_code`:** Raw-code mutations make stale retries and duplicate submits harder to classify and violate the locked opaque-handle requirement. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]
- **Library-owned verification HTML as the supported path:** That contradicts the generator-first embedded-library support contract. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/supported-surface.md] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]
- **State transition logic in host controllers:** The repo already centralizes stateful correctness in protocol/store layers; copying that logic into generated host code would be a regression. [VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verification browser surface ownership | Generic Lockspire-owned `/verify` UI product | Generated host-owned Phoenix files | Lockspire’s current install and onboarding contract is generator-first and host-editable. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: test/integration/install_generator_test.exs] |
| Concurrency control for approve/deny | Ad hoc mutexes, process mailboxes, or controller-only guards | Repository transactions plus `lock/3` / expected-state updates | Ecto officially supports row-level pessimistic locking, and the repo already uses that pattern in multiple lifecycle mutations. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Host-side abuse controls | Lockspire runtime limiter dependency | Documentation contract with Hammer / PlugAttack examples | The locked phase boundary explicitly keeps runtime enforcement in the host app. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: docs/dynamic-registration.md] |
| Code confirmation UX | Hidden autofill-only flow | Visible re-display of `user_code` with possession prompt | RFC 8628 explicitly says the code should still be displayed and confirmed for remote phishing mitigation. [CITED: https://www.rfc-editor.org/rfc/rfc8628] |
| Durable state classification | Single `pending` record with nil/non-nil field heuristics | Explicit status enum plus typed lookup outcomes | Phase 32 polling will need durable state that distinguishes pending, denied, consumed, and expired paths. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md] |

**Key insight:** This phase is mostly about preserving Lockspire’s existing seam discipline while adding enough durable state for correctness. The browser UI itself is the easy part. [VERIFIED: lib/lockspire/generators/install.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

## Common Pitfalls

### Pitfall 1: Treating `verification_uri_complete` as an action instead of a prefill

**What goes wrong:** A host app accepts `GET /verify?user_code=...` as an implicit lookup or approval step, enabling phishing shortcuts and violating the explicit-action requirement. [CITED: https://www.rfc-editor.org/rfc/rfc8628]

**Why it happens:** The code is already present in the query string, so implementers are tempted to skip the manual confirmation step. [CITED: https://www.rfc-editor.org/rfc/rfc8628]

**How to avoid:** Only prefill the input field, show the code again in the review UI, and require a user click before lookup or approval. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-UI-SPEC.md] [CITED: https://www.rfc-editor.org/rfc/rfc8628]

**Warning signs:** Generated code uses `phx-mounted`, `JS.push`, `window.onload`, or controller redirects to trigger lookup automatically when `user_code` is present. [ASSUMED]

### Pitfall 2: Planning the host seam before expanding device-authorization state

**What goes wrong:** The team scaffolds `/verify` pages first, then discovers there is no durable status machine, no actor-binding fields, and no mutation callback in the store. [VERIFIED: lib/lockspire/domain/device_authorization.ex] [VERIFIED: lib/lockspire/storage/device_authorization_store.ex]

**Why it happens:** Phase 30 only delivered request-side issuance and storage, not verification lifecycle operations. [VERIFIED: .planning/phases/30-core-device-authorization-endpoint-and-storage/30-03-SUMMARY.md]

**How to avoid:** Plan schema/domain/store changes ahead of generator and docs work, and make the lookup/mutation API the source of truth for the generated seam. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**Warning signs:** Proposed host templates call `Repository` directly, mutate by `user_code`, or branch on guessed status derived from timestamps alone. [ASSUMED]

### Pitfall 3: Returning existence-oracle errors from lookup

**What goes wrong:** The host UI exposes different copy for nonexistent vs expired codes, making brute-force feedback clearer than necessary. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**Why it happens:** Internal typed outcomes are surfaced directly instead of being collapsed into neutral UX copy. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**How to avoid:** Keep typed protocol outcomes for internals and tests, but map `:not_found` and `:expired` to the same host-facing message by default. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-UI-SPEC.md]

**Warning signs:** Docs or templates mention “this code does not exist” or “this code expired” separately on the public verification page. [ASSUMED]

### Pitfall 4: Rate-limit examples that ignore proxy-correct client IPs

**What goes wrong:** The host rate-limits the load balancer IP instead of the real client IP, or trusts spoofable forwarding headers without a trusted-proxy strategy. [CITED: https://hexdocs.pm/plug/Plug.Conn.html] [CITED: https://hexdocs.pm/remote_ip/RemoteIp.html]

**Why it happens:** `Plug.Conn.remote_ip` defaults to the peer IP unless a plug rewrites it correctly for the deployment topology. [CITED: https://hexdocs.pm/plug/Plug.Conn.html] [CITED: https://hexdocs.pm/remote_ip/RemoteIp.html]

**How to avoid:** Document rate limiting as a host Plug concern, tell hosts to derive keys from a trusted client IP source, and show proxy-aware examples instead of raw `x-forwarded-for` parsing. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: docs/dynamic-registration.md] [ASSUMED]

**Warning signs:** The docs show `get_req_header(conn, "x-forwarded-for")` as the primary key source without any trust boundary discussion. [ASSUMED]

## Code Examples

Verified patterns from official sources and repo-local analogs:

### Host-Owned Router Mount Pattern

```elixir
# Source: priv/templates/lockspire.install/router.ex
scope "/", MyAppWeb do
  pipe_through [:browser]

  get "/authorized-apps", AuthorizedAppsController, :index
  delete "/authorized-apps/:id", AuthorizedAppsController, :delete
end

scope "/" do
  forward "/lockspire", Lockspire.Web.Router
end
```
[VERIFIED: priv/templates/lockspire.install/router.ex]

### Thin Controller Delegation Pattern

```elixir
# Source: lib/lockspire/web/controllers/interaction_controller.ex
def complete(conn, %{"interaction_id" => interaction_id, "decision" => decision} = params) do
  with {:ok, interaction} <- fetch_interaction(interaction_id),
       {:ok, subject_context} <- resolve_subject_context(conn, interaction),
       outcome <- finalize_interaction(interaction_id, decision, subject_context, params) do
    case outcome do
      {:approved, redirect_uri} -> redirect(conn, external: redirect_uri)
      {:denied, redirect_uri} -> redirect(conn, external: redirect_uri)
      {:error, reason} -> render_browser_error(conn, interaction_error(reason), :bad_request)
    end
  end
end
```
[VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex]

### LiveView Form Pattern for Host Starter UI

```elixir
# Source: Phoenix.Component docs
def handle_event("submitted", params, socket) do
  {:noreply, assign(socket, form: to_form(params))}
end
```
[CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]

### Pessimistic Locking Pattern

```elixir
# Source: Ecto.Query docs
from(u in User, where: u.id == ^current_user, lock: "FOR SHARE NOWAIT")
```
[CITED: https://hexdocs.pm/ecto/Ecto.Query.html]

### Hammer Example Shape for Docs

```elixir
# Source: Hammer docs
defmodule MyApp.RateLimit do
  use Hammer, backend: :ets
end

MyApp.RateLimit.hit("some-key", :timer.seconds(1), 10)
```
[CITED: https://hexdocs.pm/hammer/Hammer.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Verification URL shortcut treated as the whole action | `verification_uri_complete` is only a shortcut into the normal user interaction and still requires code confirmation | RFC 8628, August 2019 [CITED: https://www.rfc-editor.org/rfc/rfc8628] | The host seam must remain explicit-user-action UX, even with prefill. [CITED: https://www.rfc-editor.org/rfc/rfc8628] |
| Library-owned browser UX for embedded auth libraries | Generated host-owned seams plus narrow library protocols | Repo support contract established by v1.0 onboarding/install work. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/supported-surface.md] | Phase 31 should extend install templates, not add a primary `/verify` UI inside `Lockspire.Web.Router`. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |
| Fire-and-forget mutable actions | Expected-state transitions with row locks and typed stale-state failures | Already current in Lockspire interaction/token lifecycle code. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] | Device verification should use the same transition discipline so Phase 32 can consume terminal states safely. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |

**Deprecated/outdated:**

- Lockspire-owned generic verification HTML as the supported path is outdated for this repo’s product direction and explicitly rejected for v1. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]
- Host documentation that says “rate-limit this somehow” without concrete keying and response guidance is below the support-contract bar for this phase. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `remote_ip` is the best proxy-awareness example to mention alongside Hammer and PlugAttack for most host Phoenix apps. [ASSUMED] | Standard Stack / Common Pitfalls | Low. The planner can swap to another trusted-proxy doc example without changing the core phase architecture. |
| A2 | Auto-submit warning signs in generated code are most likely to appear as `window.onload`, `phx-mounted`, or immediate `JS.push` patterns. [ASSUMED] | Common Pitfalls | Low. The exact mechanism may differ, but the anti-pattern category is unchanged. |
| A3 | The recommended generated file set likely needs controller and/or HTML templates under `priv/templates/lockspire.install/verification*`. [ASSUMED] | Architecture Patterns | Low. Final file names are discretionary and can be adjusted during planning. |
| A4 | The sample generated `/verify` routes will likely be split into `show`, `lookup`, `approve`, and `deny` actions in host code. [ASSUMED] | Architecture Patterns | Low. Route naming can change without affecting the core seam contract. |
| A5 | A dedicated `DeviceVerification` protocol module is the cleanest naming for the lookup/approve/deny API. [ASSUMED] | Architecture Patterns | Low. Module naming is discretionary. |
| A6 | The warning sign for bad host templates is direct `Repository` usage or timestamp-derived status branching in generated browser code. [ASSUMED] | Common Pitfalls | Low. The precise smell may vary, but the separation-of-concerns issue remains the same. |
| A7 | The docs should prefer a proxy-aware IP example over raw forwarding-header parsing in most Phoenix host apps. [ASSUMED] | Common Pitfalls | Low. Another trusted-proxy pattern could be substituted. |
| A8 | Controller-first is simpler for explicit `GET` and `POST`, while LiveView-first is more aligned with the current consent seam. [ASSUMED] | Open Questions | Low. Either option can satisfy the phase if the protocol/store contract stays separate. |
| A9 | The proposed quick-run command is the right minimal per-task validation slice before verification-specific tests are added. [ASSUMED] | Validation Architecture | Low. The planner can adjust the quick command once the new tests exist. |
| A10 | Verification-specific tests will likely live in new `device_verification`, controller, LiveView, and docs contract files. [ASSUMED] | Validation Architecture | Low. Exact filenames can change during planning. |

## Open Questions

1. **Should the starter verification seam be controller-first or LiveView-first?**
   - What we know: The repo already generates a consent LiveView and the UI contract names `Phoenix.Component + Phoenix LiveView` as the starter surface. [VERIFIED: priv/templates/lockspire.install/consent_live.ex] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-UI-SPEC.md]
   - What's unclear: The locked decisions allow either split as long as `GET /verify` and explicit POST-style mutations remain host-owned. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]
   - Recommendation: Plan the protocol/store work independently, then choose the generated UI shape that best reuses existing generator coverage and test helpers. Controller-first is simpler for explicit `GET` and `POST`; LiveView-first is more visually aligned with the existing consent seam. [VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex] [ASSUMED]

2. **How much request context beyond client name and scopes should lookup return?**
   - What we know: The locked minimum is `user_code`, client identity/name, and requested scopes, with optional safe device-facing context only if already supported by storage. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]
   - What's unclear: Phase 30 stores no device metadata beyond client/scopes, so richer context would require schema widening. [VERIFIED: lib/lockspire/storage/ecto/device_authorization_record.ex]
   - Recommendation: Keep Phase 31 narrow and return only fields that already exist or are clearly required for actor binding and neutral UX. Defer branding or device catalog metadata. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build, generator work, tests | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| Mix | Generator and test commands | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| PostgreSQL client (`psql`) | Local integration/test workflow | ✓ [VERIFIED: local command] | `14.17` [VERIFIED: local command] | — |
| PostgreSQL server (`pg_isready`) | Ecto-backed repo tests and migrations | ✓ [VERIFIED: local command] | accepting connections on `/tmp:5432` [VERIFIED: local command] | — |

**Missing dependencies with no fallback:** None. [VERIFIED: local command audit]

**Missing dependencies with fallback:** None. [VERIFIED: local command audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix controller and LiveView tests. [VERIFIED: mix.exs] [VERIFIED: test/lockspire/web/interaction_controller_test.exs] [VERIFIED: test/lockspire/web/live/consent_live_test.exs] |
| Config file | none — test aliases are defined in `mix.exs`. [VERIFIED: mix.exs] |
| Quick run command | `MIX_ENV=test mix test test/integration/install_generator_test.exs test/lockspire/storage/ecto/repository_device_authorization_test.exs` [VERIFIED: mix.exs] [ASSUMED] |
| Full suite command | `mix ci` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEV-04 | Generator emits host-owned `/verify` seam files and route stub. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `MIX_ENV=test mix test test/integration/install_generator_test.exs` [VERIFIED: mix.exs] | ✅ existing file, but new assertions required. [VERIFIED: test/integration/install_generator_test.exs] |
| DEV-04 | Lookup and approve/deny APIs classify pending vs terminal states correctly. [VERIFIED: .planning/REQUIREMENTS.md] | unit/integration | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs` [VERIFIED: mix.exs] | ✅ existing file, but substantial new coverage required. [VERIFIED: test/lockspire/storage/ecto/repository_device_authorization_test.exs] |
| DEV-05 | Prefilled `verification_uri_complete` does not auto-submit or auto-mutate on GET. [VERIFIED: .planning/REQUIREMENTS.md] | controller or LiveView integration | `MIX_ENV=test mix test test/lockspire/web/live/consent_live_test.exs` or new verification-surface test file. [VERIFIED: mix.exs] [ASSUMED] | ❌ Wave 0 for verification-specific surface. |
| DEV-06 | Device-flow host guide exists and is wired into docs extras or release-readiness checks. [VERIFIED: .planning/REQUIREMENTS.md] | docs / contract | `mix docs.verify` [VERIFIED: mix.exs] | ❌ Wave 0 for new guide + wiring assertions. |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/integration/install_generator_test.exs test/lockspire/storage/ecto/repository_device_authorization_test.exs` [ASSUMED]
- **Per wave merge:** `MIX_ENV=test mix test` [VERIFIED: mix.exs]
- **Phase gate:** `mix ci` and `mix docs.verify` should both pass before `/gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `test/lockspire/protocol/device_verification_test.exs` — lookup classification, actor binding, and approve/deny outcomes. [ASSUMED]
- [ ] `test/lockspire/web/controllers/lockspire_verification_controller_test.exs` or `test/lockspire/web/live/lockspire_verification_live_test.exs` — secure GET/prefill/review behavior. [ASSUMED]
- [ ] `test/integration/install_generator_test.exs` assertions for generated `/verify` files and non-overwrite behavior. [VERIFIED: test/integration/install_generator_test.exs]
- [ ] Release-readiness or docs contract test updates to cover the new device-flow host guide and onboarding links. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Approval/denial must bind to the signed-in host actor via the account resolver seam before mutation. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex] |
| V3 Session Management | no | Host session management remains outside Lockspire’s supported surface for this phase. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |
| V4 Access Control | yes | Opaque-handle mutations plus subject-context checks prevent one account from finalizing another account’s verification request. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |
| V5 Input Validation | yes | Normalize `user_code`, collapse existence-oracle copy, and keep GET side-effect free. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [CITED: https://www.rfc-editor.org/rfc/rfc8628] |
| V6 Cryptography | yes | Device and user codes are stored as hashes, and approval should continue to avoid exposing raw tokens or codes in storage. [VERIFIED: lib/lockspire/domain/device_authorization.ex] [VERIFIED: lib/lockspire/storage/ecto/device_authorization_record.ex] |

### Known Threat Patterns for Phoenix + Device Flow

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Remote phishing via `verification_uri_complete` | Spoofing | Require explicit review, re-display the code, and ask the user to confirm the device is in their possession. [CITED: https://www.rfc-editor.org/rfc/rfc8628] |
| User-code brute forcing on `/verify` | Spoofing | Host-owned IP and normalized-code rate limiting with neutral responses and short `Retry-After`. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] |
| Double-submit / poll race on approval | Tampering | Row locking and expected-state transitions in the repository layer. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Leakage of raw codes in logs or query strings | Information Disclosure | Redact logs, avoid logging raw query strings, and store only hashes. [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: lib/lockspire/domain/device_authorization.ex] |

## Sources

### Primary (HIGH confidence)

- `https://www.rfc-editor.org/rfc/rfc8628` - verified `verification_uri_complete`, user-code confirmation, and remote phishing guidance. [CITED: https://www.rfc-editor.org/rfc/rfc8628]
- `https://hexdocs.pm/phoenix/Phoenix.Router.html` - verified Phoenix `get/3` / `post/3` route semantics. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - verified `form/1` and `to_form/1` patterns for host LiveView forms. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]
- `https://hexdocs.pm/ecto/Ecto.Query.html` - verified `lock/3` support for `SELECT ... FOR UPDATE`. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html]
- `https://hexdocs.pm/hammer/Hammer.html` - verified Hammer’s built-in ETS backend and `hit/3` API. [CITED: https://hexdocs.pm/hammer/Hammer.html]
- `https://hexdocs.pm/plug_attack/PlugAttack.html` - verified PlugAttack’s throttling/plug model. [CITED: https://hexdocs.pm/plug_attack/PlugAttack.html]
- `https://hexdocs.pm/plug/Plug.Conn.html` - verified `remote_ip` semantics. [CITED: https://hexdocs.pm/plug/Plug.Conn.html]
- Local codebase files:
  - `lib/lockspire/generators/install.ex`
  - `lib/lockspire/generators/templates.ex`
  - `priv/templates/lockspire.install/router.ex`
  - `priv/templates/lockspire.install/account_resolver.ex`
  - `priv/templates/lockspire.install/consent_live.ex`
  - `lib/lockspire/web/controllers/interaction_controller.ex`
  - `lib/lockspire/web/live/consent_live.ex`
  - `lib/lockspire/protocol/device_authorization.ex`
  - `lib/lockspire/protocol/authorization_flow.ex`
  - `lib/lockspire/storage/device_authorization_store.ex`
  - `lib/lockspire/storage/ecto/device_authorization_record.ex`
  - `lib/lockspire/storage/ecto/repository.ex`
  - `docs/install-and-onboard.md`
  - `docs/dynamic-registration.md`
  - `docs/supported-surface.md`
  - `test/integration/install_generator_test.exs`
  - `test/lockspire/storage/ecto/repository_device_authorization_test.exs`

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/remote_ip/RemoteIp.html` - verified proxy-aware `remote_ip` rewriting as a docs example, but it is not mentioned in locked phase decisions. [CITED: https://hexdocs.pm/remote_ip/RemoteIp.html]
- `https://hex.pm/api/packages/phoenix`
- `https://hex.pm/api/packages/phoenix_live_view`
- `https://hex.pm/api/packages/ecto_sql`
- `https://hex.pm/api/packages/hammer`
- `https://hex.pm/api/packages/plug_attack`
- `https://hex.pm/api/packages/remote_ip`

### Tertiary (LOW confidence)

- None. All externally sourced factual claims above were verified with official documentation or official package metadata. [VERIFIED: source audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Repo-local patterns, locked phase decisions, and current official package metadata align. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md] [VERIFIED: Hex package metadata]
- Architecture: HIGH - The generator, interaction controller, consent LiveView, and repository transaction style all point to one coherent seam shape. [VERIFIED: lib/lockspire/generators/install.ex] [VERIFIED: lib/lockspire/web/controllers/interaction_controller.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
- Pitfalls: HIGH - RFC 8628’s phishing guidance and the project’s locked anti-phishing/rate-limit decisions are explicit. [CITED: https://www.rfc-editor.org/rfc/rfc8628] [VERIFIED: .planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md]

**Research date:** 2026-04-28 [VERIFIED: project clock]
**Valid until:** 2026-05-28 for repo-local architecture; re-check Hex package versions and official docs if planning slips beyond 30 days. [VERIFIED: source freshness dates]
