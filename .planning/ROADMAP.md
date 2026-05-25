# Lockspire Roadmap

## Active Milestone

No active milestone. `v1.24 client_secret_jwt` shipped on 2026-05-25.

Start the next milestone with `$gsd-new-milestone`.

## Shipped Milestones

- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; 9 plans; Lockspire now supports a narrow `client_secret_jwt` direct-client slice on the shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; 9 plans; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; 8 plans; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Next Candidate

- Support-burden reduction — improve advanced setup diagnostics and support-truth for `jwks_uri` rotation, mTLS, logout propagation, and protected-route setup if that becomes the next real friction point after `v1.24`.
