defmodule Lockspire.Web.EndSessionControllerResolver do
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "account-123"}}

  @impl true
  def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

  @impl true
  def build_claims(account, _context) do
    {:ok, %Claims{subject: to_string(account.id), id_token: %{}, userinfo: %{}}}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, _context) do
    %InteractionResult{login_path: "/sign-in"}
  end

  @impl true
  def redirect_for_logout(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/host/logout",
      return_to: Map.get(context, :return_to),
      params: %{"account_id" => Map.get(context, :account_id)}
    }
  end
end

defmodule Lockspire.Web.EndSessionControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Oban.Job

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :logout_path, "/fallback/logout")
    Application.put_env(:lockspire, :account_resolver, Lockspire.Web.EndSessionControllerResolver)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})

    Application.put_env(:lockspire, :account_resolver, Lockspire.Web.EndSessionControllerResolver)

    {:ok, _client} = register_client()
    key = publish_signing_key("end-session-kid")

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual) end)

    %{signing_key: key}
  end

  describe "GET /end_session" do
    test "returns redirect to host logout_path with signed return_to token", %{signing_key: key} do
      conn =
        build_conn(:get, "/end_session", %{
          "client_id" => "logout-client",
          "id_token_hint" => id_token_hint(key.private_jwk, "logout-client"),
          "post_logout_redirect_uri" => "https://client.example.com/logged-out",
          "state" => "logout-state-123"
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status in [302, 303]
      location = redirect_location(conn)
      assert String.starts_with?(location, "/host/logout?")

      params = location |> URI.parse() |> Map.get(:query) |> URI.decode_query()
      assert params["account_id"] == "subject-123"

      return_to = params["return_to"]
      assert return_to =~ "/lockspire/end_session/complete?token="
      assert {:ok, payload} = completion_payload(return_to)
      assert fetch_payload(payload, :sid) == "sid-123"
      assert is_binary(fetch_payload(payload, :event_id))
      assert fetch_payload(payload, :post_logout_redirect_uri) == "https://client.example.com/logged-out"
      assert fetch_payload(payload, :state) == "logout-state-123"
    end

    test "returns 400 for invalid id_token_hint signature" do
      other_key = JarTestHelpers.generate_keys()

      conn =
        build_conn(:get, "/end_session", %{
          "client_id" => "logout-client",
          "id_token_hint" => id_token_hint(other_key.private_jwk, "logout-client")
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 400
      assert conn.resp_body =~ "Logout request rejected"
      refute redirected?(conn)
    end

    test "returns 400 when client_id not in id_token_hint aud", %{signing_key: key} do
      conn =
        build_conn(:get, "/end_session", %{
          "client_id" => "logout-client",
          "id_token_hint" => id_token_hint(key.private_jwk, "other-client")
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 400
      assert conn.resp_body =~ "client_id_not_in_aud"
      refute redirected?(conn)
    end

    test "accepts request with no id_token_hint and redirects to host logout" do
      conn =
        build_conn(:get, "/end_session", %{})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status in [302, 303]
      assert location = redirect_location(conn)
      assert String.starts_with?(location, "/host/logout?")
      params = location |> URI.parse() |> Map.get(:query) |> URI.decode_query()
      assert params["return_to"] =~ "/lockspire/end_session/complete?token="
    end
  end

  describe "POST /end_session" do
    test "returns redirect to host logout_path", %{signing_key: key} do
      conn =
        build_conn(:post, "/end_session", %{
          "client_id" => "logout-client",
          "id_token_hint" => id_token_hint(key.private_jwk, "logout-client")
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status in [302, 303]
      assert redirect_location(conn) =~ "/host/logout?"
    end
  end

  describe "GET /end_session/complete" do
    test "valid signed token delegates to logout propagation and redirects to post_logout_redirect_uri" do
      now = DateTime.utc_now()
      store_session_tokens("sid-logout-123", now)
      event_id = "evt-controller-#{System.unique_integer([:positive])}"

      token =
        Phoenix.Token.sign(Lockspire.Web.Endpoint, "lockspire_logout", %{
          event_id: event_id,
          sid: "sid-logout-123",
          post_logout_redirect_uri: "https://client.example.com/logged-out",
          state: "after-logout"
        })

      conn =
        build_conn(:get, "/end_session/complete", %{"token" => token})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "Signing you out of connected apps"
      assert conn.resp_body =~ ~s(href="https://client.example.com/logged-out")
      assert conn.resp_body =~ "lockspire-frontchannel-logout-logout-client"

      revoked_count =
        TokenRecord
        |> where([token], token.sid == ^"sid-logout-123" and not is_nil(token.revoked_at))
        |> Lockspire.TestRepo.aggregate(:count, :id)

      assert revoked_count == 2

      assert Lockspire.TestRepo.aggregate(LogoutEventRecord, :count, :id) == 1

      persisted_event =
        LogoutEventRecord
        |> where([event], event.event_id == ^event_id)
        |> Lockspire.TestRepo.one!()

      persisted_deliveries =
        LogoutDeliveryRecord
        |> where([delivery], delivery.logout_event_id == ^persisted_event.id)
        |> order_by([delivery], asc: delivery.channel)
        |> Lockspire.TestRepo.all()

      assert Enum.map(persisted_deliveries, & &1.channel) == [:backchannel, :frontchannel]
      assert Enum.find(persisted_deliveries, &(&1.channel == :backchannel)).status == :enqueued
      assert Enum.find(persisted_deliveries, &(&1.channel == :frontchannel)).status == :rendered
      assert Lockspire.TestRepo.aggregate(Job, :count, :id) == 1
    end

    test "duplicate completion hits reuse the same logout event and do not duplicate jobs" do
      now = DateTime.utc_now()
      store_session_tokens("sid-logout-dup", now)
      event_id = "evt-controller-dup-#{System.unique_integer([:positive])}"

      token =
        Phoenix.Token.sign(Lockspire.Web.Endpoint, "lockspire_logout", %{
          event_id: event_id,
          sid: "sid-logout-dup",
          post_logout_redirect_uri: "https://client.example.com/logged-out",
          state: "after-logout"
        })

      first_conn =
        build_conn(:get, "/end_session/complete", %{"token" => token})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      second_conn =
        build_conn(:get, "/end_session/complete", %{"token" => token})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert first_conn.status == 200
      assert second_conn.status == 200
      assert first_conn.resp_body =~ "Signing you out of connected apps"
      assert second_conn.resp_body =~ "Signing you out of connected apps"
      assert first_conn.resp_body =~ ~s(href="https://client.example.com/logged-out")
      assert second_conn.resp_body =~ ~s(href="https://client.example.com/logged-out")

      assert Lockspire.TestRepo.aggregate(LogoutEventRecord, :count, :id) == 1
      assert Lockspire.TestRepo.aggregate(LogoutDeliveryRecord, :count, :id) == 2
      assert Lockspire.TestRepo.aggregate(Job, :count, :id) == 1
    end

    test "invalid signed token still succeeds as logout" do
      conn =
        build_conn(:get, "/end_session/complete", %{"token" => "not-a-valid-token"})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "You have been signed out"
      assert Lockspire.TestRepo.aggregate(LogoutEventRecord, :count, :id) == 0
      assert Lockspire.TestRepo.aggregate(Job, :count, :id) == 0
    end

    test "no post_logout_redirect_uri renders logged-out page" do
      store_session_tokens("sid-logout-page", DateTime.utc_now())
      event_id = "evt-controller-page-#{System.unique_integer([:positive])}"

      token =
        Phoenix.Token.sign(Lockspire.Web.Endpoint, "lockspire_logout", %{
          event_id: event_id,
          sid: "sid-logout-page",
          post_logout_redirect_uri: nil,
          state: nil
        })

      conn =
        build_conn(:get, "/end_session/complete", %{"token" => token})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "Signing you out of connected apps"
      assert conn.resp_body =~ ~s(href="#logout-complete")
      assert conn.resp_body =~ "lockspire-frontchannel-logout-logout-client"
    end
  end

  defp register_client do
    Repository.register_client(%Client{
      client_id: "logout-client",
      client_secret_hash: "sha256:logout:hash",
      client_type: :confidential,
      name: "Logout Client",
      redirect_uris: ["https://client.example.com/callback"],
      post_logout_redirect_uris: ["https://client.example.com/logged-out"],
      backchannel_logout_uri: "https://client.example.com/backchannel-logout",
      backchannel_logout_session_required: true,
      frontchannel_logout_uri: "https://client.example.com/frontchannel-logout",
      frontchannel_logout_session_required: true,
      allowed_scopes: ["openid", "profile"],
      allowed_grant_types: ["authorization_code", "refresh_token"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end

  defp publish_signing_key(kid) do
    Lockspire.TestRepo.delete_all(SigningKeyRecord)

    keys = JarTestHelpers.generate_keys()
    public_jwk = JOSE.JWK.to_public_map(keys.private_jwk) |> elem(1)
    private_jwk = JOSE.JWK.to_map(keys.private_jwk) |> elem(1)

    {:ok, _stored_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk:
          public_jwk
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: Jason.encode!(Map.put(private_jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{private_jwk: keys.private_jwk}
  end

  defp id_token_hint(private_jwk, audience) do
    claims = %{
      "aud" => audience,
      "sub" => "subject-123",
      "sid" => "sid-123",
      "exp" => DateTime.utc_now() |> DateTime.add(-300, :second) |> DateTime.to_unix()
    }

    private_jwk
    |> JOSE.JWT.sign(%{"alg" => "RS256", "typ" => "JWT"}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp completion_payload(return_to) do
    token = return_to |> URI.parse() |> Map.get(:query) |> URI.decode_query() |> Map.get("token")
    Phoenix.Token.verify(Lockspire.Web.Endpoint, "lockspire_logout", token, max_age: 600)
  end

  defp fetch_payload(payload, key) do
    Map.get(payload, key) || Map.get(payload, Atom.to_string(key))
  end

  defp store_session_tokens(sid, now) do
    {:ok, refresh_token} =
      Repository.store_token(%Token{
        token_hash: "refresh-#{sid}",
        token_type: :refresh_token,
        family_id: "family-#{sid}",
        generation: 0,
        client_id: "logout-client",
        account_id: "subject-123",
        sid: sid,
        scopes: ["offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {:ok, _access_token} =
      Repository.store_token(%Token{
        token_hash: "access-#{sid}",
        token_type: :access_token,
        family_id: "family-#{sid}",
        generation: 1,
        parent_token_id: refresh_token.id,
        client_id: "logout-client",
        account_id: "subject-123",
        sid: sid,
        scopes: ["openid"],
        issued_at: DateTime.add(now, 5, :second),
        expires_at: DateTime.add(now, 3600, :second)
      })
  end

  defp redirected?(conn), do: Plug.Conn.get_resp_header(conn, "location") != []
  defp redirect_location(conn), do: List.first(Plug.Conn.get_resp_header(conn, "location"))
end
