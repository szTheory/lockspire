# Lockspire Roadmap

## Shipped Milestones

- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) — shipped 2026-05-26; phases 91-93; 9 plans; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; 9 plans; Lockspire now supports a narrow `client_secret_jwt` direct-client slice on the shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; 9 plans; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; 8 plans; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Next Candidate

- Active on milestone branch: `v1.26 Host Integration & Operator Boundary Hardening`.

## Active Milestone: v1.26 Host Integration & Operator Boundary Hardening

**Goal:** Make the first real Phoenix SaaS adoption path clearer without adding protocol breadth.

- [x] 94: Harden host account/claims and admin-mount scaffolding
- [x] 95: Improve first-client bootstrap guidance and proof
- [x] 96: Lock adopter-facing docs, support truth, and milestone-close evidence

**Non-goals:** no hosted auth, no developer portal, no Sigra compile-time coupling, no new OAuth/OIDC endpoint family, and no Lockspire-owned operator authentication.
