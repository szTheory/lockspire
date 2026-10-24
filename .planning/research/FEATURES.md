# Feature Research

**Project:** Lockspire v1.46 Embedded Host Integration Reliability
**Researched:** 2026-10-22
**Confidence:** HIGH for scope and recorded gaps; no fresh runtime reproduction claimed.

## Feature Landscape

| Required capability | Adopter outcome | Complexity |
|---|---|---|
| One host-expanded admin route integration | Install without copying Lockspire's route inventory | Medium |
| Existing route/action and mount-path parity | Existing bookmarks, links and task URLs keep working | Medium |
| HTTP and connected host authorization | Staff policy protects both request and socket entry | High |
| Admin live-session boundary | Public/consent navigation cannot enter admin without its checks | Medium |
| Supported install and safe upgrade | Generated integrations converge without overwriting host policy | High |
| Honest installation diagnostics | Forward-only or incomplete mounts are not reported healthy | Medium |
| Packaged and minimum-version runtime proof | Integration claims match what a host actually installs | Medium |

## Existing Evidence and Gaps

- The generated router template still forwards the admin router behind :require_operator.
- The adoption demo defines the same admin LiveViews directly and retains the forward, explicitly to get host-path signing. Its runtime contract checks route parity, not a forward-only connected host.
- Install.Verify currently recognizes the forward as the required healthy shape. This must evolve with the canonical integration.
- Sampled admin mount callbacks do not resolve host staff sessions themselves. This is consistent with host ownership but makes an explicit connected authorization seam necessary.
- The public Web.Router is separate from AdminRouter; preserve that distinction rather than applying staff auth to OAuth/OIDC requests.

These are source observations and archived reports, not a newly demonstrated exploit or a fresh passing regression.

## Dependencies and Priorities

P1: route/session API and parity → host authorization integration → install/upgrade and diagnostics → packaged/versioned runtime proof. Each phase adds focused tests; final proof integrates them rather than deferring all tests to the last phase.

P2 only if required for P1: minimal shared mount-path normalization, host root-layout/session instructions and targeted diagnostic copy.

## Anti-Features and Deferrals

Do not add staff accounts, RBAC/tenant policy, a login system, per-resource ACLs, continuous authorization polling, a distributed logout coordinator, visual redesign, KMS/Vault, client-secret-JWT encryption changes or broad CI migration. Host logout/disconnect guidance may use native Phoenix mechanisms; it is not a new library-owned identity service.

Already implemented/obsolete seeds SEED-001..003 do not add scope. No pending todo files exist. The recorded Phase 144 mount gap is the direct historical input; unrelated verification and release exceptions stay disclosed.

## Success Definition

A newly installed and safely upgraded host can use all existing admin routes at supported mounts with real connected behavior, host-owned denial and navigation boundaries, while public protocol routes remain independently available. Deterministic tests and CI own acceptance; no visual signoff is needed.

## Sources

- Local: priv/templates/lockspire.install/router.ex; lib/lockspire/web/admin_router.ex; examples/adoption_demo/lib/adoption_demo_web/router.ex; test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs; lib/lockspire/install/verify.ex; .planning/STATE.md.
- [Phoenix router 1.8.5](https://hexdocs.pm/phoenix/1.8.5/Phoenix.Router.html) — compile-time route generation and ordering.
