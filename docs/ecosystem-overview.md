# Where Lockspire Fits — The Auth Stack at a Glance

If you're evaluating or adopting Lockspire, you're solving one specific problem: **letting other software call your API on behalf of your users.** That's a different job from "let users log in to my app." This page explains where Lockspire sits in a full Phoenix auth stack, what fits next to it, and how the pieces compose.

> **TL;DR.** Lockspire is the *outbound* half of an auth stack — your users prove who they are *to your app* via a separate library (Sigra is the recommended pairing, or `phx.gen.auth`), and then Lockspire mints OAuth/OIDC tokens that let *external apps* trust that identity. SAML logins from your customers' corporate IdPs are a third concern handled by Relyra. All three compose through small, host-owned glue modules.

## The two directions of authentication

Auth stacks have two directions and they need different tools:

| Direction | Job | Library |
|-----------|-----|---------|
| **Inbound — local** | Your users sign up and log in to *your* app (passwords, magic links, MFA, passkeys, "Log in with Google") | **Sigra** (or `phx.gen.auth`) |
| **Inbound — federated** | Your *enterprise customers'* employees log in via *their* corporate SSO | **Relyra** (SAML SP, WIP) |
| **Outbound** | *Other apps* ask your users for permission to call your API on their behalf | **Lockspire** ← you are here |

Lockspire deliberately does not own users, sessions, MFA, login UI, or any local-auth concern. It assumes another library has already established a session for the current user and reads that session through a small host-defined seam (`Lockspire.Host.AccountResolver`). This is what lets Lockspire focus exclusively on protocol correctness — PAR, JAR, DPoP, FAPI 2.0, token exchange, CIBA — without growing into a kitchen-sink CIAM product.

## Do you actually need Lockspire?

A common mistake is reaching for an OAuth/OIDC server when all you really need is "log in with Google" for *your* product's users. That's covered by Sigra alone (or any decent inbound auth library). Lockspire is for the *other* OAuth role — being an authorization *server* that other apps integrate against.

| Need | Solution |
|------|----------|
| "Let users log in with Google/GitHub/Apple" | Sigra's built-in OAuth-consumer support (uses Assent under the hood). **No Lockspire needed.** |
| "Let *external developers* build apps that call my API on behalf of users" | **Lockspire.** This is what it's for. |
| "Let my enterprise customers' employees SSO in via their corporate IdP" | Relyra (SAML SP) |
| "Replace my entire login UI with a managed identity provider" | Out of scope for this stack — evaluate dedicated CIAM products |

If you don't have third-party developers building against your API, you probably don't need Lockspire yet. Add it the day a real integrator pulls it.

## How a Lockspire-equipped stack wires together

```text
                                     ┌──────────────────────────────────────────┐
                                     │       Phoenix host application           │
  Browser (your users) ──────────────►  Sigra plugs / LiveView / context        │
                                     │      └─► creates Sigra session           │
                                     │                                          │
  SAML IdP (Okta, Entra) ────────────►  Relyra ACS endpoint                     │
                                     │      └─► host glue: find-or-create user  │
                                     │           └─► creates Sigra session      │
                                     │                                          │
  Third-party OAuth client ──────────►  Lockspire /authorize, /token, /userinfo │
                                     │      └─► AccountResolver reads           │
                                     │           Sigra's current_scope          │
                                     │           and builds claims              │
                                     └──────────────────────────────────────────┘
```

The key insight: **the inbound session is the single source of truth for "who is logged in."** Lockspire reads from it; Relyra writes to it; Sigra owns it. From Lockspire's point of view, it does not matter whether the user got there via password, passkey, social login, or SAML — only that there's an authenticated session it can issue tokens against.

## The integration seam

Lockspire defines one behaviour, `Lockspire.Host.AccountResolver`, with six callbacks: "who is logged in now," "look up an account by reference" (used during introspection and refresh), "redirect to login," "build claims," "redirect to logout," and (for CIBA flows) "verify a backchannel user code."

The host writes a small glue module that satisfies this behaviour. For a Sigra-backed host the implementation is roughly 80 lines and mostly involves reading `conn.assigns.current_scope` and mapping the user's data into ID-token / userinfo claim sets.

Generate a Sigra-aware stub:

```bash
mix lockspire.install --sigra-host
```

The generator emits a commented-up `AccountResolver` module into your host app. You fill in the parts that depend on your data model — which fields go into `id_token` vs `userinfo`, how org membership and roles map to claims, what `sub` looks like.

For practical wiring details, see the dedicated companion guide: **[Lockspire + Sigra](sigra-companion-host.html)**.

A typical implementation looks like:

```elixir
defmodule MyApp.Lockspire.HostImpl do
  @behaviour Lockspire.Host.AccountResolver

  def resolve_current_account(conn, _ctx) do
    case conn.assigns[:current_scope] do
      %{user: user} -> {:ok, user}
      _ -> {:redirect, %Lockspire.Host.InteractionResult{login_path: "/users/log-in"}}
    end
  end

  def build_claims(user, ctx) do
    {:ok,
     %Lockspire.Host.Claims{
       subject: to_string(user.id),
       id_token: %{"email" => user.email, "email_verified" => !!user.confirmed_at},
       userinfo: %{
         "email" => user.email,
         "name" => user.name,
         "org_ids" => MyApp.Accounts.org_ids_for(user),
         "roles" => MyApp.Accounts.roles_for(user, ctx.scopes)
       }
     }}
  end

  # ... redirect_for_login/2, redirect_for_logout/2, verify_backchannel_user_code/3
end
```

### Why the generator lives on Lockspire's side

Lockspire owns the `AccountResolver` contract, so it owns the codegen for satisfying it. Sigra exposes a stable `current_scope` shape; Lockspire knows how to consume it. This:

- Keeps Sigra free of any "every possible companion" knowledge
- Lets Lockspire's docs be the one-stop reference for adopters ("how do I integrate?")
- Mirrors `phx.gen.auth`'s "generator emits into the host app" pattern, which is the convention people will recognize
- Avoids creating a third bridge package

The host module the generator emits is not a runtime dependency on Sigra — it's host-owned code that happens to read assigns Sigra populates. There is **no mandatory Hex edge** between Sigra and Lockspire.

## Coexistence with Relyra

Relyra is a SAML Service Provider library — it terminates SAML at an ACS endpoint, validates assertions strictly, and hands you verified attributes. Lockspire and Relyra never talk to each other directly. They both talk to the inbound session layer (Sigra).

A user authenticated via SAML and a user authenticated via password are **indistinguishable to Lockspire**. Both have a Sigra session; Lockspire reads it through `AccountResolver` and builds claims the same way. The third-party OAuth client receives a token whose `sub` is the stable Sigra user id, regardless of how that user originally got in.

Relyra is currently early in development and will publish its own integration generator (likely `mix relyra.install --sigra-host`) when it ships. Until then, refer to its repo for current scope.

## Recommended adoption order

1. **Sigra first.** Get end-user auth working. Login, register, MFA if needed, optional orgs/RBAC. This is the foundation; Lockspire authorizes *after* the host can prove who the user is.
2. **Lockspire second**, when you have a concrete need to expose your API to external apps. Run `mix lockspire.install --sigra-host`, complete the AccountResolver, exercise the OIDC + token-lifecycle surface end to end (`docs/getting-started.md`), then expose third-party integrations broadly.
3. **Relyra third**, when an enterprise customer asks for SAML SSO. The Relyra → Sigra session glue is a separate, small piece; Lockspire integration does not change.

You almost never adopt all three at once.

## Subject identity and claim hygiene

A few rules that matter regardless of which inbound library you pair Lockspire with:

- **`sub`** (subject) should be a stable internal identifier — Sigra's user primary key as a string is the typical choice. Never use email; users change emails.
- **Claims** should reflect the same authorization context your app already trusts (org membership, roles), not ad-hoc lookups.
- **No mandatory Hex dependency** between Lockspire and your inbound auth library. Integration is host-generated code that reads assigns.
- **Login redirects** (`redirect_for_login`) should point at your real Sigra login route and preserve `return_to` and `interaction_id` query params Lockspire needs to resume the OAuth interaction.

## Decision summary

```text
Building a Phoenix SaaS auth stack?
  │
  ├─► Need users to log in?
  │     └─► Sigra (or phx.gen.auth as a starting point). Always. Start here.
  │
  ├─► Need third-party apps to integrate with your API?
  │     └─► Add Lockspire. mix lockspire.install --sigra-host.
  │
  └─► Need enterprise SSO for customers?
        └─► Add Relyra. Wire its ACS to create-or-find a Sigra user.
```

Each library has tight non-goals. Sigra never owns OAuth issuance. Lockspire never owns user tables. Relyra never owns sessions. The clean separation is what makes the stack composable.

## See also

- **[Lockspire + Sigra companion host](sigra-companion-host.html)** — practical Lockspire↔Sigra wiring details
- **[Getting started](getting-started.html)** — Lockspire setup walkthrough
- **[Install and onboard](install-and-onboard.html)** — `mix lockspire.install` reference
- **[Supported surface](supported-surface.html)** — exactly which RFCs and OIDC specs Lockspire implements (and which it doesn't)
- Sigra's hexdocs ecosystem overview — the mirror of this page from Sigra's perspective
