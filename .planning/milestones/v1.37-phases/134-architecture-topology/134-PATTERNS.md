# Phase 134: Architecture Topology - Pattern Map

**Mapped:** 2026-08-27  
**Files analyzed:** 23 proposed/modified files  
**Analogs found:** 23 / 23

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `lib/lockspire/client_lifecycle.ex` (new neutral owner) | service | CRUD / transaction | `lib/lockspire/admin/clients.ex` | role-match |
| `lib/lockspire/client_metadata.ex` (new neutral normalizer/validator) | service | transform | `lib/lockspire/client_registration/shape.ex` | exact |
| `lib/lockspire/clients.ex` | public facade | request-response | `lib/lockspire/admin.ex` | exact |
| `lib/lockspire/admin/clients.ex` | outer facade | request-response | `lib/lockspire/admin.ex` | exact |
| `lib/lockspire/protocol/registration.ex` | protocol orchestrator | request-response | `lib/lockspire/protocol/registration_management.ex` | exact |
| `lib/lockspire/protocol/registration_management.ex` | protocol orchestrator | request-response / transaction | `lib/lockspire/protocol/registration.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | protocol service | transform | `lib/lockspire/protocol/discovery/authorization_response_capabilities.ex` | role-match |
| `lib/lockspire/protocol/discovery/routes.ex` (new neutral route input) | utility | transform | `lib/lockspire/client_registration/shape.ex` | partial |
| `lib/lockspire/web/router.ex` | delivery route | request-response | `lib/lockspire/web/admin_router.ex` | role-match |
| `lib/lockspire/web/controllers/discovery_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/jwks_controller.ex` | exact |
| `lib/lockspire/storage/prefix.ex` (new neutral utility; exact name at planner discretion) | utility | transform | `lib/lockspire/storage/ecto/prefix.ex` | exact |
| `lib/lockspire/storage/ecto/prefix.ex` | adapter | request-response | `lib/lockspire/storage/ecto/repository.ex` | role-match |
| `lib/lockspire/config.ex` | configuration facade | request-response | `lib/lockspire/config.ex` prefix readers | exact |
| `lib/lockspire/protocol/authorization_request.ex` | protocol orchestrator | request-response | `lib/lockspire/protocol/pushed_authorization_request.ex` | exact |
| `lib/lockspire/protocol/request_object.ex` | protocol collaborator | transform | `lib/lockspire/protocol/jar.ex` | role-match |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | protocol collaborator | request-response | `lib/lockspire/protocol/dpop.ex` | role-match |
| `lib/lockspire/protocol/userinfo.ex` | protocol service | request-response | `lib/lockspire/protocol/protected_resource_dpop.ex` | role-match |
| `lib/lockspire/protocol/token_exchange*.ex` | protocol services | request-response / transaction | current token-exchange leaf grant modules | exact |
| `test/lockspire/architecture_fitness_test.exs` | architecture test | static AST / batch | existing file | exact |
| `test/lockspire/client_lifecycle_test.exs` (new) | service test | CRUD / transaction | `test/lockspire/admin/clients_test.exs` | exact |
| `test/lockspire/protocol/registration_test.exs` | protocol contract test | request-response | existing file | exact |
| `test/lockspire/protocol/registration_management_test.exs` | protocol contract test | request-response / transaction | existing file | exact |
| `test/lockspire/{protocol,web}/discovery*_test.exs` | compatibility tests | request-response | existing discovery suites | exact |

## Pattern Assignments

### Neutral client metadata/lifecycle services

**Primary analogs:** `lib/lockspire/client_registration/shape.ex:13-33`, `lib/lockspire/admin/clients.ex:54-154`, and `lib/lockspire/protocol/registration_management.ex:164-241`.

Use the `Shape.validate/2` pattern: accept normalized internal maps, return a small stable issue map, and leave boundary-specific error translation to callers.

```elixir
@spec validate(map(), keyword()) :: :ok | {:error, [issue()]}
def validate(attrs, opts \\ []) when is_map(attrs) do
  errors =
    []
    |> validate_client_type(attrs.client_type)
    |> validate_auth_method(attrs.client_type, attrs.auth_method)

  case Enum.reverse(errors) do
    [] -> :ok
    issues -> {:error, issues}
  end
end
```

The neutral lifecycle owner should own the existing atomic repository/audit composition, copied from `Admin.Clients.create_dcr_client/1` rather than reimplemented in DCR or the admin facade:

```elixir
audit_event = client_audit_event(:dcr_client_created, :succeeded, client, actor, metadata)

case Repository.transact_with_audit(audit_event, fn -> Repository.register_client(client) end) do
  {:ok, %Client{} = persisted} -> {:ok, persisted}
  {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
  {:error, reason} -> {:error, reason}
end
```

**Required split:** DCR resolves `DcrPolicy` before invoking the neutral service and maps neutral errors to `%Registration.Error{}` (`registration.ex:108-195`). Direct/operator registration retains required scopes and `%Clients.RegistrationResult{}`. The service must not import `Lockspire.Admin`, `Lockspire.Protocol.Registration`, Phoenix, or LiveView.

### Compatible public facades

**Analog:** `lib/lockspire/admin.ex:1-88`.

Keep documented root/nested modules thin, typed, and delegate-only when an implementation moves:

```elixir
@spec disable_client(String.t(), map() | keyword()) ::
        {:ok, Lockspire.Domain.Client.t()} | {:error, :not_found | term()}
defdelegate disable_client(client_id, attrs \\ %{}), to: Clients
```

This is the appropriate compatibility device for a retained public name. Do not export a new neutral service merely because facades call it.

### DCR management lifecycle preservation

**Analog:** `lib/lockspire/protocol/registration_management.ex:58-105, 164-173`.

Keep the outer DCR authorization/policy/error/telemetry contract in the protocol layer, but delegate metadata application and persistence composition to the neutral owner. Preserve RAT rotation inside the same replacement transaction:

```elixir
with {:ok, resolved} <- DcrPolicy.resolve(server_policy, nil, metadata),
     :ok <- Registration.validate_intake_metadata(metadata, resolved, server_policy, client),
     {new_rat_plaintext, new_rat_hash} <- RegistrationAccessToken.generate(),
     {:ok, updated_client} <- persist_update(client, metadata, new_rat_hash) do
  {:ok, %UpdateSuccess{client: updated_client,
                       registration_access_token_plaintext: new_rat_plaintext}}
end
```

The existing `Admin.Clients.disable_client/2` call at lines 115-134 is the exact prohibited edge to invert; retain the `:invalid_token` collapse and DCR telemetry outside the new service.

### Discovery route capability inversion

**Analog:** `lib/lockspire/protocol/discovery.ex:84-180` and `lib/lockspire/web/controllers/discovery_controller.ex:8-16`.

Protocol discovery currently gets a concrete router with `Application.get_env(:lockspire, :discovery_router, Lockspire.Web.Router)`. Move that default/concrete choice to configuration or the web edge; discovery should consume a neutral capability/module or already-resolved endpoint input. Keep the web controller thin:

```elixir
conn
|> put_resp_header("cache-control", "public, max-age=300")
|> put_status(:ok)
|> json(DiscoveryJSON.openid_configuration(Discovery.openid_configuration()))
```

Do not move Phoenix route construction into protocol code. Preserve `Discovery.openid_configuration/0` and all existing discovery document tests.

### Prefix normalization inversion

**Analog:** `lib/lockspire/storage/ecto/prefix.ex:6-32` and `lib/lockspire/config.ex:192-207`.

Extract only pure normalization to a dependency-neutral module; configuration reads env then calls it. The Ecto adapter may ask Config for configured options, but the normalizer must not call Config:

```elixir
def normalize(prefix) when is_binary(prefix) do
  prefix |> String.trim() |> case do
    "" -> nil
    prefix -> if Regex.match?(@identifier, prefix), do: prefix, else: raise(ArgumentError, ...)
  end
end
```

Keep `Lockspire.Config.storage_prefix/0` and `oban_prefix/0` as public compatibility methods and preserve their nil/default behavior.

### Cycle inversion within protocol

**Analog seam pairs:**

- `authorization_request.ex:331` invokes `RequestObject.consume/3`; `request_object.ex:27` aliases `AuthorizationRequest.Error`. Introduce a tiny neutral error/result collaborator, not reciprocal aliases.
- `userinfo.ex:69-100` delegates DPoP checks to `ProtectedResourceDPoP.validate_userinfo_access/2`, while `protected_resource_dpop.ex:13` aliases `Userinfo.Error`. Move the common error/result type or adapt at the outer caller; retain `%Userinfo.Error{}` as a compatibility-facing result.
- Token group: `token_exchange.ex:8-13` dispatches leaf grants, while leaf/shared collaborators call `AccessTokenSigner.issue/3` (`grant_support.ex:1314`). Follow current leaf-grant `with` pipelines and extract narrow signing/issuance input or a lower-level collaborator; do not create a new protocol mega-facade.

### Architecture fitness tests

**Analog:** `test/lockspire/architecture_fitness_test.exs:12-75`.

Use parse-once, deterministic AST traversal with the violating path in the assertion message:

```elixir
Enum.each(production_files(@protocol_root), fn path ->
  refute ast_contains?(parse!(path), &host_repo_call?/1),
         "#{path} calls Lockspire.Config.repo!/0"
end)
```

Add one focused graph test/alias which shells only through Mix graph output (no new dependency), parses every cycle deterministically, and reports the exact cycle/edge. AST checks should reject protocol references to `Lockspire.Web` and `Lockspire.Admin`, preserve public facade exports with `function_exported?/3`, and retain the existing direct-Ecto checks.

### Contract/characterization tests

**Analogs:** `test/lockspire/protocol/registration_management_test.exs`, `test/lockspire/admin/clients_test.exs:121-146`, `test/lockspire/protocol/dcr_audit_attribution_test.exs`, and `test/lockspire/compatibility_baseline_contract_test.exs`.

Use boundary-level public calls and pattern-match only stable success/error structs. Add direct registration required-scope negative cases separately from DCR optional-scope cases; retain immutable-field, exact redirect/logout origin, PKCE, RAT rotation, and audit attribution assertions. No new test should assert a neutral module is public.

## Shared Patterns

### Error and redaction boundary

**Sources:** `registration.ex:115-123, 188-195`; `registration_management.ex:86-104`.

Neutral services return field/reason facts. Public DCR maps them to `%Registration.Error{}` and emits only code/field/reason telemetry. Never place plaintext client secret, RAT, or keys in an error or event.

### Persistence ownership

**Sources:** `admin/clients.ex:134-162`, `registration_management.ex:164-173`.

All lifecycle writes with audit state use the repository's atomic helper; facades retain actor selection and their own telemetry. This preserves DCR RAT and audit atomicity.

### Delivery boundary

**Sources:** `web/controllers/discovery_controller.ex:8-16`, `web/router.ex:1-41`, `admin.ex:1-88`.

Phoenix controllers/routers and admin LiveViews consume facades/protocol results; protocol code must not reach outward to the router, controller, LiveView, or admin facade.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Focused Mix/xref cycle assertion helper | config/test utility | batch | No existing xref-output parser; implement as a small deterministic test helper beside `ArchitectureFitnessTest`, using its AST-helper style. |

## Risks for Planning

1. `Lockspire.Admin.Clients` currently owns both policy validation and atomic audit persistence. Moving only aliases will leave duplicated metadata transformation in Registration/RegistrationManagement; move the shared mapping and lifecycle composition together, with outer error adapters.
2. The DCR management replacement path rotates RAT atomically through `Repository.replace_client_registration/4`; a generic update path would silently weaken the RAT/audit contract.
3. `Discovery.openid_configuration/0` has extensive protocol and web tests and an existing config default to `Lockspire.Web.Router`; inversion must preserve a compatible zero-arity API while removing the protocol-to-web export edge.
4. Token-cycle work is constrained to narrow collaborator extraction. Phase 135 owns repository/token-orchestrator decomposition, so avoid changing storage aggregate ownership here.
5. `docs/supported-surface.md` and compatibility tests make nested public names part of v1.x behavior; structural tests must verify exports without accidentally promoting new internal service names.

## Metadata

**Analog search scope:** `lib/lockspire`, `test/lockspire`, `docs`, `mix.exs`, CI scripts  
**Files scanned:** 45+  
**Pattern extraction date:** 2026-08-27
