# Phase 80: Sender-Constraining Integration (DPoP & MTLS) - Pattern Map

## Target Files -> Closest Analogs

| Target file | Role | Closest analogs | Why |
|-------------|------|-----------------|-----|
| `lib/lockspire/plug/enforce_sender_constraints.ex` | New soft enforcement plug | `lib/lockspire/plug/verify_token.ex`, `lib/lockspire/protocol/fapi20_enforcer_plug.ex`, `lib/lockspire/mtls/plug.ex` | Same Plug lifecycle, soft-vs-strict split, and request rejection patterns. |
| `lib/lockspire/plug/verify_token.ex` | Authorization header parsing and token assignment | existing file, `lib/lockspire/protocol/userinfo.ex` | Needs to accept `Bearer` and `DPoP` schemes and normalize `cnf` into `%AccessToken{}`. |
| `lib/lockspire/plug/require_token.ex` | Challenge rendering and halt behavior | existing file, `test/lockspire/web/userinfo_controller_test.exs` challenge assertions | Must map sender-constraint failures into DPoP-aware `WWW-Authenticate` responses. |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | Generic DPoP validation | existing file, `lib/lockspire/protocol/token_endpoint_dpop.ex` | Already validates proof structure, `ath`, `jkt`, and replay; needs generalization for arbitrary request URIs. |
| `lib/lockspire/protocol/mtls_token_binding.ex` | Shared MTLS thumbprint helper | `lib/lockspire/protocol/userinfo.ex`, `lib/lockspire/protocol/token_endpoint_dpop.ex` | Both already implement the same `x5t#S256` hashing/match logic. |
| `test/lockspire/plug/enforce_sender_constraints_test.exs` | New plug tests | `test/lockspire/protocol/protected_resource_dpop_test.exs`, `test/lockspire/web/userinfo_controller_test.exs`, `test/lockspire/mtls/plug_test.exs` | Best examples of DPoP failure matrix, MTLS extraction semantics, and Plug assertions. |

## Concrete Reuse Notes

### `lib/lockspire/protocol/protected_resource_dpop.ex`

Reuse:

- `validate_proof/2`
- `validate_ath/2`
- `validate_token_binding/2`
- replay key construction and expiration calculations

Likely change:

- replace the hard-coded `userinfo_endpoint_uri/0` path with a request-supplied `target_uri`
- rename or wrap `validate_userinfo_access/2` so it can serve plugs and userinfo alike

### `lib/lockspire/protocol/userinfo.ex`

Reuse:

- DPoP-vs-Bearer authorization logic
- DPoP-aware invalid-token semantics
- MTLS `x5t#S256` enforcement

Likely extraction:

- move shared MTLS thumbprint comparison into a reusable protocol helper

### `lib/lockspire/protocol/token_endpoint_dpop.ex`

Reuse:

- `maybe_add_x5t_cnf/2`
- refresh-path MTLS binding validation

Likely reuse value:

- keeps `x5t#S256` hashing logic identical across issuance and protected-resource consumption

## Code Excerpts To Mirror

### DPoP proof validation entrypoint

From `lib/lockspire/protocol/protected_resource_dpop.ex`:

```elixir
case DPoP.validate_proof(
       proof,
       method: request_method(request),
       target_uri: userinfo_endpoint_uri(),
       now: now(request),
       max_age: Keyword.get(request_options(request), :dpop_max_age, 300),
       clock_skew: Keyword.get(request_options(request), :dpop_clock_skew, 30),
       security_profile: security_profile
     ) do
```

Pattern to preserve:

- explicit `method`, `target_uri`, `now`, `max_age`, `clock_skew`
- no implicit global request state

### DPoP binding check

From `lib/lockspire/protocol/protected_resource_dpop.ex`:

```elixir
defp validate_token_binding(%Token{cnf: %{"jkt" => expected_jkt}}, %DPoP{jkt: actual_jkt})
```

Pattern to preserve:

- compare normalized `jkt`
- return typed invalid-token reasons for downstream mapping

### MTLS thumbprint comparison

From `lib/lockspire/protocol/userinfo.ex`:

```elixir
actual_thumbprint = :crypto.hash(:sha256, cert) |> Base.url_encode64(padding: false)
```

Pattern to preserve:

- compute thumbprints from raw DER bytes
- treat missing cert and mismatched cert identically at the external error surface

### Strict response halt

From `lib/lockspire/plug/require_token.ex`:

```elixir
conn
|> put_resp_header("www-authenticate", www_auth)
|> put_resp_content_type("application/json")
|> send_resp(401, body)
|> halt()
```

Pattern to preserve:

- one strict plug owns HTTP failure rendering
- soft plugs mutate state, not transport

## Test Patterns To Copy

### DPoP negative matrix

Use `test/lockspire/protocol/protected_resource_dpop_test.exs` as the pattern for:

- missing proof
- wrong scheme
- wrong `ath`
- wrong proof key
- replayed proof

### Challenge expectations

Use `test/lockspire/web/userinfo_controller_test.exs` as the pattern for:

- `WWW-Authenticate: DPoP realm=...`
- `error="invalid_token"`
- `algs="..."`

### MTLS plug behavior

Use `test/lockspire/mtls/plug_test.exs` for:

- asserting `conn.private[:lockspire_mtls_cert]`
- asserting rejection when extraction fails
