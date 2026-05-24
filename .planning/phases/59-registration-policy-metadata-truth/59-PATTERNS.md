# Phase 59: Registration, Policy & Metadata Truth - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/registration.ex` | protocol/service | request-response | `lib/lockspire/protocol/registration.ex` | exact |
| `lib/lockspire/protocol/registration_management.ex` | protocol/service | request-response | `lib/lockspire/protocol/registration_management.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | protocol/service | transform | `lib/lockspire/protocol/discovery.ex` | exact |
| `lib/lockspire/protocol/client_auth.ex` | protocol/service | request-response | `lib/lockspire/protocol/client_auth.ex` | exact |
| `lib/lockspire/protocol/security_profile.ex` | utility/policy | transform | `lib/lockspire/protocol/security_profile.ex` | exact |
| `lib/lockspire/protocol/introspection.ex` | protocol/service | request-response | `lib/lockspire/protocol/introspection.ex` | exact |
| `lib/lockspire/protocol/revocation.ex` | protocol/service | request-response | `lib/lockspire/protocol/revocation.ex` | exact |
| `lib/lockspire/web/live/admin/policies_live/dcr.ex` | liveview | request-response | `lib/lockspire/web/live/admin/policies_live/security_profile.ex` | role-match |
| `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` | template/component | transform | `lib/lockspire/web/live/admin/policies_live/par.ex` | role-match |
| `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` | form/config | transform | `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` | exact |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | liveview | request-response | `lib/lockspire/web/live/admin/clients_live/show.ex` | exact |
| `test/lockspire/protocol/*` and `test/lockspire/web/discovery_controller_test.exs` | test | request-response | existing registration/discovery tests | exact |

## Pattern Assignments

### `lib/lockspire/protocol/registration.ex`

**Analog:** same file, keep the current DCR orchestrator shape.

**Imports/pipeline pattern** ([registration.ex:23](../../lib/lockspire/protocol/registration.ex:23), [registration.ex:57](../../lib/lockspire/protocol/registration.ex:57))
```elixir
alias Lockspire.Protocol.DcrPolicy
alias Lockspire.Protocol.DcrPolicy.Resolved

with :ok <- require_iat_when_policy_demands(server_policy, iat),
     {:ok, iat_record} <- maybe_redeem_iat(iat),
     {:ok, %Resolved{} = resolved} <- resolve_policy(server_policy, iat_record, metadata),
     :ok <- validate_intake_metadata(metadata, resolved, server_policy),
     credentials <- generate_credentials(),
     {:ok, %Client{} = client} <- persist_client(metadata, resolved, iat_record, credentials, source) do
```

**Validation pattern** ([registration.ex:123](../../lib/lockspire/protocol/registration.ex:123))
```elixir
def validate_intake_metadata(metadata, %Resolved{} = _resolved, server_policy)
    when is_map(metadata) do
  with :ok <- validate_unsupported_logout_metadata(metadata),
       :ok <- validate_jwks(metadata),
       :ok <- validate_grant_response_coherence(metadata),
       :ok <- validate_redirect_uris(metadata),
       :ok <- validate_fapi_2_0_readiness(metadata, server_policy) do
    validate_pkce_floor(metadata)
  end
end
```

**Current `jwks` truth seam** ([registration.ex:214](../../lib/lockspire/protocol/registration.ex:214))
```elixir
cond do
  has_jwks and has_jwks_uri ->
    {:error, %Error{code: :invalid_client_metadata, field: :jwks, reason: :mutually_exclusive_with_jwks_uri}}

  auth_method == "private_key_jwt" and not has_jwks and not has_jwks_uri ->
    {:error, %Error{code: :invalid_client_metadata, field: :token_endpoint_auth_method, reason: :missing_cryptographic_material}}
```

**Persistence mapping pattern** ([registration.ex:317](../../lib/lockspire/protocol/registration.ex:317))
```elixir
%Client{
  client_id: credentials.client_id,
  token_endpoint_auth_method: auth_method,
  jwks: Map.get(metadata, "jwks"),
  provenance: :self_registered,
  registration_access_token_hash: credentials.rat_hash,
  metadata: build_extension_metadata(metadata)
}
```

**Extension point**
- Add the narrow Phase 59 `jwks_uri` admission rules inside `validate_jwks/1` and persist them in `persist_client/5`.
- Keep the new rule in the existing slice validator chain. Do not fork a second registration path.

**Anti-patterns**
- Do not add a separate “registration metadata policy” module just for `jwks_uri`.
- Do not make `jwks_uri` generally valid for non-`private_key_jwt` auth methods.
- Do not persist truth only in `metadata`; durable first-class fields already exist on `Client`.

### `lib/lockspire/protocol/registration_management.ex`

**Analog:** same file, mirror DCR intake truth and rotate RAT on success.

**Update pipeline pattern** ([registration_management.ex:61](../../lib/lockspire/protocol/registration_management.ex:61))
```elixir
with {:ok, resolved} <- DcrPolicy.resolve(server_policy, nil, metadata),
     :ok <- Registration.validate_intake_metadata(metadata, resolved, server_policy),
     {new_rat_plaintext, new_rat_hash} <- RegistrationAccessToken.generate(),
     {:ok, updated_client} <- persist_update(client, metadata, new_rat_hash) do
```

**Error normalization pattern** ([registration_management.ex:88](../../lib/lockspire/protocol/registration_management.ex:88))
```elixir
{:error, :invalid_client_metadata, info} ->
  error = %Registration.Error{
    code: :invalid_client_metadata,
    field: info.field,
    reason: info.reason,
    allowed: info[:allowed]
  }
```

**Transaction + audit pattern** ([registration_management.ex:198](../../lib/lockspire/protocol/registration_management.ex:198))
```elixir
record
|> ClientRecord.changeset(updated_client)
|> Ecto.Changeset.change(
  registration_access_token_hash: new_rat_hash,
  updated_at: DateTime.utc_now()
)
|> repo.update()
```

**Current metadata application seam** ([registration_management.ex:242](../../lib/lockspire/protocol/registration_management.ex:242))
```elixir
%Client{
  client
  | token_endpoint_auth_method: auth_method,
    jwks: Map.get(metadata, "jwks"),
    id_token_signed_response_alg: atomize_alg(Map.get(metadata, "id_token_signed_response_alg")),
    security_profile: atomize_security_profile(Map.get(metadata, "security_profile", "inherit")),
    dpop_policy: dpop_policy_from_metadata(metadata),
    metadata: extension_metadata
}
```

**Extension point**
- Phase 59 should make this mapping truthfully mirror registration persistence, including `jwks_uri`.
- Keep reuse of `Registration.validate_intake_metadata/3`; management should not drift from intake.

**Anti-patterns**
- Do not bypass `Registration.validate_intake_metadata/3` with management-only rules.
- Do not use `ClientRecord.update_changeset/2` for RFC 7592 state; the file comments explicitly reserve DCR/admin boundaries elsewhere.
- Current code already shows a drift hazard: `apply_metadata_to_client/2` updates `jwks` but not `jwks_uri`. Phase 59 should fix by mirroring the registration mapping, not by inventing a second source of truth.

### `lib/lockspire/protocol/discovery.ex`

**Analog:** same file, centralized truth assembly with route-aware metadata and conditional keys.

**Mounted-endpoint assembly pattern** ([discovery.ex:64](../../lib/lockspire/protocol/discovery.ex:64))
```elixir
mounted_route_paths()
|> Enum.reduce(%{}, fn path, acc ->
  case endpoint_metadata_entry(issuer, path) do
    nil -> acc
    {key, value} -> Map.put(acc, key, value)
  end
end)
```

**Single document assembly pattern** ([discovery.ex:76](../../lib/lockspire/protocol/discovery.ex:76))
```elixir
%{
  "issuer" => issuer,
  "grant_types_supported" => grant_types_supported(endpoint_metadata),
  "token_endpoint_auth_methods_supported" => token_endpoint_auth_methods_supported(endpoint_metadata),
  "id_token_signing_alg_values_supported" => id_token_signing_alg_values_supported()
}
|> Map.merge(endpoint_metadata)
|> maybe_put_dpop_metadata(endpoint_metadata)
|> maybe_put_ciba_metadata(endpoint_metadata)
|> maybe_put_resource_indicators_metadata(endpoint_metadata)
|> maybe_put_authorization_details_metadata(endpoint_metadata)
|> put_bcl_fcl_metadata()
|> put_iss_parameter_metadata()
|> maybe_put_par_required_metadata()
```

**Mounted truth predicate pattern** ([discovery.ex:170](../../lib/lockspire/protocol/discovery.ex:170))
```elixir
defp token_endpoint_auth_methods_supported(endpoint_metadata) do
  if Map.has_key?(endpoint_metadata, "token_endpoint") do
    @token_endpoint_auth_methods_supported
  else
    []
  end
end
```

**Extension point**
- Add endpoint-specific metadata predicates here, backed by one shared direct-client-auth capability source.
- Follow the existing `maybe_put_*` style: publish keys only when the mounted and enforced surface supports them.

**Anti-patterns**
- Do not assemble revocation/introspection auth metadata in controllers.
- Do not add metadata-only divergence knobs disconnected from runtime behavior.
- Do not publish signing-algorithm metadata unconditionally; Phase 59 requires “only where a JWT auth method is actually published.”

### `lib/lockspire/protocol/client_auth.ex`

**Analog:** same file, shared direct-client-auth seam for token-adjacent surfaces.

**Shared capability declaration** ([client_auth.ex:9](../../lib/lockspire/protocol/client_auth.ex:9))
```elixir
@supported_auth_methods [:none, :client_secret_basic, :client_secret_post, :private_key_jwt]
```

**Authenticate orchestration pattern** ([client_auth.ex:28](../../lib/lockspire/protocol/client_auth.ex:28))
```elixir
with {:ok, attempted_method, client_id, client_secret} <- parse_client_credentials(params, authorization),
     {:ok, %Client{} = client} <- fetch_client(client_id, opts),
     :ok <- validate_registered_auth_method(client, attempted_method),
     :ok <- validate_client_secret(client, attempted_method, client_secret, opts) do
  {:ok, client}
end
```

**Registered method guard** ([client_auth.ex:138](../../lib/lockspire/protocol/client_auth.ex:138))
```elixir
case Policy.ensure_supported_token_endpoint_auth_method(auth_method) do
  :ok ->
    if auth_method == attempted_method do
      :ok
    else
      {:error, invalid_client("Client is not allowed to use this token endpoint authentication method", :unsupported_token_endpoint_auth_method)}
    end
```

**Current `private_key_jwt` validation seam** ([client_auth.ex:180](../../lib/lockspire/protocol/client_auth.ex:180))
```elixir
with [_, payload_b64, _] <- String.split(client_assertion, "."),
     {:ok, payload_json} <- Base.url_decode64(payload_b64, padding: false),
     {:ok, payload} <- Jason.decode(payload_json),
     :ok <- validate_jwt_ttl(payload),
     :ok <- validate_jwt_replay(client.client_id, payload, opts) do
  :ok
```

**Extension point**
- Use this module as the shared capability source for discovery/revocation/introspection metadata.
- Phase 59 should derive published `private_key_jwt` support from what this seam can enforce on a given endpoint, not from independent admin config.

**Anti-patterns**
- Do not copy the auth-method list into `Discovery`, `Revocation`, or `Introspection`.
- Do not introduce a second per-endpoint algorithm allowlist here ahead of `SecurityProfile`.

### `lib/lockspire/protocol/security_profile.ex`

**Analog:** same file, derived policy helper rather than operator-configured crypto plane.

**Effective policy resolution pattern** ([security_profile.ex:26](../../lib/lockspire/protocol/security_profile.ex:26))
```elixir
client_profile = normalize_client_profile(client)
effective_profile = effective_profile(server_policy.security_profile, client_profile)

%Resolved{
  global_profile: server_policy.security_profile,
  client_profile: client_profile,
  effective_profile: effective_profile,
  fapi_2_0_security?: effective_profile == :fapi_2_0_security
}
```

**Derived algorithm set pattern** ([security_profile.ex:53](../../lib/lockspire/protocol/security_profile.ex:53))
```elixir
def allowed_signing_algorithms(:fapi_2_0_security), do: ["ES256", "PS256"]
def allowed_signing_algorithms(:none), do: ["RS256", "ES256", "PS256", "EdDSA"]
```

**Extension point**
- Phase 59 algorithm publication should be derived from this helper or a thin wrapper around it.

**Anti-patterns**
- Do not add `dcr_allowed_private_key_jwt_algs` or similar to `ServerPolicy`.
- Do not let admin surfaces edit algorithm lists directly.

### `lib/lockspire/protocol/introspection.ex`

**Analog:** same file, thin endpoint wrapper over shared client auth.

**Auth wrapper pattern** ([introspection.ex:60](../../lib/lockspire/protocol/introspection.ex:60))
```elixir
case ClientAuth.authenticate(params, authorization, client_auth_options(request)) do
  {:ok, %Client{} = client} -> {:ok, client}
  {:error, %ClientAuth.Error{} = error} ->
    {:error, %Error{status: error.status, error: error.error, error_description: error.error_description, reason_code: error.reason_code}}
end
```

**Endpoint-specific truth predicate seam** ([introspection.ex:86](../../lib/lockspire/protocol/introspection.ex:86))
```elixir
defp validate_confidential_caller(%Client{
       client_type: :confidential,
       token_endpoint_auth_method: method
     })
     when method in [:client_secret_basic, :client_secret_post] do
  {:ok, true}
end
```

**Extension point**
- Phase 59 metadata helpers for introspection should reflect this endpoint’s real accepted methods.
- If support expands to `:private_key_jwt` later, change this predicate and let discovery follow it.

**Anti-patterns**
- Do not publish introspection `private_key_jwt` support before this predicate can actually allow it.

### `lib/lockspire/protocol/revocation.ex`

**Analog:** same file, same wrapper pattern as introspection.

**Auth wrapper pattern** ([revocation.ex:59](../../lib/lockspire/protocol/revocation.ex:59))
```elixir
case ClientAuth.authenticate(params, authorization, client_auth_options(request)) do
  {:ok, %Client{} = client} -> {:ok, client}
  {:error, %ClientAuth.Error{} = error} ->
    {:error, %Error{status: error.status, error: error.error, error_description: error.error_description, reason_code: error.reason_code}}
end
```

**Extension point**
- Add a small endpoint truth helper alongside this module or in `Discovery`, based on what `ClientAuth` can really authenticate here.

**Anti-patterns**
- Do not hardcode metadata separately from the runtime-auth path.

### `lib/lockspire/web/live/admin/policies_live/dcr.ex`

**Analog:** `lib/lockspire/web/live/admin/policies_live/security_profile.ex` and `par.ex`.

**LiveView policy editor pattern** ([policies_live/dcr.ex:28](../../lib/lockspire/web/live/admin/policies_live/dcr.ex:28), [security_profile.ex:33](../../lib/lockspire/web/live/admin/policies_live/security_profile.ex:33))
```elixir
def handle_event("save_policy", %{"policy" => policy_params}, socket) do
  changeset = PolicyForm.changeset(policy_params)

  if changeset.valid? do
    policy_attrs = Ecto.Changeset.apply_changes(changeset)
    attrs = Map.from_struct(policy_attrs)
    case Admin.put_dcr_policy(attrs) do
```

**Extension point**
- Keep this LiveView focused on server policy editing and explanatory read-only truth.
- If Phase 59 adds effective-algorithm display, follow the `security_profile.ex` pattern of showing current global state and summary, not a new mutable control plane.

**Anti-patterns**
- Do not turn this into a broad remote-key management console.

### `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`

**Analog:** existing DCR template plus `par.ex`/`security_profile.ex` explanatory copy.

**Template style pattern** ([dcr.html.heex:4](../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex:4))
```heex
<Lockspire.Web.Components.AdminComponents.section_card
  title="Global DCR policy"
  subtitle={"Current mode is #{@policy.registration_policy}. This governs Dynamic Client Registration."}
>
```

**Extension point**
- Add read-only explanatory blocks for whether self-registered `private_key_jwt` is allowed and which assertion algorithms are effective.
- Phrase the UI as “Lockspire will accept/publish/enforce …” rather than asking operators to design crypto policy.

**Anti-patterns**
- No editable algorithm textbox.
- No “test fetch remote JWKS” affordance in this phase.

### `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex`

**Analog:** same file, narrow form schema only for durable mutable policy.

**Embedded-schema pattern** ([policy_form.ex:10](../../lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex:10))
```elixir
embedded_schema do
  field(:registration_policy, Ecto.Enum, values: [:disabled, :initial_access_token, :open])
  field(:dcr_allowed_token_endpoint_auth_methods, {:array, :string}, default: [])
end
```

**CSV-to-array normalization pattern** ([policy_form.ex:50](../../lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex:50))
```elixir
Enum.reduce(array_fields, attrs, fn field, acc ->
  case Map.fetch(acc, field) do
    {:ok, [val]} when is_binary(val) -> ...
    {:ok, val} when is_binary(val) -> ...
```

**Extension point**
- Only add fields here if they are durable operator policy. Derived effective signing algorithms should stay out of the form.

**Anti-patterns**
- Do not model a second algorithm allowlist here.

### `lib/lockspire/web/live/admin/clients_live/show.ex`

**Analog:** same file, read-only effective-policy presentation with narrow task links.

**Truthful effective-state presentation pattern** ([show.ex:153](../../lib/lockspire/web/live/admin/clients_live/show.ex:153))
```elixir
subtitle="Immutable security posture stays fixed. Safe edits are targeted workflows."
...
<p>Global security profile: <code>{security_profile_label(@effective_security_profile.global_profile)}</code></p>
<p>Client security override: <code>{security_profile_label(@client.security_profile)}</code></p>
<p>Effective security profile: <strong>{security_verdict_for(@effective_security_profile)}</strong></p>
```

**Scoped workflow pattern** ([show.ex:215](../../lib/lockspire/web/live/admin/clients_live/show.ex:215))
```elixir
<.link patch={show_path(@client.client_id, :edit)}>Edit metadata</.link>
<.link patch={show_path(@client.client_id, :security_profile)}>Edit security profile</.link>
<.link patch={show_path(@client.client_id, :par_policy)}>Edit PAR policy</.link>
```

**Extension point**
- If Phase 59 touches client detail UX, keep it read-only and explanatory for `jwks_uri` / `private_key_jwt`.
- Reuse the effective-policy display idiom: global policy, client override, effective result, warning when override changes behavior.

**Anti-patterns**
- Do not add first-class admin create/edit flows for operator-managed `private_key_jwt` clients in this phase.
- Do not extend `FormComponent` new/edit selects to support `private_key_jwt`; current omission is intentional scope control.

### Tests

**Registration test pattern** ([registration_test.exs:351](../../test/lockspire/protocol/registration_test.exs:351))
```elixir
describe "register/1 — D-14 validator" do
  test "rejects private_key_jwt without jwks or jwks_uri" do
    ...
    assert {:error, %Error{code: :invalid_client_metadata, field: :token_endpoint_auth_method, reason: :missing_cryptographic_material}} =
             Registration.register(request)
  end
end
```

**Management test pattern** ([registration_management_test.exs:150](../../test/lockspire/protocol/registration_management_test.exs:150))
```elixir
describe "update/2 — RAT rotation" do
  ...
  assert {:ok, %UpdateSuccess{client: updated_client, registration_access_token_plaintext: new_rat}} =
           RegistrationManagement.update(client_id, request)
```

**Discovery truth test pattern** ([discovery_controller_test.exs:62](../../test/lockspire/web/discovery_controller_test.exs:62), [discovery_test.exs:90](../../test/lockspire/protocol/discovery_test.exs:90))
```elixir
assert body["token_endpoint_auth_methods_supported"] == ["none", "client_secret_basic", "client_secret_post"]
refute Map.has_key?(body, "require_pushed_authorization_requests")
```

**Fixture pattern** ([dcr_fixtures.ex:13](../../test/support/fixtures/dcr_fixtures.ex:13))
```elixir
@valid_metadata %{
  "token_endpoint_auth_method" => "client_secret_basic",
  "scope" => "openid profile"
}
```

**Extension point**
- Add fixture helpers for the supported `private_key_jwt` + `jwks_uri` slice rather than repeating inline payload setup.
- Follow the existing negative-path assertion style: explicit `%Error{field, reason}` matching and `Map.has_key?`/`refute` for metadata truth.

## Shared Patterns

### Derived Policy, Not Mutable Crypto Planes
**Sources:** [security_profile.ex:26](../../lib/lockspire/protocol/security_profile.ex:26), [security_profile.ex:53](../../lib/lockspire/protocol/security_profile.ex:53), [discovery.ex:114](../../lib/lockspire/protocol/discovery.ex:114)

Use effective security posture to derive published algorithms:
```elixir
Lockspire.Protocol.SecurityProfile.allowed_signing_algorithms(global_security_profile())
```

Apply to:
- discovery auth-signing metadata
- admin read-only DCR policy surfaces
- any future helper advertising `private_key_jwt` support

### Centralized Metadata Truth
**Source:** [discovery.ex:76](../../lib/lockspire/protocol/discovery.ex:76)

Add Phase 59 metadata in `Lockspire.Protocol.Discovery.openid_configuration/0` via conditional helper functions. Keep route-mounted truth and runtime truth in one place.

### Shared Direct-Client-Auth Capability
**Sources:** [client_auth.ex:28](../../lib/lockspire/protocol/client_auth.ex:28), [introspection.ex:60](../../lib/lockspire/protocol/introspection.ex:60), [revocation.ex:59](../../lib/lockspire/protocol/revocation.ex:59)

Endpoint modules wrap `ClientAuth.authenticate/3`; they do not own independent auth-method policy. Metadata should follow this seam.

### DCR / RFC 7592 Error Shape
**Sources:** [registration.ex:108](../../lib/lockspire/protocol/registration.ex:108), [registration_management.ex:88](../../lib/lockspire/protocol/registration_management.ex:88)

Keep explicit `%Registration.Error{code, field, reason, allowed}` failures. Phase 59 should add new metadata-truth rejections in this shape.

### Narrow Admin UX
**Sources:** [show.ex:155](../../lib/lockspire/web/live/admin/clients_live/show.ex:155), [dcr.html.heex:18](../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex:18), [security_profile.ex:82](../../lib/lockspire/web/live/admin/policies_live/security_profile.ex:82)

Operator surfaces explain effective behavior and exceptions. They do not preview remote fetches, create freeform crypto knobs, or widen client creation workflows.

## No Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| New discovery helper functions for revocation/introspection auth-signing metadata | utility | transform | No existing helper yet for endpoint-specific auth-signing metadata; implement in `Discovery` using existing `maybe_put_*` and mounted truth patterns. |
| Read-only DCR algorithm summary block | template/component | transform | No exact DCR-specific block exists yet; closest analog is security-profile summary UI, but Phase 59 should keep the new block derived and non-editable. |

## Extension Points To Prefer

- `Registration.validate_intake_metadata/3` for the narrow `jwks_uri` acceptance gate.
- `Registration.persist_client/5` and `RegistrationManagement.apply_metadata_to_client/2` for durable `jwks_uri` truth.
- `Discovery.openid_configuration/0` plus new conditional helpers for token/revocation/introspection metadata publication.
- `ClientAuth.supported_auth_methods/0` and endpoint-specific caller predicates as the capability source.
- `SecurityProfile.allowed_signing_algorithms/1` for effective `private_key_jwt` algorithm truth.
- `PoliciesLive.Dcr` template copy and `ClientsLive.Show` read-only presentation patterns for operator visibility.

## Anti-Patterns To Avoid

- Adding a mutable JWT client-assertion algorithm allowlist to `ServerPolicy`, `PolicyForm`, or admin UI.
- Publishing `private_key_jwt` or signing algorithms from discovery before revocation/introspection runtime predicates actually allow them.
- Scattering metadata truth across controllers, plugs, or endpoint modules instead of `Lockspire.Protocol.Discovery`.
- Broadening admin client create/edit workflows to manage `private_key_jwt` keys in Phase 59.
- Treating `jwks_uri` as generic remote metadata ingestion rather than a narrow `private_key_jwt` slice.
- Persisting Phase 59 truth only in `metadata` JSON when first-class `Client` fields already exist.

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/web/live/admin`, `lib/lockspire/domain`, `lib/lockspire/storage/ecto`, `test/lockspire/protocol`, `test/lockspire/web`, `test/support/fixtures`
**Primary analogs used:** `registration.ex`, `registration_management.ex`, `discovery.ex`, `client_auth.ex`, `security_profile.ex`, `introspection.ex`, `revocation.ex`, `policies_live/security_profile.ex`, `policies_live/par.ex`, `clients_live/show.ex`
**Pattern extraction date:** 2026-05-06
