# Phase 56: RAR Domain Validation & Storage - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 21 (5 NEW source + 1 NEW migration + 5 NEW tests + 1 NEW test-support + 9 EXTEND)
**Analogs found:** 19 / 21 (2 partial — see "No Analog Found")

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| NEW `lib/lockspire/host/rar_type_validator.ex` | host-seam (behaviour) | request-response | `lib/lockspire/host/token_exchange_validator.ex` | exact |
| NEW `lib/lockspire/host/permissive_rar_validator.ex` (test-support default) | host-seam (default impl) | request-response | `lib/lockspire/host/default_delegation_validator.ex` + `default_deny_token_exchange_validator.ex` | exact |
| NEW `lib/lockspire/rar/dispatcher.ex` | service (internal dispatcher) | request-response + telemetry-span | None for span; closest is `Lockspire.Observability.emit/4` (event shape) — span itself is from `:telemetry.span/3` stdlib | partial (composes existing pieces) |
| NEW `lib/lockspire/rar/fingerprint.ex` | utility (pure transform/hash) | transform | `lib/lockspire/redaction.ex` lines 159-169 (`:crypto.hash(:sha256, ...)` idiom) | role-match (different domain, same hash idiom) |
| NEW `lib/lockspire/rar.ex` | utility (small public helper) | transform | `lib/lockspire/oban.ex` (small public Lockspire.* module shape) | role-match |
| NEW `priv/repo/migrations/<ts>_add_rar_durable_storage.exs` | migration | DDL | `priv/repo/migrations/20260506020000_add_rar_intake_state.exs` (Phase 55 alter-table) + `20260429110020_create_lockspire_logout_deliveries.exs` (FK + index) | exact (composite) |
| EXTEND `lib/lockspire/config.ex` (add `rar_validators/0`, `rar_types_supported/0`) | config | accessor | `lib/lockspire/config.ex` lines 37-44 (`token_exchange_validator/0`) | exact (in-file mirror) |
| EXTEND `lib/lockspire/protocol/authorization_request.ex` (`validate_authorization_details/2`) | controller | request-response (validation pipeline) | self lines 570-590 (existing function) | exact (extension point) |
| EXTEND `lib/lockspire/protocol/authorization_flow.ex` (`maybe_store_consent/3`, `issue_authorization_code/3`) | controller | CRUD (consent + token write) | self lines 252-316 (existing functions) | exact (extension point) |
| EXTEND `lib/lockspire/protocol/refresh_exchange.ex` (propagate `consent_grant_id`) | controller | CRUD (rotation) | self lines 291-327 (`build_rotated_*` mirror `family_id`/`sid` carry-forward) | exact (in-file mirror) |
| EXTEND `lib/lockspire/protocol/consent_policy.ex` (`reusable_grant/4` with fingerprint) | service (decision) | request-response | self lines 1-41 (existing 3-arg form) | exact (extension point) |
| EXTEND `lib/lockspire/protocol/pushed_authorization_request.ex` (`persist_pushed_request/3` + `pre_validated?` flag on consume) | controller | CRUD | self lines 105-133 | exact (extension point) |
| EXTEND `lib/lockspire/domain/consent_grant.ex` (add 2 fields) | model (struct) | n/a | self lines 1-39 | exact |
| EXTEND `lib/lockspire/storage/ecto/consent_grant_record.ex` (add 2 fields + cast + projection) | model (Ecto schema) | CRUD | self lines 1-70 | exact |
| EXTEND `lib/lockspire/domain/token.ex` (add `consent_grant_id`) | model (struct) | n/a | self lines 1-61 | exact |
| EXTEND `lib/lockspire/storage/ecto/token_record.ex` (add field + cast + projection) | model (Ecto schema) | CRUD | self lines 1-95 | exact |
| NEW `test/lockspire/rar/fingerprint_test.exs` | test (unit + property) | transform-assert | RESEARCH.md §"Property-test scaffold" (no in-repo property test exists yet) | partial (no in-repo property analog) |
| NEW `test/lockspire/rar/dispatcher_test.exs` | test (unit + telemetry assert) | request-response | `test/integration/phase55_rar_intake_e2e_test.exs` lines 44-61 (`Application.put_env` swap pattern) | role-match |
| NEW `test/lockspire/host/rar_type_validator_test.exs` | test (behaviour smoke) | n/a | (host-behaviour tests are minimal — pattern is "behaviour module compiles + callbacks declared") | role-match |
| NEW `test/lockspire/rar_test.exs` | test (helper) | transform | `Ecto.Changeset.traverse_errors/2` doctest in RESEARCH.md §Example 4 | partial |
| NEW `test/support/test_rar_validators.ex` | test-support (fake host impl) | request-response | `test/support/test_account_resolver.ex` | exact |

## Pattern Assignments

### `lib/lockspire/host/rar_type_validator.ex` (host-seam, behaviour)

**Analog:** `lib/lockspire/host/token_exchange_validator.ex` (verbatim shape)

**Module skeleton** (verbatim from analog, lines 1-20):
```elixir
defmodule Lockspire.Host.TokenExchangeValidator do
  @moduledoc """
  Behaviour for validating token exchange requests against host application business logic.
  """

  alias Lockspire.Host.TokenExchangeContext

  @doc """
  Validates a token exchange request.

  Returns:
    - `:ok` to permit the exchange with default claims.
    - `{:ok, %{claims: claims}}` to permit and merge additional claims.
    - `{:error, reason}` to deny the exchange.
  """
  @callback validate(context :: TokenExchangeContext.t()) ::
              :ok
              | {:ok, %{claims: map()}}
              | {:error, term()}
end
```

**Phase 56 shape** (apply per D-04):
```elixir
defmodule Lockspire.Host.RarTypeValidator do
  @moduledoc """
  Behaviour for validating a single Rich Authorization Request detail object
  for one specific `type` value. See `Lockspire.RAR.error_description/1` for
  the error-formatting helper.
  """

  @callback validate(detail :: map(), ctx :: map()) ::
              {:ok, map()} | {:error, Ecto.Changeset.t() | String.t()}
end
```

**Why this analog:** Same host-seam discipline (single behaviour module, no macros, runtime config registration via `Application.get_env`). `TokenExchangeValidator` is also two-arity-with-context-struct precedent, justifying D-04's `(detail, ctx)` shape.

---

### `lib/lockspire/host/permissive_rar_validator.ex` (test-support default impl, planning's call)

**Analog:** `lib/lockspire/host/default_deny_token_exchange_validator.ex` (verbatim shape — short default impl with `Logger.warning`)

**Verbatim analog body** (lines 1-19):
```elixir
defmodule Lockspire.Host.DefaultDenyTokenExchangeValidator do
  @moduledoc """
  Default implementation of the token exchange validator that denies all requests.
  """
  @behaviour Lockspire.Host.TokenExchangeValidator

  require Logger
  alias Lockspire.Host.TokenExchangeContext

  @impl true
  def validate(%TokenExchangeContext{} = context) do
    Logger.warning(
      "Token exchange requested by client #{context.client_id} but no validator is configured. Denying."
    )

    {:error, :exchange_not_configured}
  end
end
```

**Note for planner:** RESEARCH.md Open Question #4 recommends shipping this as test-support **only** (do NOT make it the default in `Config.rar_validators/0`; default `%{}` strict-rejects, which is safer than accept-all). If planner agrees, place under `test/support/test_rar_validators.ex` rather than `lib/lockspire/host/`. The analog above is included because it is the closest in-repo body shape regardless of final location.

**Companion analog (`DefaultDelegationValidator`)** lines 1-12 — multi-clause head pattern in case the planner wants a struct-context permissive impl:
```elixir
defmodule Lockspire.Host.DefaultDelegationValidator do
  @moduledoc "..."
  @behaviour Lockspire.Host.TokenExchangeValidator
  alias Lockspire.Host.TokenExchangeContext

  @impl true
  def validate(%TokenExchangeContext{actor_token: nil}), do: :ok
  def validate(%TokenExchangeContext{actor_token: actor_token}) when is_map(actor_token) do
    # ...
  end
end
```

---

### `lib/lockspire/rar/dispatcher.ex` (service, internal dispatch + telemetry-span)

**Analog (telemetry shape):** `lib/lockspire/observability.ex` lines 24-43 — the `emit/4` helper for the `[:lockspire, :rar, :unknown_type]` event.

```elixir
@spec emit(entity(), action(), measurements(), metadata()) :: :ok
def emit(entity, action, measurements \\ %{}, metadata \\ %{})
    when is_atom(entity) and is_atom(action) do
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
```

**Use as:** `Observability.emit(:rar, :unknown_type, %{count: 1}, %{type: type, client_id: ctx[:client_id]})` for the strict-reject event (D-20). Note the helper takes 2-element event names (`[entity, action]`); the validation span is 3-element (`[:lockspire, :rar, :validation, :start|:stop|:exception]`) so it must call `:telemetry.span/3` directly inside the dispatcher (RESEARCH.md note after Example 2 confirms — keep `Observability.emit/4` 2-element-only).

**Analog (config lookup pattern):** `lib/lockspire/config.ex` lines 37-44 (mirrored for the new `Config.rar_validators/0`):
```elixir
@spec token_exchange_validator() :: module()
def token_exchange_validator do
  Application.get_env(
    @app,
    :token_exchange_validator,
    Lockspire.Host.DefaultDelegationValidator
  )
end
```

**Analog (call-site lookup):** `lib/lockspire/protocol/rfc8693_exchange.ex:267-271`:
```elixir
defp token_exchange_validator(request) do
  request
  |> Map.get(:opts, [])
  |> Keyword.get_lazy(:token_exchange_validator, fn -> Config.token_exchange_validator() end)
end
```

**Pattern note for dispatcher body:** No in-repo `:telemetry.span/3` wrapper exists today (`grep` confirmed zero hits for `telemetry.span` in `lib/`). The dispatcher introduces this idiom; use the verbatim body in RESEARCH.md §"Code Examples 2" (lines 588-674 of 56-RESEARCH.md) which is already verified-correct against `:telemetry.span/3` semantics. **Anti-pattern reminder:** do NOT wrap `:telemetry.span/3` in your own try/rescue (Pitfall in RESEARCH.md "Anti-Patterns to Avoid").

---

### `lib/lockspire/rar/fingerprint.ex` (utility, JCS canonicalize + SHA-256)

**Analog (SHA-256 idiom):** `lib/lockspire/redaction.ex` lines 159-169:
```elixir
def handle(type, value) when is_atom(type) do
  encoded =
    value
    |> normalize_scalar()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 12)

  "#{type}_#{encoded}"
end
```

Six other call sites use the identical `|> then(&:crypto.hash(:sha256, &1))` pipe (`lib/lockspire/protocol/dpop.ex:57`, `protected_resource_dpop.ex:191`, `token_endpoint_dpop.ex:288`, `id_token.ex:103`, etc.) — this is the established Lockspire SHA-256 idiom. Use it.

**Phase 56 shape (verbatim from RESEARCH.md §Example 3):**
```elixir
defmodule Lockspire.RAR.Fingerprint do
  @moduledoc "RFC 8785 JCS canonicalization + SHA-256 hashing..."

  @spec compute([map()]) :: binary() | nil
  def compute([]), do: nil

  def compute(authorization_details) when is_list(authorization_details) do
    authorization_details
    |> Jcs.encode()
    |> then(&:crypto.hash(:sha256, &1))
  end
end
```

**Note (no in-repo JCS analog):** `grep` for `jcs\|Jcs` in `lib/` returns zero hits. The `jcs` Hex package (v0.2.0) is a new dep introduced in this phase (RESEARCH.md "Standard Stack" + "Environment Availability" — first task = `mix.exs` deps update).

---

### `lib/lockspire/rar.ex` (utility, public helper)

**Analog (small public Lockspire.* module shape):** `lib/lockspire/oban.ex` (69 lines) and `lib/lockspire/observability.ex` (64 lines) — both are short public modules with focused helpers + `@moduledoc`. No closer analog exists; this is a new minimal helper.

**Phase 56 shape (verbatim from RESEARCH.md §Example 4):**
```elixir
defmodule Lockspire.RAR do
  @moduledoc "Public helpers for host RAR validator implementations."

  @spec error_description(Ecto.Changeset.t() | String.t()) :: String.t()
  def error_description(%Ecto.Changeset{} = cs) do
    cs
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
    |> Enum.join("; ")
  end

  def error_description(description) when is_binary(description), do: description
end
```

---

### `priv/repo/migrations/<ts>_add_rar_durable_storage.exs` (migration)

**Analog 1 (alter-table + `{:array, :map}`):** `priv/repo/migrations/20260506020000_add_rar_intake_state.exs` (Phase 55, verbatim — 14 lines):
```elixir
defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddRarIntakeState do
  use Ecto.Migration

  def change do
    alter table(:lockspire_pushed_authorization_requests) do
      add(:authorization_details, {:array, :map}, default: [])
    end

    alter table(:lockspire_interactions) do
      add(:authorization_details, {:array, :map}, default: [])
    end
  end
end
```

**Analog 2 (`references` + `on_delete` + index):** `priv/repo/migrations/20260429110020_create_lockspire_logout_deliveries.exs` lines 6-30 (uses `:delete_all`; Phase 56 must use `:nilify_all` per D-14):
```elixir
add :logout_event_id, references(:lockspire_logout_events, on_delete: :delete_all), null: false
# ...
create index(:lockspire_logout_deliveries, [:logout_event_id])
```

**Phase 56 composite shape (verbatim from RESEARCH.md §Example 5):**
```elixir
defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddRarDurableStorage do
  use Ecto.Migration

  def change do
    alter table(:lockspire_consent_grants) do
      add(:authorization_details, {:array, :map}, default: [])
      add(:authorization_details_fingerprint, :binary)
    end

    alter table(:lockspire_tokens) do
      add(:consent_grant_id, references(:lockspire_consent_grants, on_delete: :nilify_all))
    end

    create_if_not_exists(
      index(:lockspire_consent_grants, [:account_id, :client_id, :authorization_details_fingerprint],
        name: :consent_grants_reuse_idx,
        where: "status = 'active'"
      )
    )

    create_if_not_exists(index(:lockspire_tokens, [:consent_grant_id]))
  end
end
```

**Migration timestamp note:** Phase 55's migration is `20260506020000`. Use a timestamp greater than that (e.g., `20260507000000_add_rar_durable_storage.exs` or whatever current `mix ecto.gen.migration` produces on the working day). Do NOT collide with Phase 55's timestamp.

---

### `lib/lockspire/config.ex` (EXTEND — add `rar_validators/0`, `rar_types_supported/0`)

**Analog (in-file mirror, lines 37-44):**
```elixir
@spec token_exchange_validator() :: module()
def token_exchange_validator do
  Application.get_env(
    @app,
    :token_exchange_validator,
    Lockspire.Host.DefaultDelegationValidator
  )
end
```

**Phase 56 extension (drop in alongside, after line 44):**
```elixir
@spec rar_validators() :: %{String.t() => module()}
def rar_validators do
  Application.get_env(@app, :rar_validators, %{})
end

@spec rar_types_supported() :: [String.t()]
def rar_types_supported do
  rar_validators() |> Map.keys() |> Enum.sort()
end
```

**Critical:** Default is `%{}` (D-09 strict-reject). Do NOT default to a permissive impl — see "no analog" guidance + RESEARCH.md Open Question #4.

---

### `lib/lockspire/protocol/authorization_request.ex` (EXTEND — `validate_authorization_details/2`)

**Analog (in-file extension point, lines 570-590):**
```elixir
defp validate_authorization_details(params, pushed?) do
  case Map.get(params, "authorization_details") do
    nil ->
      {:ok, []}

    "" ->
      {:ok, []}

    value when is_binary(value) ->
      with :ok <- validate_authorization_details_length(value, pushed?, params),
           {:ok, decoded} <- decode_authorization_details(value, params) do
        ensure_authorization_details_shape(decoded, params)
      end

    value when is_list(value) ->
      ensure_authorization_details_shape(value, params)

    _other ->
      invalid_authorization_details(params)
  end
end
```

**Existing redirect-error helper (lines 625-633) — REUSE for dispatcher errors:**
```elixir
defp invalid_authorization_details(params) do
  {:redirect_error,
   redirect_error(
     params,
     :invalid_authorization_details,
     "authorization_details must be a JSON array of objects",
     :invalid_authorization_details
   )}
end
```

**Phase 56 extension shape (planner derives):**
1. After `ensure_authorization_details_shape/2` succeeds, add a `case decoded do [] -> reject_empty(...); list -> Dispatcher.dispatch_each(list, ctx) end` step (Pitfall 6 — empty-array rejection per RFC 9396 §2 MUST).
2. On `Dispatcher.dispatch_each` returning `{:ok, normalized}`, the validated path now holds normalized output (D-08).
3. On `{:error, :invalid_authorization_details, description, _meta}`, funnel through the existing `redirect_error/4` helper (`error_description` MUST stay generic at redirect surface — D-11; offending type goes to telemetry/log only).

**PAR re-entry note (Pitfall 3 / WR-04):** `pushed_request_to_params/1` lines 723-739 already feeds `request.authorization_details` back into `validate/1`. Add `pre_validated?: true` flag so the dispatcher is bypassed on PAR consume re-entry (RESEARCH.md Open Question #3 — recommendation: bypass).

---

### `lib/lockspire/protocol/authorization_flow.ex` (EXTEND — `maybe_store_consent/3`, `issue_authorization_code/3`)

**Analog (in-file extension point — `maybe_store_consent/3`, lines 305-316):**
```elixir
defp maybe_store_consent(%Interaction{} = interaction, subject_id, remember?, opts) do
  grant = %ConsentGrant{
    account_id: subject_id,
    client_id: interaction.client_id,
    scopes: interaction.scopes_requested,
    granted_at: now(opts),
    status: :active,
    kind: ConsentPolicy.approval_kind(remember?)
  }

  consent_store(opts).grant_consent(grant)
end
```

**Phase 56 extension:** Add two fields to the struct literal:
```elixir
grant = %ConsentGrant{
  ...,
  authorization_details: interaction.authorization_details,
  authorization_details_fingerprint:
    Lockspire.RAR.Fingerprint.compute(interaction.authorization_details)
}
```

**Analog (in-file extension point — `issue_authorization_code/3`, lines 278-303):**
```elixir
defp issue_authorization_code(%Interaction{} = interaction, subject_id, opts) do
  raw_code = generate_code(opts)
  now = now(opts)
  token_hash = Policy.hash_token(raw_code)

  token = %Token{
    token_hash: token_hash,
    token_type: :authorization_code,
    client_id: interaction.client_id,
    account_id: subject_id,
    interaction_id: interaction.interaction_id,
    sid: interaction.sid,
    redirect_uri: interaction.redirect_uri,
    scopes: interaction.scopes_requested,
    audience: interaction.resources_requested,
    code_challenge: interaction.code_challenge,
    code_challenge_method: interaction.code_challenge_method,
    issued_at: now,
    expires_at: DateTime.add(now, @authorization_code_ttl, :second)
  }
  # ...
end
```

**Phase 56 extension:** Add `consent_grant_id: consent_grant_id` to the `%Token{...}` struct. Pitfall 4 in RESEARCH.md is explicit: this FK MUST be set at the auth-code Token row so it propagates code → access+refresh → refresh-rotated chain. Planning needs to thread the id from `maybe_store_consent/3`'s return into this call (currently they are sibling calls — wiring decision for the planner). Mirror `interaction_id` — set on auth-code Token, copied forward at exchange/rotation.

**Analog (`build_interaction/5`, lines 252-276):**
```elixir
defp build_interaction(%Validated{} = validated, interaction_id, subject_id, status, now) do
  %Interaction{
    interaction_id: interaction_id,
    sid: generate_sid(),
    client_id: validated.client_id,
    account_id: subject_id,
    scopes_requested: validated.scopes,
    resources_requested: validated.resources,
    authorization_details: validated.authorization_details,
    # ... 12 more fields ...
  }
end
```

**Note:** `validated.authorization_details` will now hold normalized output (D-08), so this line stays unchanged but its semantics shift. Tests asserting `interaction.authorization_details == raw_input` need updating — see "Phase 55 retrofit" callout in PATTERNS.md `## Shared Patterns`.

---

### `lib/lockspire/protocol/refresh_exchange.ex` (EXTEND — `consent_grant_id` propagation)

**Analog (in-file mirror, `build_rotated_access_token/6` lines 291-309):**
```elixir
defp build_rotated_access_token(
       %Client{} = client,
       formatted_access_token,
       rotated_at,
       context,
       %Token{} = source_token,
       requested_resources
     ) do
  %Token{
    token_hash: formatted_access_token.token_hash,
    token_type: :access_token,
    client_id: client.client_id,
    account_id: nil,
    sid: source_token.sid,             # carries forward
    audience: requested_resources,
    cnf: context.cnf,
    expires_at: DateTime.add(rotated_at, @access_token_ttl, :second)
  }
end
```

**Phase 56 extension** (add one line, mirror `sid`):
```elixir
%Token{
  ...,
  sid: source_token.sid,
  consent_grant_id: source_token.consent_grant_id,  # NEW — carries forward
  audience: requested_resources,
  ...
}
```

Apply identically to `build_rotated_refresh_token/5` (lines 311-327). RESEARCH.md §"Pattern 5" notes `family_id` is NOT passed via the struct here (storage layer derives it from `parent_token_id`); `consent_grant_id` IS passed via the struct because the storage layer does NOT derive it. Mirror the explicit-pass approach.

---

### `lib/lockspire/protocol/consent_policy.ex` (EXTEND — `reusable_grant/4` with fingerprint)

**Analog (in-file extension point, lines 1-41 — entire module):**
```elixir
@spec reusable_grant([ConsentGrant.t()], [String.t()], [String.t()]) ::
        {:reuse, ConsentGrant.t()} | :consent_required
def reusable_grant(grants, requested_scopes, prompt)
    when is_list(grants) and is_list(requested_scopes) and is_list(prompt) do
  if "consent" in prompt do
    :consent_required
  else
    requested = MapSet.new(requested_scopes)

    case Enum.find(grants, &reusable_grant?(&1, requested)) do
      nil -> :consent_required
      grant -> {:reuse, grant}
    end
  end
end

defp reusable_grant?(
       %ConsentGrant{
         status: :active,
         kind: :remembered,
         revoked_at: nil,
         scopes: granted_scopes
       },
       requested
     ) do
  MapSet.subset?(requested, MapSet.new(granted_scopes))
end

defp reusable_grant?(_grant, _requested), do: false
```

**Phase 56 shape (verbatim from RESEARCH.md §Example 6 — adds 4th positional arg per A7):**
```elixir
@spec reusable_grant([ConsentGrant.t()], [String.t()], [String.t()], binary() | nil) ::
        {:reuse, ConsentGrant.t()} | :consent_required
def reusable_grant(grants, requested_scopes, prompt, fingerprint)
    when is_list(grants) and is_list(requested_scopes) and is_list(prompt) do
  if "consent" in prompt do
    :consent_required
  else
    requested = MapSet.new(requested_scopes)

    case Enum.find(grants, &reusable_grant?(&1, requested, fingerprint)) do
      nil -> :consent_required
      grant -> {:reuse, grant}
    end
  end
end

defp reusable_grant?(
       %ConsentGrant{
         status: :active,
         kind: :remembered,
         revoked_at: nil,
         scopes: granted_scopes,
         authorization_details_fingerprint: grant_fp
       },
       requested,
       requested_fp
     ) do
  MapSet.subset?(requested, MapSet.new(granted_scopes)) and grant_fp == requested_fp
end

defp reusable_grant?(_grant, _requested, _fp), do: false
```

**Equality semantics (RESEARCH.md note after Example 6):** `nil == nil` reuses, `nil != binary` re-prompts, `bin1 != bin2` re-prompts. Correct on all four cases.

**Caller-update note:** All call-sites of the existing arity-3 form must be migrated. The planner should grep `reusable_grant(` to inventory.

---

### `lib/lockspire/protocol/pushed_authorization_request.ex` (EXTEND — `persist_pushed_request/3` + PAR consume `pre_validated?: true`)

**Analog (in-file extension point, lines 105-133):**
```elixir
defp persist_pushed_request(%AuthorizationRequest.Validated{} = validated, request, now) do
  pushed_request =
    PushedAuthorizationRequestState.issue(
      %{
        client_id: validated.client_id,
        redirect_uri: validated.redirect_uri,
        scopes: validated.scopes,
        resources_requested: validated.resources,
        authorization_details: validated.authorization_details,   # <-- already normalized after D-08
        prompt: validated.prompt,
        # ...
      },
      now: now,
      request_uri_generator: request_uri_generator(request)
    )
  # ...
end
```

**Phase 56 extension:** No body change here — `validated.authorization_details` automatically holds normalized output once `validate_authorization_details/2` is extended. Behavior shifts implicitly (D-08).

**Pitfall 3 / WR-04 fix at PAR consume:** Located in `authorization_request.ex:723` (`pushed_request_to_params/1`). Plumb `pre_validated?: true` into the `Dispatcher.dispatch_each/2` call so the dispatcher short-circuits on PAR consume re-entry. Implementation hint: dispatcher inspects ctx, returns `{:ok, details}` unchanged when flag is set.

---

### `lib/lockspire/domain/consent_grant.ex` (EXTEND — add 2 fields)

**Analog (entire file, 39 lines):**
```elixir
defmodule Lockspire.Domain.ConsentGrant do
  @moduledoc "Durable consent state granted by an account to a client."

  @type t :: %__MODULE__{
          id: integer() | nil,
          account_id: String.t(),
          client_id: String.t(),
          scopes: [String.t()],
          granted_at: DateTime.t(),
          status: :active | :revoked,
          kind: :remembered | :one_time,
          revoked_at: DateTime.t() | nil,
          # ...
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id, :account_id, :client_id, :granted_at,
    scopes: [],
    status: :active,
    kind: :remembered,
    # ...
    metadata: %{},
    inserted_at: nil,
    updated_at: nil
  ]
end
```

**Phase 56 extension:**
- Add to `@type t :: %__MODULE__{...}`:
  - `authorization_details: [map()]`
  - `authorization_details_fingerprint: binary() | nil`
- Add to `defstruct`:
  - `authorization_details: []` (default — matches migration default `[]`)
  - `authorization_details_fingerprint: nil`

---

### `lib/lockspire/storage/ecto/consent_grant_record.ex` (EXTEND — schema + cast + projection)

**Analog (entire file, 70 lines — schema/changeset/to_domain triple):**
```elixir
defmodule Lockspire.Storage.Ecto.ConsentGrantRecord do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Lockspire.Domain.ConsentGrant

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_consent_grants" do
    field(:account_id, :string)
    field(:client_id, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:granted_at, :utc_datetime_usec)
    # ...
    field(:metadata, :map, default: %{})
    timestamps()
  end

  def changeset(record, %ConsentGrant{} = grant) do
    record
    |> cast(Map.from_struct(grant), [:account_id, :client_id, :scopes, ...])
    |> validate_required([:account_id, :client_id, :scopes, :granted_at, :status, :kind])
  end

  def to_domain(%__MODULE__{} = record) do
    %ConsentGrant{
      id: record.id,
      account_id: record.account_id,
      # ... copy each field ...
      metadata: record.metadata || %{},
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
```

**Phase 56 extension — three places to touch in this single file:**
1. `schema "lockspire_consent_grants" do` — add:
   ```elixir
   field(:authorization_details, {:array, :map}, default: [])
   field(:authorization_details_fingerprint, :binary)
   ```
2. `cast/3` allowed keys list in `changeset/2` — append:
   ```elixir
   :authorization_details, :authorization_details_fingerprint
   ```
3. `to_domain/1` — add:
   ```elixir
   authorization_details: record.authorization_details || [],
   authorization_details_fingerprint: record.authorization_details_fingerprint
   ```

Mirror the `metadata: record.metadata || %{}` `nil` guard pattern for `authorization_details`.

---

### `lib/lockspire/domain/token.ex` (EXTEND — add `consent_grant_id`)

**Analog (entire file, 61 lines):**
```elixir
defmodule Lockspire.Domain.Token do
  @moduledoc "Durable token and token-family state owned by Lockspire."

  @type t :: %__MODULE__{
          id: integer() | nil,
          token_hash: String.t(),
          token_type: token_type(),
          # ...
          interaction_id: String.t() | nil,
          # ...
        }

  defstruct [
    :id, :token_hash, :token_type, :client_id, :expires_at,
    jti: nil,
    family_id: nil,
    # ...
    interaction_id: nil,
    # ...
  ]
end
```

**Phase 56 extension:** Mirror `interaction_id` (which is the closest existing analog — a nullable FK-id-by-string carried through code → access → refresh → rotation).
- `@type` — add `consent_grant_id: integer() | nil`
- `defstruct` — add `consent_grant_id: nil`

---

### `lib/lockspire/storage/ecto/token_record.ex` (EXTEND — schema + cast + projection)

**Analog (entire file, 95 lines — schema/changeset/to_domain triple):**
```elixir
schema "lockspire_tokens" do
  field(:token_hash, :string)
  field(:token_type, Ecto.Enum, values: [:authorization_code, :access_token, :refresh_token])
  field(:jti, :string)
  field(:family_id, :string)
  field(:generation, :integer, default: 0)
  field(:parent_token_id, :integer)
  # ...
  field(:interaction_id, :string)
  # ...
  timestamps()
end

def changeset(record, %Token{} = token) do
  record
  |> cast(Map.from_struct(token), [:token_hash, :token_type, :jti, :family_id, ..., :interaction_id, ...])
  |> validate_required([:token_hash, :token_type, :client_id, :expires_at])
  |> unique_constraint(:token_hash)
end

def to_domain(%__MODULE__{} = record) do
  %Token{
    id: record.id,
    token_hash: record.token_hash,
    # ...
    interaction_id: record.interaction_id,
    # ...
  }
end
```

**Phase 56 extension — three places:**
1. `schema "lockspire_tokens" do` — add:
   ```elixir
   field(:consent_grant_id, :integer)
   ```
   (Plain `:integer` mirrors `:parent_token_id`. The FK constraint lives in the migration, not the schema.)
2. `cast/3` allowed keys — append `:consent_grant_id`.
3. `to_domain/1` — add `consent_grant_id: record.consent_grant_id`.

Treat exactly like `interaction_id` / `parent_token_id` — nullable, no validation, no default.

---

### `test/support/test_rar_validators.ex` (NEW — test-support fake host impls)

**Analog:** `test/support/test_account_resolver.ex` (45 lines, verbatim shape):
```elixir
defmodule Lockspire.TestAccountResolver do
  @moduledoc false
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, _context) do
    {:ok, %{id: "account-123"}}
  end

  @impl true
  def resolve_account(account_reference, _context) do
    {:ok, %{id: account_reference}}
  end

  # ... other callbacks ...
end
```

**Phase 56 shape (planner picks naming):** A single file with multiple inline `defmodule` test fakes (one for each test scenario — happy-path, changeset-error, string-error, raises) mirrors the inline-fake pattern in RESEARCH.md §Example 7 (FakePaymentValidator inside `defmodule Lockspire.RAR.DispatcherTest do ... end`). Either approach works — extract to `test/support/` if reused across multiple test files.

---

### `test/lockspire/rar/dispatcher_test.exs` (NEW)

**Analog (test-time validator swap):** `test/integration/phase55_rar_intake_e2e_test.exs:44-61` — the `Application.put_env` setup pattern:
```elixir
setup_all do
  Application.put_env(:lockspire, Lockspire.Web.Endpoint, ...)
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  Application.put_env(:lockspire, :issuer, "https://example.test")
  Application.put_env(:lockspire, :mount_path, "")
  Application.put_env(:lockspire, :known_scopes, ["openid", "offline_access"])
  Application.put_env(:lockspire, :account_resolver, RarHostResolver)
  # ...
  :ok
end
```

**Phase 56 shape (verbatim from RESEARCH.md §Example 7 — sets `:rar_validators` env with `on_exit` restore + `async: false`):**
```elixir
defmodule Lockspire.RAR.DispatcherTest do
  use ExUnit.Case, async: false  # Application.put_env mutates global state

  defmodule FakePaymentValidator do
    @behaviour Lockspire.Host.RarTypeValidator
    @impl true
    def validate(%{"type" => "payment_initiation", "amount" => amount}, _ctx)
        when is_integer(amount) and amount > 0 do
      {:ok, %{"type" => "payment_initiation", "amount" => amount, "validated" => true}}
    end

    def validate(_detail, _ctx), do: {:error, "amount must be a positive integer"}
  end

  setup do
    prior = Application.get_env(:lockspire, :rar_validators)
    Application.put_env(:lockspire, :rar_validators, %{"payment_initiation" => FakePaymentValidator})
    on_exit(fn ->
      if prior, do: Application.put_env(:lockspire, :rar_validators, prior),
                else: Application.delete_env(:lockspire, :rar_validators)
    end)
    :ok
  end
end
```

**Critical:** `async: false` — Pitfall 8 in RESEARCH.md (env leak across async tests).

---

### `test/lockspire/rar/fingerprint_test.exs` + `fingerprint_property_test.exs` (NEW)

**Analog:** None in-repo. Property-test scaffold from RESEARCH.md §Example 3 note (StreamData):
```elixir
property "fingerprint is invariant under map-key construction order" do
  check all keys <- list_of(string(:alphanumeric, min_length: 1), min_length: 1, max_length: 8) |> nonempty(),
            values <- list_of(integer(), length: length(keys)) do
    pairs = Enum.zip(keys, values)
    a = pairs |> Enum.shuffle() |> Map.new() |> then(&[Map.put(&1, "type", "test")])
    b = pairs |> Enum.shuffle() |> Map.new() |> then(&[Map.put(&1, "type", "test")])
    assert Lockspire.RAR.Fingerprint.compute(a) == Lockspire.RAR.Fingerprint.compute(b)
  end
end
```

**New dep flag:** `{:stream_data, "~> 1.0", only: :test}` is NOT in `mix.lock` today (RESEARCH.md "Wave 0 Gaps"). Add to `mix.exs` deps in Wave 0 framework-install task.

---

### `test/lockspire/host/rar_type_validator_test.exs` (NEW)

**Analog:** No host-behaviour smoke test exists in `test/lockspire/host/` today. The pattern is minimal — one test asserting the behaviour module compiles and exports the expected `@callback`s. Suggested body (planner finalizes):
```elixir
defmodule Lockspire.Host.RarTypeValidatorTest do
  use ExUnit.Case, async: true

  test "behaviour module declares validate/2 callback" do
    callbacks = Lockspire.Host.RarTypeValidator.behaviour_info(:callbacks)
    assert {:validate, 2} in callbacks
  end
end
```

---

### `test/lockspire/rar_test.exs` (NEW)

**Analog:** RESEARCH.md §Example 4 doctests (use `ExUnit.DocTest`). Lockspire convention is doctests-as-primary for small public helpers; planner can opt for explicit unit tests too. Minimal shape:
```elixir
defmodule Lockspire.RARTest do
  use ExUnit.Case, async: true
  doctest Lockspire.RAR
end
```

---

## Shared Patterns

### Pattern S1: Host-seam discipline (applies to all `lib/lockspire/host/*` and `Config` accessors)

**Source:** `lib/lockspire/host/token_exchange_validator.ex` (behaviour) + `lib/lockspire/host/default_*_validator.ex` (default impl) + `lib/lockspire/config.ex:37-44` (accessor).

**Apply to:**
- NEW `lib/lockspire/host/rar_type_validator.ex`
- (Planning's call) NEW `lib/lockspire/host/permissive_rar_validator.ex` OR `test/support/test_rar_validators.ex`
- EXTEND `lib/lockspire/config.ex` — add `rar_validators/0` + `rar_types_supported/0`

**Discipline (PROJECT.md "host-seam discipline"):** single behaviour module, no macros, no compile-time auto-registration, `Application.get_env` runtime config only, default impl shipped alongside.

```elixir
# Behaviour
defmodule Lockspire.Host.X do
  @callback method(arg) :: result
end

# Default impl
defmodule Lockspire.Host.DefaultX do
  @behaviour Lockspire.Host.X
  @impl true
  def method(arg), do: ...
end

# Config accessor
def x do
  Application.get_env(:lockspire, :x, Lockspire.Host.DefaultX)
end
```

---

### Pattern S2: Domain → Record → Store extension (no new triple)

**Source:**
- `lib/lockspire/domain/consent_grant.ex` (struct + `@type t`)
- `lib/lockspire/storage/ecto/consent_grant_record.ex` (Ecto schema + `changeset/2` + `to_domain/1`)
- `lib/lockspire/domain/token.ex` (struct + `@type t`)
- `lib/lockspire/storage/ecto/token_record.ex` (Ecto schema + `changeset/2` + `to_domain/1`)

**Apply to:**
- EXTEND `lib/lockspire/domain/consent_grant.ex` (add 2 fields)
- EXTEND `lib/lockspire/storage/ecto/consent_grant_record.ex` (3 mirroring touches)
- EXTEND `lib/lockspire/domain/token.ex` (add 1 field)
- EXTEND `lib/lockspire/storage/ecto/token_record.ex` (3 mirroring touches)

**Three-touch checklist for each Record extension:**
1. Add field to `schema "lockspire_..." do`
2. Add field to `cast/3` allowed-keys list in `changeset/2`
3. Add field projection in `to_domain/1` (with `|| default` if non-nullable in domain)

**Discipline (D-13):** Do NOT introduce a parallel `AuthorizationGrant` domain — `ConsentGrant` already plays the durable-consent role.

---

### Pattern S3: FK propagation through token rotations (mirror `family_id` / `sid`)

**Source:** `lib/lockspire/protocol/refresh_exchange.ex:291-327` — `build_rotated_access_token/6` and `build_rotated_refresh_token/5`.

**Apply to:**
- EXTEND `lib/lockspire/protocol/authorization_flow.ex` — `issue_authorization_code/3` (auth-code Token gets `consent_grant_id`)
- EXTEND `lib/lockspire/protocol/refresh_exchange.ex` — both `build_rotated_*` helpers carry `consent_grant_id` forward
- (Planning audit) — code → access+refresh exchange path (Pitfall 4 / Assumption A5 in RESEARCH.md — module name not pinpointed; likely `Lockspire.Protocol.TokenExchange` or a `Lockspire.Protocol.AuthorizationCodeExchange`. First task: locate the exchange call site.)

**Pattern:**
```elixir
%Token{
  ...,
  sid: source_token.sid,                          # existing carry-forward
  consent_grant_id: source_token.consent_grant_id, # NEW carry-forward
  ...
}
```

**Critical:** `consent_grant_id` is set via the **domain struct** (not derived in storage layer), unlike `family_id` which storage derives from `parent_token_id`. RESEARCH.md "Pattern 5" note.

---

### Pattern S4: Telemetry emission (Observability + `:telemetry.span/3`)

**Source:**
- `lib/lockspire/observability.ex:24-43` — `Observability.emit/4` for 2-element event names (`[entity, action]`).
- `:telemetry.span/3` from telemetry stdlib (no in-repo analog exists; first use in this phase).

**Apply to:**
- NEW `lib/lockspire/rar/dispatcher.ex`:
  - `Observability.emit(:rar, :unknown_type, %{count: 1}, %{type: ..., client_id: ...})` for strict-reject (D-20).
  - `:telemetry.span([:lockspire, :rar, :validation], start_metadata, fn -> ... end)` for the validator-call span (start/stop/exception triplet).

**Critical (RESEARCH.md "Anti-Patterns"):** Do NOT wrap `:telemetry.span/3` in your own try/rescue — it suppresses `:exception` events. Let validator exceptions bubble through `span/3`'s built-in handler, then convert to `{:redirect_error, ...}` at a higher layer.

---

### Pattern S5: SHA-256 hash idiom

**Source:** `lib/lockspire/redaction.ex:159-169` (and 6 other call sites — `lib/lockspire/protocol/dpop.ex:57`, `protected_resource_dpop.ex:191`, `token_endpoint_dpop.ex:288`, `id_token.ex:103`, `security/policy.ex:143-160`, `token_formatter.ex:25`).

**Pattern:**
```elixir
content
|> normalize_or_canonicalize()
|> then(&:crypto.hash(:sha256, &1))
```

**Apply to:** NEW `lib/lockspire/rar/fingerprint.ex` — pipe `Jcs.encode/1` → `:crypto.hash(:sha256, ...)`.

---

### Pattern S6: `{:redirect_error, %Error{...}}` tuple flow

**Source:** `lib/lockspire/protocol/authorization_request.ex:625-633` (`invalid_authorization_details/1` redirect-error helper) + lines 771-779 (`redirect_error/4` constructor).

**Apply to:** NEW `lib/lockspire/rar/dispatcher.ex` — return `{:error, :invalid_authorization_details, description, %{type: type}}` shape from the dispatcher; the controller (EXTEND `authorization_request.ex`) lifts it into `{:redirect_error, redirect_error(params, :invalid_authorization_details, description, :reason_code)}` exactly as Phase 55 already does.

**Critical (D-11):** `error_description` at the redirect surface MUST stay generic ("authorization_details type is not supported") — do NOT include offending type name. Telemetry + Logger.warning carry the type for operators (D-21 + D-20).

---

### Pattern S7: Test-time host-impl swap via `Application.put_env` + `on_exit`

**Source:** `test/integration/phase55_rar_intake_e2e_test.exs:44-61` — establishes the canonical Lockspire pattern (also used in `phase48_token_exchange_e2e_test.exs:16-23`).

**Apply to:**
- NEW `test/lockspire/rar/dispatcher_test.exs`
- NEW `test/lockspire/rar_test.exs` (if it swaps env)
- NEW `test/integration/phase56_rar_validation_storage_e2e_test.exs`
- Extend `test/lockspire/protocol/authorization_request_test.exs` (Wave 0 retrofit)

**Discipline (Pitfall 8):** `async: false` for ANY test that mutates `:rar_validators`. Capture prior value in `setup`, restore in `on_exit`. Do NOT introduce Mox.

---

### Pattern S8: Phase 55 retrofit (D-08 — validator output replaces raw input)

**Inventory action for planner:**
```bash
grep -rn "authorization_details ==" /Users/jon/projects/lockspire/test/
grep -rn "interaction.authorization_details" /Users/jon/projects/lockspire/test/
grep -rn "pushed_authorization_request.*authorization_details\|PushedAuthorizationRequest.*authorization_details" /Users/jon/projects/lockspire/test/
```

**Apply to:** Every Phase 55 test fixture or integration test that asserts raw-input round-trip on `Interaction.authorization_details` or `PushedAuthorizationRequest.authorization_details`. After D-08, those fields hold normalized output, not raw input. Update the assertions.

**Files most likely affected:**
- `test/integration/phase55_rar_intake_e2e_test.exs`
- `test/lockspire/protocol/authorization_request_test.exs` (and the `validate_authorization_details` unit tests)
- `test/lockspire/protocol/pushed_authorization_request_test.exs`
- Any fixture in `test/support/fixtures/`

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/lockspire/rar/fingerprint.ex` (JCS canonicalization) | utility | transform | No in-repo `jcs`/JCS usage. The `jcs` Hex package (v0.2.0) is NEW in this phase. **Planner action:** First task is `mix.exs` deps update — `{:jcs, "~> 0.2"}`. Mitigation: SHA-256 idiom (S5 pattern above) IS established; only the JCS encode step is new. |
| `test/lockspire/rar/fingerprint_property_test.exs` | test (property) | invariant-assert | No in-repo property test exists today (`stream_data` not in `mix.lock`). **Planner action:** Add `{:stream_data, "~> 1.0", only: :test}` to `mix.exs` in Wave 0 framework-install. Use scaffold from RESEARCH.md §Example 3 note. |

## Metadata

**Analog search scope:**
- `lib/lockspire/host/` (host-seam analogs)
- `lib/lockspire/protocol/` (extension points + redirect-error machinery)
- `lib/lockspire/domain/` + `lib/lockspire/storage/ecto/` (Domain/Record triple)
- `lib/lockspire/config.ex` (accessor pattern)
- `lib/lockspire/observability.ex` + `lib/lockspire/redaction.ex` (telemetry + SHA-256)
- `priv/repo/migrations/` (migration shape — JSONB array, FK, partial index)
- `test/support/` (test-double pattern)
- `test/integration/phase55_rar_intake_e2e_test.exs` + `phase48_token_exchange_e2e_test.exs` (env-swap test pattern)

**Files scanned:** 21 source/migration/test files read; ~6 grep passes for cross-cutting idioms (telemetry.span, crypto.hash, on_delete, Application.put_env).

**Pattern extraction date:** 2026-05-06

**Confidence:** HIGH — every Phase 56 file has either an exact in-repo analog or composes two established Lockspire patterns. Only the `Jcs.encode/1` step is genuinely new code with no in-repo precedent (and the `jcs` package itself encapsulates the RFC 8785 complexity).
