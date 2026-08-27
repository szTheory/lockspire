defmodule CleanRoomProvider.Bootstrap do
  @moduledoc false

  @bearer_redirect "http://127.0.0.1:4101/oauth/callback"
  @dpop_redirect "http://127.0.0.1:4101/oauth/dpop/callback"
  @billing_resource "http://127.0.0.1:4100/api/billing"

  def provision!(handoff_dir) do
    {:ok, %{key: key}} = Lockspire.Admin.generate_key(:sig)
    {:ok, _} = Lockspire.Admin.publish_key(key.id)
    {:ok, _} = Lockspire.Admin.activate_key(key.id)

    {:ok, bearer} =
      Lockspire.Clients.register_client(client_attrs("clean-room-bearer", @bearer_redirect))

    {:ok, dpop} =
      Lockspire.Clients.register_client(client_attrs("clean-room-dpop", @dpop_redirect))

    {:ok, _} = Lockspire.Admin.update_client(dpop.client.client_id, %{dpop_policy: :dpop})
    {:ok, %{dpop_policy: :dpop}} = Lockspire.Admin.get_client(dpop.client.client_id)
    {:ok, %{dpop_policy: bearer_policy}} = Lockspire.Admin.get_client(bearer.client.client_id)

    write_secret!(handoff_dir, "bearer-client.secret", bearer.client_secret)
    write_secret!(handoff_dir, "dpop-client.secret", dpop.client_secret)

    %{
      bearer_client_id: bearer.client.client_id,
      dpop_client_id: dpop.client.client_id,
      bearer_policy: bearer_policy
    }
  end

  defp client_attrs(client_id, redirect_uri) do
    %{
      client_id: client_id,
      client_type: :confidential,
      name: client_id,
      redirect_uris: [redirect_uri],
      allowed_scopes: ["openid", "profile", "read:billing", "offline_access"],
      allowed_grant_types: ["authorization_code", "refresh_token"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      metadata: %{resource_indicators: [@billing_resource, "http://127.0.0.1:4100/api/other"]}
    }
  end

  defp write_secret!(directory, filename, secret) do
    File.mkdir_p!(directory)
    path = Path.join(directory, filename)
    File.write!(path, secret, [:binary])
    File.chmod!(path, 0o600)
  end
end
