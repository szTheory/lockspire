# Architecture Research

**Project:** Lockspire v1.46 Embedded Host Integration Reliability
**Researched:** 2026-10-22
**Confidence:** MEDIUM for API design, HIGH for native routing constraints.

## Recommended Architecture

A library-owned route definition expands into the host router, inside an explicit admin live_session. The host supplies its browser/staff pipeline, session interpretation and LiveView authorization hook. Public protocol forwarding and host consent routes stay separate. The library supplies admin functionality, not staff identity or permission policy.

A macro is a recommended implementation direction, not a finalized public signature. Phase 167 must reproduce the old connection failure, test the supported-floor macro expansion, and settle option ownership, hook composition, session naming, path normalization and compatibility before implementation plans freeze them.

## Boundaries and Data Flow

1. HTTP: host endpoint/session → host browser/staff plugs → host-expanded route → host authorization hook → admin LiveView.
2. Connect/reconnect: signed host session → host authorization hook → admin mount; never assume conn.assigns exist on the connected socket.
3. Navigation: admin session boundary and host hooks protect entry; in-session patches retain the agreed host policy. Public/consent sessions cannot reuse admin authorization accidentally.
4. Upgrade: manifest/ownership preflight → managed helper changes → explicit host-owned hook instructions → compile and runtime proof.

## New versus Modified Components

| Area | Proposed change |
|---|---|
| lib/lockspire/web/admin_router.ex or adjacent route API | Central reusable declarations; preserve or explicitly migrate existing module surface |
| priv/templates/lockspire.install/router.ex | Consume route API in host router with required connected authorization wiring |
| Host-owned auth hook template/instructions | Fail closed until the host supplies real staff policy; never assume a user table or boolean session flag is authoritative |
| lib/lockspire/install/verify.ex | Inspect direct route inventory, actions, ordering and session/hook metadata; describe structural evidence honestly |
| Demo, generated host, clean-room provider | Use the same canonical integration instead of hand-copied admin lists |
| Existing tests, scripts and CI | Add lifecycle, version and packaged installation proof |

## Important Tradeoffs

- A required host hook is explicit and testable but needs migration guidance. Missing configuration must not silently expose connected admin views.
- Keeping the old module may preserve compilation for existing code; that does not make forward-only LiveView mounting supported or healthy. Choose compatibility behavior with executable evidence.
- Most current navigation uses ordinary hrefs. Preserve those URLs; test LiveView patch/navigation where used or supported without converting the visual/navigation design wholesale.
- A static verifier can inspect wiring but cannot prove arbitrary host authorization semantics. Generated request/socket tests and clean-room denial scenarios provide the behavioral evidence.
- Mount identity should use native session primitives. Do not interpolate secrets or user-controlled atoms into route/session declarations.

## Build Order

167 route/session contract and route parity; 168 host authorization seam and denial; 169 generated install/upgrade, diagnostics and consumer convergence; 170 packaged host, supported-floor runtime and CI proof. Every phase includes focused regression owners.

## Sources

- [LiveView router](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3) — native session/routing composition.
- [LiveView hooks](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.html#on_mount/1) — host lifecycle integration.
- Local: AdminRouter; generated router template; Install.Verify; Install.OperationPlan; Install.Manifest; Mix.Tasks.Lockspire.Upgrade; admin layout and overview path helpers.
