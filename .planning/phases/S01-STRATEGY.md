# Phase S01: Telemetry Foundation & LiveDashboard Integration (Strategy)

## Context & User Preferences
Based on user directives, Lockspire defaults to deep, cohesive, one-shot architectural decisions optimized for developer ergonomics, the principle of least surprise, and idiomatic Elixir/Phoenix patterns, mirroring lessons from successful ecosystem libraries.

## 1. Telemetry Naming Schema
**Decision:** Adopt a strict hierarchical schema: `[:lockspire, :<entity>, :<action>]` (e.g., `[:lockspire, :token, :issued]`, `[:lockspire, :dpop, :failed]`).
**Rationale:** 
- **Idiomatic Elixir:** Matches `Ecto` (`[:ecto, :repo, :query]`) and `Phoenix` (`[:phoenix, :endpoint, :stop]`).
- **Developer Ergonomics:** Makes it trivial for host apps to pattern match, filter, and group events in APMs like Datadog, Prometheus, or AppSignal.
- **Actionable:** Replaces existing flat events (e.g., `[:lockspire, :access_token_issued]`) before the 1.0 API freeze ensures no breaking changes for GA users.

## 2. LiveDashboard Integration Strategy
**Decision:** Add `:phoenix_live_dashboard` to `mix.exs` with `optional: true` and use conditional compilation (`Code.ensure_loaded?(Phoenix.LiveDashboard.PageBuilder)`) to provide a default Lockspire LiveDashboard page.
**Rationale:**
- **Zero Friction:** Phoenix users get a beautiful, out-of-the-box UI by simply adding one line to their router: `live_dashboard "/dashboard", additional_pages: [lockspire: Lockspire.LiveDashboardPage]`.
- **No Bloat:** Non-Phoenix (Plug-only) or headless consumers do not download the dashboard dependency.
- **Prior Art:** This is the exact strategy used successfully by `Oban` (for its free dashboard) and `Broadway`. Creating a separate package (`lockspire_dashboard`) is overkill and creates version-syncing maintenance overhead.

## 3. Protocol Failure Instrumentation
**Decision:** Inject `Observability.emit/2` directly at protocol boundary modules (e.g., `Lockspire.Protocol.ProtectedResourceDPoP` and `Lockspire.Protocol.FAPI20EnforcerPlug`).
**Rationale:**
- **High Signal-to-Noise:** Catching errors exactly where they occur allows telemetry payloads to include rich context (Client ID, User ID, exact failure reason) rather than relying on generic exception handlers at the Plug layer.
- **Security Auditability:** DPoP and FAPI 2.0 failures are security-critical events. Explicit boundary instrumentation guarantees these are captured for the host app's audit logs.

## Next Steps
This strategy finalizes the gray areas for Phase S01. The phase is ready for planning/execution.