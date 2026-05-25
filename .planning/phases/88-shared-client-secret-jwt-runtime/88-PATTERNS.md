# Phase 88: Shared `client_secret_jwt` Runtime - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 5 planned work items
**Primary analogs:** 5 / 5

## File Classification

| Planned File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/client_auth.ex` | service | request-response | `lib/lockspire/protocol/client_auth.ex` | exact |
| `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` | service | request-response | `lib/lockspire/protocol/client_auth/private_key_jwt.ex` | role-match |
| `test/lockspire/protocol/client_auth_test.exs` | test | request-response | `test/lockspire/protocol/client_auth_test.exs` | exact |
| `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` | test | request-response | `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` | role-match |
| `test/lockspire/audit/event_test.exs` | test | transform | `test/lockspire/audit/event_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/protocol/client_auth.ex`

**Analog:** `lib/lockspire/protocol/client_auth.ex`

**Routing shape to preserve** (`lib/lockspire/protocol/client_auth.ex:36-45`):
```elixir
def authenticate(params, authorization, opts) when is_map(params) and is_list(opts) do
  with {:ok, raw_method, client_id, client_secret} <-
         parse_client_credentials(params, authorization),
       {:ok, %Client{} = client} <- fetch_client(client_id, opts),
       attempted_method = resolve_implicit_method(raw_method, client.token_endpoint_auth_method),
       :ok <- validate_registered_auth_method(client, attempted_method),
       :ok <- validate_client_secret(client, attempted_method, client_secret, opts) do
    {:ok, client}
  end
end
```

**JWT assertion parse seam** (`lib/lockspire/protocol/client_auth.ex:89-95`):
```elixir
defp evaluate_client_credentials(%{is_jwt_bearer?: true, client_assertion: a})
     when not is_nil(a) do
  case peek_jwt_client_id(a) do
    {:ok, client_id} -> {:ok, :private_key_jwt, client_id, a}
    :error -> {:error, invalid_client("Malformed client_assertion", :invalid_client_assertion)}
  end
end
```
Planner note: this is the current implicit-routing seam Phase 88 must replace. Keep the tentative client lookup via `peek_jwt_client_id/1`, but stop hard-coding `:private_key_jwt` before the stored method is known.

**Fail-closed method enforcement** (`lib/lockspire/protocol/client_auth.ex:158-190`):
```elixir
defp validate_registered_auth_method(
       %Client{token_endpoint_auth_method: auth_method},
       attempted_method
     )
     when auth_method in @supported_auth_methods do
  case Policy.ensure_supported_token_endpoint_auth_method(auth_method) do
    :ok ->
      if auth_method == attempted_method do
        :ok
      else
        {:error,
         invalid_client(
           "Client is not allowed to use this token endpoint authentication method",
           :unsupported_token_endpoint_auth_method
         )}
      end
```
Use this exact fail-closed posture for `client_secret_jwt`: no fallback to `client_secret_basic`, `client_secret_post`, or `private_key_jwt`.

**Verifier dispatch pattern** (`lib/lockspire/protocol/client_auth.ex:192-233`):
```elixir
defp validate_client_secret(%Client{} = client, :private_key_jwt, client_assertion, opts) do
  case PrivateKeyJwt.verify(client, client_assertion, opts) do
    :ok ->
      :ok

    {:error, reason_code} ->
      {:error, invalid_client("Client authentication failed", reason_code)}
  end
end
```
New runtime code should plug in here with the same `{:error, reason_code}` to OAuth `invalid_client` mapping.

### `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`

**Analog:** `lib/lockspire/protocol/client_auth/private_key_jwt.ex`

**File placement and module naming**:
- Verifier modules live under `lib/lockspire/protocol/client_auth/`.
- Module name matches file path: `Lockspire.Protocol.ClientAuth.PrivateKeyJwt` in [`lib/lockspire/protocol/client_auth/private_key_jwt.ex`](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth/private_key_jwt.ex:1).
- Follow the same placement for `Lockspire.Protocol.ClientAuth.ClientSecretJwt`.

**Top-level verifier contract** (`lib/lockspire/protocol/client_auth/private_key_jwt.ex:16-44`):
```elixir
@spec verify(Client.t(), String.t(), keyword()) :: :ok | {:error, atom()}
def verify(%Client{} = client, assertion, opts)
    when is_binary(assertion) and is_list(opts) do
  case resolve_keys(client, opts) do
    {:ok, verified_client, jwks_source} ->
      with {:ok, allowed_signing_algorithms} <-
             allowed_signing_algorithms(verified_client, opts),
           {:ok, verified_assertion} <-
             verify_signature(
               assertion,
               verified_client,
               allowed_signing_algorithms,
               jwks_source,
               opts
             ),
           :ok <- validate_claims(verified_assertion, verified_client, opts),
           :ok <- record_replay(verified_assertion, verified_client, opts) do
        :ok
      else
        {:error, reason} = error ->
          record_failure(reason, client, jwks_source_for_failure(client, jwks_source), opts)
          error
      end
```
Copy the contract and sequencing, not the asymmetric-key internals. Phase 88 needs the same order: verify -> validate claims -> record replay -> emit generic failure.

**Algorithm allowlist seam** (`lib/lockspire/protocol/client_auth/private_key_jwt.ex:62-70`, `154-166`; `lib/lockspire/protocol/security_profile.ex:61-64`):
```elixir
resolved = SecurityProfile.resolve_effective_profile(server_policy, client)
{:ok, SecurityProfile.allowed_signing_algorithms(resolved.effective_profile)}
```
```elixir
case Map.get(header, "alg") do
  alg when is_binary(alg) ->
    if alg in allowed_signing_algorithms do
      :ok
    else
      {:error, :client_assertion_algorithm_not_allowed}
    end
```
Planner note: `private_key_jwt` derives its allowlist from the effective profile. Phase 88 needs a narrower branch: `client_secret_jwt` should still consult profile truth, but fail closed to `HS256` only and reject all symmetric JWT use under FAPI profiles.

**Claim validation pattern** (`lib/lockspire/protocol/client_auth/private_key_jwt.ex:168-277`):
```elixir
with :ok <- validate_required_subject(verified_assertion, client.client_id),
     :ok <- validate_required_timing_claims(verified_assertion),
     :ok <- validate_assertion_lifetime(verified_assertion),
     :ok <-
       Jar.validate_claims(
         verified_assertion,
         expected_client_id: client.client_id,
         expected_audience: Config.issuer!(),
         now: now(opts),
         leeway: @clock_skew,
         max_age: @max_assertion_age
       ) do
  :ok
else
  {:error, reason} -> {:error, map_claim_validation_reason(reason)}
end
```
This is the closest analog for issuer-string `aud`, `iss`/`sub` binding, lifetime bounding, and generic reason-code mapping.

**Replay pattern** (`lib/lockspire/protocol/client_auth/private_key_jwt.ex:228-247`):
```elixir
with {:ok, jti} <- fetch_replay_claim(claims, "jti"),
     {:ok, exp} <- fetch_replay_expiration(claims),
     {:ok, expires_at} <- DateTime.from_unix((exp + @clock_skew) * 1_000_000, :microsecond),
     {:ok, result} <-
       replay_store(opts).record_used_jti(%UsedJti{
         client_id: client.client_id,
         jti: jti,
         expires_at: expires_at
       }) do
  case result do
    :accepted -> :ok
    :replay -> {:error, :client_assertion_replayed}
  end
```
Keep this exact post-verification replay timing and `UsedJti` write pattern.

**Telemetry and audit pattern** (`lib/lockspire/protocol/client_auth/private_key_jwt.ex:279-341`):
```elixir
metadata = failure_metadata(client, reason, jwks_source)
action = telemetry_action(reason)

Observability.emit(:client_auth, action, %{}, metadata)
append_audit_event(reason, client, metadata, opts)
```
```elixir
event =
  Event.normalize(%{
    action: audit_action(reason),
    outcome: audit_outcome(reason),
    reason_code: reason,
    actor: %{type: :client, id: client.client_id, display: client.client_id},
    resource: %{type: :client_authentication, id: client.client_id},
    metadata: metadata
  })
```
Mirror the event shape. For the symmetric verifier, keep metadata limited to safe fields like `client_id`, `auth_method`, and `reason_code`.

**Secret verification primitive** (`lib/lockspire/security/policy.ex:150-173`):
```elixir
@spec verify_client_secret(String.t(), String.t()) :: boolean()
def verify_client_secret("sha256:" <> rest, client_secret)
    when is_binary(client_secret) do
  case String.split(rest, ":", parts: 2) do
    [salt, expected_hash] ->
      calculated_hash =
        :crypto.hash(:sha256, salt <> client_secret)
        |> Base.encode64()

      secure_compare(expected_hash, calculated_hash)
```
Use this as the storage boundary. Do not introduce recoverable secrets or widen the host seam.

### Endpoint delegates using shared client auth

**Closest analogs:** [`lib/lockspire/protocol/introspection.ex`](/Users/jon/projects/lockspire/lib/lockspire/protocol/introspection.ex:48), [`lib/lockspire/protocol/revocation.ex`](/Users/jon/projects/lockspire/lib/lockspire/protocol/revocation.ex:30), [`lib/lockspire/protocol/device_authorization.ex`](/Users/jon/projects/lockspire/lib/lockspire/protocol/device_authorization.ex:45), [`lib/lockspire/protocol/backchannel_authentication.ex`](/Users/jon/projects/lockspire/lib/lockspire/protocol/backchannel_authentication.ex:37), [`lib/lockspire/protocol/token_exchange.ex`](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:245)

**Shared delegate pattern**:
```elixir
case ClientAuth.authenticate(params, authorization, client_auth_options(request)) do
  {:ok, %Client{} = client} ->
    {:ok, client}

  {:error, %ClientAuth.Error{} = error} ->
    {:error,
     %Error{
       status: error.status,
       error: error.error,
       error_description: error.error_description,
       reason_code: error.reason_code
     }}
end
```
References:
- `lib/lockspire/protocol/introspection.ex:77-89`
- `lib/lockspire/protocol/revocation.ex:59-70`
- `lib/lockspire/protocol/device_authorization.ex:72-84`
- `lib/lockspire/protocol/backchannel_authentication.ex:64-76`
- `lib/lockspire/protocol/token_exchange.ex:245-258`

Planner note: endpoint modules should not learn symmetric-JWT specifics. All new behavior belongs under shared `ClientAuth`.

### `test/lockspire/protocol/client_auth_test.exs`

**Analog:** `test/lockspire/protocol/client_auth_test.exs`

**Describe-block naming convention** (`test/lockspire/protocol/client_auth_test.exs:21`):
```elixir
describe "authenticate/3 with private_key_jwt" do
```
Add the new runtime proof as a sibling `describe "authenticate/3 with client_secret_jwt"` block in the same file.

**Verifier proof style**:
- success + attacker failure in one test: `test/lockspire/protocol/client_auth_test.exs:36-66`
- remote/lookup retry proof when relevant: `:68-121`
- profile-bound algorithm rejection: `:123-139`
- audience mismatch proof: `:141-161`
- replay-after-claims proof: `:163-223`
- telemetry/audit proof: `:225-286`

**Reusable helper naming** (`test/lockspire/protocol/client_auth_test.exs:433-469`):
```elixir
defp private_key_jwt_params(assertion) do
  %{
    "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
    "client_assertion" => assertion
  }
end
```
Copy the helper shape and rename it to `client_secret_jwt_params/1` only if the test needs method-specific clarity; otherwise keep one shared assertion helper.

### `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`

**Analog:** `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`

**File naming convention**:
- representative shared-runtime endpoint proofs live in `test/lockspire/protocol/direct_client_auth_<method>_test.exs`
- module name mirrors filename: `Lockspire.Protocol.DirectClientAuthPrivateKeyJwtTest` in `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs:1`

**Representative surface coverage** (`test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs:57-147`):
- introspection
- revocation
- device authorization
- backchannel authentication

**Cross-endpoint failure proof** (`test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs:149-212`):
```elixir
Enum.each(requests, fn request ->
  assert {:error,
          %{error: "invalid_client", reason_code: :client_assertion_signature_invalid}} =
           request.()
end)
```
Phase 88 should reuse this exact representative-proof structure for symmetric assertions, changing only the assertion builder and expected reason codes where Phase 88 intentionally differs.

**In-memory shared store pattern** (`test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs:214-301`):
- single `SharedStore` implementing `fetch_client_by_id/1`, `record_used_jti/1`, `get_server_policy/0`
- endpoint-specific stores alongside it
- `Process.put/2` state seeded in `setup`

### `test/lockspire/audit/event_test.exs`

**Analog:** `test/lockspire/audit/event_test.exs`

**Audit redaction proof pattern** (`test/lockspire/audit/event_test.exs:6-30`):
```elixir
event =
  Event.normalize(%{
    action: :client_auth_failed,
    outcome: :failed,
    reason_code: :client_assertion_signature_invalid,
    actor: %{type: :client, id: "client-123"},
    resource: %{type: :client_authentication, id: "client-123"},
    metadata: %{
      client_id: "client-123",
      client_assertion: "raw.jwt.value",
      jwt_header: %{"alg" => "RS256"},
      jwt_claims: %{"sub" => "client-123"},
      jwks_body: %{"keys" => [%{"kid" => "kid-1"}]},
      jwks_source: :jwks_uri
    }
  })
```
Add symmetric-JWT-specific redaction proof here if new metadata keys are introduced.

## Shared Patterns

### Auth-method support lists

**Sources:**
- `lib/lockspire/protocol/client_auth.ex:10-17`
- `lib/lockspire/security/policy.ex:9-16`
- `lib/lockspire/domain/client.ex:7-13`
- `lib/lockspire/storage/ecto/client_record.ex:27-38`

Pattern: auth methods are declared in parallel lists/types across runtime, policy, domain, and Ecto enum storage. If Phase 88 broadens any list, update all matching seams together; do not add a runtime-only atom in one place and leave the others stale.

### Security-profile truth

**Sources:**
- `lib/lockspire/protocol/security_profile.ex:28-64`
- `lib/lockspire/protocol/discovery.ex:251-257`
- `test/lockspire/protocol/discovery_test.exs:178-190`

Pattern: profile restrictions narrow algorithm publication and verification; they never widen convenience behavior. New symmetric JWT logic should follow that same posture.

### Redaction and audit normalization

**Sources:**
- `lib/lockspire/redaction.ex:8-177`
- `lib/lockspire/audit/event.ex:68-105`

Relevant excerpt:
```elixir
metadata:
  attrs
  |> get_value(:metadata, %{})
  |> Redaction.for_audit()
  |> compact_metadata(),
```
If the new verifier emits metadata, rely on `Event.normalize/1` and `Redaction.for_audit/1`; do not hand-roll per-call redaction.

### Discovery truth for shared direct-client auth

**Sources:**
- `lib/lockspire/protocol/discovery.ex:210-281`
- `test/lockspire/protocol/discovery_test.exs:118-190`

Pattern: discovery publishes only methods the mounted runtime can actually verify, and publishes signing algorithms only when a JWT auth method is advertised. If a later plan touches discovery, copy this route-sensitive truth shape.

## Naming And Placement Conventions

- Runtime verifiers live in `lib/lockspire/protocol/client_auth/` and use CamelCase module names matching the file path.
- Shared auth entrypoint stays in `lib/lockspire/protocol/client_auth.ex`; endpoint modules only delegate to it.
- Unit-style auth runtime tests stay in `test/lockspire/protocol/client_auth_test.exs` under `describe "authenticate/3 with <method>"`.
- Representative endpoint proofs use dedicated files named `test/lockspire/protocol/direct_client_auth_<method>_test.exs`.
- Audit redaction normalization proofs stay in `test/lockspire/audit/event_test.exs`.

## Closest Analogs By Planned Work Item

- Shared JWT auth routing in `ClientAuth`: `lib/lockspire/protocol/client_auth.ex:36-45`, `:89-95`, `:158-233`
- New `client_secret_jwt` verifier runtime: `lib/lockspire/protocol/client_auth/private_key_jwt.ex:16-44`, `:168-247`, `:279-341`
- Cross-endpoint proof for shipped direct-client surfaces: `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs:57-212`
- Verifier unit proof for replay/audience/algorithm/audit: `test/lockspire/protocol/client_auth_test.exs:36-286`
- Audit/redaction regression proof: `test/lockspire/audit/event_test.exs:6-30`
