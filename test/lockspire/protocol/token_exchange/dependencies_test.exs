defmodule Lockspire.Protocol.TokenExchange.DependenciesTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.LegacyOptions
  alias Lockspire.Storage.Ecto.Repository

  test "normalizes every supported legacy token option into one typed bundle" do
    now = fn -> ~U[2026-08-27 00:00:00Z] end
    validator = Lockspire.Host.DefaultDelegationValidator

    request = %{
      opts: [
        client_store: __MODULE__.ClientStore,
        token_store: __MODULE__.TokenStore,
        device_authorization_store: __MODULE__.DeviceStore,
        ciba_authorization_store: __MODULE__.CibaStore,
        interaction_store: __MODULE__.InteractionStore,
        key_store: __MODULE__.KeyStore,
        server_policy_store: __MODULE__.PolicyStore,
        dpop_replay_store: __MODULE__.ReplayStore,
        now: now,
        token_generator: :fallback_generator,
        access_token_generator: :access_generator,
        refresh_token_generator: :refresh_generator,
        token_format_options: [token_generator: :exchange_generator],
        token_exchange_validator: validator,
        mtls_cert: :certificate,
        dpop_max_age: 42,
        dpop_clock_skew: 7,
        dpop_nonce_max_age: 21,
        secret_key_base: "secret"
      ]
    }

    assert {:ok, %Dependencies{} = dependencies} = LegacyOptions.from_request(request)
    assert dependencies.client_store == __MODULE__.ClientStore
    assert dependencies.token_store == __MODULE__.TokenStore
    assert dependencies.device_authorization_store == __MODULE__.DeviceStore
    assert dependencies.ciba_authorization_store == __MODULE__.CibaStore
    assert dependencies.interaction_store == __MODULE__.InteractionStore
    assert dependencies.key_store == __MODULE__.KeyStore
    assert dependencies.server_policy_store == __MODULE__.PolicyStore
    assert dependencies.dpop_replay_store == __MODULE__.ReplayStore
    assert dependencies.audit_store == __MODULE__.TokenStore
    assert dependencies.transaction_store == __MODULE__.TokenStore
    assert dependencies.now == now
    assert dependencies.token_generator == :fallback_generator
    assert dependencies.access_token_generator == :access_generator
    assert dependencies.refresh_token_generator == :refresh_generator
    assert dependencies.token_format_options == [token_generator: :exchange_generator]
    assert dependencies.token_exchange_validator == validator
    assert dependencies.mtls_cert == :certificate
    assert dependencies.dpop_max_age == 42
    assert dependencies.dpop_clock_skew == 7
    assert dependencies.dpop_nonce_max_age == 21
    assert dependencies.secret_key_base == "secret"
  end

  test "keeps established production defaults and preserves nil override semantics" do
    assert {:ok, dependencies} = LegacyOptions.from_request(%{opts: [dpop_replay_store: nil]})

    assert dependencies.client_store == Repository
    assert dependencies.token_store == Repository
    assert dependencies.device_authorization_store == Repository
    assert dependencies.ciba_authorization_store == Repository
    assert dependencies.interaction_store == Repository
    assert dependencies.key_store == Repository
    assert dependencies.server_policy_store == Repository
    assert dependencies.dpop_replay_store == nil
    assert is_function(dependencies.now, 0)
  end

  test "reports an invalid durable capability as a deterministic safe token error" do
    assert {:ok, dependencies} = LegacyOptions.from_request(%{opts: [token_store: __MODULE__]})
    assert {:error, error} = Dependencies.validate(dependencies, :refresh)

    assert error.error == "server_error"
    assert error.reason_code == :dependency_capability_unavailable
    assert error.error_description == "Token exchange dependencies are unavailable"
  end
end
