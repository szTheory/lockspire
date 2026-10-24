# Stack Research

**Project:** Lockspire v1.46 Embedded Host Integration Reliability
**Researched:** 2026-10-22
**Confidence:** HIGH for framework constraints; MEDIUM for the exact integration API pending Phase 167 reproduction.

## Recommendation

Use the existing Phoenix/LiveView stack. Add no authentication framework, service or runtime dependency. Route declarations must expand inside the host router; staff identity, session resolution and access decisions remain host-owned. This is an integration repair, not a visual milestone.

## Recommended Stack

| Technology | Supported baseline / observed lock | Purpose |
|---|---|---|
| Phoenix | Floor 1.8.5; root lock 1.8.13 | Host routes, plugs, route metadata and scopes |
| Phoenix LiveView | Floor 1.1.28; root lock 1.2.10; declared >=1.1.28 and <2.0.0 | Host-expanded live routes, live_session and host on_mount hooks |
| Elixir / OTP | Existing CI current and minimum lanes | Preserve current support contract; no version bump needed |
| Phoenix.LiveViewTest / ExUnit | Already available | Connected lifecycle, denial and navigation regressions |
| Existing clean-room and demo harnesses | Repository-owned; host-only Bandit | Packaged host and real client/socket proof |

The observed lock is not a claim about the latest release. The exact compatibility fixture pins Phoenix 1.8.5 and LiveView 1.1.28 but currently compiles only; v1.46 needs runtime integration coverage there too.

## Framework Constraints

LiveView 1.1.28 documents that live_session does not support forward and expects live routes in the host router. Its route options provide host on_mount, session and root-layout seams. Hook callbacks execute before disconnected and connected mounts. These constraints also appear in the installed 1.2.10 router source.

## Alternatives Considered

| Option | Assessment |
|---|---|
| Library route macro expanding in host router | Recommended direction: reuse the existing generated macro approach, centralize admin declarations and preserve native metadata |
| Host manually duplicates every admin live route | Works around path signing but makes drift an adopter responsibility; the demo already illustrates this cost |
| Patch forwarded joins or private Phoenix socket internals | Reject: fights a documented framework constraint and adds version sensitivity |
| New staff auth framework or hosted admin service | Outside the embedded-library boundary |

## Installation and Compatibility

No dependency installation is proposed. Keep host endpoint/session/assets wiring explicit and preserve existing application/root-layout choices. Test the root-lock pair and exact supported floor without unlocking dependencies. This milestone does not add reverse-proxy script_name support, multiple concurrent mounts or tenant routers unless the current supported contract already requires them.

## Sources

- [LiveView 1.1.28 router](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3) — forwarding restriction and session options.
- [LiveView 1.1.28 callbacks](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.html#on_mount/1) — lifecycle hook contract.
- Local: mix.exs, mix.lock, compatibility/phoenix_1_8_live_view_1_1/mix.exs, deps/phoenix_live_view/lib/phoenix_live_view/router.ex, .github/workflows/ci.yml.
