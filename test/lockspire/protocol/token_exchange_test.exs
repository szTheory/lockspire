defmodule Lockspire.Protocol.TokenExchangeTest do
  use Lockspire.TokenExchangeCase

  @capability_inventory %{
    "authorization_code_test.exs" => 20,
    "device_code_test.exs" => 10,
    "ciba_and_resource_test.exs" => 4,
    "../token_exchange_test.exs" => 5
  }

  test "rejects unsupported grant types and unsupported token-endpoint auth methods" do
    secret = "post-secret"
    {:ok, basic_client} = create_client("client-basic-only", :client_secret_basic, secret)

    _code =
      create_authorization_code(basic_client,
        raw_code: "code-post",
        code_verifier: "verifier-post"
      )

    assert {:error, grant_error} =
             exchange(
               %{
                 "grant_type" => "refresh_token",
                 "code" => "code-post",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-post"
               },
               authorization: basic_auth(basic_client.client_id, secret)
             )

    assert grant_error.error == "unsupported_grant_type"

    assert {:error, auth_error} =
             exchange(%{
               "grant_type" => "authorization_code",
               "client_id" => basic_client.client_id,
               "client_secret" => secret,
               "code" => "code-post",
               "redirect_uri" => "https://client.example.com/callback",
               "code_verifier" => "verifier-post"
             })

    assert auth_error.error == "invalid_client"
    assert auth_error.reason_code == :unsupported_token_endpoint_auth_method
  end

  test "grant coordinators own facade dispatch without internal TokenExchange callbacks" do
    facade =
      File.read!(Path.expand("../../../lib/lockspire/protocol/token_exchange.ex", __DIR__))

    grant_support =
      File.read!(
        Path.expand(
          "../../../lib/lockspire/protocol/token_exchange/grant_support.ex",
          __DIR__
        )
      )

    coordinators = [
      "authorization_code_grant.ex",
      "device_code_grant.ex",
      "ciba_grant.ex"
    ]

    assert facade =~ "AuthorizationCodeGrant.exchange(request)"
    assert facade =~ "DeviceCodeGrant.exchange(request)"
    assert facade =~ "CibaGrant.exchange(request)"
    refute Regex.match?(~r/^\s*def exchange\(/m, grant_support)
    refute function_exported?(TokenExchange.GrantSupport, :exchange, 1)

    Enum.each(coordinators, fn coordinator ->
      source =
        File.read!(
          Path.expand("../../../lib/lockspire/protocol/token_exchange/#{coordinator}", __DIR__)
        )

      refute source =~ "TokenExchange.__"
      assert source =~ "GrantSupport"
    end)
  end

  test "stable facade exposes every public entry point and result field" do
    assert Code.ensure_loaded?(TokenExchange)
    assert function_exported?(TokenExchange, :exchange, 1)
    assert function_exported?(TokenExchange, :exchange_authorization_code, 1)
    assert function_exported?(TokenExchange, :issue_ciba_tokens, 4)

    assert Map.keys(struct(TokenExchange.Success)) |> Enum.sort() ==
             [
               :__struct__,
               :access_token,
               :expires_in,
               :id_token,
               :issued_token_type,
               :refresh_token,
               :scope,
               :token_type
             ]

    assert Map.keys(struct(TokenExchange.Error)) |> Enum.sort() ==
             [:__struct__, :dpop_nonce, :error, :error_description, :reason_code, :status]
  end

  test "facade routing matrix names one owner for every supported grant" do
    facade = File.read!(Path.expand("../../../lib/lockspire/protocol/token_exchange.ex", __DIR__))

    routing_matrix = [
      {"authorization_code", "Internal.AuthorizationCodeGrant.exchange(request)"},
      {"refresh_token", "exchange_refresh_token(request)"},
      {"urn:ietf:params:oauth:grant-type:device_code", "Internal.DeviceCodeGrant.exchange(request)"},
      {"urn:openid:params:grant-type:ciba", "Internal.CibaGrant.exchange(request)"},
      {"urn:ietf:params:oauth:grant-type:token-exchange", "exchange_rfc8693(request)"}
    ]

    Enum.each(routing_matrix, fn {grant_type, owner_call} ->
      assert facade =~ ~s("#{grant_type}" -> #{owner_call})
    end)

    assert facade =~ "Internal.RefreshExchange.exchange_refresh_token(client, request)"
    assert facade =~ "Internal.Rfc8693Exchange.exchange(client, request)"
    refute facade =~ "TokenExchange.Compatibility"
  end

  test "capability suite inventory remains complete, unique, and wrapper-free" do
    inventories =
      Map.new(@capability_inventory, fn {relative_path, expected_count} ->
        path = Path.expand("token_exchange/#{relative_path}", __DIR__)
        source = File.read!(path)

        titles =
          Regex.scan(~r/^\s*test\s+"([^"]+)"/m, source, capture: :all_but_first)
          |> List.flatten()

        assert length(titles) == expected_count
        refute source =~ "Code." <> "require_file"

        {relative_path, titles}
      end)

    titles = inventories |> Map.values() |> List.flatten()
    assert length(titles) == 39
    assert Enum.uniq(titles) == titles
  end
end
