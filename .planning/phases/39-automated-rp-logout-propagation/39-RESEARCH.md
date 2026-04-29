# Phase 39: Automated RP Logout Propagation - Research

**Researched:** 2026-04-29 [VERIFIED: `date +%F`]
**Domain:** OIDC Back-Channel Logout, OIDC Front-Channel Logout, durable delivery orchestration in an embedded Phoenix library [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [VERIFIED: repo reads]
**Confidence:** HIGH [CITED: official OIDC specs + Oban docs] [VERIFIED: current repo state]

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
| SLO-03 | Implement Back-Channel Logout webhook dispatch (server-to-server POST) via `req`. | Durable `logout_events` + `logout_deliveries`, `Req` for POSTing `logout_token`, Oban-backed unique delivery jobs, bounded retry policy, audit/telemetry separation, and integration tests that drain the queue and inspect persisted outcomes. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.Worker.html] [VERIFIED: repo reads] |
| SLO-04 | Implement Front-Channel Logout asynchronous iframe rendering on host return. | Plain controller-rendered completion page, iframe fan-out from durable delivery rows, `iss`/`sid` query composition when required, truthful browser limitation copy, and controller/integration tests that assert rendered iframes rather than fictitious remote acknowledgement. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [VERIFIED: repo reads] |
</phase_requirements>

## Summary

Phase 39 should treat logout propagation as two different channels with different truth models: Back-Channel Logout is the reliable protocol primitive, while Front-Channel Logout is browser-mediated best effort. The OIDC Back-Channel spec requires an OP to send an HTTP `POST` with `logout_token` to each registered `backchannel_logout_uri`, and the Front-Channel spec defines iframe rendering plus explicit browser limitations around third-party state access. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]

The current Lockspire code already gives Phase 39 the right seam: `/end_session/complete` is the authoritative completion point, `sid` is persisted on interactions and tokens, `EndSessionController` already revokes by `sid`, discovery still truthfully publishes `backchannel_logout_supported: false` and `frontchannel_logout_supported: false`, Oban is already a dependency but is not yet started in `Lockspire.Application`, and the repo has audit, telemetry, and redaction seams that can be reused. [VERIFIED: `lib/lockspire/web/controllers/end_session_controller.ex`] [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [VERIFIED: `lib/lockspire/application.ex`] [VERIFIED: `mix.exs`] [VERIFIED: `mix.lock`] [VERIFIED: `lib/lockspire/observability.ex`] [VERIFIED: `lib/lockspire/audit/event.ex`] [VERIFIED: `lib/lockspire/redaction.ex`]

The implementation-ready recommendation is to persist one durable `logout_event` per completed OP logout, persist one durable `logout_delivery` per client/channel snapshot, enqueue only back-channel deliveries onto a named Lockspire-owned Oban instance, and render front-channel deliveries from the completion page using the stored snapshot rows. That keeps retries, audit truth, operator inspection, and browser limitations explicit instead of burying them inside controller state or `oban_jobs`. [CITED: https://hexdocs.pm/oban/2.21.1/Oban.Job.html] [CITED: https://hexdocs.pm/oban/2.21.1/unique_jobs.html] [VERIFIED: repo architecture and phase context]

**Primary recommendation:** Use durable `logout_events` + `logout_deliveries` as protocol truth, a Lockspire-owned named Oban instance for back-channel execution, strict operator-only client metadata with DCR rejection, and a truthful best-effort iframe completion page for front-channel logout. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persist logout event truth | Database / Storage [VERIFIED: project storage thesis] | API / Backend [VERIFIED: controller already delegates] | Retryable fan-out, audit history, and operator inspection need durable rows rather than request memory. [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `lib/lockspire/web/controllers/end_session_controller.ex`] |
| Back-channel logout token creation | API / Backend [CITED: spec defines OP POST + logout token] | Database / Storage [VERIFIED: event snapshot feeds payload] | The OP constructs the protocol artifact; storage only supplies event and client snapshot state. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] |
| Back-channel delivery execution | Frontend Server / OTP worker tier [CITED: Oban worker lifecycle] | Database / Storage [CITED: Oban jobs persist in DB] | HTTP dispatch belongs in a background worker, not the controller transaction. [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.Worker.html] |
| Front-channel iframe rendering | Frontend Server / Phoenix controller [VERIFIED: existing completion page is controller-rendered] | Browser / Client [CITED: spec uses iframe via user agent] | Lockspire renders the completion document; the browser executes the iframe requests. [VERIFIED: `lib/lockspire/web/controllers/end_session_controller.ex`] [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
| Host session clearing | Host app seam [VERIFIED: Phase 38 seam] | — | Host ownership remains unchanged and precedes propagation. [VERIFIED: `.planning/phases/38-session-tracking-rp-initiated-logout/38-CONTEXT.md`] |
| Discovery truth | API / Backend [VERIFIED: `Discovery.openid_configuration/0`] | — | Published booleans must match what the mounted feature actually does. [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [CITED: both OIDC logout specs] |
| Client logout metadata validation | API / Backend [VERIFIED: `Lockspire.Admin.Clients` and `Registration`] | Database / Storage [VERIFIED: first-class fields live on client schema] | Validation and DCR rejection already live in admin/protocol seams, not LiveView. [VERIFIED: `lib/lockspire/admin/clients.ex`] [VERIFIED: `lib/lockspire/protocol/registration.ex`] [VERIFIED: `lib/lockspire/storage/ecto/client_record.ex`] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `oban` | `2.21.1` locked in repo; `2.22.0` latest on Hex at research time [VERIFIED: `mix.lock`] [VERIFIED: `mix hex.info oban`] | Durable background execution, retries, unique jobs, queue draining in tests | Already a project dependency; supports transactional enqueue, unique jobs, durable retries, and named instances. [VERIFIED: `mix.exs`] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html] |
| `req` | `0.5.17` latest on Hex at research time [VERIFIED: `mix hex.info req`] | Server-to-server HTTP `POST` for back-channel logout | The phase requirement explicitly calls for `req`; official docs show first-class POST APIs and structured responses. [CITED: https://hexdocs.pm/req/Req.html] |
| `jose` | `~> 1.11` [VERIFIED: `mix.exs`] | Sign the back-channel logout token as a JWT | Lockspire already uses JOSE for ID tokens, JAR, and DPoP; logout tokens are JWTs by spec. [VERIFIED: repo grep] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] |
| `ecto_sql` | `~> 3.13.5` [VERIFIED: `mix.exs`] | Durable event/delivery tables and repository updates | Project-wide durable truth layer. [VERIFIED: `.planning/PROJECT.md`] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix Controller / HEEx | `~> 1.8.5` [VERIFIED: `mix.exs`] | Completion-page rendering and `/end_session/complete` extension | Use for front-channel iframe page and operator-safe fallback copy. [VERIFIED: `lib/lockspire/web/controllers/end_session_controller.ex`] |
| `Oban.Testing` + `drain_queue/2` | bundled with Oban [CITED: Oban testing docs] | Assert enqueued jobs and run delivery workers in sandboxed tests | Use in unit and integration tests for SLO-03 without waiting on real queue polling. [CITED: https://hexdocs.pm/oban/testing.html] [CITED: https://hexdocs.pm/oban/testing_queues.html] [CITED: https://hexdocs.pm/oban/Oban.Testing.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Oban-backed durable worker pipeline [CITED: Oban docs] | Inline controller HTTP or `Task.Supervisor` [VERIFIED: current code has no worker infra] | Inline or in-memory dispatch loses durable retries, clustered coordination, and operator truth; it contradicts locked Decisions D-01 through D-07. [VERIFIED: `lib/lockspire/application.ex`] [VERIFIED: `39-CONTEXT.md`] |
| `req` [VERIFIED: `mix hex.info req`] | `:httpc` or Finch directly [ASSUMED] | `req` is the requested slice and gives a higher-level API; lower-level clients add ceremony without phase value. |

**Installation:** [VERIFIED: repo dependency state] [VERIFIED: `mix hex.info req`]
```bash
mix deps.add req --version "~> 0.5.17"
```

## Architecture Patterns

### System Architecture Diagram

```text
RP -> /end_session -> host logout -> /end_session/complete
                                  |
                                  v
                    persist logout_event (one per OP logout)
                                  |
                    persist logout_deliveries (one per client/channel snapshot)
                          |                             |
                          v                             v
        enqueue back-channel deliveries in Oban     render front-channel page
                          |                             |
                          v                             v
        Req POST logout_token to RP callback      invisible iframes + visible continue link
                          |                             |
                          v                             v
        update delivery status + audit/telemetry  mark rendered-at snapshot only
```

### Recommended Project Structure
```text
lib/lockspire/
├── application.ex                         # start Lockspire.Oban and fail fast on invalid config
├── oban.ex                                # named Oban facade: use Oban, otp_app: :lockspire
├── protocol/
│   ├── logout_propagation.ex              # event creation, client fan-out selection, URL building
│   └── discovery.ex                       # truthful logout booleans
├── workers/
│   └── backchannel_logout_delivery_worker.ex
├── domain/
│   ├── logout_event.ex
│   └── logout_delivery.ex
├── storage/ecto/
│   ├── logout_event_record.ex
│   └── logout_delivery_record.ex
└── web/controllers/end_session_html/
    └── logged_out.html.heex               # upgraded completion page with iframe fan-out

priv/repo/migrations/
├── *_create_lockspire_logout_events.exs
├── *_create_lockspire_logout_deliveries.exs
└── *_add_logout_propagation_fields_to_lockspire_clients.exs
```

### Pattern 1: Event row as the authoritative logout fact
**What:** Persist a single `logout_event` after `/end_session/complete` revokes `sid`-scoped tokens and before any outbound work is attempted. [VERIFIED: current completion flow] [VERIFIED: `39-CONTEXT.md`]
**When to use:** Every successful completion where Lockspire has enough identity/session context to propagate logout. [CITED: Back-Channel logout token needs `sub` or `sid`] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]
**Recommended shape:** [CITED: durable audit needs snapshots] [VERIFIED: repo storage/audit patterns]

| Field | Recommendation | Why |
|------|----------------|-----|
| `event_id` | UUID string, unique, public-safe handle [ASSUMED] | Stable correlation key across audit, telemetry, and deliveries. |
| `sid` | nullable string, indexed [VERIFIED: Phase 38 already persists `sid`] | Primary propagation pivot for this phase’s session-scoped model. [VERIFIED: `lib/lockspire/domain/token.ex`] |
| `subject` / `account_id` | nullable string snapshot [VERIFIED: EndSession.Result includes account_id] | Lets logout tokens include `sub` when available and preserves operator context. [VERIFIED: `lib/lockspire/protocol/end_session.ex`] |
| `initiated_by` | `:rp_initiated_logout` enum/text [VERIFIED: phase scope] | Distinguishes future logout sources without schema churn. |
| `post_logout_redirect_uri` | nullable string snapshot [VERIFIED: current completion flow carries it] | Operator truth for what the user-facing completion page was targeting. |
| `frontchannel_continue_to` | nullable string snapshot [ASSUMED] | Prevents later page rendering from depending on mutable request state. |
| `inserted_at` / `completed_at` | timestamps [VERIFIED: existing repo patterns] | Supports audit ordering and phase success checks. |

**Recommendation:** do not store the raw logout JWT on `logout_events`. Store only correlation metadata such as `logout_token_jti` on delivery rows, because the spec requires the RP-facing artifact to be a signed JWT and the phase context forbids persisting sensitive artifacts. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: `39-CONTEXT.md`] [VERIFIED: `lib/lockspire/redaction.ex`]

### Pattern 2: Delivery rows as per-client, per-channel snapshots
**What:** Persist one `logout_delivery` row for each `(logout_event, client_id, channel)` combination, including a snapshot of the URI and session-required flags at event time. [VERIFIED: locked D-03, D-08, D-14] [VERIFIED: current client metadata model]
**When to use:** Always for eligible clients; never derive delivery state solely from `oban_jobs` or from the rendered page. [CITED: Oban retains job rows but they are queue mechanics, not domain truth] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html]
**Recommended shape:** [VERIFIED: operator-truth requirement] [CITED: specs define distinct client metadata per channel]

| Field | Recommendation | Why |
|------|----------------|-----|
| `logout_event_id` | FK + index [VERIFIED: standard repo pattern] | Groups all fan-out work under one logout. |
| `client_id` | string + index [VERIFIED: repo client identity is client_id] | Stable operator-facing identifier. |
| `channel` | `:backchannel | :frontchannel` enum/text [CITED: two specs define separate channels] | A single table preserves one operator timeline while keeping behavior explicit. |
| `target_uri` | string snapshot [CITED: both specs define registered URIs] | Client edits after logout must not rewrite history. |
| `session_required` | boolean snapshot [CITED: both specs define `*_session_required`] | Explains why `sid` and `iss` were or were not attached. |
| `status` | text enum: `pending`, `enqueued`, `attempted`, `succeeded`, `retryable`, `discarded`, `rendered`, `skipped` [ASSUMED] | Distinguishes protocol execution from best-effort browser rendering. |
| `attempt_count` | integer default `0` [CITED: Oban retries are attempt-based] | Keeps operator truth after Oban jobs are pruned. |
| `last_attempted_at`, `delivered_at`, `rendered_at`, `finalized_at` | timestamps [VERIFIED: repo uses UTC timestamps] | Needed for retries, audit timelines, and UI truth. |
| `http_status` | nullable integer [VERIFIED: Req response has `status`] | Durable record of RP HTTP outcome for back-channel rows only. [CITED: https://hexdocs.pm/req/Req.Response.html] |
| `failure_reason` | nullable text/atom-string [VERIFIED: repo audit pattern uses reason codes] | Bounded retry logic needs machine-readable terminal reasons. |
| `logout_token_jti` | nullable string snapshot [CITED: logout token may include `jti`; replay detection is optional for RPs] | Correlates deliveries without storing the raw JWT. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] |
| `oban_job_id` | nullable integer [ASSUMED] | Useful correlation from domain truth to queue mechanics; not the source of truth. |

**Recommended durable rule:** front-channel rows stop at `rendered` or `skipped`; they never claim `succeeded`, because the OP does not receive a cross-origin proof of RP logout completion. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]

### Pattern 3: Named Oban instance owned by Lockspire, configured by the host
**What:** Add `Lockspire.Oban` as a facade module and start it in `Lockspire.Application`, sourcing config from `config :lockspire, Lockspire.Oban` or a merged `Config.oban_config()` seam. [CITED: Oban facade + supervision pattern] [VERIFIED: current app has no children yet] [VERIFIED: current config exposes `oban`]
**When to use:** Always for Phase 39 back-channel dispatch. [VERIFIED: locked D-04]
**Example:** [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html]
```elixir
defmodule Lockspire.Oban do
  use Oban, otp_app: :lockspire
end

def start(_type, _args) do
  children = [
    Lockspire.Oban
  ]

  Supervisor.start_link(children, strategy: :one_for_one, name: Lockspire.Supervisor)
end
```

**Execution ownership boundary:** the host owns repo wiring, queue concurrency, plugins, and deploy/runtime health; Lockspire owns queue names, worker modules, job args shape, retry classification, and when propagation is enqueued. That preserves the embedded-library shape without making protocol correctness optional. [CITED: Oban facade config pattern] [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `lib/lockspire/application.ex`] [VERIFIED: `lib/lockspire/config.ex`]

### Pattern 4: Enqueue inside the same transaction that persists deliveries
**What:** Insert `logout_event`, insert `logout_delivery` snapshots, and enqueue back-channel jobs through `Oban.insert/5` in the same `Ecto.Multi` or repository transaction. [CITED: Oban supports `insert/5` into `Ecto.Multi`; jobs only trigger after successful transaction] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.Job.html]
**When to use:** Every time `/end_session/complete` creates propagation state. [VERIFIED: locked D-02 and D-06]
**Why:** it prevents the controller from claiming work exists when the rows never committed, and it prevents orphaned rows with no queued execution. [CITED: Oban transactional control] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html]

### Anti-Patterns to Avoid
- **Inline HTTP from `EndSessionController.complete/2`:** blocks user completion on RP latency and violates locked D-01, D-02, and D-06. [VERIFIED: `39-CONTEXT.md`]
- **Using `oban_jobs` as the only audit record:** Oban job retention is queue-mechanics truth, not operator-facing logout truth. Persist delivery rows separately. [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html]
- **Treating front-channel iframe load as success:** the spec only defines browser-mediated rendering and separately documents third-party storage blocking. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]
- **Advertising only `*_supported` without `*_session_supported`:** locked D-13 forbids half-truth discovery, and Phase 38 already emits `sid` in ID tokens. [VERIFIED: `39-CONTEXT.md`] [VERIFIED: `test/lockspire/protocol/id_token_test.exs`] [CITED: both OIDC logout specs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Durable retries and clustered job dispatch | `Task.Supervisor`, `send_after`, process dictionaries [VERIFIED: repo has no queue infra yet] | Oban workers + named queue [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html] | Oban already provides persistence, retry state, uniqueness, queue control, and test helpers. |
| HTTP transport for logout callbacks | raw `:httpc` wrapper [ASSUMED] | `Req.post/2` with explicit timeout and form body [CITED: https://hexdocs.pm/req/Req.html] | The phase requirement calls for `req`, and `Req` gives structured responses for status-based retry logic. |
| JWT signing for logout tokens | custom JOSE wrapper from scratch [VERIFIED: JOSE already used] | existing JOSE signing patterns reused from ID token code [VERIFIED: repo grep] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] | Logout tokens are JWTs and should reuse the repo’s signing-key lifecycle. |
| Browser completion acknowledgement | cross-origin `postMessage` protocol or `iframe.onload` heuristics [CITED: browser limitations section] | bounded delay + continue link + truthful copy [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] | The OP cannot reliably prove front-channel success across origins. |

**Key insight:** use Oban as execution infrastructure and `logout_deliveries` as domain truth; using only one of them leaves either retries or operator truth underspecified. [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html] [VERIFIED: phase decisions]

## Common Pitfalls

### Pitfall 1: Treating repeated `/end_session/complete` hits as harmless duplicates
**What goes wrong:** duplicate completion requests can create duplicate fan-out and duplicate audit noise. [VERIFIED: current controller would sign/reuse completion tokens without durable dedupe]
**Why it happens:** browser retries, users reopening the host return URL, or clustered workers all re-enter the same logical logout. [ASSUMED]
**How to avoid:** persist a unique `logout_event` correlation key per completion token and make each back-channel job unique by delivery id across incomplete states. [CITED: https://hexdocs.pm/oban/2.21.1/unique_jobs.html]
**Warning signs:** multiple delivery rows for the same `(event, client, channel)` or repeated `logout_requested` telemetry for the same `sid`. [ASSUMED]

### Pitfall 2: Letting client edits rewrite historical delivery truth
**What goes wrong:** operator UI shows a URI that did not receive the logout. [VERIFIED: client config is mutable in admin path]
**Why it happens:** reading live client metadata at render/worker time instead of snapshotting `target_uri` and `session_required` onto delivery rows. [ASSUMED]
**How to avoid:** snapshot per-delivery metadata at event creation and drive workers/pages from those rows. [VERIFIED: current admin fields are mutable] [CITED: specs register URIs as client metadata]
**Warning signs:** historical pages or audit records change after a client edit. [ASSUMED]

### Pitfall 3: Assuming front-channel logout is remotely verifiable
**What goes wrong:** UI or audit overstates success even when browser privacy features prevent iframe state access. [CITED: front-channel browser limitation section]
**Why it happens:** confusing “iframe rendered” with “RP session cleared.” [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]
**How to avoid:** mark rows `rendered`, not `succeeded`; copy should say “best effort.” [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]
**Warning signs:** tests asserting on `onload` or cross-origin callbacks instead of rendered HTML. [ASSUMED]

### Pitfall 4: Retrying permanent 4xx failures forever
**What goes wrong:** noisy queues, repeated outbound traffic, and misleading “still retrying” operator state. [VERIFIED: locked D-07]
**Why it happens:** treating every non-2xx response as transient. [ASSUMED]
**How to avoid:** classify network errors and `5xx` as retryable; classify stable `4xx` and invalid snapshot state as terminal `discarded`/`skipped`. [VERIFIED: `39-CONTEXT.md`] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.Worker.html]
**Warning signs:** attempt counts climbing on `400`/`401`/`404` responses. [ASSUMED]

## Code Examples

### Back-channel delivery worker shape
```elixir
# Source: Oban worker options and result semantics
# https://hexdocs.pm/oban/2.21.1/Oban.Worker.html
defmodule Lockspire.Workers.BackchannelLogoutDeliveryWorker do
  use Oban.Worker,
    queue: :lockspire_logout,
    max_attempts: 5,
    unique: [period: :infinity, keys: [:delivery_id], states: :incomplete]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"delivery_id" => delivery_id}}) do
    with {:ok, delivery} <- LogoutDeliveries.fetch_pending_backchannel(delivery_id),
         {:ok, token} <- LogoutTokens.sign(delivery),
         {:ok, response} <-
           Req.post(
             url: delivery.target_uri,
             form: [logout_token: token],
             receive_timeout: 5_000
           ) do
      case response.status do
        status when status in 200..299 -> LogoutDeliveries.mark_succeeded(delivery, status)
        status when status in 500..599 -> {:error, {:http_retryable, status}}
        status -> {:cancel, {:http_terminal, status}}
      end
    end
  end
end
```

### Front-channel logout URL composition
```elixir
# Source: OIDC Front-Channel Logout 1.0, §2 and §3.1
# https://openid.net/specs/openid-connect-frontchannel-1_0.html
def build_frontchannel_url(target_uri, issuer, sid, true) do
  target_uri
  |> append_query_param("iss", issuer)
  |> append_query_param("sid", sid)
end

def build_frontchannel_url(target_uri, _issuer, _sid, false), do: target_uri
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| RP-initiated logout stops after host session clear + token revocation [VERIFIED: Phase 38] | OP also propagates logout to registered RPs over back-channel and front-channel [CITED: OIDC logout specs] | Phase 39 scope [VERIFIED: ROADMAP.md] | Connected apps are actively notified instead of inferring logout only from token expiry or next request. |
| Discovery advertises `backchannel_logout_supported: false` and `frontchannel_logout_supported: false` [VERIFIED: `lib/lockspire/protocol/discovery.ex`] | Discovery flips all four logout booleans truthfully once Phase 39 is live [CITED: both OIDC logout specs] | Phase 39 [VERIFIED: `39-CONTEXT.md`] | RPs can register and rely on shipped logout behavior. |
| No library-owned worker services in `Lockspire.Application` [VERIFIED: `lib/lockspire/application.ex`] | Lockspire starts a named Oban instance for protocol-owned background execution [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html] | Phase 39 recommendation | Background delivery becomes a first-class library capability instead of host ad hoc wiring. |

**Deprecated/outdated:**
- Inline best-effort logout fan-out from the controller is outdated for this phase because it contradicts the locked durable pipeline decisions. [VERIFIED: `39-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `logout_event.event_id` should be a UUID string rather than an integer-only internal id. | Architecture Patterns | Low — an integer PK still works if a separate correlation key is added later. |
| A2 | `logout_delivery.status` should use the exact enum set `pending/enqueued/attempted/succeeded/retryable/discarded/rendered/skipped`. | Architecture Patterns | Low — naming can change if the state distinctions remain. |
| A3 | Persisting `frontchannel_continue_to` on the event row is worth the extra column. | Architecture Patterns | Low — can be recomputed from existing redirect data if the planner prefers. |
| A4 | `oban_job_id` should be stored on delivery rows for correlation. | Architecture Patterns | Low — observability can rely on telemetry correlation only if needed. |
| A5 | Warning-sign examples that mention repeated telemetry for the same `sid` assume telemetry consumers will key by `sid` or event id. | Common Pitfalls | Low — affects ops ergonomics, not protocol correctness. |

## Resolved Decision

1. **Phase 39 will hard-fail startup when required Oban runtime config is missing or invalid.**
   - What we know: the repo already fail-fast validates required config such as `logout_path`, and `Lockspire.Application` currently has no worker children. [VERIFIED: `lib/lockspire/config.ex`] [VERIFIED: `lib/lockspire/application.ex`]
   - Resolution: treat Oban as required protocol infrastructure for the shipped Phase 39 surface rather than a truth-based feature toggle. [VERIFIED: `39-CONTEXT.md`]
   - Planner implication: `Lockspire.Application`/`Lockspire.Oban` startup must surface a clear configuration error instead of silently hiding discovery booleans or degrading logout propagation. [VERIFIED: project fail-fast pattern] [CITED: https://hexdocs.pm/oban/2.21.1/Oban.html]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Mix | adding `req`, compiling, tests | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL | Oban persistence and repo-backed tests | ✓ [VERIFIED: `pg_isready`] | `14.17` client; local server accepting connections on `/tmp:5432` [VERIFIED: `psql --version`] [VERIFIED: `pg_isready`] | — |
| Oban | back-channel job execution | ✓ in repo [VERIFIED: `mix.exs`] [VERIFIED: `mix.lock`] | locked `2.21.1` [VERIFIED: `mix.lock`] | — |
| Req | back-channel HTTP transport | ✗ in repo today [VERIFIED: `mix.exs` missing `req`] | latest `0.5.17` on Hex [VERIFIED: `mix hex.info req`] | none — add dependency |

**Missing dependencies with no fallback:**
- `req` is not yet declared in `mix.exs`; Phase 39 should add it before implementing SLO-03. [VERIFIED: `mix.exs`] [VERIFIED: `mix hex.info req`]

**Missing dependencies with fallback:**
- None. [VERIFIED: current repo + environment checks]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix/Ecto sandbox tests [VERIFIED: `test/test_helper.exs`] [VERIFIED: existing test files] |
| Config file | `test/test_helper.exs` [VERIFIED: file read] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs test/lockspire/workers/backchannel_logout_delivery_worker_test.exs test/lockspire/web/end_session_controller_test.exs` [ASSUMED] |
| Full suite command | `MIX_ENV=test mix test.fast` plus targeted integration `MIX_ENV=test mix test --include integration test/integration/phase39_logout_propagation_e2e_test.exs` [VERIFIED: `mix.exs` aliases] [ASSUMED: new phase39 test file path] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SLO-03 | `/end_session/complete` persists a logout event, persists back-channel delivery rows, enqueues exactly one unique job per back-channel delivery, and does not block on outbound HTTP. [VERIFIED: locked D-01 through D-06] | controller + enqueue integration | `MIX_ENV=test mix test test/lockspire/web/end_session_controller_test.exs` [VERIFIED: file exists] | ✅ existing file, needs new cases |
| SLO-03 | worker posts `logout_token`, classifies 2xx as success, retries transient failures, and marks permanent failures terminal. [CITED: back-channel spec + Oban retry semantics] | worker unit/integration | `MIX_ENV=test mix test test/lockspire/workers/backchannel_logout_delivery_worker_test.exs` [ASSUMED] | ❌ Wave 0 |
| SLO-03 | DCR rejects logout propagation metadata as unsupported in this slice. [VERIFIED: locked D-10] | protocol unit | `MIX_ENV=test mix test test/lockspire/protocol/registration_test.exs` [VERIFIED: file exists] | ✅ existing file, needs new cases |
| SLO-03 | admin validation persists first-class logout fields and rejects invalid URI/session-required combinations. [VERIFIED: admin client seam] | admin unit | `MIX_ENV=test mix test test/lockspire/admin/clients_test.exs` [VERIFIED: file exists] | ✅ existing file, needs new cases |
| SLO-03 | discovery publishes all four truthful logout booleans once the feature is live. [VERIFIED: locked D-13] | protocol + controller unit | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` [VERIFIED: files exist] | ✅ existing files, needs new cases |
| SLO-04 | completion page renders one invisible iframe per eligible front-channel delivery, includes `iss` and `sid` only when required, and shows a visible continue fallback. [CITED: front-channel spec] | controller/template unit | `MIX_ENV=test mix test test/lockspire/web/end_session_controller_test.exs` [VERIFIED: file exists] | ✅ existing file, needs new cases |
| SLO-03 + SLO-04 | end-to-end logout completion revokes tokens, enqueues/drains back-channel work, records durable outcomes, and renders front-channel iframe HTML from the same event. [VERIFIED: current Phase 38 e2e analog] | integration | `MIX_ENV=test mix test --include integration test/integration/phase39_logout_propagation_e2e_test.exs` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** targeted unit/controller tests for touched seam. [VERIFIED: repo has fine-grained tests]
- **Per wave merge:** run back-channel worker tests plus discovery/controller tests and one phase integration drain. [ASSUMED]
- **Phase gate:** targeted Phase 39 integration plus relevant existing Phase 38 logout e2e regression before `/gsd-verify-work`. [VERIFIED: `test/integration/phase38_session_logout_e2e_test.exs`]

### Wave 0 Gaps
- [ ] `test/lockspire/workers/backchannel_logout_delivery_worker_test.exs` — covers SLO-03 delivery execution, retry classification, and redaction.
- [ ] `test/lockspire/protocol/logout_propagation_test.exs` — covers client fan-out selection, logout token claims, and front-channel URL construction.
- [ ] `test/lockspire/storage/ecto/repository_logout_propagation_test.exs` — covers event/delivery persistence helpers and snapshot updates.
- [ ] `test/integration/phase39_logout_propagation_e2e_test.exs` — covers durable enqueue + drain + iframe rendering on one logout event.
- [ ] test Oban setup in `config/test.exs` or helper bootstrap — use `testing: :manual` and `use Oban.Testing, repo: Lockspire.TestRepo`. [CITED: https://hexdocs.pm/oban/testing.html] [CITED: https://hexdocs.pm/oban/Oban.Testing.html]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [CITED: logout tokens are signed JWTs from the OP] | Verify logout tokens are signed with Lockspire signing keys; do not emit `alg=none`. [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: project security defaults] |
| V3 Session Management | yes [VERIFIED: phase scope is logout/session propagation] | Use persisted `sid`, session-required metadata, and token revocation before fan-out. [VERIFIED: Phase 38 code and context] |
| V4 Access Control | yes [VERIFIED: operator-managed metadata only] | Keep logout propagation fields in admin-only surfaces; DCR rejects them in Phase 39. [VERIFIED: `39-CONTEXT.md`] [VERIFIED: `lib/lockspire/protocol/registration.ex`] |
| V5 Input Validation | yes [CITED: specs define URI constraints] | Reuse strict URI validation, forbid fragments, require front-channel same scheme/host/port as a registered redirect URI, and reject `*_session_required` without the corresponding URI. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] [VERIFIED: existing `Clients.validate_redirect_uris/1`] |
| V6 Cryptography | yes [CITED: logout token is JWT-based] | Sign logout tokens with JOSE and existing Lockspire signing-key lifecycle; never persist raw JWTs in audit or telemetry. [VERIFIED: repo JOSE usage] [VERIFIED: `lib/lockspire/redaction.ex`] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious or misconfigured RP logout URI causing SSRF | Tampering / Info Disclosure | Accept only operator-managed URIs, validate them offline, never live-probe on save, and keep DCR unsupported for these fields in Phase 39. [VERIFIED: locked D-10 and D-11] |
| Raw logout token leakage in logs or audit | Information Disclosure | Store only `jti`, status, client id, URI snapshot, and redacted reason metadata; extend redaction keys if needed for `logout_token`. [VERIFIED: `lib/lockspire/redaction.ex`] [VERIFIED: locked D-22] |
| Duplicate dispatch from repeated completion or clustered workers | Tampering / DoS | Unique Oban jobs keyed by delivery id plus unique delivery rows per `(event, client, channel)`. [CITED: https://hexdocs.pm/oban/2.21.1/unique_jobs.html] |
| Slow or failing RPs exhausting request time | DoS | Run outbound work in Oban with low per-request timeouts, bounded `max_attempts`, and terminal handling for stable `4xx`. [CITED: https://hexdocs.pm/oban/2.21.1/Oban.Worker.html] [CITED: https://hexdocs.pm/req/Req.html] |
| Browser privacy features preventing front-channel cleanup | Repudiation / Reliability | Document best-effort semantics and never mark front-channel rows `succeeded`. [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |

## Sources

### Primary (HIGH confidence)
- OpenID Connect Back-Channel Logout 1.0 incorporating errata set 1 — support booleans, RP metadata, logout token claims, POST semantics, and RP validation steps. https://openid.net/specs/openid-connect-backchannel-1_0.html
- OpenID Connect Front-Channel Logout 1.0 — iframe flow, RP metadata, `iss`/`sid` rules, discovery booleans, and browser limitation section. https://openid.net/specs/openid-connect-frontchannel-1_0.html
- Oban v2.21.1 docs — named instances, supervision, transactional enqueue, worker retry/backoff semantics, and queue draining in tests. https://hexdocs.pm/oban/2.21.1/Oban.html
- Oban.Worker v2.21.1 — `max_attempts`, `unique`, return semantics, and `backoff/1`. https://hexdocs.pm/oban/2.21.1/Oban.Worker.html
- Oban unique jobs guide — insertion-time uniqueness semantics and state scoping. https://hexdocs.pm/oban/2.21.1/unique_jobs.html
- Repo code and planning artifacts read during this session — Phase 38/39 docs, current logout code, discovery, admin clients, audit, redaction, tests, and mix metadata. [VERIFIED: file reads listed in this session]

### Secondary (MEDIUM confidence)
- Req docs/readme for POST and response handling. https://hexdocs.pm/req/Req.html
- Hex package info for current `oban` and `req` release availability. [VERIFIED: `mix hex.info oban`] [VERIFIED: `mix hex.info req`]

### Tertiary (LOW confidence)
- None. All material protocol/runtime claims above were either verified in the repo or cited from official docs.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — repo-pinned dependencies, Hex package verification, and official docs align. [VERIFIED: `mix.exs`] [VERIFIED: `mix.lock`] [VERIFIED: `mix hex.info oban`] [VERIFIED: `mix hex.info req`]
- Architecture: HIGH — recommendations are directly constrained by locked Phase 39 decisions, existing Phase 38 seams, and Oban/OIDC normative behavior. [VERIFIED: `39-CONTEXT.md`] [VERIFIED: repo reads] [CITED: official specs/docs]
- Pitfalls: MEDIUM — the retry/browser pitfalls are strongly supported by docs, while some warning-sign examples are operational inference. [CITED: official specs/docs] [ASSUMED: operational examples]

**Research date:** 2026-04-29 [VERIFIED: `date +%F`]
**Valid until:** 2026-05-29 for repo-shape guidance; re-check before implementation if Oban is upgraded beyond `2.21.1` or if logout scope changes. [VERIFIED: `mix.lock`] [VERIFIED: `mix hex.info oban`]
