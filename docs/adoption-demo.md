# Adoption demo

Lockspire includes a small Phoenix host app at `examples/adoption_demo`.

The demo is not a new product surface or Hex package content. It is a repo-local adopter proof that boots a representative SaaS host, mounts Lockspire, seeds realistic OAuth clients, and exercises the library over HTTP.

## What it proves

- OIDC discovery and JWKS publish from a mounted embedded Lockspire provider.
- Host-owned login, account resolution, claims, and consent handoff for authorization code + PKCE.
- Host-guarded operator access to the Lockspire admin router.
- Device authorization approval through a host-owned `/verify` page.
- Issued-token behavior through Lockspire `userinfo`, plus protected-route rejection for an anonymous host API request.

The canonical support contract still lives in `docs/supported-surface.md`; the demo is an executable confidence check for adoption DX.

## Run it locally

From the repo root:

```sh
cd examples/adoption_demo
mix deps.get
mix ecto.setup
mix phx.server
```

Then open `http://127.0.0.1:4100`.

Seeded demo accounts:

| Login | Role | Account |
| --- | --- | --- |
| `alice` | SaaS user | `alice@acme.test` |
| `bob` | SaaS user | `bob@globex.test` |
| `ops` | Operator | `ops@acme.test` |

Seeded OAuth clients:

| Client ID | Shape |
| --- | --- |
| `acme-ledger-public` | Authorization code + PKCE public client |
| `acme-tv-device` | Device authorization client |
| `acme-ledger-backend` | Confidential backend client with `client_secret_basic` |

## Run the black-box smoke

Start the demo server, then run:

```sh
python3 scripts/demo/adoption_smoke.py
```

The script waits for the server, drives browser-like cookies through login and consent, exchanges real tokens, approves a device-code request, and calls the protected demo API. CI runs the same smoke in the `Adoption Demo Smoke` job.
