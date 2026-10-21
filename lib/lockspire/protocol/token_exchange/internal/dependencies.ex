defmodule Lockspire.Protocol.TokenExchange.Internal.Dependencies do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Observability
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Storage.ClientLifetime

  @enforce_keys [
    :client_store,
    :client_lifetime,
    :token_store,
    :device_authorization_store,
    :ciba_authorization_store,
    :interaction_store,
    :key_store,
    :server_policy_store,
    :dpop_replay_store,
    :audit_store,
    :transaction_store,
    :now,
    :token_exchange_validator,
    :issuer,
    :account_resolver,
    :observability_emitter
  ]
  defstruct [
    :client_store,
    :client_lifetime,
    :token_store,
    :device_authorization_store,
    :ciba_authorization_store,
    :interaction_store,
    :key_store,
    :server_policy_store,
    :dpop_replay_store,
    :audit_store,
    :transaction_store,
    :now,
    :token_generator,
    :access_token_generator,
    :refresh_token_generator,
    token_format_options: [],
    token_exchange_validator: nil,
    mtls_cert: nil,
    dpop_max_age: 300,
    dpop_clock_skew: 30,
    dpop_nonce_max_age: 300,
    secret_key_base: nil,
    signer: nil,
    issuer: nil,
    account_resolver: nil,
    observability_emitter: nil,
    config: Config,
    telemetry: Observability,
    capabilities: %{}
  ]

  @type t :: %__MODULE__{}

  @spec validate(t(), atom()) :: {:ok, t()} | {:error, Error.t()}
  def validate(%__MODULE__{} = dependencies, grant) do
    if participants_available?(dependencies, grant) and
         Enum.all?(required_capabilities(grant), &capability_available?(dependencies, &1)) do
      {:ok, dependencies}
    else
      {:error,
       if(participants_available?(dependencies, grant),
         do: unavailable_error(),
         else: authority_error()
       )}
    end
  end

  @doc false
  @spec attach(map(), t()) :: map()
  def attach(request, %__MODULE__{} = dependencies) when is_map(request),
    do: Map.put(request, :token_exchange_dependencies, dependencies)

  @doc false
  @spec fetch!(map()) :: t()
  def fetch!(request) when is_map(request), do: Map.fetch!(request, :token_exchange_dependencies)

  defp participants_available?(
         %__MODULE__{client_lifetime: %ClientLifetime{} = lifetime} = d,
         grant
       ) do
    authority = lifetime.transaction_authority
    participants = if is_map(authority), do: Map.get(authority, :participants), else: nil
    required = required_participants(d, grant)

    is_map(participants) and not is_nil(Map.get(authority, :identity)) and
      Enum.all?(required, fn {role, store} -> Map.get(participants, role) == store end) and
      lifetime.client_store == d.client_store
  end

  defp participants_available?(_dependencies, _grant), do: false

  defp required_participants(dependencies, grant) do
    base = [
      client_store: dependencies.client_store,
      transaction_store: dependencies.transaction_store
    ]

    grant_participants =
      case grant do
        :device_code ->
          [
            device_authorization_store: dependencies.device_authorization_store,
            token_store: dependencies.token_store,
            audit_store: dependencies.audit_store
          ]

        :ciba ->
          [
            ciba_authorization_store: dependencies.ciba_authorization_store,
            token_store: dependencies.token_store,
            audit_store: dependencies.audit_store
          ]

        :authorization_code_mutation ->
          [token_store: dependencies.token_store, audit_store: dependencies.audit_store]

        :refresh ->
          [token_store: dependencies.token_store, audit_store: dependencies.audit_store]

        :rfc8693 ->
          [token_store: dependencies.token_store, audit_store: dependencies.audit_store]

        _ ->
          []
      end

    Enum.uniq_by(base ++ grant_participants, &elem(&1, 0))
  end

  defp required_capabilities(:authorization_code) do
    [
      {:client_store, :fetch_client_by_id, 1},
      {:token_store, :fetch_authorization_code, 1}
    ]
  end

  # Request and grant validation must retain their OAuth error precedence. The
  # mutation-only capabilities are checked immediately before redemption, after
  # PKCE/client/redirect validation and before any durable write.
  defp required_capabilities(:authorization_code_mutation) do
    [
      {:token_store, :redeem_authorization_code, 3},
      {:transaction_store, :transact, 1},
      {:audit_store, :append_audit_event, 1}
    ]
  end

  defp required_capabilities(:device_code) do
    [
      {:client_store, :fetch_client_by_id, 1},
      {:device_authorization_store, :record_device_poll, 3},
      {:token_store, :store_token, 1},
      {:transaction_store, :transact, 1},
      {:audit_store, :append_audit_event, 1}
    ]
  end

  defp required_capabilities(:ciba) do
    [
      {:client_store, :fetch_client_by_id, 1},
      {:ciba_authorization_store, :record_ciba_poll, 3},
      {:token_store, :store_token, 1},
      {:transaction_store, :transact, 1},
      {:audit_store, :append_audit_event, 1}
    ]
  end

  defp required_capabilities(:refresh) do
    [
      {:token_store, :fetch_refresh_token, 1},
      {:transaction_store, :transact, 1},
      {:audit_store, :append_audit_event, 1}
    ]
  end

  defp required_capabilities(:rfc8693) do
    [
      {:client_store, :fetch_client_by_id, 1},
      {:client_store, :lock_clients, 1},
      {:token_store, :fetch_lifecycle_token, 1},
      {:token_store, :lock_lifecycle_tokens, 1},
      {:token_store, :store_token, 1},
      {:audit_store, :append_audit_event, 1},
      {:transaction_store, :transact, 1}
    ]
  end

  defp required_capabilities(_grant), do: []

  # Dependency capabilities are declared while adapting the legacy option bag,
  # rather than discovered on a hot protocol path.  This keeps unsupported
  # custom stores deterministic without making their exported functions part of
  # token-exchange control flow.
  defp capability_available?(dependencies, {field, function, arity}) do
    case Map.get(dependencies.capabilities, field, :all) do
      :all -> true
      capabilities when is_list(capabilities) -> {function, arity} in capabilities
      _other -> false
    end
  end

  defp unavailable_error do
    %Error{
      status: 500,
      error: "server_error",
      error_description: "Token exchange dependencies are unavailable",
      reason_code: :dependency_capability_unavailable
    }
  end

  defp authority_error do
    %Error{
      status: 500,
      error: "server_error",
      error_description:
        "Token exchange storage adapters must declare one shared transaction authority for the selected grant",
      reason_code: :transaction_authority_unavailable
    }
  end
end
