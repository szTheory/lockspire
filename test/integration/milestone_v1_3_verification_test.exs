defmodule Lockspire.Integration.MilestoneV13VerificationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Admin
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  defmodule VerificationHostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context),
      do: {:ok, %{id: "v1.3-verifier"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: to_string(account.id),
         id_token: %{"email" => "#{account.id}@example.test"},
         userinfo: %{
           "email" => "#{account.id}@example.test"
         }
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, context) do
      %InteractionResult{
        login_path: "/login",
        return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
        params: %{
          "interaction_id" =>
            Map.get(context, :interaction_id) || Map.get(context, "interaction_id")
        }
      }
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email"])
    Application.put_env(:lockspire, :account_resolver, VerificationHostResolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    # Pre-publish a signing key so OIDC flows work
    publish_signing_key("v1.3-verification-kid")

    {:ok, %{client: client}} =
      Admin.create_client(%{
        client_id: "v1.3-verifier-client",
        client_type: :public,
        name: "Verification Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true
      })

    %{client: client}
  end

  describe "Scenario: Global Optional (Default)" do
    test "direct authorize succeeds when global policy is optional and client inherits", %{
      client: client
    } do
      Admin.put_server_policy(:optional)
      # client par_policy defaults to :inherit (which resolves to :optional)

      conn = build_authorize_conn(client)
      assert conn.status in [302, 303]
      assert get_resp_header(conn, "location") |> List.first() =~ "/lockspire/consent/"
    end
  end

  describe "Scenario: Global Required" do
    test "direct authorize is rejected when global policy is required", %{client: client} do
      Admin.put_server_policy(:required)
      # client inherits :required

      conn = build_authorize_conn(client)
      assert conn.status in [302, 303]

      location = get_resp_header(conn, "location") |> List.first()
      params = URI.parse(location).query |> URI.decode_query()

      assert params["error"] == "invalid_request"
      assert params["error_description"] == "request_uri from the PAR endpoint is required"
    end

    test "PAR-backed flow succeeds when global policy is required", %{client: client} do
      Admin.put_server_policy(:required)

      # 1. PAR Request
      par_conn =
        build_conn(:post, "/par", %{
          "client_id" => client.client_id,
          "response_type" => "code",
          "redirect_uri" => "https://client.example.com/callback",
          "scope" => "openid email",
          "state" => "v1.3-par-state",
          "nonce" => "v1.3-par-nonce",
          "code_challenge" => code_challenge("v1.3-verifier"),
          "code_challenge_method" => "S256"
        })
        |> put_req_header("accept", "application/json")
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert par_conn.status == 201
      assert %{"request_uri" => request_uri} = Jason.decode!(par_conn.resp_body)

      # 2. Authorize with request_uri
      auth_conn =
        build_conn(:get, "/authorize", %{
          "client_id" => client.client_id,
          "request_uri" => request_uri
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert auth_conn.status in [302, 303]
      assert get_resp_header(auth_conn, "location") |> List.first() =~ "/lockspire/consent/"
    end
  end

  describe "Scenario: Client Override Required" do
    test "direct authorize is rejected when client override is required (even if global is optional)",
         %{client: client} do
      Admin.put_server_policy(:optional)
      Admin.update_client(client.client_id, %{par_policy: :required})

      # Rejected for this client
      conn = build_authorize_conn(client)
      assert conn.status in [302, 303]
      location = get_resp_header(conn, "location") |> List.first()
      params = URI.parse(location).query |> URI.decode_query()
      assert params["error"] == "invalid_request"

      # Still works for another client with :inherit (resolves to :optional)
      {:ok, %{client: other_client}} =
        Admin.create_client(%{
          client_id: "v1.3-other-client",
          client_type: :public,
          name: "Other Client",
          redirect_uris: ["https://client.example.com/callback"],
          allowed_scopes: ["email"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :none,
          pkce_required: true,
          par_policy: :inherit
        })

      other_conn = build_authorize_conn(other_client)
      assert other_conn.status in [302, 303]
      assert get_resp_header(other_conn, "location") |> List.first() =~ "/lockspire/consent/"
    end
  end

  describe "Scenario: Client Override Optional (Exemption)" do
    test "direct authorize SUCCEEDS for client with :optional override despite global :required",
         %{client: client} do
      Admin.put_server_policy(:required)
      Admin.update_client(client.client_id, %{par_policy: :optional})

      conn = build_authorize_conn(client)
      assert conn.status in [302, 303]
      assert get_resp_header(conn, "location") |> List.first() =~ "/lockspire/consent/"
    end
  end

  # Helpers

  defp build_authorize_conn(client) do
    build_conn(:get, "/authorize", %{
      "client_id" => client.client_id,
      "response_type" => "code",
      "redirect_uri" => List.first(client.redirect_uris),
      "scope" => Enum.join(client.allowed_scopes, " "),
      "state" => "v1.3-state",
      "code_challenge" => code_challenge("v1.3-verifier"),
      "code_challenge_method" => "S256"
    })
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  defp publish_signing_key(kid) do
    key = JOSE.JWK.generate_key({:rsa, 2048})
    {_fields, jwk} = JOSE.JWK.to_map(key)

    {:ok, _published_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: "sig",
        public_jwk:
          jwk
          |> Map.take(["kty", "kid", "alg", "use", "n", "e"])
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    key
  end

  defp code_challenge(verifier) do
    :sha256
    |> :crypto.hash(verifier)
    |> Base.url_encode64(padding: false)
  end
end
