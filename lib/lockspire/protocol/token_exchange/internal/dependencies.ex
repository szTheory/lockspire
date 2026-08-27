defmodule Lockspire.Protocol.TokenExchange.Internal.Dependencies do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Observability
  alias Lockspire.Protocol.TokenResult.Error

  @enforce_keys [
    :client_store,
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
    :token_exchange_validator
  ]
  defstruct [
    :client_store,
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
    config: Config,
    telemetry: Observability,
    capabilities: %{}
  ]

  @type t :: %__MODULE__{}

  @spec validate(t(), atom()) :: {:ok, t()} | {:error, Error.t()}
  def validate(%__MODULE__{} = dependencies, grant) do
    if Enum.all?(required_capabilities(grant), &capability_available?(dependencies, &1)) do
      {:ok, dependencies}
    else
      {:error, unavailable_error()}
    end
  end

  @doc false
  @spec attach(map(), t()) :: map()
  def attach(request, %__MODULE__{} = dependencies) when is_map(request),
    do: Map.put(request, :token_exchange_dependencies, dependencies)

  @doc false
  @spec fetch!(map()) :: t()
  def fetch!(request) when is_map(request), do: Map.fetch!(request, :token_exchange_dependencies)

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
      {:token_store, :fetch_lifecycle_token, 1},
      {:token_store, :store_token, 1}
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
end
