# API Coverage — Lockspire embedded OAuth/OIDC surface (as consumed by `mix adopter.walk`)

> Full coverage by default. Opt-outs are explicit, reasoned decisions.

**Scope note.** Phase 126 integrates no *third-party* API or SDK. The detector fired on the phrase
"token-consuming endpoint", which refers to Lockspire's **own** embedded protocol surface mounted
inside the generated host app (`lib/lockspire/web/router.ex`), plus the host-facing Mix task surface
the documented adopter path invokes. That surface is nonetheless a real capability surface with real
opt-outs, so the matrix is authored against it rather than declared inapplicable — the walk's value
is precisely that its coverage gaps are decided rather than accidental.

The capability list is derived from `lib/lockspire/web/router.ex` (read in-session) and
`docs/install-and-onboard.md` §§1-8.

## HTTP protocol surface

| capability | decision | reason |
|---|---|---|
| discovery — `GET <mount>/.well-known/openid-configuration` | INTEGRATE | |
| jwks — `GET <mount>/jwks` | INTEGRATE | |
| authorize — `GET <mount>/authorize` | INTEGRATE | |
| interaction resume — `GET <mount>/interactions/:interaction_id` | INTEGRATE | |
| interaction complete — `POST <mount>/interactions/:interaction_id/complete` | INTEGRATE | |
| consent LiveView — `GET <mount>/consent/:interaction_id` | INTEGRATE | |
| token, `authorization_code` + PKCE — `POST <mount>/token` | INTEGRATE | |
| userinfo — `GET <mount>/userinfo` | INTEGRATE | |
| protected host route (`docs/protect-phoenix-api-routes.md` pipeline) | INTEGRATE | |
| token, `refresh_token` grant | OPT-OUT | not needed — ADOPT-04 requires one *usable* access token; refresh rotation is already proven by `mix ci`'s protocol suites and adds no adopter-path signal |
| token, `device_code` grant | OPT-OUT | explicitly out of milestone — FUTURE-01 (device flow) |
| device authorization — `POST <mount>/device/code` | OPT-OUT | explicitly out of milestone — FUTURE-01; guide §8's host `/verify` seam is recorded in the ledger as "checked, not walked" |
| CIBA — `POST <mount>/bc-authorize` | OPT-OUT | explicitly out of milestone — FUTURE-01 |
| PAR — `POST <mount>/par` | OPT-OUT | not needed yet — not part of guide §6's proof bar for a first install |
| dynamic client registration — `POST/GET/PUT/DELETE <mount>/register` | OPT-OUT | not needed — guide §6 registers the first client via `mix lockspire.client.create`; DCR is out of milestone |
| introspection — `POST <mount>/introspect` | OPT-OUT | explicitly out of scope per D-31 — needs a confidential client and only proves the AS validated its own token, not that a resource server accepted it |
| revocation — `POST <mount>/revoke` | OPT-OUT | not needed yet — no revocation step exists on the documented adopter path §§1-6 |
| RP-initiated logout — `GET/POST <mount>/end_session`, `GET <mount>/end_session/complete` | OPT-OUT | not needed yet — guide §6 presents logout propagation conditionally ("if you configure RP logout"); recorded in the ledger as "checked, not walked" |
| admin mount — `Lockspire.Web.AdminRouter` at `<mount>/admin` | OPT-OUT | explicitly out of scope — v1.36 forbids admin/operator UI work |
| sender-constrained tokens (DPoP / mTLS) | OPT-OUT | not needed yet — the walk registers a public bearer client; `EnforceSenderConstraints` still runs in the protected pipeline, and its `dpop_replay_store` is `required: false` |
| `private_key_jwt` / `client_secret_jwt` direct client auth | OPT-OUT | not needed — the walk's client uses `token_endpoint_auth_method: "none"`; guide §6 presents both as optional modes |
| RAR consent copy (`authorization_details`) | OPT-OUT | not needed — guide §3 presents it conditionally ("if you need custom RAR consent copy") |

## Host-facing Mix task surface (the documented adopter path)

| capability | decision | reason |
|---|---|---|
| `mix lockspire.install` (guide §2) | INTEGRATE | |
| `mix ecto.migrate` as the guide documents it (guide §4) | INTEGRATE | |
| `mix lockspire.verify` (guide §5) | INTEGRATE | |
| `mix lockspire.client.create` (guide §6) | INTEGRATE | |
| `mix lockspire.install --storage-prefix public --oban-prefix public` | OPT-OUT | not needed — the walk keeps the generated default so any prefix/schema failure becomes real ledger evidence rather than being configured away (RESEARCH Open Question 4) |
| `mix lockspire.upgrade` (guide §7) | OPT-OUT | not needed — §7 is an upgrade path, not a first-install path; recorded in the ledger as "checked, not walked" |
| `mix lockspire.doctor remote-jwks` | OPT-OUT | not needed — diagnoses remote `jwks_uri` incidents, which the walk's public client never creates |
