defmodule Lockspire.Plug.VerifyTokenTelemetryTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  alias Lockspire.KeyCache
  alias Lockspire.Plug.VerifyToken
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Domain.SigningKey

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})

    {handler_id, _events} = attach_events(self())
    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  # Mirrors test/lockspire/clients_test.exs:158-182 (the repo's telemetry idiom),
  # but uses the 4-arg handler so measurements (%{count: 1}, D-04) are assertable.
  defp attach_events(pid) do
    handler_id = "rs-token-format-test-#{System.unique_integer([:positive])}"
    events = [[:lockspire, :rs, :token_format]]

    :ok =
      :telemetry.attach_many(
        handler_id,
        events,
        fn event, measurements, metadata, test_pid ->
          send(test_pid, {:telemetry_event, event, measurements, metadata})
        end,
        pid
      )

    {handler_id, events}
  end

  # Mints a real signed at+jwt against an active SigningKey + refreshed KeyCache,
  # mirroring VerifyTokenTest.generate_key_and_token/2 (the repo's real-mint idiom,
  # also the pattern in test/integration/phase100_sender_constraint_e2e_test.exs).
  defp generate_key_and_token(claims \\ %{}, header_overrides \\ %{}) do
    jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})
    kid = "telemetry-test-kid-#{System.unique_integer()}"
    public_jwk = jose_jwk |> JOSE.JWK.to_public() |> JOSE.JWK.to_map() |> elem(1)

    key = %SigningKey{
      kid: kid,
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: public_jwk,
      status: :active,
      inserted_at: DateTime.utc_now()
    }

    {:ok, _} = Repository.publish_key(key)

    send(KeyCache, :refresh)
    :sys.get_state(KeyCache)

    default_claims = %{
      "client_id" => "telemetry_client",
      "iss" => Lockspire.Config.issuer!(),
      "sub" => "telemetry-user-#{System.unique_integer()}",
      "aud" => "https://billing.acme-ledger.test",
      "iat" => System.os_time(:second) - 60,
      "exp" => System.os_time(:second) + 3600,
      "nbf" => System.os_time(:second) - 60
    }

    merged_claims =
      default_claims
      |> Map.merge(claims)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    default_header = %{"alg" => "RS256", "kid" => kid, "typ" => "at+jwt"}

    merged_header =
      default_header
      |> Map.merge(header_overrides)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    {_, signed_token} =
      JOSE.JWT.sign(jose_jwk, merged_header, merged_claims)
      |> JOSE.JWS.compact()

    {signed_token, merged_claims}
  end

  defp build_opaque_token,
    do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

  defp call_with_bearer(token, opts \\ []) do
    conn(:get, "/")
    |> put_req_header("authorization", "Bearer #{token}")
    |> VerifyToken.call(VerifyToken.init(opts))
  end

  describe "[:lockspire, :rs, :token_format] telemetry" do
    test "emits :jwt with claims-sourced metadata on a verified at+jwt" do
      {token, claims} = generate_key_and_token()

      call_with_bearer(token)

      assert_received {:telemetry_event, [:lockspire, :rs, :token_format], %{count: 1},
                       %{
                         token_format: :jwt,
                         client_id: client_id,
                         audience: audience,
                         binding_type: binding_type
                       }}

      assert client_id == Map.get(claims, "client_id")
      assert audience == Map.get(claims, "aud")
      # No cnf binding on this token, so binding_type is nil.
      assert binding_type == nil
    end

    test "emits the literal :\"opaque-rejected\" atom with all-nil metadata on an opaque token" do
      token = build_opaque_token()

      call_with_bearer(token)

      assert_received {:telemetry_event, [:lockspire, :rs, :token_format], %{count: 1},
                       %{
                         token_format: :"opaque-rejected",
                         client_id: nil,
                         audience: nil,
                         binding_type: nil
                       }}
    end
  end
end
