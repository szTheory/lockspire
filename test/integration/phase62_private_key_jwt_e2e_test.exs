defmodule Lockspire.Integration.Phase62PrivateKeyJwtE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository

  defmodule RemoteJwksFetcher do
    def get_keys(_uri, _opts) do
      increment_fetch_count()
      current_response()
    end

    def refresh_keys(_uri, _opts) do
      increment_fetch_count()
      current_response()
    end

    defp increment_fetch_count do
      Process.put(:phase62_jwks_fetch_count, Process.get(:phase62_jwks_fetch_count, 0) + 1)
    end

    defp current_response do
      case Process.get(:phase62_remote_jwks_response, {:ok, Process.get(:phase62_remote_jwks)}) do
        {:ok, %{"keys" => _keys} = jwks} -> {:ok, JOSE.JWK.from_map(jwks)}
        {:ok, key_map} when is_map(key_map) -> {:ok, JOSE.JWK.from_map(%{"keys" => [key_map]})}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "offline_access"])

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup _context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    original_fetcher_opts = Application.get_env(:lockspire, :jwks_fetcher_opts)
    original_fetcher = Application.get_env(:lockspire, :jwks_fetcher)

    on_exit(fn ->
      if is_nil(original_fetcher_opts) do
        Application.delete_env(:lockspire, :jwks_fetcher_opts)
      else
        Application.put_env(:lockspire, :jwks_fetcher_opts, original_fetcher_opts)
      end

      if is_nil(original_fetcher) do
        Application.delete_env(:lockspire, :jwks_fetcher)
      else
        Application.put_env(:lockspire, :jwks_fetcher, original_fetcher)
      end
    end)

    inline_keys = JarTestHelpers.generate_keys()
    remote_old_keys = JarTestHelpers.generate_keys()
    remote_new_keys = JarTestHelpers.generate_keys()
    remote_old_pub = Map.put(remote_old_keys.pub_jwk_map, "kid", "remote-old-kid")
    remote_new_pub = Map.put(remote_new_keys.pub_jwk_map, "kid", "remote-new-kid")
    remote_uri = "https://keys.example.test/phase62-#{System.unique_integer([:positive])}.json"

    Process.put(:phase62_remote_jwks, remote_old_pub)
    Process.put(:phase62_remote_jwks_response, {:ok, remote_old_pub})
    Process.put(:phase62_jwks_fetch_count, 0)

    Application.put_env(:lockspire, :jwks_fetcher_opts, resolver: &__MODULE__.public_resolver/1)
    Application.put_env(:lockspire, :jwks_fetcher, RemoteJwksFetcher)

    {:ok, inline_client} =
      Repository.register_client(%Client{
        client_id: "phase62-inline-client",
        client_type: :confidential,
        token_endpoint_auth_method: :private_key_jwt,
        name: "Phase 62 Inline Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["openid", "offline_access"],
        allowed_grant_types: ["refresh_token"],
        allowed_response_types: ["code"],
        jwks: inline_keys.pub_jwk_map,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, remote_client} =
      Repository.register_client(%Client{
        client_id: "phase62-remote-client",
        client_type: :confidential,
        token_endpoint_auth_method: :private_key_jwt,
        name: "Phase 62 Remote Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["openid", "offline_access"],
        allowed_grant_types: ["refresh_token"],
        allowed_response_types: ["code"],
        jwks_uri: remote_uri,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    seed_refresh_token(inline_client, "phase62-inline-refresh", "phase62-inline-family")
    seed_refresh_token(remote_client, "phase62-remote-refresh-1", "phase62-remote-family-1")
    seed_refresh_token(remote_client, "phase62-remote-refresh-2", "phase62-remote-family-2")
    seed_refresh_token(remote_client, "phase62-remote-refresh-3", "phase62-remote-family-3")

    %{
      inline_client: inline_client,
      inline_keys: inline_keys,
      remote_client: remote_client,
      remote_old_keys: remote_old_keys,
      remote_new_keys: remote_new_keys,
      remote_new_pub: remote_new_pub
    }
  end

  test "token endpoint accepts inline jwks and recovers from jwks_uri rotation",
       %{
         inline_client: inline_client,
         inline_keys: inline_keys,
         remote_client: remote_client,
         remote_old_keys: remote_old_keys,
         remote_new_keys: remote_new_keys,
         remote_new_pub: remote_new_pub
       } do
    inline_response =
      issue_refresh_token(
        inline_client.client_id,
        signed_assertion(inline_keys.private_jwk, inline_client.client_id, jti: "inline-pass"),
        "phase62-inline-refresh"
      )

    assert inline_response.status == 200
    assert Map.has_key?(Jason.decode!(inline_response.resp_body), "access_token")

    remote_first_response =
      issue_refresh_token(
        remote_client.client_id,
        signed_assertion(remote_old_keys.private_jwk, remote_client.client_id,
          jti: "remote-old",
          kid: "remote-old-kid"
        ),
        "phase62-remote-refresh-1"
      )

    assert remote_first_response.status == 200
    assert Process.get(:phase62_jwks_fetch_count) == 1

    Process.put(:phase62_remote_jwks, remote_new_pub)
    Process.put(:phase62_remote_jwks_response, {:ok, remote_new_pub})

    remote_rotated_response =
      issue_refresh_token(
        remote_client.client_id,
        signed_assertion(remote_new_keys.private_jwk, remote_client.client_id,
          jti: "remote-new",
          kid: "remote-new-kid"
        ),
        "phase62-remote-refresh-2"
      )

    assert remote_rotated_response.status == 200
    assert Process.get(:phase62_jwks_fetch_count) == 2
    assert {:ok, refreshed_client} = Repository.fetch_client_by_id(remote_client.client_id)
    refute Map.has_key?(refreshed_client.metadata, "remote_jwks_diagnostic")
  end

  test "remote jwks_uri current request fails closed while key-unavailable diagnostics stay support-safe",
       %{
         remote_client: remote_client,
         remote_old_keys: remote_old_keys,
         remote_new_keys: remote_new_keys
       } do
    assert issue_refresh_token(
             remote_client.client_id,
             signed_assertion(remote_old_keys.private_jwk, remote_client.client_id,
               jti: "remote-old",
               kid: "remote-old-kid"
             ),
             "phase62-remote-refresh-1"
           ).status == 200

    Process.put(
      :phase62_remote_jwks_response,
      {:ok, Map.put(JarTestHelpers.generate_keys().pub_jwk_map, "kid", "remote-bad-kid")}
    )

    failed_remote_response =
      issue_refresh_token(
        remote_client.client_id,
        signed_assertion(remote_new_keys.private_jwk, remote_client.client_id,
          jti: "remote-fail",
          kid: "remote-new-kid"
        ),
        "phase62-remote-refresh-3"
      )

    assert failed_remote_response.status == 401
    assert Process.get(:phase62_jwks_fetch_count) == 3

    assert Jason.decode!(failed_remote_response.resp_body) == %{
             "error" => "invalid_client",
             "error_description" => "Client authentication failed"
           }

    assert {:ok, failed_client} = Repository.fetch_client_by_id(remote_client.client_id)

    assert %{
             "class" => "remote_jwks_key_unavailable",
             "stage" => "select_key",
             "subreason" => "post_refresh_key_still_missing",
             "forced_refresh_attempted?" => true,
             "requested_kid_present_in_cached_set?" => false
           } = failed_client.metadata["remote_jwks_diagnostic"]
  end

  test "remote jwks_uri invalid content stays generic on the wire while persisting parse diagnostics",
       %{
         remote_client: remote_client,
         remote_old_keys: remote_old_keys,
         remote_new_keys: remote_new_keys
       } do
    assert issue_refresh_token(
             remote_client.client_id,
             signed_assertion(remote_old_keys.private_jwk, remote_client.client_id,
               jti: "remote-old",
               kid: "remote-old-kid"
             ),
             "phase62-remote-refresh-1"
           ).status == 200

    Process.put(:phase62_remote_jwks_response, {:error, {:jwks_fetch_failed, :invalid_format}})

    failed_remote_response =
      issue_refresh_token(
        remote_client.client_id,
        signed_assertion(remote_new_keys.private_jwk, remote_client.client_id,
          jti: "remote-invalid-format",
          kid: "remote-new-kid"
        ),
        "phase62-remote-refresh-2"
      )

    assert failed_remote_response.status == 401
    assert Process.get(:phase62_jwks_fetch_count) == 2

    assert Jason.decode!(failed_remote_response.resp_body) == %{
             "error" => "invalid_client",
             "error_description" => "Client authentication failed"
           }

    assert {:ok, failed_client} = Repository.fetch_client_by_id(remote_client.client_id)

    assert %{
             "class" => "remote_jwks_invalid",
             "stage" => "parse",
             "subreason" => "invalid_format",
             "forced_refresh_attempted?" => false
           } = failed_client.metadata["remote_jwks_diagnostic"]
  end

  def public_resolver("keys.example.test"), do: {:ok, [{93, 184, 216, 34}]}
  def public_resolver(_host), do: {:error, :nxdomain}

  defp issue_refresh_token(client_id, assertion, refresh_token) do
    build_conn(:post, "/token", %{
      "grant_type" => "refresh_token",
      "client_id" => client_id,
      "refresh_token" => refresh_token,
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    })
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  defp seed_refresh_token(client, raw_refresh_token, family_id) do
    now = DateTime.utc_now()

    {:ok, _token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(raw_refresh_token),
        token_type: :refresh_token,
        family_id: family_id,
        generation: 0,
        client_id: client.client_id,
        account_id: "phase62-subject",
        interaction_id: "interaction-#{family_id}",
        scopes: ["openid", "offline_access"],
        audience: ["api.example.test"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })
  end

  defp signed_assertion(private_jwk, client_id, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:second))

    JarTestHelpers.sign_jar(
      private_jwk,
      %{
        "iss" => client_id,
        "sub" => client_id,
        "aud" => Lockspire.Config.issuer!(),
        "jti" => Keyword.get(opts, :jti, "jti-#{System.unique_integer([:positive])}"),
        "iat" => DateTime.to_unix(now),
        "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
      },
      extra_header:
        case Keyword.get(opts, :kid) do
          kid when is_binary(kid) -> %{"kid" => kid}
          _ -> %{}
        end
    )
  end
end
