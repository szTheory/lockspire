defmodule Lockspire.Protocol.TokenExchange.Internal.LegacyOptions do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Observability
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Storage.Ecto.Repository

  @spec from_request(map(), atom()) :: {:ok, Dependencies.t()} | {:error, struct()}
  def from_request(request, grant \\ :all) when is_map(request) do
    dependencies = build(request_options(request))

    case grant do
      :all -> {:ok, dependencies}
      _ -> Dependencies.validate(dependencies, grant)
    end
  end

  defp build(opts) do
    client_store = Keyword.get(opts, :client_store, Repository)
    token_store = Keyword.get(opts, :token_store, Repository)

    %Dependencies{
      client_store: client_store,
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
      config: Keyword.get(opts, :config, Config),
      telemetry: Keyword.get(opts, :telemetry, Observability)
    }
  end

  defp request_options(request), do: Map.get(request, :opts, Map.get(request, "opts", []))
end
