defmodule GeneratedHostAppWeb.ProtectedApiReplayStore do
  def record_dpop_proof(_replay), do: {:ok, :accepted}
end

defmodule GeneratedHostAppWeb.ProtectedApiController do
  use Phoenix.Controller, formats: [:json]

  alias Lockspire.AccessToken

  def show(conn, _params) do
    %AccessToken{} = access_token = conn.assigns.access_token

    json(conn, %{
      access_token: %{
        client_id: access_token.client_id,
        subject: Map.get(access_token.claims || %{}, "sub"),
        authorization_scheme: access_token.authorization_scheme,
        binding_type: access_token.binding_type,
        binding_requirements: access_token.binding_requirements,
        audience: Map.get(access_token.claims || %{}, "aud"),
        scope: Map.get(access_token.claims || %{}, "scope")
      }
    })
  end
end
