# Phase 61: Shared Private Key JWT Verification - Pattern Map

**Mapped:** 2026-05-06
**Scope:** Shared `private_key_jwt` verification through `ClientAuth`, direct-client endpoint rollout, internal failure shaping, observability, audit, redaction, and tests.

## File Classification

| File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/client_auth.ex` | service | request-response | `lib/lockspire/protocol/client_auth.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | service | transform | `lib/lockspire/protocol/discovery.ex` | exact |
| `lib/lockspire/protocol/introspection.ex` | service | request-response | `lib/lockspire/protocol/introspection.ex` | exact |
| `lib/lockspire/protocol/revocation.ex` | service | request-response | `lib/lockspire/protocol/revocation.ex` | exact |
| `lib/lockspire/protocol/pushed_authorization_request.ex` | service | request-response | `lib/lockspire/protocol/pushed_authorization_request.ex` | exact |
| `lib/lockspire/protocol/device_authorization.ex` | service | request-response | `lib/lockspire/protocol/device_authorization.ex` | exact |
| `lib/lockspire/protocol/token_exchange.ex` | service | request-response | `lib/lockspire/protocol/token_exchange.ex` | exact |
| `lib/lockspire/protocol/backchannel_authentication.ex` | service | request-response | `lib/lockspire/protocol/backchannel_authentication.ex` | exact |
| `test/lockspire/protocol/client_auth_test.exs` | test | request-response | `test/lockspire/protocol/client_auth_test.exs` | exact |
| `test/lockspire/storage/ecto/repository_used_jti_test.exs` | test | CRUD | `test/lockspire/storage/ecto/repository_used_jti_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/protocol/client_auth.ex`

**Use as the single shared seam.**

- Stage pipeline shape to preserve and extend: [client_auth.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth.ex:28)
```elixir
with {:ok, attempted_method, client_id, client_secret} <-
       parse_client_credentials(params, authorization),
     {:ok, %Client{} = client} <- fetch_client(client_id, opts),
     :ok <- validate_registered_auth_method(client, attempted_method),
     :ok <- validate_client_secret(client, attempted_method, client_secret, opts) do
  {:ok, client}
end
```
- Keep the tentative-unverified lookup seam, but only for candidate client resolution: [client_auth.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth.ex:74)
```elixir
case peek_jwt_client_id(a) do
  {:ok, client_id} -> {:ok, :private_key_jwt, client_id, a}
  :error -> {:error, invalid_client("Malformed client_assertion", :invalid_client_assertion)}
end
```
- Rework `validate_client_secret/4` into verified-assertion stages; current `private_key_jwt` branch is the cleanup target because it trusts decoded payload and writes replay before signature truth: [client_auth.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth.ex:185)
```elixir
with [_, payload_b64, _] <- String.split(client_assertion, "."),
     {:ok, payload_json} <- Base.url_decode64(payload_b64, padding: false),
     {:ok, payload} <- Jason.decode(payload_json),
     :ok <- validate_jwt_ttl(payload),
     :ok <- validate_jwt_replay(client.client_id, payload, opts) do
  :ok
end
```
- Preserve result shape for all direct-client endpoints: [client_auth.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth.ex:11), [client_auth.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth.ex:272)
```elixir
defstruct [:status, :error, :error_description, :reason_code]

defp invalid_client(description, reason_code) do
  oauth_error(401, "invalid_client", description, reason_code)
end
```

### `lib/lockspire/protocol/jar.ex`

**Copy the verify-then-claims split.**

- Use `decode/1` only for untrusted structural inspection: [jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:76)
- Copy the JOSE verification pattern and explicit algorithm allowlist handling: [jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:116)
```elixir
def verify_signature(jwt, %Client{jwks: jwks}, allowed_algorithms)
    when is_binary(jwt) and is_map(jwks) and is_list(allowed_algorithms) do
  case extract_public_keys(jwks) do
    {:ok, []} -> {:error, :no_matching_key}
    {:ok, public_keys} -> verify_against_keys(jwt, public_keys, allowed_algorithms)
    {:error, reason} -> {:error, reason}
  end
end
```
- Copy the per-key verification loop and hard failure on structural header rejection: [jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:182)
- Copy claim validation as a separate trusted step after signature verification, especially audience, issuer, expiration, `nbf`, and `iat`: [jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:258)
```elixir
with {:ok, expected_client_id, expected_audience, now, leeway, max_age} <- parse_opts(opts),
     :ok <- check_issuer(claims, expected_client_id),
     :ok <- check_audience(claims, expected_audience),
     :ok <- check_expiration(claims, now, leeway, max_age),
     :ok <- check_not_before(claims, now, leeway),
     :ok <- check_issued_at(claims, now, leeway) do
  :ok
end
```

### `lib/lockspire/protocol/token_endpoint_dpop.ex`

**Use as the replay-ordering precedent.**

- Pattern to copy: verify first, then persist replay: [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:35), [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:165)
```elixir
with {:ok, proof} <- validate_proof_with_flag(effective_dpop_required, request),
     :ok <- record_dpop_proof_use(proof, request) do
  {:ok, issuance_context(effective_mode, proof, resolved_security_profile)}
end
```
- Replay expiry should be derived from the effective acceptance window, not raw input alone: [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:275)
```elixir
max_age = Keyword.get(request_options(request), :dpop_max_age, 300)
clock_skew = Keyword.get(request_options(request), :dpop_clock_skew, 30)
DateTime.from_unix((iat + max_age + clock_skew) * 1_000_000, :microsecond)
```
- Fail closed on replay-store failure with stable internal reason codes: [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:176)

### Direct-client endpoint modules

**Keep endpoints as thin adapters over `ClientAuth`; do not add endpoint-local auth policy.**

- Common adapter pattern to preserve across PAR, device auth, token exchange, revocation, introspection, and CIBA:
  [pushed_authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/pushed_authorization_request.ex:89)
  [device_authorization.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/device_authorization.ex:72)
  [token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:244)
  [revocation.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/revocation.ex:59)
  [introspection.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/introspection.ex:60)
  [backchannel_authentication.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/backchannel_authentication.ex:64)
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
- Introspection has current post-auth drift that Phase 61 should remove: [introspection.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/introspection.ex:86)
```elixir
defp validate_confidential_caller(%Client{
       client_type: :confidential,
       token_endpoint_auth_method: method
     })
     when method in [:client_secret_basic, :client_secret_post] do
  {:ok, true}
end
```
- Discovery has current metadata drift that Phase 61 should remove: [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:228), [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:237)
```elixir
defp introspection_endpoint_auth_methods_supported(endpoint_metadata) do
  if Map.has_key?(endpoint_metadata, "introspection_endpoint") do
    published_direct_client_auth_methods()
    |> Enum.filter(&(&1 in @introspection_supported_auth_methods))
  else
    []
  end
end

defp published_direct_client_auth_methods do
  ClientAuth.supported_auth_method_names()
  |> Enum.reject(&(&1 == "private_key_jwt"))
end
```

## Shared Patterns

### Error and `reason_code` shaping

- Preserve structured internal error structs with `status`, OAuth `error`, external `error_description`, and internal `reason_code`: [client_auth.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth.ex:11), [revocation.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/revocation.ex:13), [introspection.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/introspection.ex:14)
- Endpoint modules copy `ClientAuth.Error` fields verbatim into local error structs instead of remapping policy locally: same references as above.
- Follow `TokenEndpointDPoP` for stable atom reason codes on internal failures and generic public-facing messages: [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:123), [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:331)

### Observability and redaction

- Emit through the shared observability seam only: [observability.ex](/Users/jon/projects/lockspire/lib/lockspire/observability.ex:24)
```elixir
redacted_metadata = redact(metadata)
normalized_measurements = Map.put_new(measurements, :count, 1)
:telemetry.execute(@audit_prefix ++ [entity, action], normalized_measurements, redacted_metadata)
:telemetry.execute(@telemetry_prefix ++ [entity, action], normalized_measurements, redacted_metadata)
```
- Failure metadata pattern to copy: include stable `reason_code`, top-level OAuth `error`, and safe identifiers only:
  [revocation.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/revocation.ex:97)
  [introspection.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/introspection.ex:205)
  [token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:1294)
- Respect global drop lists for secrets/raw payloads and use handled IDs where present: [redaction.ex](/Users/jon/projects/lockspire/lib/lockspire/redaction.ex:8), [redaction.ex](/Users/jon/projects/lockspire/lib/lockspire/redaction.ex:138), [redaction.ex](/Users/jon/projects/lockspire/lib/lockspire/redaction.ex:202)
```elixir
@telemetry_drop_keys MapSet.new([:authorization, :client_secret, :params, :payload, :raw_payload, ...])
@audit_drop_keys MapSet.new([:authorization, :client_secret, :params, :payload, :raw_payload, ...])
@telemetry_handle_keys %{ :family_id => :family, "family_id" => :family }
```

### Audit normalization

- Durable audit events should carry reason codes, actor/resource identity, and already-redacted metadata; normalize through `Audit.Event`: [audit/event.ex](/Users/jon/projects/lockspire/lib/lockspire/audit/event.ex:68)
```elixir
%__MODULE__{
  action: attrs |> get_value(:action) |> normalize_required_value(),
  outcome: attrs |> get_value(:outcome) |> normalize_required_value(),
  reason_code: attrs |> get_value(:reason_code) |> normalize_optional_value(),
  ...
  metadata:
    attrs
    |> get_value(:metadata, %{})
    |> Redaction.for_audit()
    |> compact_metadata()
}
```
- Revocation and token exchange show the durable audit event shape to reuse for security-significant assertion failures/replay events:
  [revocation.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/revocation.ex:186)
  [token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:1742)

### Discovery metadata truth

- Published capability should derive from runtime truth and shared policy source:
  [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:48)
  [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:169)
  [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:208)
```elixir
def token_endpoint_auth_methods_supported, do: ClientAuth.supported_auth_method_names()

if Map.has_key?(endpoint_metadata, "token_endpoint") do
  published_direct_client_auth_methods()
else
  []
end

if "private_key_jwt" in Map.get(metadata, methods_key, []) do
  Map.put(metadata, algorithms_key, SecurityProfile.allowed_signing_algorithms(global_security_profile()))
end
```
- Planner target: stop suppressing shared runtime support in published direct-client metadata.

## Test Patterns

### Protocol module tests

- `ClientAuth` tests currently use a local fake store module plus direct `authenticate/3` calls; keep that seam, but shift fixtures from unsigned payload-shape tests to cryptographic ordering tests: [client_auth_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/client_auth_test.exs:15), [client_auth_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/client_auth_test.exs:154)
- `TokenEndpointDPoP` tests are the best shape for request-level verification plus replay-store injection:
  [token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:18)
  [token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:48)
  [token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:66)
- Copy the pattern of injecting `now`, replay store, and policy store through request opts rather than global mutation.

### Replay storage tests

- Durable replay proof shape to copy for `UsedJti`: [repository_used_jti_test.exs](/Users/jon/projects/lockspire/test/lockspire/storage/ecto/repository_used_jti_test.exs:22)
```elixir
assert {:ok, :accepted} = Repository.record_used_jti(jti)
assert {:ok, :replay} = Repository.record_used_jti(jti)
```
- Preserve uniqueness semantics by `{client_id, jti}` only: [repository_used_jti_test.exs](/Users/jon/projects/lockspire/test/lockspire/storage/ecto/repository_used_jti_test.exs:44)

## Planner Notes

- Prefer one shared verifier pipeline inside `ClientAuth`; endpoints should inherit behavior via existing adapter code.
- Reuse `Jar` for JOSE verification and trusted-claims validation structure, and reuse `TokenEndpointDPoP` for replay ordering and fail-closed store behavior.
- Keep public auth failures generic, but preserve detailed stable internal `reason_code` atoms for telemetry and selective audit.
