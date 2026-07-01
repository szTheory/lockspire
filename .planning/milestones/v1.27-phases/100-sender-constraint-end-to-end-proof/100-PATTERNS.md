# Phase 100: Sender-Constraint End-to-End Proof - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 8 (3 runtime EDIT, 1 NEW test file, 4 test EDIT/ADD)
**Analogs found:** 8 / 8 (all in-repo; this is a verification/proof phase — every primitive already exists)

> Domain: backend Elixir (Lockspire OAuth/OIDC resource-server library). Mix/ExUnit, no frontend.
> All anchors below were re-read live this session and match RESEARCH.md (cosmetic line drift only, flagged inline). This is a security-critical pipeline — **copy excerpts verbatim**, do not paraphrase plug-clause shapes or error maps.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/access_token.ex` (EDIT, D-01) | model / pipeline struct | transform | self (existing `defstruct` + `@type`) | exact (self-extend) |
| `lib/lockspire/plug/enforce_sender_constraints.ex` (EDIT, D-02) | middleware (plug) | request-response | self (success-return clauses 69-78, 111-128) | exact (self-extend) |
| `lib/lockspire/plug/require_token.ex` (EDIT, D-03) | middleware (plug) | request-response | self (`call/2` clause order 19-36 + `handle_structured_error` 86-93, `handle_insufficient_scope` 63-84) | exact (self-extend) |
| `test/integration/phase100_sender_constraint_e2e_test.exs` (NEW, D-06/07/08/09/10) | integration test | request-response (full pipeline) | `test/integration/phase81_generated_host_route_protection_e2e_test.exs` | exact (lift-and-refine) |
| `test/lockspire/plug/require_token_test.exs` (ADD, D-10 negative) | plug-unit test | request-response | self (clauses 14-22 pass-through, 69-96 sender-constraint) | exact (self-extend) |
| `test/lockspire/plug/enforce_sender_constraints_test.exs` (ADD, D-02 positive) | plug-unit test | request-response | self (success tests 57-80, 192-234; `dpop_fixture/2` 279-311) | exact (self-extend) |
| `test/lockspire/access_token_test.exs` (UPDATE, D-01 default) | unit test | transform | self (defaults test 7-17) | exact (self-extend) |
| `test/lockspire/release_readiness_contract_test.exs` (ADD, D-05 ordering) | contract test | batch (file-I/O) | self (audience clause 761-791 + `extract_canonical_pipeline!/2` 140-157) | exact (self-extend) |

---

## Pattern Assignments

### `lib/lockspire/access_token.ex` (model, transform) — D-01

**Analog:** self. The struct currently has exactly 7 fields, all defaulting to `nil`. Add an 8th, `binding_verified`, **defaulting to `false`** (the only non-nil default — fail-closed). Do NOT touch the existing 7.

**Existing struct + type to extend** (lines 6-29, read verbatim):
```elixir
defstruct [
  :token,
  :claims,
  :client_id,
  :authorization_scheme,
  :binding_type,
  :binding_requirements,
  :error
]

@type t :: %__MODULE__{
        token: String.t() | nil,
        claims: map() | nil,
        client_id: String.t() | nil,
        authorization_scheme: String.t() | nil,
        binding_type: String.t() | nil,
        binding_requirements:
          %{
            optional(:dpop_jkt) => String.t(),
            optional(:mtls_x5t_s256) => String.t()
          }
          | nil,
        error: term()
      }
```

**Pattern to apply:** The `:field` shorthand in `defstruct` defaults to `nil`; for a non-nil default use the `key: value` form. So append `binding_verified: false` to the list (it must use the `key: value` form, NOT the bare-atom form). Add `binding_verified: boolean()` to the `@type`.
```elixir
# in defstruct — note: bare-atom keys above default to nil; this one needs the kw form:
  :error,
  binding_verified: false
# in @type:
  error: term(),
  binding_verified: boolean()
```
> Caveat: in Elixir `defstruct`, `key: value` entries must come AFTER all bare-atom entries (the parser requires the keyword list at the tail). `binding_verified: false` placed last satisfies this. Do not interleave it among the `:field` atoms.

---

### `lib/lockspire/plug/enforce_sender_constraints.ex` (middleware, request-response) — D-02

**Analog:** self. Set `binding_verified: true` on the `access_token` assign on **every success path that validated a binding** — and NOT on the unbound no-op path. RESEARCH cited success paths at 67-78 / 111-128; live they are `enforce_constraints/3` (67-78), `maybe_validate_dpop/3` (80-109), `maybe_validate_mtls/4` (111-128). Note: the success returns currently leave `conn` **unchanged** (DPoP returns `{:ok, _proof}` then falls into mtls; mtls success returns `conn` as-is). The new field must be set on `conn.assigns.access_token` before the plug returns success.

**The entry clause that gates binding (lines 56-65) — the no-op path that MUST stay untouched** (leaves `binding_verified: false`):
```elixir
def call(conn, opts) do
  case conn.assigns[:access_token] do
    %AccessToken{error: nil, binding_requirements: requirements} = access_token
    when is_map(requirements) ->
      enforce_constraints(conn, access_token, opts)

    _other ->
      conn          # <-- UNBOUND / no-op path: do NOT set binding_verified here
  end
end
```

**The two success return shapes to amend** (lines 67-78 dpop→mtls handoff; lines 116-118 mtls success):
```elixir
defp enforce_constraints(conn, %AccessToken{} = access_token, opts) do
  case maybe_validate_dpop(access_token, conn, opts) do
    {:ok, _proof} ->
      maybe_validate_mtls(conn, access_token, opts)      # success path
    :skip ->
      maybe_validate_mtls(conn, access_token, opts)      # success path (mtls-only or both-skip)
    {:error, sender_error} ->
      assign(conn, :access_token, %AccessToken{access_token | error: sender_error})  # failure — unchanged
  end
end

defp maybe_validate_mtls(
       conn,
       %AccessToken{binding_requirements: %{mtls_x5t_s256: expected_thumbprint}} = access_token,
       opts
     ) do
  with {:ok, cert} <- fetch_mtls_cert(conn, opts),
       true <- MTLSTokenBinding.confirmation_matches?(expected_thumbprint, cert) do
    conn                                                 # <-- mtls SUCCESS: must set binding_verified: true
  else
    # ... failure arms unchanged (assign error) ...
  end
end

defp maybe_validate_mtls(conn, _access_token, _opts), do: conn   # DPoP-only success falls here — must also set it
```

**Pattern to apply (Claude's discretion — shared helper is cleanest, per D-02):** Re-assign the struct with `binding_verified: true` at the moment of success. The idiomatic existing re-assign shape is already in this file:
```elixir
# established re-assign idiom in THIS file (line 76, 121):
assign(conn, :access_token, %AccessToken{access_token | error: sender_error})
```
Mirror it for success. One shared helper covering all three success returns (dpop-success→mtls-skip, mtls-success, dpop+mtls-both) is recommended:
```elixir
defp mark_binding_verified(conn) do
  case conn.assigns[:access_token] do
    %AccessToken{} = at -> assign(conn, :access_token, %AccessToken{at | binding_verified: true})
    _ -> conn
  end
end
```
Then funnel each success return (`conn` in `maybe_validate_mtls/4` success body, and the `defp maybe_validate_mtls(conn, _access_token, _opts), do: conn` DPoP-only-success clause) through `mark_binding_verified(conn)`. **Critical:** the two error arms (`assign(... | error: mtls_error())`) and the unbound `_other -> conn` entry clause must NOT be touched — only binding-validated successes get the breadcrumb.

> Anchor note: pull `access_token` from `conn.assigns` inside the helper (not the closed-over `access_token` param) so it picks up the same struct the success path returned — `maybe_validate_mtls/4` returns the unmodified `conn` whose assign already holds the verified token.

---

### `lib/lockspire/plug/require_token.ex` (middleware, request-response) — D-03

**Analog:** self. Add a fail-closed clause to `call/2`, ordered **before** the existing pass-through, gated on `error: nil AND binding_requirements != nil AND binding_verified == false`. Route it through the existing `handle_structured_error/2` sender-constraint path so it reuses the Phase 98 challenge taxonomy. D-03 requires **403** (the existing sender path returns 401 via `handle_invalid_token/2` — see the 403 note below).

**The `call/2` clause order to extend (lines 19-36) — new clause goes FIRST inside the `case`:**
```elixir
def call(conn, _opts) do
  case conn.assigns[:access_token] do
    # === D-03: NEW clause, inserted BEFORE the pass-through below ===
    # MUST be gated on error: nil so it never intercepts tokens that already
    # failed in VerifyToken (those carry error != nil and hit the clauses below).
    # Fires ONLY for a token that arrived bound (binding_requirements != nil) but
    # reached RequireToken without EnforceSenderConstraints marking it verified.
    %AccessToken{error: nil, binding_requirements: req, binding_verified: false}
    when not is_nil(req) ->
      handle_structured_error(conn, sender_constraint_bypass_error(req))

    # === existing pass-through (UNCHANGED, stays second) ===
    %AccessToken{error: nil, claims: claims} when not is_nil(claims) ->
      conn

    %AccessToken{error: :missing_token} ->
      handle_missing_token(conn)

    %AccessToken{error: error} when is_map(error) ->
      handle_structured_error(conn, error)

    %AccessToken{error: _reason} ->
      handle_invalid_token(conn, default_invalid_error())

    _ ->
      handle_missing_token(conn)
  end
end
```

**Existing structured-error / challenge emission to reuse (lines 86-93) — the bypass error map must carry `category: :sender_constraint` so it routes here:**
```elixir
defp handle_structured_error(conn, %{category: :sender_constraint} = error),
  do: handle_invalid_token(conn, normalize_sender_error(error))

defp handle_structured_error(conn, %{category: :insufficient_scope} = error),
  do: handle_insufficient_scope(conn, normalize_insufficient_scope_error(error))

defp handle_structured_error(conn, error),
  do: handle_invalid_token(conn, normalize_invalid_error(error))
```

**The sender-error shape to mirror — copy `EnforceSenderConstraints.sender_error/2` / `mtls_error/0` (those are the maps `normalize_sender_error/1` already consumes):**
```elixir
# from enforce_sender_constraints.ex:130-149 — the shape RequireToken already knows how to render:
%{
  category: :sender_constraint,
  challenge: challenge,            # :dpop for DPoP-bound, :bearer for mTLS-bound  (D-03 / Integration Point)
  error: "invalid_token",
  error_description: "...",
  dpop_nonce: nil                  # optional; nil is fine (normalize_sender_error reads it via Map.get)
}
```
Derive `challenge` from `binding_requirements`: `%{dpop_jkt: _}` → `:dpop`; otherwise (`%{mtls_x5t_s256: _}`) → `:bearer`. This keeps the `WWW-Authenticate` story coherent with Phase 98 (`enforce_sender_constraints.ex` uses `:dpop` for DPoP, `:bearer` for mTLS).

**403 vs 401 (load-bearing, D-03 says 403; A3/Open-Q2):** `handle_invalid_token/2` (line 48) sends **401**. `handle_insufficient_scope/2` (lines 63-84) is the in-file template that sends **403** with identical challenge-aware routing. To honor D-03's 403, add a status-explicit sender-constraint path mirroring `handle_insufficient_scope/2`'s structure but using the sender-error fields (challenge-aware `put_dpop_challenge` for `:dpop`, `www_authenticate` for `:bearer`), then `send_json(403, oauth_body(error))`. **Copy this 403 template verbatim** (lines 63-84):
```elixir
defp handle_insufficient_scope(conn, error) do
  conn =
    case error do
      %{challenge: :dpop} ->
        ProtectedResourceChallenge.put_dpop_challenge(conn, error, realm: "Lockspire")
      _other ->
        put_resp_header(conn, "www-authenticate", www_authenticate(error))
    end

  conn
  |> send_json(403, oauth_body(error))
  |> halt()
end
```
> Decision per Claude's-Discretion: a new `handle_sender_constraint_bypass/2` (403) modeled on `handle_insufficient_scope/2` is the cleanest fit. Reusing `handle_invalid_token/2` would emit 401 — acceptable to success criterion 3 ("403/401") but contrary to D-03's explicit 403.

---

### `test/integration/phase100_sender_constraint_e2e_test.exs` (NEW integration test) — D-06/07/08/09/10

**Analog:** `test/integration/phase81_generated_host_route_protection_e2e_test.exs` (read in full this session). **Lift the entire harness.** The ONE refinement (D-07): replace the hand-signed `issue_access_token/3` (`JOSE.JWT.sign`) with a real `AccessTokenSigner.issue/3` mint so the proof exercises Phase 99's `maybe_put_cnf/2` carry-through.

**Module header / setup to copy verbatim (phase81 lines 1-51):**
```elixir
defmodule Lockspire.Integration.Phase100SenderConstraintE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint
  @issuer "https://example.test/lockspire"
  @protected_route "/api/billing/summary"
  @protected_target_uri "http://api.example.test/api/billing/summary"

  import Phoenix.ConnTest
  import Plug.Conn
  # ... aliases: SigningKey, JarTestHelpers, KeyCache, DPoP, Repository ...

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64), server: false)
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, @issuer)          # MUST match Config.issuer!() so signer's iss == verifier's pin
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "profile", "email", "read:billing"])
    Application.put_env(:lockspire, :account_resolver, GeneratedHostApp.Lockspire.TestAccountResolver)
    start_supervised!(Lockspire.TestRepo)
    start_supervised!(GeneratedHostAppWeb.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})
    kid = "phase100-kid-#{System.unique_integer()}"
    signing_key = publish_signing_key(kid)
    %{signing_key: signing_key, signing_kid: kid}
  end
```

**KEY-PUBLISH HELPER — copy phase81 `publish_signing_key/1` VERBATIM (lines 257-283).** It already publishes BOTH halves (`public_jwk` for KeyCache verify + `private_jwk_encrypted` for the signer) — exactly what `AccessTokenSigner.issue/3` needs (it reads `private_jwk_encrypted` via `fetch_signing_key`, `access_token_signer.ex:196-216`):
```elixir
defp publish_signing_key(kid) do
  key = JOSE.JWK.generate_key({:rsa, 2048})
  {_fields, jwk} = JOSE.JWK.to_map(key)

  {:ok, _published_key} =
    Repository.publish_key(%SigningKey{
      kid: kid, kty: :RSA, alg: "RS256", use: "sig",
      public_jwk: jwk
        |> Map.take(["kty", "kid", "alg", "use", "n", "e"])
        |> Map.put("kid", kid) |> Map.put("alg", "RS256") |> Map.put("use", "sig"),
      private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)),
      status: :active, published_at: DateTime.utc_now(),
      activated_at: DateTime.utc_now(), metadata: %{}
    })

  send(KeyCache, :refresh)
  :sys.get_state(KeyCache)            # ⚠ MANDATORY sync point (Pitfall 2) — async refresh otherwise races sign/verify
  key
end
```
> Note: phase81 returns the `JOSE.JWK` key (used by its hand-signer). Phase 100 mints via the signer (which re-fetches the private JWK from the repo by kid), so the returned `key` is unused for signing — but keep the helper intact; the publish + KeyCache refresh is what matters.

**MINT VIA THE REAL SIGNER (the D-07 refinement — replaces phase81's `issue_access_token/3`):** Build a `%Lockspire.Domain.Token{}` with `cnf` set, plus a `%Client{}`, and call `AccessTokenSigner.issue/3`. `request` opts default `key_store` to `Config.repo!()` (TestRepo) and need no `server_policy_store` (`resolve_format` falls back to `:jwt` when nil — `access_token_signer.ex:98`).
```elixir
# BIND-01 (DPoP): cnf carries jkt
dpop_keys = JarTestHelpers.generate_ec_keys()
{:ok, jkt} = DPoP.thumbprint(dpop_keys.pub_jwk_map)

token = %Lockspire.Domain.Token{
  token_hash: "unused",                       # required no-default struct key
  token_type: :access_token,                  # required no-default struct key
  client_id: "generated-host-api-client",     # required no-default struct key
  account_id: "generated-host-user",          # → "sub"
  scopes: ["read:billing"],
  audience: ["billing-api"],                  # → LIST aud (see Pitfall 6 / A1)
  cnf: %{"jkt" => jkt},                        # ← the thing Phase 99 carries through
  issued_at: DateTime.utc_now(),
  expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)  # required no-default struct key
}

client = %Lockspire.Domain.Client{client_id: "generated-host-api-client", access_token_format: :jwt}
request = %{opts: [key_store: Lockspire.Config.repo!()]}   # server_policy_store omitted → :jwt fallback

{:ok, raw_at_jwt, _hash} = Lockspire.Protocol.AccessTokenSigner.issue(token, client, request)
```
> `base_claims/3` (`access_token_signer.ex:130-148`) reads exactly `account_id` (→sub), `audience` (via caller→aud LIST), `scopes` (→scope string), `cnf` (→`maybe_put_cnf`), `issued_at` (→iat). It sets `iss => Config.issuer!()` — that's why `setup_all` must pin `:issuer` to `@issuer`. Verified minimal `%Token{}` fields in A4.

**DPoP NONCE-RETRY DANCE — copy phase81 lines 150-215 + `generate_dpop_proof/3` (305-319) VERBATIM** (Pitfall 1: mandatory three-request shape). Swap only the token source (`raw_at_jwt` from the signer instead of the hand-signed `token`):
```elixir
# 1) proof WITHOUT nonce → 401 use_dpop_nonce + DPoP-Nonce header
challenge_conn =
  protected_conn()
  |> put_req_header("authorization", "DPoP #{raw_at_jwt}")
  |> put_req_header("dpop", generate_dpop_proof(dpop_keys.private_jwk, raw_at_jwt, nil))
  |> get(@protected_route)
assert challenge_conn.status == 401
assert [retry_nonce] = get_resp_header(challenge_conn, "dpop-nonce")

# 2) proof WITH that nonce → 200
proof = generate_dpop_proof(dpop_keys.private_jwk, raw_at_jwt, retry_nonce)
success_conn =
  protected_conn()
  |> put_req_header("authorization", "DPoP #{raw_at_jwt}")
  |> put_req_header("dpop", proof)
  |> get(@protected_route)
assert success_conn.status == 200
assert %{"access_token" => %{"binding_type" => "dpop",
         "binding_requirements" => %{"dpop_jkt" => ^jkt}}} = Jason.decode!(success_conn.resp_body)
```
`generate_dpop_proof/3` and `protected_conn/0` (host/port pin `api.example.test:80`, Pitfall 3) are copied verbatim from phase81 (305-319, 250-255).

**BIND-02 (mTLS) — genuinely new, no nonce dance.** Mint with `cnf["x5t#S256"]` derived from the same synthetic cert string presented via `conn.private[:lockspire_mtls_cert]` (`fetch_mtls_cert/2` primary path, `enforce_sender_constraints.ex:178-189`). The cert+thumbprint agreement pattern is from `enforce_sender_constraints_test.exs:192-216` and `mtls_token_binding.ex:7-17`:
```elixir
cert = "phase100-mtls-client-cert"
{:ok, x5t} = Lockspire.Protocol.MTLSTokenBinding.thumbprint(cert)

token = %Lockspire.Domain.Token{ ...same skeleton..., cnf: %{"x5t#S256" => x5t} }
{:ok, raw, _} = Lockspire.Protocol.AccessTokenSigner.issue(token, client, request)

conn =
  protected_conn()
  |> put_req_header("authorization", "Bearer #{raw}")
  |> Plug.Conn.put_private(:lockspire_mtls_cert, cert)     # primary fetch_mtls_cert path
  |> get(@protected_route)

assert conn.status == 200
assert %{"access_token" => %{"binding_type" => "mtls"}} = Jason.decode!(conn.resp_body)
```

> **A1 watch (Pitfall 6 — verify in a Wave-0 spike):** the signer emits a LIST `aud` (`["billing-api"]`); phase81's hand-signed happy path used a STRING `aud`. Confirm `VerifyToken`'s audience matcher accepts a list before relying on it. The router declares `audience: "billing-api"` (string) on the plug — `test/support/generated_host_app_web/router.ex:20`. If list-aud fails the matcher, fall back to a single-element list the matcher unwraps, or escalate. Phase 98 hardening makes list-aud acceptance very likely.

---

### `test/lockspire/plug/require_token_test.exs` (ADD plug-unit clauses, D-10 negative) — BIND-03 runtime

**Analog:** self. The existing pass-through test (lines 14-22) and the structured sender-constraint tests (69-96) are the templates. Add two clauses: bound-but-unverified → 403 halted; bearer (unbound) → still passes.

**Pass-through template to mirror for the bearer-still-passes assertion (lines 14-22):**
```elixir
test "allows request to proceed if valid AccessToken is assigned" do
  conn =
    build_conn()
    |> assign(:access_token, %AccessToken{error: nil, claims: %{"sub" => "123"}})
    |> RequireToken.call([])

  refute conn.halted
  assert conn.status == nil
end
```

**Sender-constraint challenge-assertion template (lines 69-96) — for asserting the 403 fail-closed challenge shape:**
```elixir
test "halts with DPoP-aware challenge for typed sender-constraint failures" do
  conn =
    build_conn()
    |> assign(:access_token, %AccessToken{error: %{category: :sender_constraint, challenge: :dpop, ...}})
    |> RequireToken.call([])

  assert conn.halted
  [challenge] = get_resp_header(conn, "www-authenticate")
  assert challenge =~ "DPoP realm=\"Lockspire\""
  assert challenge =~ "error=\"invalid_token\""
end
```

**New clauses to add (synthesized — Code Example, RESEARCH lines 363-376):**
```elixir
test "bound-but-unverified token fails closed with 403 (BIND-03)" do
  bound = %AccessToken{error: nil, claims: %{"sub" => "u"},
                       binding_requirements: %{dpop_jkt: "x"}, binding_verified: false}
  conn = build_conn() |> assign(:access_token, bound) |> RequireToken.call([])
  assert conn.halted
  assert conn.status == 403                              # D-03
  [challenge] = get_resp_header(conn, "www-authenticate")
  assert challenge =~ "DPoP realm=\"Lockspire\""         # DPoP-bound → :dpop challenge
end

test "bearer (unbound) token still passes through — surprise-free guarantee (BIND-03)" do
  bearer = %AccessToken{error: nil, claims: %{"sub" => "u"}, binding_requirements: nil}
  conn = build_conn() |> assign(:access_token, bearer) |> RequireToken.call([])
  refute conn.halted
  assert conn.status == nil
end
```
> Add an mTLS-bound variant asserting a `Bearer realm="Lockspire"` challenge (`binding_requirements: %{mtls_x5t_s256: "x"}`) to cover both challenge branches. The `build_conn/0` helper already exists in this file (line 9).

---

### `test/lockspire/plug/enforce_sender_constraints_test.exs` (ADD positive assertions, D-02) — BIND-03 positive

**Analog:** self. The three existing success-path tests already build the exact fixtures. ADD a `binding_verified == true` assertion to each, and confirm the no-op path leaves it `false`.

**DPoP success test to extend (lines 57-80) — add the assertion after the existing `error: nil` check:**
```elixir
test "accepts DPoP-bound tokens only with matching scheme proof ath and key" do
  %{proof: proof, jkt: jkt} = dpop_fixture()
  access_token = %AccessToken{token: @raw_access_token, authorization_scheme: "DPoP",
    binding_type: "dpop", binding_requirements: %{dpop_jkt: jkt}, claims: %{"sub" => "123"}}
  conn = request_conn() |> put_req_header("dpop", proof) |> assign(:access_token, access_token)
         |> EnforceSenderConstraints.call(dpop_replay_store: AcceptingReplayStore, dpop_max_age: 300, now: fn -> @now end)

  assert %AccessToken{error: nil} = conn.assigns.access_token
  assert conn.assigns.access_token.binding_verified == true          # ← D-02 ADD
  refute conn.halted
end
```

**mTLS success (lines 192-216, `put_private(:lockspire_mtls_cert, "mtls-cert")` + `MTLSTokenBinding.thumbprint/1`) and dual-bound success (236-270) — add the same `binding_verified == true` assertion to each `%AccessToken{error: nil}` success arm.**

**No-op path stays false (lines 33-43) — add the negative assertion:**
```elixir
test "passes through unconstrained access tokens unchanged" do
  access_token = %AccessToken{token: "plain", claims: %{"sub" => "123"}}
  conn = conn(:get, "/resource") |> assign(:access_token, access_token) |> EnforceSenderConstraints.call([])
  assert conn.assigns.access_token == access_token                   # default false preserved (== checks whole struct)
  assert conn.assigns.access_token.binding_verified == false         # ← D-02: unbound path never sets it
  refute conn.halted
end
```
> `dpop_fixture/2` (lines 279-311) is the DPoP-proof factory; reuse as-is. The `request_conn/0` helper pins scheme/host/port (272-277).

---

### `test/lockspire/access_token_test.exs` (UPDATE defaults test, D-01) — BIND-03 struct default

**Analog:** self. The defaults test enumerates the 7 existing fields (lines 7-17). Add one assertion for the new field. This is the ONLY existing test that *must* change for D-01 (Pitfall 5).

**Existing defaults test (lines 7-17):**
```elixir
test "defaults all fields to nil" do
  token = %AccessToken{}
  assert token.token == nil
  assert token.claims == nil
  assert token.client_id == nil
  assert token.authorization_scheme == nil
  assert token.binding_type == nil
  assert token.binding_requirements == nil
  assert token.error == nil
end
```

**Pattern to apply:** Add `assert token.binding_verified == false` (NOT `== nil` — the fail-closed default is `false`). Consider renaming the test or adding a comment since "defaults all fields to nil" is now inaccurate for this one field. The `allows setting fields` test (19-37) may optionally set `binding_verified: true` to round out coverage.
```elixir
  assert token.error == nil
  assert token.binding_verified == false        # ← D-01: non-nil fail-closed default
```

---

### `test/lockspire/release_readiness_contract_test.exs` (ADD ordering clause, D-05) — BIND-03 contract

**Analog:** self — the audience-substring clause (lines 761-791) is the structural twin: same four-file `{path, kind}` iteration, same `extract_canonical_pipeline!/2` call, same per-file assertion loop. The four path attributes already exist (lines 71-92). **All four blocks already order Verify→Enforce→Require, so this clause passes against current content and does NOT ripple the content hash** (D-05).

**Reuse the four-file iteration + extraction helper VERBATIM (audience clause, lines 761-770):**
```elixir
files = [
  {@protect_phoenix_api_routes_path, :elixir_in_markdown_fence},
  {@adoption_demo_router_path, :elixir},
  {@install_template_router_path, :elixir_in_commented_heredoc},
  {@adoption_smoke_script_path, :python_commented}
]

for {path, kind} <- files do
  bytes = extract_canonical_pipeline!(path, kind)
  # ... ordering assertion ...
end
```

**`extract_canonical_pipeline!/2` (lines 140-157) is the SINGLE extraction path — do NOT add a parallel one (D-05).** It reads the `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` markers and normalizes per `kind`.

**Ordering assertion (Claude's discretion — offset comparison; RESEARCH Code Example lines 381-397):** Assert `VerifyToken` byte offset < `EnforceSenderConstraints` offset < `RequireToken` offset over the normalized block.
```elixir
test "all four RECIPE-01 sites order VerifyToken → EnforceSenderConstraints → RequireToken (BIND-03/D-05)" do
  files = [ ...the four tuples above... ]

  for {path, kind} <- files do
    bytes = extract_canonical_pipeline!(path, kind)
    v = byte_offset(bytes, "Lockspire.Plug.VerifyToken")
    e = byte_offset(bytes, "Lockspire.Plug.EnforceSenderConstraints")
    r = byte_offset(bytes, "Lockspire.Plug.RequireToken")
    assert v < e and e < r,
           "canonical pipeline in #{Path.relative_to_cwd(path)} must order Verify→Enforce→Require"
  end
end
```
> **Load-bearing gap:** there is NO existing `byte_offset/2` helper in this file (grepped — confirmed absent). The executor must add a tiny private helper, e.g.:
> ```elixir
> defp byte_offset(bytes, needle) do
>   case :binary.match(bytes, needle) do
>     {start, _len} -> start
>     :nomatch -> flunk("expected #{needle} in canonical pipeline block")
>   end
> end
> ```
> A `~s` multiline-regex alternative (RESEARCH allows either) is acceptable provided it genuinely fails if Enforce/Require are transposed (anti-cheat lens). The offset approach is simpler and self-evidently correct.

---

## Shared Patterns

### The cross-plug `binding_verified` breadcrumb (D-01/D-02/D-03)
**Source:** new field on `lib/lockspire/access_token.ex` (D-01), written by `enforce_sender_constraints.ex` (D-02), read by `require_token.ex` (D-03).
**Apply to:** all three runtime files, in this order — struct field first (others depend on it), then enforcer, then guard.
**Contract:** default `false` (fail-closed); set `true` ONLY on binding-validated success; the guard fires ONLY when `error: nil AND binding_requirements != nil AND binding_verified == false`. The `error: nil` gate is non-negotiable (Pitfall 4: prevents intercepting the `verify_token_test.exs:947-1037` error-carrying bound tokens — verified those all carry `error != nil` and never reach the guarded clause).

### KeyCache publish-then-sign recipe (D-09)
**Source:** `phase81_...e2e_test.exs:257-283` (`publish_signing_key/1`); equivalently `verify_token_test.exs:39-91` (`generate_key_and_token/2`); `access_token_signer_test.exs:21-31` (`MockKeyStore`).
**Apply to:** the new integration test's `setup` (both BIND-01 and BIND-02 share one published key).
**Recipe (verbatim):** `JOSE.JWK.generate_key({:rsa, 2048})` → `Repository.publish_key(%SigningKey{... public_jwk ... private_jwk_encrypted ... status: :active})` → `send(KeyCache, :refresh)` → **`:sys.get_state(KeyCache)`** (mandatory sync; Pitfall 2). Both JWK halves required: public for `VerifyToken` (KeyCache), private for `AccessTokenSigner.issue/3` (repo fetch).
**Code excerpt:** see the `publish_signing_key/1` block under the integration-test assignment above.

### Sender-constraint error map + WWW-Authenticate emission (D-03 ↔ Phase 98 taxonomy)
**Source:** `enforce_sender_constraints.ex:130-149` (`sender_error/2`, `mtls_error/0`) produces the maps; `require_token.ex:86-93,95-103,48-61,148-159` (`handle_structured_error`/`normalize_sender_error`/`handle_invalid_token`/`www_authenticate`) renders them; `ProtectedResourceChallenge.put_dpop_challenge/3` emits the DPoP challenge.
**Apply to:** the D-03 guard error map (`require_token.ex`) and its plug-unit assertions (`require_token_test.exs`).
**Contract:** `category: :sender_constraint`, `challenge: :dpop` (DPoP-bound) | `:bearer` (mTLS-bound), `error: "invalid_token"`. Routing through `handle_structured_error/2` reuses the Phase 98 challenge formatting (DPoP gets `algs=`, etc.) — do not hand-roll a new formatter (Don't-Hand-Roll table).

### Binding-thumbprint primitives (BIND-01 jkt / BIND-02 x5t#S256)
**Source:** `DPoP.thumbprint/1` (jkt from public DPoP JWK); `MTLSTokenBinding.thumbprint/1` (`mtls_token_binding.ex:7-17`, `x5t#S256` from cert string); `DPoP.access_token_ath/1` (ath binding the proof to the token).
**Apply to:** the integration test token minting (derive `cnf` values) and proof building.
**Contract:** the presented cert/key and the token's `cnf` value MUST be derived from the SAME source so `confirmation_matches?/2` (`mtls_token_binding.ex:22-29`) / DPoP `jkt` match succeed. Never hand-roll the SHA-256 (Don't-Hand-Roll table).

---

## No Analog Found

None. Every file Phase 100 touches has an exact in-repo analog (self-extension for 7 of 8; phase81 lift for the new integration test). This is a verification/proof phase — all primitives already exist and are tested.

## Anti-Patterns to Avoid (from RESEARCH; restated for the executor)

- **Hand-signing the BIND-01/02 JWT with `JOSE.JWT.sign`** (phase81's `issue_access_token/3` shape). Proves only the plug chain, not Phase 99's `cnf` carry-through. D-07 forbids it — mint via `AccessTokenSigner.issue/3`.
- **Writing the D-03 guard without the `error: nil` gate.** Would intercept the `verify_token_test.exs:947-1037` error-carrying bound tokens and break green tests (Pitfall 4).
- **Clearing `binding_requirements` as the verified signal** (D-04 forbids — the host controller `ProtectedApiController.show/2` reads it, lines 21).
- **Setting `binding_verified: true` on the unbound no-op path** (`enforce_sender_constraints.ex:62-63` `_other -> conn`). Only binding-validated successes get the breadcrumb (D-02).
- **Omitting `:sys.get_state(KeyCache)` after `send(KeyCache, :refresh)`** (Pitfall 2 — async refresh races sign/verify → flaky unknown-kid `invalid_token`).
- **Skipping the DPoP nonce-retry dance** (Pitfall 1 — single proof without nonce → `401 use_dpop_nonce`, never `200`).
- **Adding a parallel canonical-pipeline extraction path in the contract test** (D-05 — reuse `extract_canonical_pipeline!/2`).

## Metadata

**Analog search scope:** `lib/lockspire/` (access_token, plug/*, protocol/*, domain/*), `test/lockspire/plug/`, `test/lockspire/protocol/`, `test/integration/`, `test/support/generated_host_app_web/`, `test/lockspire/release_readiness_contract_test.exs`.
**Files scanned (read this session):** 17 source/test files + 3 targeted greps. All cited anchors re-verified live against the tree.
**Anchor drift observed (cosmetic, non-material):** `require_token.ex` call clauses are at 19-36 (RESEARCH/CONTEXT cited 20-35); `enforce_sender_constraints.ex` mtls success body at 116-118; `confirmation_matches?/2` fallthrough at 29 (cited 22-27). No `byte_offset/2` helper exists in the contract test (must be added — flagged above).
**Pattern extraction date:** 2026-05-28
