# Ecosystem: Sigra companion host

**Purpose:** Coordinate **parallel** delivery of Sigra (end-user auth) and Lockspire (embedded OAuth/OIDC provider) without merging repositories or mandatory Hex coupling.

## Sequencing (authoritative for v1)

1. **Lockspire Phase 3** — OIDC discovery, JWKS, ID token / userinfo, refresh rotation, revocation, introspection (`REQUIREMENTS.md`: OIDC-*, TOKN-*). Third-party clients need this surface to trust the provider.
2. **Lockspire Phase 5** — Security and observability hardening (`SECU-*`).
3. **Lockspire Phase 6** — Install DX and release readiness (`RELS-*`). Canonical onboarding is where a **Sigra-first** tutorial belongs.
4. **Cross-repo artifacts** — Joint example app or CI matrix **after** Phase 6 credibility; optional `sigra_lockspire` glue package **deferred** (see Sigra `.planning/decisions/001-defer-sigra-lockspire-glue-package.md`).

## Integration surface (stable contract)

- **Host seam:** `Lockspire.Host.AccountResolver` (see Phase 1 context).
- **Generator:** `mix lockspire.install --sigra-host` for commented stubs pointing at Sigra docs.
- **Docs:** `docs/sigra-companion-host.md` (this repo) ↔ Sigra `guides/recipes/companion-oauth-provider.md`.

## Out of scope here

- SAML / enterprise IdP breadth (both projects defer).
- Making Sigra depend on Lockspire or vice versa in **core** `mix.exs`.
