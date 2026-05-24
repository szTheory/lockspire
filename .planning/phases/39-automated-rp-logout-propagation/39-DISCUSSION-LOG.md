# Phase 39: Automated RP Logout Propagation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `39-CONTEXT.md`; this log preserves the analysis that produced them.

**Date:** 2026-04-29
**Phase:** 39-automated-rp-logout-propagation
**Mode:** assumptions
**Areas analyzed:** back-channel delivery architecture, client metadata and discovery semantics, front-channel completion UX, repo implementation constraints

## Assumptions Presented

### Back-channel delivery architecture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Back-Channel Logout should be implemented as durable asynchronous delivery, not inline HTTP or best-effort task dispatch | Confident | `mix.exs`, `config/config.exs`, `lib/lockspire/application.ex`, `lib/lockspire/web/controllers/end_session_controller.ex`, `.planning/PROJECT.md`, OIDC Back-Channel Logout spec, Oban docs, Keycloak docs |
| `/end_session/complete` should remain the authoritative logout completion point and enqueue work after revocation rather than waiting on RP HTTP responses | Confident | `lib/lockspire/web/controllers/end_session_controller.ex`, `.planning/phases/38-session-tracking-rp-initiated-logout/38-CONTEXT.md`, `.planning/ROADMAP.md` |
| Durable logout delivery records are worth the extra schema surface because they preserve protocol truth, retries, and operator visibility | Likely | Existing auditability/durable-state posture in `.planning/PROJECT.md`, `lib/lockspire/observability.ex`, `lib/lockspire/audit/event.ex`; ecosystem lesson from OpenIddict session/store complexity |

### Client metadata and discovery semantics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 39 should ship the four standard OIDC logout client fields as first-class typed durable metadata | Confident | OIDC Back-Channel Logout spec, OIDC Front-Channel Logout spec, `lib/lockspire/domain/client.ex`, `lib/lockspire/storage/ecto/client_record.ex`, Keycloak/Duende client models |
| Logout propagation fields should be operator-managed only in this slice and rejected in DCR | Likely | `lib/lockspire/admin/clients.ex`, embedded-library/operator-controlled project thesis in `.planning/PROJECT.md`, SSRF risk from self-registered outbound callbacks |
| Discovery should only flip all related logout booleans together once the feature is fully live | Confident | `lib/lockspire/protocol/discovery.ex`, `.planning/phases/38-session-tracking-rp-initiated-logout/38-CONTEXT.md`, existing truthful-discovery pattern |

### Front-channel completion UX
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Front-channel should use a bounded auto-continue page with invisible iframes and a visible manual fallback | Confident | `.planning/ROADMAP.md`, `lib/lockspire/web/controllers/end_session_controller.ex`, `lib/lockspire/web/controllers/end_session_html/logged_out.html.heex`, OIDC Front-Channel Logout spec, Keycloak docs, MDN iframe/cookie guidance |
| Front-channel must be documented and instrumented as best-effort dispatch, not verified logout success | Confident | OIDC Front-Channel Logout spec, Keycloak docs, Microsoft/MSAL guidance, MDN iframe load behavior |
| The completion surface should remain controller-rendered HEEx, not LiveView | Likely | Existing minimal non-admin page pattern in `end_session_controller.ex` and `logged_out.html.heex`; repo preference for thin delivery surfaces |

### Repo constraints and reusable patterns
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 39 should reuse existing audit/telemetry/redaction seams rather than inventing parallel instrumentation | Confident | `lib/lockspire/observability.ex`, `lib/lockspire/redaction.ex`, `lib/lockspire/audit/event.ex` |
| Admin client editing should follow the existing explicit section/mode pattern instead of introducing chips/nested UI widgets | Likely | `lib/lockspire/web/live/admin/clients_live/form_component.ex`, `lib/lockspire/web/live/admin/clients_live/show.ex`, `lib/lockspire/web/live/admin/clients_live/index.ex` |

## Corrections Made

None. The user requested a full discuss-all pass with deep research and a coherent one-shot recommendation set, and the research converged without needing user-side correction.

## Research Applied

### Standards
- OIDC Back-Channel Logout 1.0 — logout token requirements, client metadata, discovery booleans, RP validation and response semantics
- OIDC Front-Channel Logout 1.0 — iframe flow, same-origin constraints, session-required booleans, discovery booleans
- OIDC RP-Initiated Logout 1.0 — relationship to the completion flow

### Elixir/Phoenix ecosystem
- Oban official docs — durable jobs, retries, uniqueness, triggered execution, and graceful shutdown
- Repo-local evidence that Oban is already a dependency/config seam but no library-owned workers exist yet

### Comparable systems
- Keycloak — back-channel preferred over front-channel; front-channel iframe/CSP/browser limitations stated plainly
- node-oidc-provider — proof that an embedded/mountable library can still take OIDC logout conformance seriously
- OpenIddict — caution that real back-channel logout needs durable session/store modeling
- Duende/IdentityServer — front-channel notification page pattern and bias toward back-channel for reliability

## Final Recommendation Bundle

1. Keep the host logout seam unchanged and make `/end_session/complete` the authoritative propagation point.
2. Introduce durable logout event/delivery state plus Oban-backed Back-Channel Logout dispatch.
3. Add the four standard logout metadata fields as typed durable client configuration, operator-managed only in Phase 39.
4. Publish all related discovery booleans truthfully once the implementation is live.
5. Render a bounded best-effort front-channel completion page with invisible iframes, auto-continue, and a visible manual fallback.
6. Keep audit/telemetry explicit and redacted, distinguishing enqueue, attempt, success, and failure rather than collapsing them.

## Deferred Ideas Captured

- DCR management of logout propagation metadata
- `check_session_iframe`
- Generic webhook subsystem abstraction
- Rich session browsing / replay UI
- Treating front-channel as a hard success criterion

---

*Phase: 39-automated-rp-logout-propagation*
*Discussion captured: 2026-04-29*
