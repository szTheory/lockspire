# Lockspire Roadmap

## Shipped Milestones

- [v1.26 Host Integration & Operator Boundary Hardening](milestones/v1.26-ROADMAP.md) — shipped 2026-05-27; phases 94-96; 3 plans; generated host scaffolding now shows a host-guarded admin-only mount, account/claims integration stays narrow and host-owned, first-client bootstrap guidance is clearer, and adopter docs now include a compact SaaS adoption recipe without adding protocol breadth.
- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) — shipped 2026-05-26; phases 91-93; 9 plans; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; 9 plans; Lockspire now supports a narrow `client_secret_jwt` direct-client slice on the shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; 9 plans; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; 8 plans; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Next Candidate

- None by default. Lockspire is back on the sustaining GA release train after the adoption demo smoke shipped in PR `#44`.
- If a feature-sized milestone is justified, the highest-leverage candidate is the Phoenix resource-server/token acceptance story: make it obvious which Lockspire-issued token shape a host Phoenix API should accept, how that relates to `Lockspire.Plug.VerifyToken`, and what CI proof backs the blessed path.
