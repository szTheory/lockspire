defmodule Lockspire.Protocol.TokenExchange.Internal.LegacyOptions do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Observability
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Storage.Ecto.Repository

  @spec from_request(map(), atom()) :: {:ok, Dependencies.t()} | {:error, struct()}
  def from_request(request, grant \\ :all) when is_map(request) do
    dependencies = build(request_options(request))

    with {:ok, authority} <- transaction_authority(dependencies.transaction_store),
         true <-
           authority_includes?(authority, %{
             client_store: dependencies.client_store,
             transaction_store: dependencies.transaction_store
           }),
         {:ok, lifetime} <- ClientLifetime.adapt(dependencies.client_store, authority) do
      dependencies = %{dependencies | client_lifetime: lifetime}

      case grant do
        :all -> {:ok, dependencies}
        _ -> Dependencies.validate(dependencies, grant)
      end
    else
      _ -> {:error, authority_error()}
    end
  end

  defp build(opts) do
    client_store = Keyword.get(opts, :client_store, Repository)
    token_store = Keyword.get(opts, :token_store, Repository)

    %Dependencies{
      client_store: client_store,
      client_lifetime: nil,
      token_store: token_store,
      device_authorization_store: Keyword.get(opts, :device_authorization_store, Repository),
      ciba_authorization_store: Keyword.get(opts, :ciba_authorization_store, Repository),
      interaction_store: Keyword.get(opts, :interaction_store, Repository),
      key_store: Keyword.get(opts, :key_store, Repository),
      server_policy_store: Keyword.get(opts, :server_policy_store, client_store),
      dpop_replay_store: Keyword.get(opts, :dpop_replay_store, client_store),
      audit_store: Keyword.get(opts, :audit_store, token_store),
      transaction_store: Keyword.get(opts, :transaction_store, token_store),
      now: Keyword.get(opts, :now, &DateTime.utc_now/0),
      token_generator: Keyword.get(opts, :token_generator),
      access_token_generator: Keyword.get(opts, :access_token_generator),
      refresh_token_generator: Keyword.get(opts, :refresh_token_generator),
      token_format_options: Keyword.get(opts, :token_format_options, []),
      token_exchange_validator:
        Keyword.get(opts, :token_exchange_validator, Config.token_exchange_validator()),
      mtls_cert: Keyword.get(opts, :mtls_cert),
      dpop_max_age: Keyword.get(opts, :dpop_max_age, 300),
      dpop_clock_skew: Keyword.get(opts, :dpop_clock_skew, 30),
      dpop_nonce_max_age: Keyword.get(opts, :dpop_nonce_max_age, 300),
      secret_key_base: Keyword.get(opts, :secret_key_base),
      signer: Keyword.get(opts, :signer),
      issuer: Keyword.get(opts, :issuer, Config.issuer!()),
      account_resolver: Keyword.get(opts, :account_resolver, Config.account_resolver!()),
      observability_emitter: Keyword.get(opts, :observability_emitter, Observability),
      config: Keyword.get(opts, :config, Config),
      telemetry: Keyword.get(opts, :telemetry, Observability),
      capabilities: Keyword.get(opts, :capabilities, %{})
    }
  end

  defp request_options(request), do: Map.get(request, :opts, Map.get(request, "opts", []))

  defp transaction_authority(transaction_store) when is_atom(transaction_store) do
    authority = transaction_store.transaction_authority()

    if valid_authority?(authority), do: {:ok, authority}, else: {:error, :invalid_authority}
  rescue
    _error -> {:error, :authority_unavailable}
  end

  defp transaction_authority(_transaction_store), do: {:error, :authority_unavailable}

  defp valid_authority?(%{identity: identity, participants: participants})
       when not is_nil(identity) and is_map(participants),
       do: Enum.all?(participants, fn {role, store} -> is_atom(role) and is_atom(store) end)

  defp valid_authority?(_authority), do: false

  defp authority_includes?(authority, required) do
    participants = Map.get(authority, :participants, [])
    Enum.all?(required, fn {role, store} -> Map.get(participants, role) == store end)
  end

  defp authority_error do
    %Error{
      status: 500,
      error: "server_error",
      error_description:
        "Client and transaction stores must explicitly declare one shared lifetime transaction authority",
      reason_code: :transaction_authority_unavailable
    }
  end
end
