# Phase 39: Automated RP Logout Propagation - Research

**Researched:** 2026-04-29
**Domain:** OIDC Back-Channel Logout, Front-Channel Logout, durable logout delivery, embedded Oban integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Back-channel delivery architecture
- **D-01:** Back-Channel Logout uses a **durable asynchronous delivery pipeline**, not inline HTTP from the logout controller and not best-effort `Task` dispatch.
- **D-02:** `/end_session/complete` remains the **authoritative logout completion point**. It revokes `sid`-scoped tokens, persists logout propagation intent, enqueues delivery work, and returns without waiting on relying-party HTTP responses.
- **D-03:** Lockspire models logout propagation as first-class durable state, e.g. `logout_events` and `logout_deliveries`, so retries, auditability, telemetry, and future operator tooling are grounded in Ecto/Postgres rather than process memory.
- **D-04:** **Oban is the default dispatch engine** for Back-Channel Logout delivery. Task-based or purely in-memory delivery is out of scope for protocol-bearing behavior.
- **D-05:** Delivery jobs must be **unique per logout-delivery unit** to prevent duplicate fan-out from repeated completion requests, retries, or clustered execution races.
- **D-06:** Lockspire must not hold a database transaction open while performing outbound HTTP. Persist first, dispatch second.
- **D-07:** Retry policy is durable but bounded. Transient network/server failures may retry; clearly permanent failures such as repeated invalid client configuration or stable 4xx responses must converge to terminal delivery state instead of retrying forever.

### Client metadata and discovery truth
- **D-08:** Phase 39 adds four first-class client fields: `backchannel_logout_uri`, `backchannel_logout_session_required`, `frontchannel_logout_uri`, and `frontchannel_logout_session_required`.
- **D-09:** URI presence is the opt-in. No separate enable booleans are added; the two `*_session_required` booleans default to `false` per spec.
- **D-10:** These logout-propagation fields are **operator-managed only** in Phase 39. DCR requests that include them are rejected as unsupported in this slice rather than silently ignored.
- **D-11:** Validation is strict and offline: absolute URIs only, no fragments, deduped values, `*_session_required` forbidden without the corresponding URI, and no live outbound probing during admin save or DCR validation.
- **D-12:** `frontchannel_logout_uri` must share scheme, host, and port with one of the client's registered redirect URIs per the OIDC Front-Channel Logout spec.
- **D-13:** Discovery becomes fully truthful for shipped logout semantics. Once Phase 39 is live, publish `backchannel_logout_supported`, `backchannel_logout_session_supported`, `frontchannel_logout_supported`, and `frontchannel_logout_session_supported` consistently with the implementation. Do not flip only half the booleans.
- **D-14:** Lockspire remains **back-channel first**. When a client has `backchannel_logout_uri`, Lockspire sends a logout token server-to-server. When a client also has `frontchannel_logout_uri`, Lockspire additionally renders iframe-based logout as browser-local best-effort cleanup.

### Front-channel completion UX
- **D-15:** Host ownership of session clearing stays unchanged. Front-Channel Logout begins only after the host returns to Lockspire's completion endpoint.
- **D-16:** The completion surface is a **plain Phoenix controller-rendered HEEx page**, not LiveView, extending the minimal logged-out page pattern already used in Lockspire.
- **D-17:** On completion, Lockspire renders all eligible `frontchannel_logout_uri` values in **invisible iframes** and gives them a **bounded best-effort dispatch window** before continuing.
- **D-18:** The default UX is **auto-continue after a short delay with a visible continue fallback**, not an immediate redirect and not a mandatory confirmation page.
- **D-19:** Lockspire does not block on cross-origin completion signals and does not treat `iframe.onload` as proof of successful logout.
- **D-20:** User-facing copy and docs must remain truthful: Front-Channel Logout is browser-mediated best effort and may be limited by third-party cookie/storage restrictions, SameSite settings, CSP, frame policies, or early tab closure.

### Observability and operator clarity
- **D-21:** Telemetry and durable audit must distinguish **logout requested**, **delivery enqueued**, **delivery attempted**, **delivery succeeded**, and **delivery failed/discarded**. Do not collapse enqueue and HTTP success into one event.
- **D-22:** Sensitive artifacts such as raw logout tokens, response bodies, or unredacted query strings must not be written to audit logs or telemetry payloads. Persist only the minimum redacted metadata required for operator clarity and debugging.
- **D-23:** Admin UX should use the existing truthful operator style: expose stored logout configuration explicitly and, where relevant, separate configured values from effective behavior. Add a dedicated client edit/display mode for logout propagation rather than hiding these fields in free-form metadata.

### the agent's Discretion
- Exact schema names and state-machine naming for durable logout tracking
- Queue names, worker module names, and retry interval tuning
- The exact auto-continue delay length, so long as it is short, bounded, and documented as best-effort
- The precise operator copy and page layout, provided the truthfulness and accessibility constraints above are preserved

### Deferred Ideas (OUT OF SCOPE)
- DCR/self-service management of logout propagation metadata — defer until the project explicitly wants the outbound callback risk surface and supporting policy review
- Session-management `check_session_iframe` — still out of scope
- Generic webhook framework abstraction — unnecessary broadening for v1
- Claims or events beyond the standard logout-token semantics, including proprietary “revoke offline session” behavior
- Rich session browser / replay UI — worth considering only after the durable delivery model exists and real operator needs are observed
- Treating front-channel as a hard success gate or requiring verified browser-side acknowledgements — inconsistent with modern browser reality and Lockspire's truthful preview posture
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SLO-03 | Implement Back-Channel Logout webhook dispatch (server-to-server POST) via `req`. | Use durable `logout_events` + `logout_deliveries`, `Req` form POST with `logout_token`, unique Oban worker jobs, bounded retry rules, and truthful delivery states. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://hexdocs.pm/req/Req.Steps.html] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| SLO-04 | Implement Front-Channel Logout asynchronous iframe rendering on host return. | Extend `/end_session/complete` to render a plain HEEx completion page with hidden iframes, bounded auto-continue, and truthful best-effort copy driven by durable `frontchannel` delivery rows. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
</phase_requirements>

## Summary

Phase 39 should treat Back-Channel Logout as the reliable protocol primitive and Front-Channel Logout as browser-mediated best effort. The official specs explicitly allow both mechanisms to be combined, require server-to-server logout as an HTTP form POST carrying a signed `logout_token`, and warn that front-channel iframe logout can be blocked by modern third-party storage restrictions. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-rpinitiated-1_0.html]

Lockspire already has the right architectural seams for this work: `/end_session/complete` is the completion hook, `sid` and `account_id` already flow through `Lockspire.Protocol.EndSession.Result`, discovery already publishes placeholder logout booleans, client records already carry typed logout-related fields for post-logout redirects, and the library already centralizes telemetry, audit, redaction, and Ecto transactions. [VERIFIED: lib/lockspire/protocol/end_session.ex] [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/domain/client.ex] [VERIFIED: lib/lockspire/admin/clients.ex] [VERIFIED: lib/lockspire/observability.ex] [VERIFIED: lib/lockspire/audit/event.ex] [VERIFIED: lib/lockspire/redaction.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

The implementation boundary should stay narrow: build a logout-propagation subsystem, not a generic webhook engine. Persist one `logout_event` per completion attempt, persist one `logout_delivery` per client/channel target, enqueue only back-channel deliveries into Oban, record front-channel rows as rendered or skipped without pretending remote success, and advertise discovery booleans only when the code, tests, and operator surfaces all ship together. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]

**Primary recommendation:** Implement a protocol-owned logout propagation service that snapshots target RPs into durable rows before token revocation, enqueues unique Oban jobs for back-channel POST delivery through `Req`, renders front-channel iframes from the same durable snapshot, and drives admin/discovery truth from that persisted state. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html] [CITED: https://hexdocs.pm/req/Req.Steps.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Resolve logout propagation targets from durable token history | API / Backend | Database / Storage | The back-channel spec requires the OP to remember logged-in RPs, and Lockspire already persists `sid` and `client_id` on token rows. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Persist `logout_events` and `logout_deliveries` | Database / Storage | API / Backend | The phase decisions require durable first-class state in Postgres, not in request memory. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] |
| Enqueue and execute back-channel POST delivery | API / Backend | Database / Storage | Oban jobs are backend work items backed by the repo; outbound HTTP must happen after persistence, outside controller transactions. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [CITED: https://hexdocs.pm/oban/Oban.html] |
| Render front-channel iframes and auto-continue page | Frontend Server (SSR) | Browser / Client | The front-channel spec is explicitly user-agent mediated and the phase locks the UX to a controller-rendered HEEx page. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
| Publish truthful discovery metadata | API / Backend | — | Discovery booleans are server metadata and must reflect what Lockspire actually ships. [VERIFIED: lib/lockspire/protocol/discovery.ex] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
| Validate and persist client logout metadata | API / Backend | Database / Storage | Strict URI/session-required validation belongs in domain/admin validation before records are updated. [VERIFIED: lib/lockspire/admin/clients.ex] [VERIFIED: lib/lockspire/storage/ecto/client_record.ex] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
| Present truthful operator configuration and delivery status | Frontend Server (SSR) | Database / Storage | The operator UX should read durable state and show configured-versus-effective behavior without overclaiming remote success. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [VERIFIED: lib/lockspire/web/live/admin/clients_live/show.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Oban | `2.21.1` locked, `~> 2.22` latest Hex line [VERIFIED: mix.lock] [VERIFIED: `mix hex.info oban`] | Durable async back-channel job dispatch | Matches the repo’s existing dependency and provides unique jobs, retry states, queue control, and test modes without inventing a job system. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/oban/unique_jobs.html] [CITED: https://hexdocs.pm/oban/Oban.html] |
| Req | `0.5.17` [VERIFIED: `mix hex.info req`] | Back-channel HTTP POST with form encoding and retry controls | SLO-03 explicitly calls for `req`, and Req natively encodes `application/x-www-form-urlencoded` bodies plus configurable retry logic. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://hexdocs.pm/req/Req.Steps.html] |
| JOSE | `~> 1.11` [VERIFIED: mix.exs] | Signing Logout Tokens with the same signing key flow used for ID tokens | The spec requires signed Logout Tokens and Lockspire already uses JOSE for token signing. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: mix.exs] |
| Ecto SQL | `3.13.5` [VERIFIED: mix.lock] [VERIFIED: `mix hex.info ecto_sql`] | Durable event/delivery persistence and transactional enqueue staging | The project’s durable-truth pattern is already Ecto/Postgres-first. [VERIFIED: .planning/PROJECT.md] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Phoenix | `1.8.5` [VERIFIED: mix.lock] [VERIFIED: `mix hex.info phoenix`] | Controller + HEEx completion page and discovery/controller adapters | The existing logout path and discovery adapters are Phoenix controllers, and the phase locks the completion UX to plain controller rendering. [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex] [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix LiveView | `1.1.28` locked [VERIFIED: mix.lock] [VERIFIED: `mix hex.info phoenix_live_view`] | Admin client edit/show workflows | Extend the existing admin client pages with typed logout propagation fields and truthful status copy. [VERIFIED: lib/lockspire/web/live/admin/clients_live/show.ex] [VERIFIED: lib/lockspire/web/live/admin/clients_live/form_component.ex] |
| Telemetry / OpenTelemetry API | `telemetry ~> 1.3`, `opentelemetry_api 1.5.0` [VERIFIED: mix.exs] [VERIFIED: `mix hex.info opentelemetry_api`] | Enqueue/attempt/success/failure instrumentation | Reuse the shared observability seam instead of adding a new event pipeline. [VERIFIED: lib/lockspire/observability.ex] |
| Phoenix.Token | bundled through Phoenix use [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex] | Existing signed completion handoff | Keep using it for host return-to completion state; do not repurpose it for back-channel Logout Tokens. [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Oban delivery workers | `Task.Supervisor` or raw `Task` | Rejected because the phase locks delivery to durable async state with retries and uniqueness, which tasks do not provide. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] |
| Req | Finch directly | Finch is lower-level and already powers Req, but SLO-03 explicitly names `req` and Req already solves form encoding and retry policy composition. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://hexdocs.pm/req/Req.Steps.html] |
| Controller-rendered completion page | LiveView completion page | Rejected because the phase explicitly locks the UX to a plain controller-rendered HEEx page and LiveView adds no protocol value here. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] |

**Installation:**
```bash
# add Req to mix.exs, then fetch deps
mix deps.get
```

**Version verification:** The repo already locks `phoenix 1.8.5`, `phoenix_live_view 1.1.28`, `ecto_sql 3.13.5`, and `oban 2.21.1`; `Req 0.5.17` is available on Hex but is not currently in `mix.exs`. [VERIFIED: mix.lock] [VERIFIED: mix.exs] [VERIFIED: `mix hex.info req`] [VERIFIED: `mix hex.info oban`]

## Architecture Patterns

### System Architecture Diagram

```text
RP -> /end_session -> Host logout seam -> /end_session/complete
                               |
                               v
                    LogoutPropagation.create_from_completion
                               |
                 +-------------+------------------+
                 |                                |
                 v                                v
        snapshot target clients            persist logout_event
        from durable token history         + logout_deliveries
                 |                                |
                 +-------------+------------------+
                               |
                               v
                    revoke sid/account token state
                               |
               +---------------+-------------------+
               |                                   |
               v                                   v
   enqueue unique Oban jobs for          render front-channel page
   `backchannel` deliveries              from `frontchannel` deliveries
               |                                   |
               v                                   v
      worker signs logout token            hidden iframes + auto-continue
      and POSTs via Req                    no remote success claim
               |
               v
    durable delivery status + telemetry + audit
```

### Recommended Project Structure
```text
lib/lockspire/
├── domain/
│   ├── logout_event.ex          # durable event aggregate
│   └── logout_delivery.ex       # durable per-client per-channel delivery state
├── protocol/
│   ├── logout_propagation.ex    # completion-time orchestration
│   └── logout_token.ex          # JOSE-backed back-channel logout token builder
├── storage/
│   ├── logout_store.ex          # contract for event/delivery persistence
│   └── ecto/
│       ├── logout_event_record.ex
│       └── logout_delivery_record.ex
├── workers/
│   └── backchannel_logout_worker.ex
└── web/
    ├── controllers/end_session_controller.ex
    └── controllers/end_session_html/
        └── frontchannel_logout.html.heex
```

### Pattern 1: Snapshot targets before revocation
**What:** Build `logout_event` and `logout_delivery` rows from durable token history before calling `revoke_by_sid/1` or equivalent subject-wide revocation helpers. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

**When to use:** Always at `/end_session/complete`, because post-revocation state is no longer a reliable source of target-client truth. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]

**Example:**
```elixir
# Source: Lockspire pattern adapted from Repository.transact/1 and EndSession completion
# [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
# [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex]
Repository.transact(fn ->
  targets = LogoutStore.list_targets_for_logout(%{sid: sid, account_id: account_id})
  {:ok, event} = LogoutStore.insert_logout_event(build_event(result, targets))
  {:ok, deliveries} = LogoutStore.insert_logout_deliveries(event, targets)
  {:ok, _revoked} = Repository.revoke_by_sid(sid)
  %{event: event, deliveries: deliveries}
end)
```

### Pattern 2: Back-channel worker owns HTTP, not the controller
**What:** Persist delivery state first, then enqueue one unique job per `logout_delivery` and let the worker sign the Logout Token and POST it through Req. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [CITED: https://hexdocs.pm/oban/unique_jobs.html] [CITED: https://hexdocs.pm/req/Req.Steps.html]

**When to use:** For every back-channel delivery row with a configured `backchannel_logout_uri`. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]

**Example:**
```elixir
# Source: Oban unique job pattern + Req form encoding
# https://hexdocs.pm/oban/unique_jobs.html
# https://hexdocs.pm/req/Req.Steps.html
defmodule Lockspire.Workers.BackchannelLogoutWorker do
  use Oban.Worker,
    queue: :lockspire_logout,
    max_attempts: 5,
    unique: [period: :infinity, fields: [:worker, :args], keys: [:logout_delivery_id], states: :all]

  @impl true
  def perform(%Oban.Job{args: %{"logout_delivery_id" => id}}) do
    with {:ok, delivery} <- LogoutStore.fetch_delivery(id),
         {:ok, logout_token} <- LogoutToken.sign(delivery),
         {:ok, response} <-
           Req.post(delivery.destination_uri,
             form: [logout_token: logout_token],
             retry: :transient
           ) do
      DeliveryResult.classify_and_persist(delivery, response)
    end
  end
end
```

### Pattern 3: Front-channel page is truthful best effort
**What:** Render hidden iframes from durable `frontchannel` delivery rows, mark them `rendered`, and auto-continue after a short bounded delay with a visible manual continue link. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]

**When to use:** Only after the host returns to `/end_session/complete`. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]

**Example:**
```heex
<!-- Source: OIDC front-channel iframe model -->
<!-- https://openid.net/specs/openid-connect-frontchannel-1_0.html -->
<main>
  <h1>Signing you out of connected apps…</h1>
  <p>This step is best effort and may be limited by browser privacy settings.</p>

  <%= for delivery <- @frontchannel_deliveries do %>
    <iframe
      src={delivery.dispatch_url}
      title={"Logout for " <> delivery.client_id}
      hidden
      tabindex="-1"
      aria-hidden="true"
    />
  <% end %>

  <p><a href={@continue_to}>Continue</a></p>
  <meta http-equiv="refresh" content={"3;url=" <> @continue_to} />
</main>
```

### Anti-Patterns to Avoid
- **Inline HTTP in `EndSessionController.complete/2`:** It violates D-01 and D-06, stretches request latency, and ties protocol completion to third-party availability. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]
- **Deriving target clients from only active, unrevoked tokens after revocation:** `/end_session/complete` already revokes `sid`-scoped tokens, so target selection must happen before revocation from historical session evidence. [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
- **Using `Oban.insert_all/2` for back-channel delivery fan-out:** Oban’s per-job uniqueness checks apply to `insert` paths, not to bulk insert patterns used like `insert_all`. [CITED: https://hexdocs.pm/oban/unique_jobs.html] [CITED: https://hexdocs.pm/oban/Oban.html]
- **Claiming front-channel success based on `iframe.onload`:** The front-channel spec defines browser-mediated logout, not cross-origin completion proof, and modern browsers can block third-party session access entirely. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Durable async retries | Custom GenServer/task retry loop | Oban worker + unique jobs + bounded attempts | Oban already models retryable, completed, cancelled, and discarded job states and exposes testing modes. [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Back-channel HTTP form POST | Manual body encoding and ad hoc retry glue | `Req.post(..., form: ..., retry: ...)` | Req already encodes `application/x-www-form-urlencoded` and exposes transient retry controls. [CITED: https://hexdocs.pm/req/Req.Steps.html] |
| Generic webhook platform | Multi-purpose webhook/event framework | Phase-specific `logout_event` + `logout_delivery` models | The phase scope explicitly forbids broadening into a generic outbound webhook engine. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] |
| Remote success verification for front-channel | Cross-origin JS acknowledgement protocol | Truthful “rendered/best-effort” status only | The front-channel spec and browser privacy model do not guarantee iframe access to RP session state. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |

**Key insight:** Hand-rolled durability, retry, or browser acknowledgement logic would either duplicate Oban/Req capabilities or push Lockspire outside its embedded-library boundary. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Forgetting that logged-in RP memory is part of the protocol
**What goes wrong:** Logout completion revokes tokens, but no durable target set is captured, so Lockspire cannot know which RPs to notify. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]
**Why it happens:** The spec says the OP must remember logged-in RPs, and the current repo only remembers them implicitly through token rows. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
**How to avoid:** Add a query that resolves distinct target clients from token history before revocation and persists the snapshot into `logout_deliveries`. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
**Warning signs:** Re-running `/end_session/complete` after revocation yields a different or empty target set. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

### Pitfall 2: Treating back-channel and front-channel as the same success model
**What goes wrong:** UI and telemetry claim “logout succeeded” for front-channel merely because iframes were rendered. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]
**Why it happens:** The front-channel spec defines iframe rendering, while the back-channel spec defines a direct POST plus RP-side validation. Those are not equivalent delivery guarantees. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]
**How to avoid:** Use channel-specific terminal states: `succeeded` for back-channel HTTP success; `rendered` or `skipped` for front-channel. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]
**Warning signs:** Admin copy uses the same “successful delivery” label for both channels. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]

### Pitfall 3: Using job uniqueness as if it were execution serialization
**What goes wrong:** Duplicate inserts are prevented, but multiple distinct deliveries still run concurrently and code incorrectly assumes sequence. [CITED: https://hexdocs.pm/oban/unique_jobs.html]
**Why it happens:** Oban uniqueness is enforced at insert time, not as a concurrency lock. [CITED: https://hexdocs.pm/oban/unique_jobs.html]
**How to avoid:** Make each job unique by `logout_delivery_id` and treat delivery row locking/state transitions as the source of correctness. [CITED: https://hexdocs.pm/oban/unique_jobs.html] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
**Warning signs:** Worker code depends on one-at-a-time processing instead of checking durable delivery state. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

### Pitfall 4: Retrying stable 4xx responses forever
**What goes wrong:** Misconfigured clients create permanent queue churn and misleading operator noise. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]
**Why it happens:** Req can retry transient failures, but application code still must classify permanent client-side failures. [CITED: https://hexdocs.pm/req/Req.Steps.html]
**How to avoid:** Persist response classification rules: retry transport errors and `408/429/5xx`; mark repeated `400/401/403/404/410/422` as permanent failure or discard. [CITED: https://hexdocs.pm/req/Req.Steps.html] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]
**Warning signs:** `attempt_count` climbs while `last_http_status` stays in a stable 4xx band. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

### Pitfall 5: Logging raw logout material
**What goes wrong:** Telemetry or audit rows capture raw `logout_token`, RP response bodies, or query strings containing session identifiers. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]
**Why it happens:** The existing redaction lists do not yet mention logout-specific keys. [VERIFIED: lib/lockspire/redaction.ex]
**How to avoid:** Extend redaction drop lists for logout artifacts and store only stable handles, URI origins, statuses, and reason codes. [VERIFIED: lib/lockspire/redaction.ex] [VERIFIED: lib/lockspire/observability.ex] [VERIFIED: lib/lockspire/audit/event.ex]
**Warning signs:** Tests need to assert that metadata lacks `logout_token`, `request_body`, `response_body`, and raw front-channel URLs. [VERIFIED: lib/lockspire/redaction.ex]

## Code Examples

Verified patterns from official sources:

### Unique delivery enqueue
```elixir
# Source: https://hexdocs.pm/oban/unique_jobs.html
use Oban.Worker,
  queue: :lockspire_logout,
  unique: [
    period: :infinity,
    fields: [:worker, :args],
    keys: [:logout_delivery_id],
    states: :all
  ]
```

### Req form POST for `logout_token`
```elixir
# Source: https://hexdocs.pm/req/Req.Steps.html
Req.post!(delivery.destination_uri,
  form: [logout_token: logout_token],
  retry: :transient
)
```

### Front-channel iframe URI shape
```text
# Source: https://openid.net/specs/openid-connect-frontchannel-1_0.html
https://rp.example.org/frontchannel_logout
https://rp.example.org/frontchannel_logout?iss=https%3A%2F%2Fserver.example.com&sid=08a5019c...
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Browser-only logout propagation | Back-channel first, front-channel supplemental | OIDC Front-/Back-Channel Logout finalized in September 2022. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] | Lockspire should treat server-to-server delivery as the authoritative path and front-channel as cleanup. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] |
| Front-channel assumed reliable | Browser privacy restrictions can block third-party iframe access | The front-channel spec’s implementation notes already warn about this modern browser reality. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] | Operator copy and discovery truth must not promise remote session cleanup proof. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
| Best-effort in-process background tasks | Durable DB-backed jobs with explicit retry/discard states | The repo already ships Oban and the phase explicitly locks it in. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] | Delivery state can be audited, retried, and surfaced truthfully in admin UX. [CITED: https://hexdocs.pm/oban/Oban.html] |

**Deprecated/outdated:**
- Inline logout webhook dispatch from the controller is outdated for this phase because it contradicts the locked durable async design and couples user logout latency to RP availability. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]
- Advertising only `*_logout_supported` without the matching `*_logout_session_supported` booleans is outdated for Lockspire because Phase 38 already emits `sid` in ID tokens and discovery must stay fully truthful. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: .planning/phases/38-session-tracking-rp-initiated-logout/38-CONTEXT.md] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]

## Open Questions

1. **Should Phase 39 also add a first-pass read-only admin view for recent `logout_events` and `logout_deliveries`, or only enrich client configuration surfaces?**
   - What we know: The phase locks durable state, truthful operator UX, and dedicated client configuration fields, but it does not explicitly require a new event browser. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]
   - What's unclear: Whether “truthful admin UX” for this slice means client configuration only or also recent delivery visibility. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md]
   - Recommendation: Plan client configuration and stored status fields as required work; treat a dedicated event index/detail page as optional only if it can be delivered without starving SLO-03/SLO-04 proof. [VERIFIED: .planning/ROADMAP.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build, tests, worker/runtime code | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Dependency install and test commands | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL CLI | Local inspection/debugging of Oban and durable state | ✓ [VERIFIED: `psql --version`] | `14.17` [VERIFIED: `psql --version`] | — |
| Oban Hex dependency | Durable back-channel jobs | ✓ in repo [VERIFIED: mix.exs] | `2.21.1` locked [VERIFIED: mix.lock] | — |
| Req Hex dependency | SLO-03 HTTP dispatch | ✗ in repo [VERIFIED: mix.exs] | `0.5.17` available [VERIFIED: `mix hex.info req`] | Add `{:req, "~> 0.5.17"}` to `mix.exs` and fetch deps. [VERIFIED: `mix hex.info req`] |

**Missing dependencies with no fallback:**
- None, provided Phase 39 adds `Req` as a new dependency. [VERIFIED: mix.exs] [VERIFIED: `mix hex.info req`]

**Missing dependencies with fallback:**
- None. SLO-03 explicitly names `req`, so Finch-only or `:httpc` substitutions would conflict with the requirement. [VERIFIED: .planning/REQUIREMENTS.md]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on `MIX_ENV=test`. [VERIFIED: test/test_helper.exs] |
| Config file | `test/test_helper.exs`; no standalone `ex_unit.exs` config file detected. [VERIFIED: test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs test/lockspire/workers/backchannel_logout_worker_test.exs test/lockspire/web/end_session_controller_phase39_test.exs -x` [VERIFIED: mix.exs] |
| Full suite command | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SLO-03 | Completion persists durable logout event/deliveries, enqueues unique Oban jobs, POSTs `logout_token`, and records retry/success/failure truthfully. | unit + integration | `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs test/lockspire/workers/backchannel_logout_worker_test.exs test/integration/phase39_logout_propagation_e2e_test.exs -x` | ❌ Wave 0 |
| SLO-04 | Completion renders front-channel iframes, marks front-channel rows truthfully, and auto-continues with fallback UI after host return. | controller + integration | `MIX_ENV=test mix test test/lockspire/web/end_session_controller_phase39_test.exs test/integration/phase39_logout_propagation_e2e_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Run the targeted Phase 39 test files plus any touched unit tests. [VERIFIED: mix.exs]
- **Per wave merge:** Run `MIX_ENV=test mix test.fast` and the dedicated Phase 39 integration file. [VERIFIED: mix.exs]
- **Phase gate:** Full repo test pass plus Phase 39 integration proof before `/gsd-verify-work`. [VERIFIED: .planning/PROJECT.md]

### Wave 0 Gaps
- [ ] `test/lockspire/protocol/logout_propagation_test.exs` — target resolution, event/delivery creation, DCR rejection, discovery booleans. [VERIFIED: lib/lockspire/protocol/end_session.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex]
- [ ] `test/lockspire/workers/backchannel_logout_worker_test.exs` — Req stub, response classification, retry/permanent-failure paths, redaction assertions. [CITED: https://hexdocs.pm/req/Req.Steps.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- [ ] `test/lockspire/web/end_session_controller_phase39_test.exs` — front-channel completion page, continue fallback, no fake success signaling. [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex]
- [ ] `test/integration/phase39_logout_propagation_e2e_test.exs` — end-to-end host return, Oban drain, back-channel stub capture, front-channel iframe markup, discovery flip. [VERIFIED: test/integration/phase38_session_logout_e2e_test.exs] [CITED: https://hexdocs.pm/oban/Oban.html]
- [ ] Shared Oban test helper or fixture setup using `testing: :manual` and `Oban.drain_queue/2`; none exists yet in `test/support/`. [VERIFIED: `rg -n 'Oban.Testing|drain_queue|assert_enqueued' test`] [CITED: https://hexdocs.pm/oban/Oban.html]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] | Signed Logout Tokens validated against Lockspire signing keys and exact client audience. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: lib/lockspire/protocol/end_session.ex] |
| V3 Session Management | yes [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] | `sid`-scoped logout propagation plus host-owned web session clearing seam. [VERIFIED: .planning/phases/38-session-tracking-rp-initiated-logout/38-CONTEXT.md] |
| V4 Access Control | no direct new surface [VERIFIED: lib/lockspire/web/router.ex] | Existing operator/admin access model remains in host app scope. [VERIFIED: .planning/PROJECT.md] |
| V5 Input Validation | yes [VERIFIED: lib/lockspire/admin/clients.ex] | Strict URI validation, no fragments, front-channel origin match, session-required coherence, DCR rejection. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
| V6 Cryptography | yes [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] | JOSE-signed Logout Tokens, no `alg=none`, reuse existing signing-key controls. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: mix.exs] |

### Known Threat Patterns for Lockspire logout propagation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged back-channel logout token | Spoofing | Sign Logout Tokens with existing signing keys; set `aud` to client ID; never allow `alg=none`; persist only redacted telemetry. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: lib/lockspire/redaction.ex] |
| Replay or duplicate delivery enqueue | Tampering | Unique Oban jobs keyed by `logout_delivery_id` plus durable delivery state checks before execution. [CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Permanent misconfiguration causing retry storms | Denial of Service | Classify stable 4xx responses as terminal failures and cap `max_attempts`. [CITED: https://hexdocs.pm/req/Req.Steps.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Leakage of raw logout token or session identifiers | Information Disclosure | Extend shared redaction lists and audit normalization to drop raw bodies and tokens. [VERIFIED: lib/lockspire/redaction.ex] [VERIFIED: lib/lockspire/audit/event.ex] |
| False operator claim that front-channel logout succeeded remotely | Repudiation | Persist `rendered`/`skipped` for front-channel instead of `succeeded`, and surface truthful copy in UI/docs. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |

## Sources

### Primary (HIGH confidence)
- `https://openid.net/specs/openid-connect-backchannel-1_0.html` - logout token requirements, POST format, RP memory requirement, discovery booleans, retry semantics.
- `https://openid.net/specs/openid-connect-frontchannel-1_0.html` - iframe flow, URI/session-required rules, discovery booleans, browser privacy limitations.
- `https://openid.net/specs/openid-connect-rpinitiated-1_0.html` - composition of RP-initiated logout with front-/back-channel propagation.
- `https://hexdocs.pm/oban/unique_jobs.html` - unique job semantics, conflict handling, replacement rules.
- `https://hexdocs.pm/oban/Oban.html` - test modes, queue disabling, drain execution, instance configuration.
- `https://hexdocs.pm/oban/Oban.Worker.html` - worker return values and retry/backoff semantics.
- `https://hexdocs.pm/req/Req.Steps.html` - form encoding and retry configuration.
- Local code: `mix.exs`, `mix.lock`, `lib/lockspire/protocol/end_session.ex`, `lib/lockspire/web/controllers/end_session_controller.ex`, `lib/lockspire/protocol/discovery.ex`, `lib/lockspire/admin/clients.ex`, `lib/lockspire/storage/ecto/repository.ex`, `lib/lockspire/observability.ex`, `lib/lockspire/audit/event.ex`, `lib/lockspire/redaction.ex`, `lib/lockspire/application.ex`, `lib/lockspire/web/live/admin/clients_live/show.ex`, `lib/lockspire/web/live/admin/clients_live/form_component.ex`, `test/integration/phase38_session_logout_e2e_test.exs`.

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Repo-pinned versions and Hex verification exist for all recommended dependencies; only `Req` is new, and its current Hex release was verified directly. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: `mix hex.info req`]
- Architecture: HIGH - The phase boundary, code seams, and official logout specs are aligned and concrete. [VERIFIED: .planning/phases/39-automated-rp-logout-propagation/39-CONTEXT.md] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]
- Pitfalls: HIGH - The main failure modes are explicit in the specs, Oban docs, and current repo seams. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [CITED: https://hexdocs.pm/oban/unique_jobs.html] [VERIFIED: lib/lockspire/redaction.ex]

**Research date:** 2026-04-29
**Valid until:** 2026-05-29 for local-code findings; re-check official docs sooner if Oban or Req versions are bumped.

## RESEARCH COMPLETE

**Phase:** 39 - automated-rp-logout-propagation
**Confidence:** HIGH

### Key Findings
- Back-channel delivery should be modeled as durable per-delivery work, not inline controller HTTP, and the official spec requires `application/x-www-form-urlencoded` POSTs with a signed `logout_token`. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]
- Front-channel logout must stay explicitly best effort because the spec warns that third-party browser storage restrictions can prevent iframe-based RP logout from accessing session state. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]
- Lockspire already has the right seams for this phase: `EndSessionController.complete/2`, `EndSession.Result`, discovery placeholders, typed client fields, shared redaction/observability, and an exposed `oban` config seam. [VERIFIED: lib/lockspire/web/controllers/end_session_controller.ex] [VERIFIED: lib/lockspire/protocol/end_session.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/config.ex]
- The repo does not currently depend on `Req`, so Phase 39 needs to add it before implementing SLO-03. [VERIFIED: mix.exs] [VERIFIED: `mix hex.info req`]
- There is no existing Oban testing helper in `test/support/`, so Wave 0 should add manual Oban test setup and targeted Phase 39 proof files. [VERIFIED: `rg -n 'Oban.Testing|drain_queue|assert_enqueued' test`] [CITED: https://hexdocs.pm/oban/Oban.html]

### File Created
`.planning/phases/39-automated-rp-logout-propagation/39-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Repo versions and Hex package metadata were verified directly. |
| Architecture | HIGH | Spec rules and existing code seams line up cleanly. |
| Pitfalls | HIGH | The relevant delivery, browser, and redaction pitfalls are explicit in the specs and current code. |

### Open Questions
- Decide during planning whether Phase 39 includes only client-config truth or also a first-pass read-only logout delivery browser.

### Ready for Planning
Research complete. Planner can now create PLAN.md files.
