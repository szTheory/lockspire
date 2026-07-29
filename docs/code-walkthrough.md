# Lockspire Code Walkthrough

This guide begins where the [architecture guide](architecture.md) stops. The
architecture guide names the boundaries; this one follows values through the
code that enforces them.

Hold one route in your head:

```text
request parameters
  -> validated authorization value
  -> durable interaction
  -> hashed authorization code
  -> bound token exchange
  -> access and refresh records
  -> row-locked refresh family
```

The excerpts below are copied from current source and shortened. Every deliberate
cut is marked with `# ...`. Internal modules and private functions are shown to
explain the design; they are not promises of public API. The public ceiling
remains the [supported surface](supported-surface.md).

## Boot: host configuration becomes runtime mechanics

Lockspire is a library application, but it is not passive. The host supplies the
repository, account resolver, issuer, mount, prefixes, and Oban configuration.
`Lockspire.Config` turns missing or unsafe values into early failures.
`Lockspire.Application` starts only Lockspire-owned runtime children.

```elixir
def issuer! do
  issuer = fetch_required!(:issuer)
  mount_path = mount_path()
  signing_alg = Application.get_env(@app, :signing_alg, "RS256")

  Policy.validate_issuer_and_mount_path!(issuer, mount_path)
  Policy.validate_signing_alg!(signing_alg)

  issuer
end

def start(_type, _args) do
  children = [
    {Lockspire.Oban, Lockspire.Oban.runtime_config!()},
    Cachex.child_spec(name: :lockspire_jwks_cache),
    Lockspire.KeyCache
  ]

  Supervisor.start_link(children, strategy: :one_for_one, name: Lockspire.Supervisor)
end
```

The repository and Phoenix endpoint remain host processes. Lockspire supervises
its named Oban runtime and key caches. That is the embedded shape in OTP terms:
shared host infrastructure, separately owned protocol workers.

Configuration is read when a protocol boundary needs it, and the install
verifier probes the full required set. Invalid issuer/mount combinations and
forbidden signing algorithms fail before a request can become partial protocol
state.

## Install: generated files get owners

`Lockspire.Generators.Install` renders both ownership classes, but the manifest
receives only managed templates. `plan/1` is a side-effect-free classification
pass: it never writes, and it classifies the manifest itself alongside the
twelve rendered destinations, so `apply_plan!/3` has one write/print path --
including the `--dry-run` label swap -- for all thirteen destinations.

```elixir
def plan(assigns) do
  rendered_templates = rendered_templates(assigns)
  # ... classify_destination/3 for each of the twelve rendered destinations

  managed_templates =
    rendered_templates
    |> Enum.filter(&(&1.template.ownership == :managed))

  manifest_rendered = build_manifest_rendered(assigns, managed_templates)

  case classify_destination(manifest_rendered, %{}, expanded_root) do
    {:conflict, reason} = outcome ->
      {[{manifest_rendered, outcome} | classified], [{manifest_rendered, reason} | conflicts]}

    outcome ->
      {[{manifest_rendered, outcome} | classified], conflicts}
  end
end
```

Unchanged reruns and overwrite refusal read the same way for every managed
file, including the manifest: `classify_destination/3` compares current bytes
against freshly rendered bytes and never writes. That filter is the upgrade
boundary. The generated account, interaction, consent, device, and product UX
modules remain host-owned even though Lockspire created their first version.

`Lockspire.Install.Verify` then checks the assembled application rather than
assuming generation was enough:

```elixir
def run(opts \\ []) do
  router = Keyword.fetch!(opts, :router)
  resolver_module = Keyword.fetch!(opts, :resolver_module)
  interaction_handler_module = Keyword.fetch!(opts, :interaction_handler_module)
  repo = Keyword.get(opts, :repo, Lockspire.Config.repo!())
  mount_path = Keyword.get(opts, :mount_path, Lockspire.Config.mount_path())

  checks = [
    config_check(),
    seam_modules_check(resolver_module, interaction_handler_module),
    router_check(router, mount_path),
    migrations_check(repo)
  ]

  %{ok?: Enum.all?(checks, &(&1.status == :ok)), checks: checks}
end
```

The router check is deliberately order-aware: the guarded admin forward must
precede the public Lockspire forward. The migration check covers both the
protocol tables and the named Oban runtime in their configured prefixes.

**Test lens — generated ownership.** The install-generator integration tests
assert the manifest contains managed config, router, and smoke-test files but
not the account resolver. They also prove unchanged reruns and overwrite
refusal. `Lockspire.Install.VerifyTest` covers missing `/verify` routes, a missing
admin guard, and public-forward shadowing.

## Mount: web delivery stays thin

`Lockspire.Web.Router` makes the endpoint topology visible. Most routes enter a
small controller. The ordinary authorization, token, and userinfo routes share
the FAPI boundary so resolved client/server policy can make stricter profiles
mandatory without creating a second router.

```elixir
pipeline :fapi_boundary do
  plug(Lockspire.Protocol.FAPI20EnforcerPlug)
end

scope "/" do
  get("/.well-known/openid-configuration", Lockspire.Web.DiscoveryController, :show)
  get("/jwks", Lockspire.Web.JwksController, :index)
  post("/par", Lockspire.Web.PushedAuthorizationRequestController, :create)
  post("/revoke", Lockspire.Web.RevocationController, :create)
  post("/introspect", Lockspire.Web.IntrospectionController, :create)
  # ...
  scope "/" do
    pipe_through(:fapi_boundary)

    get("/authorize", Lockspire.Web.AuthorizeController, :show)
    post("/token", Lockspire.Web.TokenController, :create)
    get("/userinfo", Lockspire.Web.UserinfoController, :show)
  end
end
```

The router tells you where a value enters. The protocol coordinator tells you
what it means.

## Cross the host seam

The host boundary is expressed as values, not callbacks that can mutate
Lockspire internals. `Lockspire.Host.AccountResolver` receives a connection-like
value and a `Lockspire.Host.Context`; it returns a host account, claims, or an
interaction handoff.

```elixir
@callback resolve_current_account(conn_or_socket :: connection(), context()) ::
            {:ok, account()} | {:redirect, InteractionResult.t()}

@callback resolve_account(account_reference :: term(), context()) ::
            {:ok, account()} | {:error, :not_found | term()}

@callback build_claims(account(), context()) ::
            {:ok, Claims.t()} | {:error, term()}

def build_id_token_claims(%__MODULE__{} = claims, protocol_claims) do
  claims.id_token
  |> Map.drop(@protocol_claims)
  |> Map.put("sub", claims.subject)
  |> Map.merge(protocol_claims)
  |> drop_nil_claims()
end
```

Notice the merge order. Host-provided claim maps cannot replace protocol claims
such as `iss`, `aud`, `exp`, `nonce`, `auth_time`, `sub`, or `sid`. The host is
authoritative for source data; Lockspire is authoritative for the token's
protocol envelope.

The generated resolver's explanatory exception currently shows a stale
`%Claims{claims: ...}` illustration. The real struct has `subject`, `id_token`,
and `userinfo` fields, as the code above shows.

## Validate before involving a person

`Lockspire.Web.AuthorizeController.show/2` has three top-level outcomes. It asks
the host for a subject only after `Lockspire.Protocol.AuthorizationRequest`
returns a canonical validated value.

```elixir
def show(conn, params) do
  case AuthorizationRequest.validate(params) do
    {:ok, %Validated{} = validated} ->
      with {:ok, subject_context} <- resolve_subject_context(conn, validated),
           outcome <-
             AuthorizationFlow.start_authorization(
               validated,
               subject_context,
               protocol_store_opts()
             ) do
        handle_authorization_outcome(conn, outcome)
      else
        {:error, %Error{} = error} ->
          render_browser_error(conn, error, :internal_server_error)
      end

    {:browser_error, %Error{} = error} ->
      render_browser_error(conn, error, :bad_request)

    {:redirect_error, %Error{} = error} ->
      redirect(conn, external: redirect_location(error))
  end
end
```

Browser-safe and redirect-safe errors are different types because an OAuth
error redirect is itself a security decision. `validate_redirect_uri/2` must
succeed before later validation can trust the URI.

```elixir
defp validate_redirect_uri(client, %{"redirect_uri" => redirect_uri})
     when is_binary(redirect_uri) and redirect_uri != "" do
  if redirect_uri in client.redirect_uris do
    {:ok, redirect_uri}
  else
    {:browser_error,
     browser_error(
       :invalid_request,
       "redirect_uri must match a registered URI",
       :invalid_redirect_uri
     )}
  end
end

# ... the S256-specific acceptance clause runs before this fallback

defp validate_pkce(client, params, opts) do
  security_profile = Keyword.get(opts, :security_profile, %SecurityProfile.Resolved{})

  cond do
    security_profile.fapi_2_0_security? ->
      {:redirect_error,
       redirect_error(params, :invalid_request, "PKCE S256 is required", :missing_pkce)}

    client.pkce_required ->
      {:redirect_error,
       redirect_error(params, :invalid_request, "PKCE S256 is required", :missing_pkce)}

    true ->
      :ok
  end
end
```

The exact membership check is the entire redirect-matching policy. No URI
normalizer repairs a slash or query string. The preceding S256-specific clause,
omitted here, accepts only a valid S256 challenge; this fallback rejects a
missing or different method when policy requires PKCE.

## Turn browser work into durable state

`Lockspire.Protocol.AuthorizationFlow.start_authorization/3` decides whether
the request can run silently, must enter host login, or can proceed with the
current subject.

```elixir
def start_authorization(%Validated{} = validated, subject_context, opts \\ []) do
  now = now(opts)
  interaction_id = generate_interaction_id(opts)

  cond do
    silent_prompt?(validated.prompt) ->
      start_silent_authorization(validated, subject_context, interaction_id, now, opts)

    login_required?(validated, subject_context, now) ->
      validated
      |> build_interaction(interaction_id, nil, :pending_login, now)
      |> persist_login_required(opts)

    true ->
      start_subject_authorization(validated, subject_context, interaction_id, now, opts)
  end
end
```

The value crossing into persistence is a `Lockspire.Domain.Interaction`. It
contains the exact redirect URI, requested scopes/resources, state, nonce, PKCE
challenge, response mode, subject and authentication time when known, and one of
five statuses: pending login, pending consent, completed, denied, or expired.

Approval is a guarded transition. The expected status is passed to storage, so
two browser submissions cannot both complete the interaction. Consent and the
authorization code are created inside the same audited operation.

```elixir
defp issue_authorization_code(%Interaction{} = interaction, subject_id, consent_grant_id, opts) do
  raw_code = generate_code(opts)
  now = now(opts)
  token_hash = Policy.hash_token(raw_code)

  token = %Token{
    token_hash: token_hash,
    token_type: :authorization_code,
    client_id: interaction.client_id,
    account_id: subject_id,
    interaction_id: interaction.interaction_id,
    consent_grant_id: consent_grant_id,
    sid: interaction.sid,
    redirect_uri: interaction.redirect_uri,
    scopes: interaction.scopes_requested,
    audience: interaction.resources_requested,
    code_challenge: interaction.code_challenge,
    code_challenge_method: interaction.code_challenge_method,
    issued_at: now,
    expires_at: DateTime.add(now, @authorization_code_ttl, :second)
  }

  with {:ok, stored_token} <- token_store(opts).store_token(token) do
    emit(:authorization_code, :issued, interaction, subject_id, %{token_id: stored_token.id})
    approval_redirect(interaction, raw_code, opts)
  end
end
```

Plaintext and durable state split at `raw_code`/`token_hash`. The redirect gets
the former. PostgreSQL gets the latter plus every binding needed at redemption.

**Test lens — interaction state.**
`Lockspire.Protocol.AuthorizationFlowTest` proves login and consent states are
durable, remembered consent is scope-bounded, `prompt=none` does not invoke UI,
approval stores only a hash, and expired or duplicate completion fails. Its
audit assertions are part of the state-machine contract, not incidental logging.

## Redeem the authorization code

`Lockspire.Web.TokenController` packages form parameters, client authorization,
DPoP proof, HTTP method, mTLS certificate context, secret-key base, and storage
implementations into a request map for `Lockspire.Protocol.TokenExchange`. It
also enforces `no-store` and `no-cache` on both success and failure responses.

Grant dispatch happens before grant-specific work, but authorization-code
exchange has a strict sequence: authenticate the client, resolve DPoP context,
load the code by hash, check activity, then check every original binding.

```elixir
defp validate_code_binding(%Client{} = client, %Token{} = authorization_code, params) do
  with :ok <- validate_client_binding(client, authorization_code),
       :ok <- validate_redirect_uri_binding(authorization_code, params) do
    validate_pkce_binding(authorization_code, params)
  end
end

defp validate_redirect_uri_binding(%Token{} = authorization_code, params) do
  redirect_uri = normalize_optional_string(params["redirect_uri"])

  if redirect_uri == authorization_code.redirect_uri do
    :ok
  else
    {:error,
     invalid_grant(
       "redirect_uri does not match the issued authorization code",
       :redirect_uri_mismatch
     )}
  end
end
```

The PKCE check hashes the presented verifier and compares it with the stored
challenge. Resource Indicators are checked against the authorized audience,
not treated as a chance to broaden it.

After token construction, redemption and persistence move together with the
durable audit event:

```elixir
defp persist_authorization_code_grant(
       code_hash,
       issued_at,
       %Token{} = access_token,
       %Token{} = authorization_code,
       nil,
       _issuance_context,
       request
     ) do
  audit_event =
    redemption_audit_event(client_actor(authorization_code.client_id), authorization_code)

  case transact_with_audit_event(token_store(request), audit_event, fn ->
         token_store(request).redeem_authorization_code(code_hash, issued_at, access_token)
       end) do
    {:ok, %{access_token: %Token{} = persisted_access_token}} ->
      {:ok, %{access_token: persisted_access_token}}

    {:error, reason} ->
      {:error, reason}
  end
end
```

The branch that also creates a refresh token wraps code redemption and initial
family persistence in the same outer transaction. This prevents a consumed code
from being committed without the token set the response claims to have issued.

## Sign, format, and forget plaintext

`Lockspire.Protocol.AccessTokenSigner` is the shared access-token issuance
boundary. Client policy may choose JWT or opaque format. In the JWT branch, the
active server key supplies `alg` and `kid`; client input never does.

```elixir
defp sign_jwt(claims, request) do
  with {:ok, %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}} <-
         fetch_signing_key(request),
       {:ok, jwk_map} <- decode_private_jwk(private_jwk) do
    {_, compact} =
      JOSE.JWT.sign(
        JOSE.JWK.from_map(jwk_map),
        %{"alg" => alg, "kid" => kid, "typ" => "at+jwt"},
        claims
      )
      |> JOSE.JWS.compact()

    {:ok, compact, Policy.hash_token(compact)}
  else
    {:error, reason} ->
      Logger.error("Failed to sign access token: #{inspect(reason)}")

      {:error,
       %Error{
         status: 500,
         error: "server_error",
         error_description: "Unable to sign access token.",
         reason_code: :token_signing_failed
       }}
  end
end

def hash_token(token) when is_binary(token) do
  :sha256 |> :crypto.hash(token) |> Base.encode16(case: :lower)
end
```

The raw compact JWT or opaque random value returns to the caller. The durable
record is re-pointed to the hash of the exact wire token. Authorization codes,
refresh tokens, opaque access tokens, and client secrets follow the same bounded
plaintext principle at their respective issuance edges.

**Test lens — code binding and issuance.**
`Lockspire.Protocol.TokenExchangeTest` covers client, redirect, verifier, expiry,
and replay failures; JWT and opaque formats; ID-token conditions; refresh-family
creation; DPoP binding; hashes at rest; and durable audit rows. The phase-three
OIDC lifecycle integration test drives the matching behavior through HTTP.

## Storage makes atomicity explicit

The protocol depends on a behavior, not Ecto calls scattered through every
coordinator. The important callbacks state which compound operations must be
atomic.

```elixir
@callback redeem_authorization_code(String.t(), DateTime.t(), Token.t()) ::
            {:ok, %{authorization_code: Token.t(), access_token: Token.t()}}
            | {:error, store_error()}

@callback rotate_refresh_token(
            String.t(),
            String.t(),
            DateTime.t(),
            Token.t(),
            Token.t(),
            expected_cnf()
          ) ::
            {:ok,
             %{
               presented_refresh_token: Token.t(),
               refresh_token: Token.t(),
               access_token: Token.t()
             }}
            | {:error, store_error()}
```

`Lockspire.Storage.Ecto.Repository` implements code redemption by locking the
credential row before changing it and inserting the access token.

```elixir
def redeem_authorization_code(token_hash, redeemed_at, %Token{} = access_token)
    when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
  transact(fn ->
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :authorization_code)
    |> lock("FOR UPDATE")
    |> repo_one(sensitive: true)
    |> redeem_authorization_code_record(redeemed_at, access_token)
  end)
end
```

The `sensitive: true` path controls inspection and query logging around token
records. The lock controls concurrency. The transaction controls contradictory
durable outcomes.

## Rotate a refresh family atomically

`Lockspire.Protocol.RefreshExchange` hashes the presented token, validates its
client/resource/sender context, constructs child values, and delegates the
family mutation to the store. It interprets reuse as a durable denial rather
than a generic lookup failure.

```elixir
# ... access and refresh token values have been constructed

case store.rotate_refresh_token(
       refresh_token_hash,
       client.client_id,
       rotated_at,
       refresh_token,
       access_token,
       expected_cnf
     ) do
  {:ok,
   %{
     presented_refresh_token: %Token{} = presented,
     refresh_token: %Token{} = persisted_refresh_token,
     access_token: %Token{}
   } = success} ->
    {:ok, success, [refresh_rotation_audit_event(client, presented, persisted_refresh_token)]}

  {:error, :reuse_detected} ->
    {:durable_error,
     invalid_grant(
       "Refresh token reuse detected; the token family has been revoked",
       :refresh_token_reuse_detected
     ), reuse_audit_events(client, presented_refresh_token)}

  {:error, reason} ->
    {:error, refresh_rotation_error(reason)}
end

# ... the audited transaction maps the durable outcome to an OAuth response
```

The repository transaction locks the presented family member. The state of that
one row decides between ordinary rotation and containment. These helpers show
the serialization point and the two pieces of reuse evidence written by the
reuse branch:

```elixir
defp locked_refresh_token_query(token_hash) do
  TokenRecord
  |> where([token], token.token_hash == ^token_hash)
  |> where([token], token.token_type == :refresh_token)
  |> lock("FOR UPDATE")
end

defp mark_refresh_token_reuse(%TokenRecord{} = record, detected_at, updated_at) do
  record
  |> Ecto.Changeset.change(
    reuse_detected_at: record.reuse_detected_at || detected_at,
    updated_at: updated_at
  )
  |> repo_update(sensitive: true)
  |> map_one(&TokenRecord.to_domain/1)
end

defp revoke_token_family_records(family_id, revoked_at, updated_at) do
  {count, _records} =
    TokenRecord
    |> where([token], token.family_id == ^family_id)
    |> repo_update_all(
      [set: [revoked_at: revoked_at, updated_at: updated_at]],
      [sensitive: true],
      inc: []
    )

  {:ok, count}
rescue
  error -> {:error, error}
end
```

The coordinator excerpt omits the construction around the store call. On reuse,
the repository branch records `reuse_detected_at`, revokes active family
members, appends reuse and family-revocation audit events, and commits before
returning `invalid_grant`.

**Test lens — concurrency and containment.**
`Lockspire.Protocol.RefreshExchangeTest` proves normal child generation,
preserved `cnf`, no mutation on binding mismatch, ancestor replay, family-wide
revocation, and explicit audit reason codes. The repository assertions are what
make the coordinator's security claim credible.

## Observe without leaking

Operational telemetry and durable audit evidence take different paths.
`Lockspire.Observability` redacts metadata before emitting both the ordinary and
audit-prefixed telemetry events. `Lockspire.Audit.Event` separately normalizes
records that storage can commit.

```elixir
def emit(entity, action, measurements, metadata) do
  redacted_metadata = redact(metadata)
  normalized_measurements = Map.put_new(measurements, :count, 1)

  :telemetry.execute(
    @audit_prefix ++ [entity, action],
    normalized_measurements,
    redacted_metadata
  )

  :telemetry.execute(
    @telemetry_prefix ++ [entity, action],
    normalized_measurements,
    redacted_metadata
  )

  :ok
end

def normalize(%__MODULE__{} = event) do
  %__MODULE__{
    event
    | metadata: event.metadata |> Redaction.for_audit() |> compact_metadata()
  }
end
```

The `[:lockspire, :audit, ...]` name is still a telemetry event. A persisted
`Lockspire.Audit.Event` is durable incident evidence. Both redact raw tokens,
secrets, verifier material, request bodies, and other unsafe values; telemetry
also replaces refresh family IDs with correlation handles.

## A secondary boundary: protect a host API

The resource-server route repeats the same separation of protocol truth and
product policy. The order is intentional:

```elixir
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken,
    scopes: ["read:billing"],
    audience: "https://api.example.test/billing",
    enforce_audience: true

  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore

  plug Lockspire.Plug.RequireToken
end
```

`VerifyToken` establishes signature or opaque-token facts and applies route
scope/audience restrictions. `EnforceSenderConstraints` proves DPoP or mTLS
binding. `RequireToken` fails closed if a bound token reaches it without verified
binding. Only after that does host code decide tenant membership, object access,
plan limits, or another business rule. The task-level contract lives in
[Protect Phoenix API routes](protect-phoenix-api-routes.md).

## Next source-reading sessions

Each route below has one question. Stop when you can answer it from the source
and its focused tests.

1. **Why may this browser redirect happen?** Read
   `Lockspire.Web.AuthorizeController`, `Lockspire.Protocol.AuthorizationRequest`,
   then `Lockspire.Protocol.AuthorizationFlow` alongside
   `Lockspire.Protocol.AuthorizationFlowTest`.
2. **Can code redemption leave partial state?** Read
   `Lockspire.Web.TokenController`, `Lockspire.Protocol.TokenExchange`,
   `Lockspire.Storage.TokenStore`, and the narrow authorization-code functions in
   `Lockspire.Storage.Ecto.Repository`; compare
   `Lockspire.Protocol.TokenExchangeTest`.
3. **What happens when two presenters use one refresh generation?** Read
   `Lockspire.Protocol.RefreshExchange`, the row-locked refresh functions in
   `Lockspire.Storage.Ecto.Repository`, and
   `Lockspire.Protocol.RefreshExchangeTest`.
4. **Which generated files may an upgrade replace?** Read
   `Lockspire.Generators.Templates`, `Lockspire.Generators.Install`,
   `Lockspire.Install.Manifest`, and `Lockspire.Install.Verify`; then read the
   install-generator and verifier integration tests.
5. **Where does a protected request become host policy?** Read
   `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and
   `Lockspire.Plug.RequireToken`, then the host route that runs after the
   pipeline.
6. **How does an advanced grant reuse the core?** Start at the matching web
   controller, follow its protocol coordinator to its domain record and storage
   behavior, and find where it converges on token issuance and audit evidence.

Return to the [architecture guide](architecture.md) when you need the larger
ownership map, and to the [supported surface](supported-surface.md) before
treating any readable internal module as a compatibility promise.
