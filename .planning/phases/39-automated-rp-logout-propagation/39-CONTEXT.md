# Phase 39: Automated RP Logout Propagation - Context

**Gathered:** 2026-04-29 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Actively propagate logout events to relying parties after the host app clears its own web session.
This phase extends Phase 38's `/end_session` completion path with standards-based Back-Channel
Logout and Front-Channel Logout, while preserving Lockspire's embedded-library shape and the
host-owned logout seam.

This phase covers:
- Back-Channel Logout webhook dispatch to registered relying parties
- Front-Channel Logout iframe rendering during the logout completion return
- Durable tracking of logout propagation attempts and outcomes
- Client metadata, discovery metadata, and operator UX needed to configure and observe the feature

This phase does not broaden Lockspire into a hosted session service, custom logout protocol, or
generic outbound webhook engine.
</domain>

<decisions>
## Implementation Decisions

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
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project constraints
- `.planning/ROADMAP.md` — Phase 39 goal, success criteria (SLO-03, SLO-04), and dependency on Phase 38
- `.planning/REQUIREMENTS.md` — SLO-03 and SLO-04 requirements
- `.planning/PROJECT.md` — embedded-library boundaries, durable-storage thesis, host seam ownership, and release-truth constraints
- `.planning/STATE.md` — current milestone position and carry-forward protocol decisions
- `.planning/METHODOLOGY.md` — active lenses: assumption-first, least-surprise host seam, research-first decisive defaults

### Prior phase decisions that constrain this work
- `.planning/phases/38-session-tracking-rp-initiated-logout/38-CONTEXT.md` — Phase 38 locked `sid`, `/end_session`, host logout seam, and truthful placeholder discovery flags
- `.planning/phases/38-session-tracking-rp-initiated-logout/38-RESEARCH.md` — prior logout-domain research and phase ordering rationale
- `.planning/phases/38-session-tracking-rp-initiated-logout/38-UI-SPEC.md` — current non-admin logout page and admin UX patterns

### Existing repo implementation targets
- `lib/lockspire/web/controllers/end_session_controller.ex` — current logout completion path to extend
- `lib/lockspire/protocol/discovery.ex` — current truthful discovery placeholders to upgrade
- `lib/lockspire/domain/client.ex` — durable client shape extension point
- `lib/lockspire/storage/ecto/client_record.ex` — durable client schema/update path
- `lib/lockspire/admin/clients.ex` — operator-managed mutable client boundary and validation style
- `lib/lockspire/observability.ex` — telemetry emission seam
- `lib/lockspire/audit/event.ex` — durable audit shape and redaction path
- `lib/lockspire/redaction.ex` — sensitive metadata redaction rules
- `lib/lockspire/application.ex` — current library supervision tree; no library-owned workers yet
- `config/config.exs` — existing public `oban` config seam

### Standards and ecosystem references
- `https://openid.net/specs/openid-connect-backchannel-1_0.html` — Back-Channel Logout token rules, client metadata, discovery booleans, validation, and RP response semantics
- `https://openid.net/specs/openid-connect-frontchannel-1_0.html` — Front-Channel Logout iframe flow, client metadata, discovery booleans, and same-origin redirect-URI constraint
- `https://openid.net/specs/openid-connect-rpinitiated-1_0.html` — RP-Initiated Logout relationship to the propagation flows
- `https://hexdocs.pm/oban/Oban.html` — durable job execution, unique jobs, triggered execution, and graceful shutdown semantics
- `https://hexdocs.pm/oban/Oban.Worker.html` — worker retries/backoff semantics
- `https://www.keycloak.org/docs/latest/server_admin/` — pragmatic operator guidance: back-channel is more reliable than front-channel; front-channel iframe limitations
- `https://github.com/panva/node-oidc-provider` — evidence that an embedded/mountable library can still take OIDC logout conformance seriously

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Web.EndSessionController` already owns the protocol-to-host-to-completion logout path. Phase 39 extends this rather than inventing a parallel logout entrypoint.
- `Lockspire.Observability`, `Lockspire.Redaction`, and `Lockspire.Audit.Event` already provide the shared telemetry/audit/redaction seams needed for logout delivery instrumentation.
- `clients_live/show.ex` and `form_component.ex` already establish the operator pattern for protocol-critical client fields: explicit sections, truthful copy, and newline-based multi-value editing.
- The existing minimal non-admin logout page pattern (`logged_out.html.heex`) is the right base for the bounded front-channel completion surface.

### Established Patterns
- Durable protocol truth lives in Ecto/Postgres, not in request-local memory or ambient Phoenix session state.
- Thin Phoenix controllers delegate correctness to protocol/domain logic and should not own third-party network side effects inline.
- Discovery metadata is deliberately truthful and should only advertise features that are actually live end-to-end.
- Host seams stay explicit and narrow. The host owns local session clearing and page framing around its own logout route; Lockspire owns protocol artifacts and state.
- Operator/admin surfaces prefer typed durable fields over hiding protocol behavior in generic metadata blobs.

### Integration Points
- `/end_session/complete` must become the fork point for both durable back-channel enqueueing and front-channel rendering.
- Client persistence, admin edit flow, and possibly DCR rejection logic must all be updated together so the logout metadata surface remains coherent.
- Discovery, docs, and tests must flip together with implementation so feature truth remains defensible.
- Oban integration must be introduced in a way that respects Lockspire's embedded-library shape and existing public config seam.
</code_context>

<specifics>
## Specific Ideas

- Treat Back-Channel Logout as the **reliable protocol primitive** and Front-Channel Logout as **best-effort browser choreography**. This is the central coherence rule for the entire phase.
- Keep the host seam exactly where it is now: host clears its own session, then returns to Lockspire; Lockspire handles propagation from there.
- Prefer a small bounded completion page with honest status text such as “Signing you out of connected apps…” over either an immediate redirect or a blocking “wait for all apps” fiction.
- If operator surfaces expose delivery state in this phase, they should distinguish configured channel, dispatch status, and failure reason instead of pretending front-channel dispatch is remotely verified.
</specifics>

<deferred>
## Deferred Ideas

- DCR/self-service management of logout propagation metadata — defer until the project explicitly wants the outbound callback risk surface and supporting policy review
- Session-management `check_session_iframe` — still out of scope
- Generic webhook framework abstraction — unnecessary broadening for v1
- Claims or events beyond the standard logout-token semantics, including proprietary “revoke offline session” behavior
- Rich session browser / replay UI — worth considering only after the durable delivery model exists and real operator needs are observed
- Treating front-channel as a hard success gate or requiring verified browser-side acknowledgements — inconsistent with modern browser reality and Lockspire's truthful preview posture
</deferred>

---

*Phase: 39-automated-rp-logout-propagation*
*Context gathered: 2026-04-29*
