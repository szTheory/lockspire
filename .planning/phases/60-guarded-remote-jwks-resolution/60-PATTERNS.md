# Phase 60: Guarded Remote JWKS Resolution - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/jwks_fetcher.ex` | protocol/service | request-response | `lib/lockspire/jwks_fetcher.ex` | exact |
| `lib/lockspire/jwks_fetcher/target_safety.ex` | utility/security | transform | `lib/lockspire/protocol/security_profile.ex` | role-match |
| `lib/lockspire/application.ex` | supervision | setup | `lib/lockspire/application.ex` | exact |
| `lib/lockspire/protocol/client_auth.ex` | protocol/service | request-response | `lib/lockspire/protocol/client_auth.ex` | exact |
| `test/lockspire/jwks_fetcher_test.exs` | unit test | request-response | `test/lockspire/jwks_fetcher_test.exs` | exact |
| `test/lockspire/jwks_fetcher/target_safety_test.exs` | unit test | transform | `test/lockspire/protocol/security_policy_test.exs` | role-match |

## Pattern Assignments

### `lib/lockspire/jwks_fetcher.ex`

**Analog:** same file, keep the current narrow public API and extend its internal guards.

**Current cache/fetch pattern**
```elixir
case Cachex.fetch(@cache_name, uri, fn _uri -> fetch_from_network(uri, opts) end) do
  {:ok, keys} -> {:ok, keys}
  {:commit, keys} -> {:ok, keys}
  {:ignore, {:error, reason}} -> {:error, reason}
end
```

**Current network default pattern**
```elixir
req_opts =
  Keyword.merge(
    [
      retry: false,
      receive_timeout: 5000
    ],
    opts
  )
```

**Extension point**
- Keep the fetcher as the only public remote-JWKS API.
- Add stricter request defaults, structured failure reasons, and forced-refresh semantics inside this module.
- Prefer small pure helpers for URL validation, option normalization, and cache-bypass decisions.

**Anti-patterns**
- Do not spread remote-key policy across `ClientAuth` and the fetcher in this phase.
- Do not turn this module into a generic HTTP utility.
- Do not introduce host-managed network policy seams for the dangerous defaults.

### `lib/lockspire/jwks_fetcher/target_safety.ex`

**Analog:** a small policy/helper module similar in spirit to `SecurityProfile`: pure, narrow, and easy to test.

**Expected pattern**
- A pure classifier that accepts a host or resolved addresses and returns `:ok` or a structured unsafe-target error.
- Optional resolver injection through function arguments or opts for tests.

**Extension point**
- Isolate destination classification so the main fetcher stays readable.
- Keep the module internal in scope and vocabulary: this is about `jwks_uri` fetch safety, not a reusable firewall DSL.

**Anti-patterns**
- Do not couple the module to Phoenix config or runtime UI state.
- Do not bury IP classification logic inside ad hoc test-only branches in `jwks_fetcher.ex`.

### `lib/lockspire/application.ex`

**Analog:** same file, keep supervision changes minimal.

**Current pattern**
```elixir
children = [
  {Lockspire.Oban, Lockspire.Oban.runtime_config!()},
  Cachex.child_spec(name: :lockspire_jwks_cache)
]
```

**Extension point**
- Only touch application supervision if the cache contract needs a narrow config adjustment or an explicit cache name option.
- Prefer leaving supervision unchanged if fetcher-only changes are sufficient.

**Anti-patterns**
- Do not introduce new workers for background refresh or polling in Phase 60.

### `lib/lockspire/protocol/client_auth.ex`

**Analog:** same file, note the downstream seam but avoid Phase 61 work here.

**Current `private_key_jwt` seam**
```elixir
with [_, payload_b64, _] <- String.split(client_assertion, "."),
     {:ok, payload_json} <- Base.url_decode64(payload_b64, padding: false),
     {:ok, payload} <- Jason.decode(payload_json),
     :ok <- validate_jwt_ttl(payload),
     :ok <- validate_jwt_replay(client.client_id, payload, opts) do
  :ok
```

**Extension point**
- If a tiny seam is needed for later force-refresh use, keep it opt-in and non-behavioral in this phase.
- Otherwise leave `ClientAuth` unchanged and let Phase 61 consume the hardened fetcher later.

**Anti-patterns**
- Do not implement signature verification here in Phase 60.
- Do not couple fetcher policy to endpoint-specific OAuth error rendering yet.

### `test/lockspire/jwks_fetcher_test.exs`

**Analog:** same file, continue the `Req.Test` contract style.

**Current pattern**
- unique URI per test,
- `Req.Test.expect/2` for network assertions,
- direct result assertions from `JwksFetcher.get_keys/2`.

**Extension point**
- Add transport-policy and refresh behavior tests alongside the existing happy/error/cache cases.
- Keep tests focused on observable fetcher behavior rather than internal implementation details.

**Anti-patterns**
- Do not rely on live network access.
- Do not make refresh behavior assertions depend on test ordering or shared cache state without unique keys.

## Pattern Summary

- Keep the public seam narrow: `Lockspire.JwksFetcher` stays the fetcher contract.
- Use one small helper for target safety if needed.
- Preserve supervised cache ownership and avoid background workers.
- Let Phase 61 consume the result instead of half-implementing verification early.
