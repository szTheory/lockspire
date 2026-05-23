# Lockspire + Sigra (same Phoenix host)

**Lockspire** is an embedded **OAuth/OIDC authorization server** for **third-party clients** of your API. **Sigra** is your **end-user authentication** stack (sessions, passwords, MFA, passkeys, “login with Google” via Assent, admin, audit).

This document is the **Lockspire-side** counterpart to Sigra’s recipe **Companion OAuth provider** (`guides/recipes/companion-oauth-provider.md` on hexdocs).

## Boundaries (do not blur)

| Own in Sigra / host | Own in Lockspire |
|---------------------|------------------|
| User table, sessions, MFA, passkeys, login UX | Clients, codes, tokens, consent protocol, JWKS, discovery |
| `sub` identity for **your** users | Authorization decisions for **external** OAuth clients |

Lockspire must **not** import Sigra at compile time. Integration is **host-generated** code: your `AccountResolver` reads the same session Sigra established, typically through `conn.assigns.current_scope.user`.

## Install hint

```bash
mix lockspire.install --sigra-host
```

This adds **Sigra-oriented comments** (and `@moduledoc`) to the generated `AccountResolver` stub. You still implement real `resolve_current_account/2` and claim building.

It does **not** create a second install topology. The canonical path is still `mix lockspire.install`; `--sigra-host` only adjusts guidance for the host-owned seam.

After wiring the generated files, use:

```bash
mix lockspire.verify
```

to confirm router wiring, seam presence, config, and migrations. Later, use `mix lockspire.upgrade` only for Lockspire-managed scaffolding; keep Sigra-facing resolver and UX code host-owned.

## Recommended sequencing

1. Ship **Sigra** end-user auth first (register, login, orgs if needed).
2. Add Lockspire; complete **Phase 3** (OIDC + token lifecycle) before exposing third-party integrations broadly.
3. Point `login_path` at your real Sigra login route; preserve `return_to` / `interaction_id` query params Lockspire needs, then resume the browser through the generated Lockspire interaction route after sign-in.

## Host seam contract

For a Sigra-backed host, keep the seam narrow:

- Read the signed-in user from `conn.assigns.current_scope.user`.
- Build `sub` from a stable internal identifier, not email.
- Keep the canonical example claim set narrow; richer profile or org claims remain host-owned decisions.
- Preserve both `return_to` and `interaction_id` through your login bounce so Lockspire can resume the pending interaction safely.

The repo-owned proof for that shape lives in `test/integration/phase6_onboarding_e2e_test.exs`, which exercises unauthenticated `/authorize` -> host login -> interaction resume -> consent -> token exchange through generated-host code.

If the same Sigra-backed host also exposes Phoenix API routes, use the Lockspire plug pipeline documented in [`docs/protect-phoenix-api-routes.md`](protect-phoenix-api-routes.md). Sigra still owns the signed-in browser session; Lockspire verifies the API token; your host app still owns post-token business authorization.

## Planning

Cross-repo sequencing lives in Lockspire **`.planning/ECOSYSTEM-SIGRA.md`**.
