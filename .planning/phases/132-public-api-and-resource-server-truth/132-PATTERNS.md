# Phase 132: Public API and Resource-Server Truth - Pattern Map

**Mapped:** 2026-08-26  
**Files analyzed:** 27 likely modified/new files  
**Analogs found:** 26 / 27

## File Classification

| New/Modified File | Role | Data flow | Closest analog | Match |
|---|---|---|---|---|
| `lib/lockspire/access_token.ex` | public value object / normalization utility | transform | existing `AccessToken` struct and `VerifyToken` normalizers | exact extension |
| `lib/lockspire/plug/verify_token.ex` | Plug / verifier | request-response | existing restrictions and binding extraction | exact |
| `lib/lockspire/plug/enforce_sender_constraints.ex` | Plug | request-response | existing DPoP request builder | exact |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | protocol service | request-response + persistence | existing lazy store resolution | exact |
| `lib/lockspire/clients.ex` | public facade / registration service | CRUD | existing normalize → validate → persist pipeline | exact |
| `lib/lockspire/client_registration/shape.ex` (likely new) | neutral pure validation utility | transform | `Registration.validate_intake_metadata/4` and `Clients.validation_errors/1` | role match |
| `lib/lockspire/protocol/registration.ex` | protocol registration orchestrator | request-response + CRUD | existing ordered `with` intake validation | exact |
| `lib/lockspire/protocol/authorization_request.ex` | protocol validator | request-response | exact redirect-membership guard and built-in `openid` scope logic | exact |
| `lib/lockspire/protocol/discovery.ex` | capability metadata provider | transform | mounted-route truthful capability methods | exact |
| `lib/lockspire/storage/dpop_replay_store.ex` | behavior / storage port | persistence port | existing behaviour | exact |
| `lib/lockspire/storage/ecto/repository.ex` | durable adapter | transactional persistence | `record_dpop_proof/1` | exact |
| `test/lockspire/access_token_test.exs` | unit test | transform | existing public struct test | exact |
| `test/lockspire/plug/verify_token_test.exs` | Plug test | request-response | existing JWT fixture + assign assertions | exact |
| `test/lockspire/plug/enforce_sender_constraints_test.exs` | Plug test | request-response | existing sender constraint cases | exact |
| `test/lockspire/protocol/protected_resource_dpop_test.exs` | service unit test | request-response | injectable store modules | exact |
| `test/lockspire/storage/ecto/repository_dpop_replay_test.exs` | integration test | persistence | durable conflict test | exact |
| `test/lockspire/clients_test.exs` | public facade integration test | CRUD | registration secret + structured error tests | exact |
| `test/lockspire/protocol/registration_test.exs` | DCR test | request-response + CRUD | `Error`-shape assertions | exact |
| `test/lockspire/protocol/authorization_request_test.exs` | protocol negative test | request-response | redirect exact-match cases | exact |
| `test/lockspire/protocol/discovery_test.exs` | metadata test | transform | advertised capability assertions | exact |
| `test/lockspire/web/controllers/registration_controller_test.exs` | HTTP integration test | request-response | DCR configured-repo setup | exact |
| `test/support/generated_host_app_web/router.ex` | generated-host fixture | request-response | protected pipeline fixture | exact |
| `test/support/generated_host_app_web/controllers/protected_api_controller.ex` | generated-host controller example | request-response | existing raw-claims example | exact replacement |
| `priv/templates/lockspire.install/router.ex` | generator template / docs source | transform | protected-pipeline marker block | exact |
| `docs/protect-phoenix-api-routes.md` | canonical adoption guide | documentation contract | canonical protected pipeline | exact |
| `docs/supported-surface.md` | release/support contract | documentation contract | existing bounded support bullets | exact |
| `docs/upgrading/v1.37.md` (likely new) | migration / deprecation guide | documentation | `docs/upgrading/v1.27.md` | role match |

## Pattern Assignments

### Access-token accessors and one normalization contract

**Primary files:** `lib/lockspire/access_token.ex`, `lib/lockspire/plug/verify_token.ex`, `test/lockspire/access_token_test.exs`, `test/lockspire/plug/verify_token_test.exs`.

**Analog:** `lib/lockspire/plug/verify_token.ex:218-318`.

```elixir
with :ok <- validate_audience(access_token.claims, opts, authorization_scheme),
     :ok <- validate_scopes(access_token.claims, opts, authorization_scheme) do
  access_token
end

defp normalize_token_audiences(claims) do
  case Map.get(claims, "aud") do
    audience when is_binary(audience) -> {:ok, [audience]}
    audiences when is_list(audiences) -> ...
    _other -> {:error, :invalid_audience}
  end
end

defp normalize_token_scopes(scope_claim) when is_binary(scope_claim) do
  scope_claim |> String.split(~r/\s+/, trim: true) |> Enum.uniq()
end
```

Put semantic accessors on the existing public `Lockspire.AccessToken` module rather than adding fields or replacing `%AccessToken{}`. Preserve every current field and raw `claims`; make `VerifyToken` delegate its scope/audience interpretation to the same helper that backs public accessors. A reasonable public shape is `subject/1`, `scopes/1`, `audiences/1`, `expires_at/1`, and `confirmation/1`, returning `nil` / `[]` / normalized map predictably for missing or malformed raw claims. Do not expose a helper that treats malformed audience claims as accepted: verifier needs a typed error distinction (`missing_audience` vs `invalid_audience`) while a reader accessor can return `[]`.

**Related binding analog:** `lib/lockspire/plug/verify_token.ex:492-504,573-593` builds normalized sender binding requirements without copying arbitrary `cnf` content. Confirmation accessor should follow this whitelist/trim approach, not return mutable raw nested maps as a new semantic contract.

**Tests:** use the existing signed JWT fixture helper in `test/lockspire/plug/verify_token_test.exs` and direct `%AccessToken{claims: ...}` cases in `test/lockspire/access_token_test.exs`. Cover scalar/list audience; whitespace-delimited and duplicate scopes; numeric integer dates; string/invalid dates; valid, empty, and malformed `cnf`; and parity between an accessor result and route scope/audience enforcement.

### Capability-aware registration shared by direct and DCR paths

**Primary files:** `lib/lockspire/clients.ex`, likely a new pure neutral `lib/lockspire/client_registration/shape.ex`, `lib/lockspire/protocol/registration.ex`, `lib/lockspire/protocol/authorization_request.ex`, `lib/lockspire/protocol/discovery.ex` and their tests.

**Direct facade analog:** `lib/lockspire/clients.ex:105-179,211-230`.

```elixir
def register_client(attrs) when is_map(attrs) do
  with {:ok, normalized} <- normalize(attrs),
       {:ok, persisted_client} <- persist_client(normalized.client) do
    {:ok, %RegistrationResult{client: persisted_client, client_secret: normalized.plaintext_secret}}
  else
    {:error, errors} -> {:error, errors}
  end
end

defp validation_errors(normalized) do
  []
  |> validate_client_type(normalized.client_type)
  |> validate_auth_method(normalized.client_type, normalized.auth_method)
  |> validate_redirect_uris(normalized.redirect_uris)
  |> validate_scopes(normalized.allowed_scopes)
end
```

**DCR analog:** `lib/lockspire/protocol/registration.ex:128-146,417-460` preserves a deterministic ordered `with` and typed `%Registration.Error{code, field, reason}`. New shared shape validation should be pure and return data that each boundary translates into its existing error contract; do not make the public direct facade return DCR structs or make DCR leak internal `error_detail` maps.

```elixir
with :ok <- validate_jwks(metadata),
     :ok <- validate_grant_response_coherence(metadata),
     :ok <- validate_redirect_uris(metadata),
     :ok <- validate_token_endpoint_auth_metadata(metadata, server_policy) do
  validate_pkce_floor(metadata)
end
```

**Runtime guard to retain:** `lib/lockspire/protocol/authorization_request.ex:272-289`:

```elixir
if redirect_uri in client.redirect_uris do
  {:ok, redirect_uri}
else
  {:browser_error, browser_error(:invalid_request, "redirect_uri must match a registered URI", :invalid_redirect_uri)}
end
```

The registration relaxation applies only when a client has no authorization-code/redirect capability. A client with `authorization_code`, `code`, or any redirect-based response shape must still have a non-empty valid URI list. Device-only (`urn:ietf:params:oauth:grant-type:device_code`, no code/response capability) can be URI-less. Add the negative pair in both direct and DCR tests: device-only accepted; code/mixed client with no redirects deterministically rejected.

**OIDC analog:** `lib/lockspire/protocol/authorization_request.ex:967-971` makes `openid` built-in for request validation, while `lib/lockspire/protocol/discovery.ex:204-207` advertises `"openid"` independently. The direct facade currently rejects it at `Clients.validate_scopes/2` (`clients.ex:342-357`); move it into shared capability semantics, preserve scope-token validation, and prove direct+DCR parity.

**`private_key_jwt` analog:** `Registration.validate_jwks/1` (`registration.ex:305-349`) already owns its inline-JWKS / HTTPS-JWKS-URI constraints. The direct facade presently normalizes `:private_key_jwt` but rejects it in `validate_auth_method/3` (`clients.ex:267-283`) and does not copy JWKS fields into its persisted client struct. Plan the direct shape as a complete, persistable input (not merely relaxing the auth-method allowlist), then reuse the key-material constraint from one shared helper. Keep FAPI algorithm gates where the respective policy context exists.

**Discovery:** retain the truth-based architecture in `lib/lockspire/protocol/discovery.ex:59-85,204-225`: static support upper bounds and mounted-route publication are distinct. Any advertised client/auth shape must be proven registerable under the corresponding supported conditions.

### DPoP default store plus dependency injection

**Primary files:** `lib/lockspire/plug/enforce_sender_constraints.ex`, `lib/lockspire/protocol/protected_resource_dpop.ex`, `lib/lockspire/storage/dpop_replay_store.ex`, `lib/lockspire/storage/ecto/repository.ex`, plus plug/protocol/repository tests and generated docs/templates.

**Storage-port analog:** `lib/lockspire/storage/dpop_replay_store.ex:1-13` is the complete advanced-injection contract.

```elixir
@callback record_dpop_proof(DpopReplay.t()) ::
            {:ok, :accepted | :replay} | {:error, term()}
```

**Default resolution analog:** `lib/lockspire/protocol/protected_resource_dpop.ex:260-264`.

```elixir
defp dpop_replay_store(request),
  do:
    Keyword.get_lazy(request_options(request), :dpop_replay_store, fn ->
      Keyword.get(request_options(request), :token_store, Repository)
    end)
```

The standard path must resolve `Lockspire.Storage.Ecto.Repository`, which in turn resolves `Lockspire.Config.repo!/0` (`repository.ex:1290-1292`). Preserve a supplied behavior implementation exactly as `ProtectedResourceDPoPTest` does with nested `AcceptingReplayStore` / `ReplayingReplayStore` modules (`test/.../protected_resource_dpop_test.exs:11-17`).

**Durability analog:** `repository.ex:466-512` wraps pruning + `insert_all(... on_conflict: :nothing, conflict_target: [:replay_key])` in `transact/1`; `repository_dpop_replay_test.exs:94-153` proves first use, repeated use, fresh calls, and expiry. Do not replace this database uniqueness decision with ETS/process-local fallback. A store error must remain `invalid_dpop_proof` via `ProtectedResourceDPoP.record_dpop_proof_use/2` (`protected_resource_dpop.ex:122-142`).

**Critical integration bug to plan explicitly:** `EnforceSenderConstraints.maybe_validate_dpop/3` always puts `dpop_replay_store: Keyword.get(opts, :dpop_replay_store)` into request opts (`enforce_sender_constraints.ex:69-84`). When absent, that creates a present `nil` key; `Keyword.get_lazy/3` does not execute its fallback for a present nil, so `nil.record_dpop_proof/1` fails closed rather than selecting `Repository`. Construct opts by omitting nil or make resolver treat nil as absent, then add an end-to-end Plug test proving default Ecto selection. This is not just documentation work.

### Documentation, generated examples, compatibility, and release contracts

**Primary files:** `docs/protect-phoenix-api-routes.md`, `docs/supported-surface.md`, `priv/templates/lockspire.install/router.ex`, generated-host fixture files, `test/lockspire/release/support_surface_contract_test.exs`, `test/lockspire/release_readiness_contract_test.exs`, and likely a new v1.37 upgrade guide.

**Canonical-guide analog:** `docs/protect-phoenix-api-routes.md:11-31` owns the one protected pipeline. Its access-token section (`:48-65`) currently describes fields (`subject`, `scope`, `audience`, `expires_at`, `cnf`) that do not exist on the current struct, while fixture controller `test/support/.../protected_api_controller.ex:13-24` reads raw claims. Update them together to semantic accessor calls and make the guide the one source of truth.

**Generated-comment analog:** `priv/templates/lockspire.install/router.ex:11-18` is a comment-only canonical block and must remain a valid host-owned example. Default installation should not require `MyAppWeb.ProtectedApiReplayStore`; present injection as an advanced override. Update the compiled generated fixture in lockstep, because Phase 131 established template/fixture parity.

**Contract-test analog:** `test/lockspire/release/support_surface_contract_test.exs` uses literal, bounded text assertions; `test/lockspire/release_readiness_contract_test.exs:1-76` has an exact inventory of test names and will fail when tests are added or renamed. Add narrowly named contract tests and update that inventory in the same plan. Use `documentation_contract_test.exs` style for ExDoc/package-facing additions.

**Deprecation analog:** `docs/upgrading/v1.27.md` provides release-specific migration guidance without removing old fields. For v1.x, preserve `%AccessToken{claims: ...}`; describe raw access as low-level compatibility/extension input, do not claim it is removed. Only add an Elixir `@deprecated` annotation when an actual public function is superseded—fields cannot receive one. Do not silently change the meaning of existing raw claim values.

## Shared Patterns

### Public API evolution

**Source:** `lib/lockspire/access_token.ex:1-32`, `lib/lockspire/clients.ex:105-138`.

Add small, typed public functions to existing facade/value modules; preserve struct fields and return shapes. Use `@spec`, `@doc`, and direct unit tests. Avoid leaking protocol-only error structs across public boundaries.

### Fail-closed storage

**Source:** `lib/lockspire/protocol/protected_resource_dpop.ex:122-142` and `lib/lockspire/storage/ecto/repository.ex:466-512`.

Store errors turn into typed invalid-token failure; conflicts become replay; configured Repo access remains inside the Ecto adapter. No fallback storage state.

### Validation ordering and errors

**Source:** `lib/lockspire/protocol/registration.ex:128-146` and `lib/lockspire/clients.ex:211-230`.

Keep validations deterministic. DCR returns `%Registration.Error{}`; direct registration returns ordered `%{field, reason, detail}` entries. Tests should assert the exact field/reason for new capability errors while preserving old supported error contracts.

### Host ownership boundary

**Source:** `docs/protect-phoenix-api-routes.md:11-46,72-90`.

Lockspire verifies JWT/route constraints/sender proof; hosts decide tenant membership, object and billing authorization, response content, and rate limits. Examples must not suggest a claim accessor replaces product authorization.

## No Analog Found

| File | Role | Data flow | Reason |
|---|---|---|---|
| `lib/lockspire/client_registration/shape.ex` (if introduced) | pure shared validator | transform | Existing logic is split between private direct-facade and DCR functions; no neutral shared collaborator exists yet. Keep it small, dependency-light, and independent of both boundary facades pending Phase 134 topology work. |

## Plan-Shaping Risks

1. The direct `Clients` API does not merely need an allowlist edit: it currently rejects `:private_key_jwt`, rejects `openid`, requires redirects unconditionally, and omits JWKS fields from its persisted `%Client{}`. Plan its input/persistence contract before sharing validation.
2. The current default DPoP path is broken when entered through `EnforceSenderConstraints` because an explicit nil option masks the lazy default. Include a real-repository plug/integration proof, not only a unit test of `ProtectedResourceDPoP` called without opts.
3. Device-only registration relaxation must be capability-based, not a blanket empty-redirect exception. Retain the authorization-request exact-match guard and add mixed/code negative tests at both direct and DCR boundaries.
4. The generated fixture has an accepting custom replay store and raw-claims response. Updating guide, template, fixture, and release contract separately will drift; put them in one documentation-contract plan.
5. `test/lockspire/release_readiness_contract_test.exs` inventories test names exactly. Any new release/support test requires its inventory update in the same change.

## Metadata

**Analog search scope:** `lib/lockspire`, `test/lockspire`, `test/integration`, `test/support`, `priv/templates`, `docs`, migrations  
**Files scanned:** 42  
**Pattern extraction date:** 2026-08-26
