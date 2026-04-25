# Phase 22: Request Object Integration - Pattern Map

**Mapped:** 2026-04-25
**Files analyzed:** 10 (1 created module, 1 created test helper, 4 modified runtime modules, 5 modified test files; per-file analog count locked to one decisive recommendation per CONTEXT.md D-22)
**Analogs found:** 10 / 10

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/request_object.ex` (NEW) | service / orchestrator | request-response (transform) | `lib/lockspire/protocol/pushed_authorization_request.ex` | exact |
| `lib/lockspire/protocol/jar.ex` (MOD) | service / primitive | transform | `lib/lockspire/protocol/jar.ex` (self; existing claim-validation style) | exact |
| `lib/lockspire/protocol/authorization_request.ex` (MOD) | service / orchestrator | request-response | `lib/lockspire/protocol/authorization_request.ex` (self; existing `validate/1` `with`-chain) | exact |
| `lib/lockspire/protocol/pushed_authorization_request.ex` (MOD) | service / orchestrator | request-response | `lib/lockspire/protocol/pushed_authorization_request.ex` (self; existing `push/1` `with`-chain) | exact |
| `lib/lockspire/config.ex` (MOD) | config / accessor | static | `lib/lockspire/config.ex` (self; `known_scopes/0` accessor pattern) | exact |
| `test/support/jar_test_helpers.ex` (NEW) | test helper | utility | `test/lockspire/protocol/jar_test.exs` (existing `sign_jwt/4`, `client_with_single_jwk/1` private helpers — promoted to a public module) | role-match (existing helpers are inline `defp`; new module follows the conventional `test/support/` shape — see Wave 0 Gaps recommendation) |
| `test/lockspire/protocol/jar_test.exs` (MOD) | test | unit | `test/lockspire/protocol/jar_test.exs` (self; existing `describe "verify_signature/2"` block setup + `sign_jwt/4`) | exact |
| `test/lockspire/protocol/authorization_request_test.exs` (MOD) | test | unit | `test/lockspire/protocol/authorization_request_test.exs` (self; existing `:request_uri_conflict` test at lines 473-485) | exact |
| `test/lockspire/protocol/pushed_authorization_request_test.exs` (MOD) | test | unit | `test/lockspire/protocol/pushed_authorization_request_test.exs` (self; existing `:confidential_client` setup with Basic auth) | exact |
| `test/lockspire/web/authorize_controller_test.exs` (MOD) | test | integration (controller seam) | `test/lockspire/web/authorize_controller_test.exs` (self; existing `call_authorize/1` helper at 422-425 + `redirected?/1`) | exact |
| `test/integration/phase15_par_authorization_e2e_test.exs` (MOD) | test | end-to-end | `test/integration/phase15_par_authorization_e2e_test.exs` (self; existing required-PAR flow setup) | exact |

## Pattern Assignments

### `lib/lockspire/protocol/request_object.ex` (NEW — orchestrator, request-response)

**Analog:** `lib/lockspire/protocol/pushed_authorization_request.ex`

This is the canonical "orchestrator that composes pure protocol primitives via a `with`-chain and returns a tagged-tuple result discriminated by `Error` struct" shape. The new module mirrors its surface exactly so the splice into `AuthorizationRequest.validate/1` is a one-line addition.

**Module shell pattern** (from `pushed_authorization_request.ex:1-11`):

```elixir
defmodule Lockspire.Protocol.PushedAuthorizationRequest do
  @moduledoc """
  Accepts pushed authorization requests and returns opaque PAR references.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.PushedAuthorizationRequest, as: PushedAuthorizationRequestState
  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Storage.Ecto.Repository
```

**`with`-chain orchestration shape** (from `pushed_authorization_request.ex:42-61`):

```elixir
@spec push(map()) :: result()
def push(request) when is_map(request) do
  params = Map.get(request, :params, Map.get(request, "params", request))
  authorization = Map.get(request, :authorization, Map.get(request, "authorization"))
  now = now(request)

  with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
       {:ok, %AuthorizationRequest.Validated{} = validated} <- validate_request(params, client),
       {:ok, %PushedAuthorizationRequestState{} = pushed_request} <-
         persist_pushed_request(validated, request, now) do
    {:ok,
     %Success{
       request_uri: pushed_request.request_uri,
       expires_in: DateTime.diff(pushed_request.expires_at, now, :second)
     }}
  else
    {:error, %Error{} = error} ->
      {:error, error}
  end
end
```

**How `request_object.ex` adapts this shape** (target `consume/3`, per RESEARCH.md Pattern 1):

- Accepts `(params, %Client{}, opts)` — same "outer-input plus authenticated client" shape as `validate_pushed/2`.
- The `with`-chain steps mirror RESEARCH.md Architecture Patterns lines 280-289: `reject_request_uri_collision → reject_outer_param_conflicts → fetch_request → require_client_jwks → verify (decode + verify_signature) → validate (validate_claims w/ max_age) → project_to_params`.
- Result tuple is `{:ok, projected_params_map} | {:browser_error, %AuthorizationRequest.Error{}} | {:redirect_error, %AuthorizationRequest.Error{}}` so the caller's `else` clauses in `AuthorizationRequest.validate/1` (lines 83-91) absorb it without restructuring.

**Reuse the existing `Error` struct — do NOT define a new one.** `pushed_authorization_request.ex:25-38` defines its own `Error` because `/par`'s wire envelope (JSON with `status`) differs from `/authorize`'s (redirect or rendered page); JAR consumption flows back through `AuthorizationRequest.Error`, so the orchestrator aliases and constructs `Lockspire.Protocol.AuthorizationRequest.Error` directly. The struct already carries free-form `reason_code: atom()` (`authorization_request.ex:54-63`), so the new D-14 atoms slot in without struct changes.

---

### `lib/lockspire/protocol/jar.ex` (MOD — primitive, transform)

**Analog:** itself (existing claim-validation tuple-error style is the canonical shape new branches must match).

WR-01 (typ check), WR-02 (aud-list strictness), and WR-03 (`exp` max-age ceiling) all land **inside** this primitive (per RESEARCH.md alternatives table, line 122). New code must match the existing `defp check_*` shape so the `with`-chain in `validate_claims/2` absorbs the new branches without restructuring.

**Existing claim-validation `with`-chain to splice into** (`jar.ex:190-200`):

```elixir
@spec validate_claims(t(), keyword()) :: :ok | {:error, validate_claims_reason()}
def validate_claims(%__MODULE__{claims: claims}, opts) when is_map(claims) and is_list(opts) do
  with {:ok, expected_client_id, expected_audience, now, leeway} <- parse_opts(opts),
       :ok <- check_issuer(claims, expected_client_id),
       :ok <- check_audience(claims, expected_audience),
       :ok <- check_expiration(claims, now, leeway),
       :ok <- check_not_before(claims, now, leeway),
       :ok <- check_issued_at(claims, now, leeway) do
    :ok
  end
end
```

WR-03 extends `parse_opts/1` to return a 6-tuple including `max_age`, then `check_expiration/3` becomes `check_expiration/4` and gains a `check_max_age/4` follow-up call (RESEARCH.md Example 8, lines 729-741).

**Existing `check_audience/2` shape that WR-02 tightens** (`jar.ex:245-263`):

```elixir
defp check_audience(claims, expected_audience) do
  case Map.get(claims, "aud") do
    nil ->
      {:error, :missing_audience}

    aud when is_binary(aud) ->
      if aud == expected_audience, do: :ok, else: {:error, :invalid_audience}

    aud when is_list(aud) ->
      if Enum.any?(aud, fn entry -> entry == expected_audience end) do
        :ok
      else
        {:error, :invalid_audience}
      end

    _ ->
      {:error, :invalid_audience}
  end
end
```

WR-02 tightens the `aud when is_list(aud)` branch by rejecting empty lists and lists with non-binary entries (RESEARCH.md Example 7, lines 690-696). New error stays `:invalid_audience` — no new atom — preserving the existing taxonomy.

**Existing `verify_with_single_jwk/2` to splice WR-01 into** (`jar.ex:142-161`):

```elixir
defp verify_with_single_jwk(jwt, public_jwk) do
  try do
    case JOSE.JWT.verify_strict(public_jwk, @allowed_algorithms, jwt) do
      {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
        {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
        {_modules, header} = JOSE.JWS.to_map(jws_struct)
        {:ok, %__MODULE__{claims: claims, header: header}}

      {false, _jwt_struct, _jws_struct} ->
        {:error, :invalid_signature}

      {:error, _} ->
        {:error, :invalid_signature}
    end
  rescue
    _ -> {:error, :invalid_signature}
  catch
    _, _ -> {:error, :invalid_signature}
  end
end
```

WR-01 inserts a `check_typ(header)` call between the `to_map` calls and the `{:ok, %__MODULE__{...}}` return on the success branch (RESEARCH.md Example 6, lines 644-672). New error atom `:invalid_typ` joins the `verify_signature/2` reason set; the orchestrator maps it to `:invalid_request_object_typ` per D-14.

**Type-spec extension:** the `@type validate_claims_reason` union at `jar.ex:18-29` gains `| :expiration_too_far` (WR-03). The `verify_signature/2` `@spec` return at `jar.ex:71-72` gains `| :invalid_typ`.

---

### `lib/lockspire/protocol/authorization_request.ex` (MOD — orchestrator splice point)

**Analog:** itself (existing `validate/1` `with`-chain is the splice target).

**Existing pipeline that JAR consumption splices into** (`authorization_request.ex:68-92`):

```elixir
@spec validate(map()) :: result()
def validate(params) when is_map(params) do
  with {:ok, %Client{} = client} <- fetch_client(params),
       {:ok, resolved_par_policy} <- resolve_effective_par_policy(client),
       :ok <- maybe_require_pushed_authorization_request(params, client, resolved_par_policy),
       {:ok, resolved_params} <- resolve_authorization_params(params, client),
       {:ok, %Validated{} = validated} <- validate_with_client(resolved_params, client) do
    validated = %Validated{validated | client: client}

    Observability.emit(:authorization_request_accepted, %{}, %{
      client_id: client.client_id,
      redirect_safe: true
    })

    {:ok, validated}
  else
    {:browser_error, %Error{} = error} ->
      emit_rejection(params["client_id"], error, false)
      {:browser_error, error}

    {:redirect_error, %Error{} = error} ->
      emit_rejection(params["client_id"], error, true)
      {:redirect_error, error}
  end
end
```

**Splice rule (D-02):** insert one new step `{:ok, post_jar_params} <- maybe_consume_request_object(resolved_params, client)` between `resolve_authorization_params/2` and `validate_with_client/3`. The new private function gates on `params["request"]` presence and routes through `RequestObject.consume/3` (RESEARCH.md Pattern 2, lines 320-346). When `request` is absent the function returns `{:ok, params}` unchanged. The `else` clauses already absorb both error tuple shapes — no `else`-branch additions needed.

**Removal task — `@unsupported_params`** (`authorization_request.ex:15`):

```elixir
@unsupported_params ~w(claims request request_uri resource response_mode)
```

Per D-18 this becomes `~w(claims resource response_mode)`. Drop both `request` (positively handled by the new orchestrator) and `request_uri` (gated earlier in the pipeline by `maybe_require_pushed_authorization_request/3` and `validate_lockspire_request_uri/1`). The existing `reject_unsupported_params/1` at lines 472-486 stays as-is — it just operates over a smaller list.

---

### `lib/lockspire/protocol/pushed_authorization_request.ex` (MOD — orchestrator splice point)

**Analog:** itself.

**Existing pipeline that JAR consumption splices into** (`pushed_authorization_request.ex:42-61`, see full excerpt above).

**Splice rule (D-03):** insert `{:ok, post_jar_params} <- maybe_consume_request_object(params, client)` between `authenticate_client/3` and `validate_request/2`. `ClientAuth.authenticate/3` continues to run unchanged (D-10) — JAR signature verification is an additional, independent step. Because `RequestObject.consume/3` returns `{:browser_error, %AuthorizationRequest.Error{}}` while `push/1`'s `else` clause expects `{:error, %PushedAuthorizationRequest.Error{}}`, the splice site MUST either:
- **(Recommended, decisive)** wrap the JAR result via the same shape adapter `validate_request/2` already uses at lines 63-71 (`{:error, oauth_error(400, error.error, error.error_description, error.reason_code)}`), keeping `push/1`'s `else` clause unchanged; OR
- extend the `else` clause with a JAR-specific match (more code, more drift).

Pick the wrap. It's one helper function, mirrors `validate_request/2`'s existing pattern verbatim, and the `Error` struct shapes line up cleanly.

---

### `lib/lockspire/config.ex` (MOD — config accessor)

**Analog:** itself (existing `known_scopes/0` accessor is the canonical "optional-with-default" pattern, per RESEARCH.md Example 5).

**Existing `known_scopes/0` excerpt** (`config.ex:37-42`):

```elixir
@spec known_scopes() :: [String.t()]
def known_scopes do
  @app
  |> Application.get_env(:known_scopes, [])
  |> List.wrap()
end
```

**New `jar_max_age_seconds/0` follows the same shape** (RESEARCH.md Example 5, lines 605-621):

```elixir
@jar_max_age_default 600

@spec jar_max_age_seconds() :: pos_integer()
def jar_max_age_seconds do
  Application.get_env(@app, :jar_max_age_seconds, @jar_max_age_default)
end
```

**Why follow `known_scopes/0` and NOT `issuer!/0` (`config.ex:20-30`):** `:jar_max_age_seconds` has a sensible default and never causes a startup failure. `issuer!/0` is the pattern for required-with-no-default; `known_scopes/0` is the pattern for optional-with-default. Use the latter.

**No bang-suffix.** The accessor never raises, so it does NOT route through `fetch_required!/1` (`config.ex:49-51`).

---

### `test/support/jar_test_helpers.ex` (NEW — test helper)

**Analog:** existing private helpers in `test/lockspire/protocol/jar_test.exs:36-54` (the `setup` block plus `sign_jwt/4`, `client_with_single_jwk/1`, `client_with_jwks_set/1`).

The Lockspire `test/support/` directory currently holds only `endpoint.ex` (`test/support/endpoint.ex:1-10`) — there is no shared `Case` module to mirror. The conventional Phoenix/Ecto `DataCase` / `IntegrationCase` shape does not exist here, so the new helper module is plain — no `using` macro, no `setup` callbacks. It exposes pure functions that callers `import` or `alias` and call directly.

**Compilation seam already configured** (`mix.exs:53`):

```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_env), do: ["lib"]
```

`test/support/*.ex` files are auto-compiled in the `:test` env. The new module follows the same shape as `test/support/endpoint.ex`: no `use ExUnit.Case`, just `defmodule ... do ... end` exposing public functions.

**Existing inline helpers to promote** (`test/lockspire/protocol/jar_test.exs:36-54`):

```elixir
setup do
  private_jwk = JOSE.JWK.generate_key({:rsa, 2048})
  {_, pub_jwk_map} = JOSE.JWK.to_public_map(private_jwk)
  {_, priv_jwk_map} = JOSE.JWK.to_map(private_jwk)
  %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map, priv_jwk_map: priv_jwk_map}
end

defp sign_jwt(private_jwk, claims, alg \\ "RS256", extra_header \\ %{}) do
  header = Map.merge(%{"alg" => alg}, extra_header)
  JOSE.JWT.sign(private_jwk, header, claims) |> JOSE.JWS.compact() |> elem(1)
end

defp client_with_single_jwk(pub_jwk_map) do
  %Client{jwks: pub_jwk_map}
end

defp client_with_jwks_set(pub_jwk_map) do
  %Client{jwks: %{"keys" => [pub_jwk_map]}}
end
```

**Recommended new module shape** (combining `endpoint.ex`'s plain-module style with the helpers above):

```elixir
defmodule Lockspire.JarTestHelpers do
  @moduledoc false
  # Test-only helpers for signing JAR request objects and registering matching
  # client JWKs. Used by jar_test.exs, authorization_request_test.exs,
  # pushed_authorization_request_test.exs, authorize_controller_test.exs, and
  # phase15_par_authorization_e2e_test.exs.

  alias Lockspire.Domain.Client

  @doc """
  Generates an RSA-2048 keypair plus the JOSE pub/priv map forms.
  Returns %{private_jwk:, pub_jwk_map:, priv_jwk_map:}.
  """
  def generate_keys do
    private_jwk = JOSE.JWK.generate_key({:rsa, 2048})
    {_, pub_jwk_map} = JOSE.JWK.to_public_map(private_jwk)
    {_, priv_jwk_map} = JOSE.JWK.to_map(private_jwk)
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map, priv_jwk_map: priv_jwk_map}
  end

  @doc """
  Signs a JAR. Accepts opts: :alg (default "RS256"), :extra_header (default %{}).
  """
  def sign_jar(private_jwk, claims, opts \\ []) do
    alg = Keyword.get(opts, :alg, "RS256")
    extra_header = Keyword.get(opts, :extra_header, %{})
    header = Map.merge(%{"alg" => alg}, extra_header)
    JOSE.JWT.sign(private_jwk, header, claims) |> JOSE.JWS.compact() |> elem(1)
  end

  @doc "Returns a %Client{} with a single inline JWK (public)."
  def client_with_single_jwk(pub_jwk_map), do: %Client{jwks: pub_jwk_map}

  @doc "Returns a %Client{} with a JWK Set containing one public key."
  def client_with_jwks_set(pub_jwk_map), do: %Client{jwks: %{"keys" => [pub_jwk_map]}}
end
```

**Naming note:** the `pattern_mapping_context` requested a `sign_jar/2` helper. The module exposes `sign_jar/3` (with the third arg as keyword opts) so WR-01 tests can pass `extra_header: %{"typ" => "JWT-bearer"}` without overloading. The default-arg form gives the requested 2-arity ergonomics (`sign_jar(jwk, claims)`) while supporting the new typ-injection use case.

---

### `test/lockspire/protocol/jar_test.exs` (MOD — extension)

**Analog:** itself. The existing `describe "verify_signature/2"` block (line 34) and `describe "validate_claims/2"` block (around line 230 — see Sources at lines 232-244 in RESEARCH.md) already use the exact setup shape new tests need.

**Existing test structure to extend** (lines 56-69):

```elixir
test "returns {:ok, %Jar{}} for a validly signed JWT with matching client JWK", %{
  private_jwk: private_jwk,
  pub_jwk_map: pub_jwk_map
} do
  claims = %{"iss" => "client_id", "aud" => "https://server.example.com", "response_type" => "code"}
  jwt = sign_jwt(private_jwk, claims)
  client = client_with_single_jwk(pub_jwk_map)

  assert {:ok, %Jar{claims: verified_claims, header: header}} =
           Jar.verify_signature(jwt, client)

  assert verified_claims == claims
  assert header["alg"] == "RS256"
end
```

**New WR-01/02/03 tests slot in unchanged.** The existing `sign_jwt/4` already accepts an `extra_header` argument (line 43-46) — WR-01 tests reuse it directly with `extra_header: %{"typ" => "JWT-bearer"}` etc. After the test-helper module lands, these tests can `import Lockspire.JarTestHelpers, only: [sign_jar: 3, client_with_single_jwk: 1]` and the existing private `defp` helpers can be deleted; until then the existing helpers stay.

**~10 new cases per RESEARCH.md Validation Architecture section A** (lines 821-830).

---

### `test/lockspire/protocol/authorization_request_test.exs` (MOD — extension)

**Analog:** itself. The existing `:request_uri_conflict` test is the structural template for `:request_object_conflict` and `:request_object_and_request_uri_conflict`.

**Existing conflict test (lines 473-485)** — copy this shape verbatim, swap `request_uri` for `request`:

```elixir
test "rejects mixed request_uri and raw authorization parameters", %{client: client} do
  pushed_request = put_pushed_request!(client.client_id)

  assert {:browser_error, %Error{} = error} =
           AuthorizationRequest.validate(%{
             "client_id" => client.client_id,
             "request_uri" => pushed_request.request_uri,
             "redirect_uri" => "https://client.example.com/callback"
           })

  assert error.error == "invalid_request"
  assert error.reason_code == :request_uri_conflict
end
```

**Existing setup pattern (lines 22-60)** — new JAR tests reuse the `client` registered here, but MUST register a client variant with `jwks: pub_jwk_map`. Use `Repository.update_client(client, %{jwks: pub_jwk_map})` after the keypair is generated, OR create a dedicated `setup_with_jar_keys` helper that wraps the existing `setup` and calls `Lockspire.JarTestHelpers.generate_keys/0` per-test.

**Existing `valid_params/1` helper (lines 487-498)** — reused unchanged for non-JAR flows; for JAR flows, build params as `%{"client_id" => cid, "request" => signed_jar}` directly.

**Issuer config for `aud`** — `config/test.exs` sets issuer to `https://example.test/lockspire` per RESEARCH.md Sources (line 948). JAR claims must use this exact value. Recommended: pull via `Lockspire.Config.issuer!()` inside the test.

**~11 new cases per RESEARCH.md Validation Architecture sections B-E** (lines 838-867).

---

### `test/lockspire/protocol/pushed_authorization_request_test.exs` (MOD — extension)

**Analog:** itself. The existing setup registers both a `public_client` and a `confidential_client` with `client_secret_basic` auth (lines 42-61) — exactly what D-10 requires for the "ClientAuth + JAR run independently" proof.

**Existing setup excerpt (lines 42-61)** — `confidential_client` already has `token_endpoint_auth_method: :client_secret_basic`. The two new tests (per RESEARCH.md Validation Architecture, line 891-894):

1. **Valid Basic auth + invalid JAR signature → JAR error wins.** Proves the splice site catches JAR failures after `ClientAuth.authenticate/3` succeeds. Construct `Authorization: Basic <base64(client_id:secret)>` header (the existing fixture `confidential_client` has secret `"par-confidential-secret"` at line 42), present a JAR signed with a wrong key.

2. **Wrong Basic password + valid JAR → ClientAuth error wins.** Proves ordering: `ClientAuth` runs first (D-03), JAR is never evaluated when client auth fails.

The `confidential_client` MUST be re-registered with `jwks: pub_jwk_map` (existing fixture has none). Use `Repository.update_client(confidential_client, %{jwks: pub_jwk_map})` in the test setup.

---

### `test/lockspire/web/authorize_controller_test.exs` (MOD — extension)

**Analog:** itself. The existing `call_authorize/1` helper and `redirected?/1` predicate are the entry-point shape for the two new tests (RESEARCH.md Validation Architecture, lines 870-877).

**Existing helper excerpt (lines 422-429):**

```elixir
defp call_authorize(params) do
  conn = build_conn(:get, "/authorize", params)
  Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))
end

defp redirected?(conn), do: Plug.Conn.get_resp_header(conn, "location") != []

defp redirect_location(conn), do: List.first(Plug.Conn.get_resp_header(conn, "location"))
```

**Existing browser-error assertion shape (lines 410-419)** — copy this shape for the JAR rejection-page test:

```elixir
burned_conn =
  %{
    "client_id" => client.client_id,
    "request_uri" => pushed_request.request_uri
  }
  |> call_authorize()

assert burned_conn.status == 400
refute redirected?(burned_conn)
assert burned_conn.resp_body =~ "request_uri is invalid, expired, or already used"
```

For the JAR-bad-signature case, swap to `%{"client_id" => cid, "request" => bad_signature_jwt}` and assert `conn.resp_body =~ "Authorization request rejected"` (or the actual error-page text, which the planner verifies against `lib/lockspire/web/templates`). Two new cases — exactly per CONTEXT.md (Claude's Discretion clause).

---

### `test/integration/phase15_par_authorization_e2e_test.exs` (MOD — surgical extension)

**Analog:** itself. The existing setup (lines 53-64 + 66-87) already configures the issuer as `https://example.test/lockspire` and registers a public client with redirect URI `https://client.example.com/callback`. The existing required-PAR test (line 89+) is the pattern the new JAR-by-PAR test mirrors.

**Existing `setup_all` excerpt (lines 53-64)** — issuer + repo + sandbox config carry over unchanged:

```elixir
setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
  Application.put_env(:lockspire, :mount_path, "/lockspire")
  Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])
  Application.put_env(:lockspire, :account_resolver, GeneratedHostResolver)

  start_supervised!(Lockspire.TestRepo)
  Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

  :ok
end
```

**One new test branch.** The existing required-PAR flow (line 89+) is the structural template. The new test:
1. Registers a confidential client with inline `jwks` AND `client_secret_basic`.
2. Signs a JAR with `iss = client_id`, `aud = "https://example.test/lockspire"`, `exp = now + 300`, claims for redirect_uri/scope/PKCE.
3. POSTs `/par` with `Authorization: Basic ...` AND body `{client_id, request: jwt}`.
4. Reads back the `request_uri`.
5. GETs `/authorize?client_id=...&request_uri=...`.
6. Drives consent through `GeneratedHostResolver`.
7. POSTs `/token`, verifies id_token.

Per D-21 do NOT create `phase22_jar_authorization_e2e_test.exs`. One surgical addition only.

---

## Shared Patterns

### Authentication / Authorization

**Source:** `lib/lockspire/protocol/client_auth.ex` (consumed by `pushed_authorization_request.ex:73-87` and unchanged in Phase 22 per D-10).

**Apply to:** `pushed_authorization_request.ex` only — the `/par` splice site. `ClientAuth.authenticate/3` continues to run **before** the new JAR step. `/authorize` does not invoke `ClientAuth` at all (browser endpoint).

```elixir
# pushed_authorization_request.ex:73-87 — keep verbatim, JAR splices AFTER this
defp authenticate_client(params, authorization, request) do
  case ClientAuth.authenticate(params, authorization, client_auth_options(request)) do
    {:ok, %Client{} = client} -> {:ok, client}

    {:error, %ClientAuth.Error{} = error} ->
      {:error,
       %Error{
         status: error.status,
         error: error.error,
         error_description: error.error_description,
         reason_code: error.reason_code
       }}
  end
end
```

### Error Handling

**Source:** `lib/lockspire/protocol/authorization_request.ex:49-63` (the `Error` struct), lines 488-506 (the `browser_error/3` and `redirect_error/4` constructors).

**Apply to:** `request_object.ex` (the orchestrator constructs `AuthorizationRequest.Error` directly — D-14 atoms slot in without struct changes), and the new JAR error-mapping helper.

```elixir
# authorization_request.ex:49-63
defmodule Error do
  @type t :: %__MODULE__{
          error: String.t(),
          error_description: String.t(),
          reason_code: atom(),
          state: String.t() | nil,
          redirect_uri: String.t() | nil
        }

  defstruct [:error, :error_description, :reason_code, :state, :redirect_uri]
end

# authorization_request.ex:488-496
defp browser_error(error, description, reason_code) do
  %Error{
    error: to_string(error),
    error_description: description,
    reason_code: reason_code,
    redirect_uri: nil,
    state: nil
  }
end
```

### Sealed-envelope conflict rejection

**Source:** `lib/lockspire/protocol/authorization_request.ex:393-411` (the `reject_request_uri_conflicts/1` function).

**Apply to:** `request_object.ex` (D-04 mirror) and arguably extracted as a generic `reject_param_conflicts/2` helper (per RESEARCH.md Open Question 2 — recommended).

```elixir
# authorization_request.ex:393-411
defp reject_request_uri_conflicts(params) do
  conflict_keys =
    params
    |> Enum.reject(fn {key, _value} -> key in ["client_id", "request_uri"] end)
    |> Enum.filter(fn {_key, value} -> present?(value) end)

  case conflict_keys do
    [] ->
      :ok

    _other ->
      {:browser_error,
       browser_error(
         :invalid_request,
         "request_uri cannot be combined with raw authorization parameters",
         :request_uri_conflict
       )}
  end
end
```

D-04's outer-param conflict rejector for JAR is structurally identical — replace `"request_uri"` with `"request"` and `:request_uri_conflict` with `:request_object_conflict`. Recommend extracting `reject_param_conflicts(params, allowed_keys, conflict_atom, description)` so both call sites remain one-line.

### Redirect-safety classification

**Source:** `lib/lockspire/protocol/authorization_request.ex:170-189` (the `par_required_error/2` dispatch).

**Apply to:** `request_object.ex` (D-16 mirror — but see note).

```elixir
# authorization_request.ex:170-189
defp par_required_error(params, %Client{} = client) do
  case validate_redirect_uri(client, params) do
    {:ok, _redirect_uri} ->
      {:redirect_error,
       redirect_error(
         params,
         :invalid_request,
         "request_uri from the PAR endpoint is required",
         :par_required_request_uri
       )}

    {:browser_error, %Error{}} ->
      {:browser_error,
       browser_error(
         :invalid_request,
         "request_uri from the PAR endpoint is required",
         :par_required_request_uri
       )}
  end
end
```

**Note (per D-16 + RESEARCH.md Example 4 commentary):** because D-04 forbids outer `redirect_uri` when `request` is present, the `{:ok, _}` branch is **practically unreachable** for JAR-validation failures. The orchestrator can produce `:browser_error` unconditionally for JAR failures and document the trade-off. Keep the dispatch shape for symmetry (cheap, future-proof if D-04 is ever loosened) — do not try to construct a clever redirect-safe JAR-failure path.

### Telemetry emission

**Source:** `lib/lockspire/protocol/authorization_request.ex:508-514` (the `emit_rejection/3` call), unchanged from Phase 18.

**Apply to:** all new D-14 and D-15 atoms — no orchestrator-side changes needed; new atoms surface automatically through `Observability.emit/3`.

```elixir
# authorization_request.ex:508-514
defp emit_rejection(client_id, %Error{} = error, redirect_safe) do
  Observability.emit(:authorization_request_rejected, %{}, %{
    client_id: client_id,
    reason_code: error.reason_code,
    redirect_safe: redirect_safe
  })
end
```

### `with`-chain orchestration

**Source:** both `authorization_request.ex:69-92` and `pushed_authorization_request.ex:42-61`.

**Apply to:** `request_object.ex` (the new orchestrator), and the splice rules for `authorization_request.ex` and `pushed_authorization_request.ex`.

The pattern: tagged-tuple `{:ok, _}` carries forward; `{:browser_error, _}` and `{:redirect_error, _}` short-circuit out of the `with`. The `else` clause unifies error handling. New JAR step produces results in the same shape so existing `else` clauses absorb them with **zero modification**.

## No Analog Found

None. Every new file or modification has a strong analog in the existing codebase. This phase is pure wiring + three small primitive additions, all of which map 1:1 to established Lockspire patterns.

## Metadata

**Analog search scope:**
- `lib/lockspire/protocol/` — orchestrator and primitive analogs (jar.ex, authorization_request.ex, pushed_authorization_request.ex, client_auth.ex)
- `lib/lockspire/config.ex` — accessor pattern
- `test/lockspire/protocol/` — test-style analogs (jar_test.exs, authorization_request_test.exs, pushed_authorization_request_test.exs)
- `test/lockspire/web/` — controller-seam test analogs (authorize_controller_test.exs)
- `test/integration/` — e2e test analogs (phase15_par_authorization_e2e_test.exs)
- `test/support/` — shared helper analogs (endpoint.ex; no Case modules exist)
- `mix.exs:53` — confirmed `test/support` is on the `:test`-env compilation path

**Files scanned for analog selection:** ~12 (all referenced at file:line in CONTEXT.md and RESEARCH.md, plus three exploratory passes for test/support shape and `Case`-module presence).

**Pattern extraction date:** 2026-04-25
