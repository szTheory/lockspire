# Pitfalls Research

**Project:** Lockspire v1.46 Embedded Host Integration Reliability
**Researched:** 2026-10-22
**Confidence:** HIGH for documented lifecycle risks; application-specific behavior needs reproduction.

## Critical Pitfalls

| Pitfall | Prevention | Owner / proof |
|---|---|---|
| A 200 HTML response is treated as connected success | Exercise a connected mount and real client join/rejoin at the host URL | 167 regression; 170 packaged socket/client journey |
| HTTP staff plug is assumed to authorize LiveView navigation | Require host LiveView authorization and separate admin session; test denied socket entry and navigation | 168 |
| Authentication trusts a stale session boolean or conn.assigns | Resolve current staff authority through the host hook; test missing, invalid and no-longer-authorized sessions | 168 |
| Demo-only route duplication hides the public integration defect | One route API consumed by all hosts; enforce complete path/view/action parity | 167 and 169 |
| Correct admin routes are shadowed by the public forward | Inspect every admin route's precedence, not just one sentinel; run public-route separation cases | 167 and 169 |
| A custom mount produces default-prefix links or signed paths | Exercise configured mount normalization, task URLs, redirects, joins and patches together | 167 and 170 |
| Existing host auth code is overwritten during upgrade | Preserve ownership, manifest checks, drift refusal, dry-run and repeat-run behavior | 169 |
| A compile-only compatibility fixture is reported as runtime proof | Execute relevant connected behavior under exact Phoenix 1.8.5 / LiveView 1.1.28 | 170 |
| Static hook presence is described as proof of host policy | Separate structural diagnostics from behavioral host tests; keep errors actionable and secret-safe | 169 |

## Security Boundary and Limits

Phoenix requires authorization on stateful entry as well as HTTP. Reconnect runs mount again. Host logout can use native live_socket_id disconnection, but changing host permissions does not automatically invalidate an already connected view. Define and test the supported boundary explicitly; do not promise continuous permission revocation or per-event resource policy from a mount-only hook. Arbitrary host policy, tenant isolation and fine-grained action permissions remain host responsibilities. Any integration escape discovered while reproducing must be resolved within the agreed admin-access boundary or explicitly raised before expanding scope.

## Looks Done But Isn't

- Route table parity alone does not prove websocket paths, hooks or root-layout/assets integration.
- A locally path-dependent host does not establish that packaged templates include every required file.
- A trusted test connection does not cover unsigned/invalid or later-invalidated host sessions.
- A passing demo with fallback duplicated routes does not cover a fresh generated installation.
- A test on the current root lock does not establish the supported floor.

## Recovery

Keep a red regression for the old forward-only path. Give existing hosts an explicit migration recipe and diagnostics rather than a private-framework patch. Run upgrade preflight before mutations and refuse drift safely. Keep proofs redaction-safe; record synthetic identities and never log session cookies, live tokens, credentials or private key material.

## Sources

- [Phoenix security model](https://hexdocs.pm/phoenix_live_view/security-model.html) — accessed 2026-10-22; served v1.2.13, used for lifecycle/security guidance, not a dependency upgrade recommendation.
- [LiveView 1.1.28 tests](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html) — distinguishes disconnected and connected test mounts.
- Local: .planning/STATE.md Phase 144 deferral; generated/demo routers; Install.Verify; compatibility fixture; CI.
