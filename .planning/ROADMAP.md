# Lockspire Roadmap

## Current Milestone

No active feature milestone. Lockspire is back on the sustaining GA release train until concrete adopter, support, or release evidence justifies another scoped milestone.

Start the next milestone with `/gsd-new-milestone`.

## Shipped Milestones

- [v1.32 Admin Page IA & Interaction Model Polish](milestones/v1.32-ROADMAP.md) - shipped 2026-06-30; phases 121-125; route scorecards, Support and Operate flow polish, Configure propagation, redaction-safe fixtures, browser/manual evidence, deterministic guardrails, bounded operator docs, and adversarial proof now make the admin/operator UI more deliberately composed without protocol, storage, host-seam, public lab, theming, browser-tooling, or support-surface creep.
- [v1.31 Admin Design-System Stress Test](milestones/v1.31-ROADMAP.md) - shipped 2026-06-26; phases 116-120; route/component/lab inventory, redaction-safe fixtures, shared admin primitives, weak-page IA/copy polish, source-derived browser proof, deterministic guardrails, bounded operator docs, and final adversarial signoff now strengthen the admin/operator design system without protocol, storage, host-seam, public lab, theming, or browser-tooling creep.
- [v1.30 Adoption Demo Docker DX & Repo Hygiene](milestones/v1.30-ROADMAP.md) - shipped 2026-06-24; phases 111-115; the repo-local adoption demo now has one public URL contract, a direct Docker app+PostgreSQL path, conflict-resistant project/port controls, optional Traefik routing, redacted startup/reprint output, wrapper-driven smoke proof, scoped stop/reset/cleanup helpers, Docker-free CI hygiene, and no broadened protocol or hosted-auth surface.
- [v1.29 Admin UI Journey & Design-System Deep Polish](milestones/v1.29-ROADMAP.md) - shipped 2026-06-04; phases 107-110; route-by-route admin journeys, shared BEM/design-token primitives, weak-spot support/operations/configuration polish, demo seed truth, docs, screenshots, contract tests, and 390px mobile no-page-overflow proof now align across the admin operator surface.
- [v1.28 Admin UI Operator Experience Polish](milestones/v1.28-ROADMAP.md) - shipped 2026-06-03; phases 103-106; admin UI operator journeys, shared BEM/design-token primitives, client/support/operations/security/DCR/key workflow polish, demo seed truth, operator docs, screenshots, and design-system contract tests now align as one coherent operator product.
- [v1.27 Phoenix Resource Server Token Acceptance](milestones/v1.27-ROADMAP.md) - shipped 2026-06-03; phases 97-102; `Lockspire.Plug.VerifyToken` narrowed to RFC 9068 `at+jwt`, default access-token issuance flipped to `:jwt`, sender-constraint proof delivered, adoption-demo re-wired, and generated-host scaffolding updated.
- [v1.26 Host Integration & Operator Boundary Hardening](milestones/v1.26-ROADMAP.md) - shipped 2026-05-27; phases 94-96; generated host scaffolding now shows a host-guarded admin-only mount, account/claims integration stays narrow and host-owned, first-client bootstrap guidance is clearer, and adopter docs include a compact SaaS adoption recipe without adding protocol breadth.
- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) - shipped 2026-05-26; phases 91-93; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) - shipped 2026-05-25; phases 88-90; Lockspire supports a narrow `client_secret_jwt` direct-client slice on shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) - shipped 2026-05-24; phases 85-87; self-service clients can create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) - shipped 2026-05-24; phases 82-84; automatic `DPoP-Nonce` challenge and retry support covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Archives

Full shipped milestone details live in `.planning/milestones/`.
