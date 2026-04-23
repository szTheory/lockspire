# Lockspire + Sigra (same Phoenix host)

**Lockspire** is an embedded **OAuth/OIDC authorization server** for **third-party clients** of your API. **Sigra** is your **end-user authentication** stack (sessions, passwords, MFA, passkeys, “login with Google” via Assent, admin, audit).

This document is the **Lockspire-side** counterpart to Sigra’s recipe **Companion OAuth provider** (`guides/recipes/companion-oauth-provider.md` on hexdocs).

## Boundaries (do not blur)

| Own in Sigra / host | Own in Lockspire |
|---------------------|------------------|
| User table, sessions, MFA, passkeys, login UX | Clients, codes, tokens, consent protocol, JWKS, discovery |
| `sub` identity for **your** users | Authorization decisions for **external** OAuth clients |

Lockspire must **not** import Sigra at compile time. Integration is **host-generated** code: your `AccountResolver` reads the same session Sigra established.

## Install hint

```bash
mix lockspire.install --sigra-host
```

This adds **Sigra-oriented comments** (and `@moduledoc`) to the generated `AccountResolver` stub. You still implement real `resolve_current_account/2` and claim building.

## Recommended sequencing

1. Ship **Sigra** end-user auth first (register, login, orgs if needed).
2. Add Lockspire; complete **Phase 3** (OIDC + token lifecycle) before exposing third-party integrations broadly.
3. Point `login_path` at your real Sigra login route; preserve `return_to` / `interaction_id` query params Lockspire needs.

## Planning

Cross-repo sequencing lives in Lockspire **`.planning/ECOSYSTEM-SIGRA.md`**.
