defmodule Lockspire.Web.RegistrationJSON do
  @moduledoc false
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Config

  def success_response(%Registration.Success{
        client: client,
        client_secret_plaintext: client_secret,
        registration_access_token_plaintext: rat
      }) do
    base_payload(client)
    |> Map.put(:client_secret, client_secret)
    |> Map.put(:registration_access_token, rat)
  end

  def read_response(%Client{} = client) do
    base_payload(client)
  end

  def update_response(%RegistrationManagement.UpdateSuccess{
        client: client,
        registration_access_token_plaintext: rat
      }) do
    base_payload(client)
    |> Map.put(:registration_access_token, rat)
  end

  def error_response(%Registration.Error{code: code, field: field, reason: reason}) do
    payload = %{error: to_string(code)}

    if field || reason do
      description = build_error_description(field, reason)
      Map.put(payload, :error_description, description)
    else
      payload
    end
  end

  defp base_payload(%Client{} = client) do
    payload = Map.new(client.metadata || %{})

    payload
    |> Map.put(:client_id, client.client_id)
    |> Map.put(:token_endpoint_auth_method, stringify_auth_method(client.token_endpoint_auth_method))
    |> Map.put(
      :client_id_issued_at,
      if(client.inserted_at, do: DateTime.to_unix(client.inserted_at), else: 0)
    )
    |> Map.put(
      :client_secret_expires_at,
      if(client.client_secret_expires_at,
        do: DateTime.to_unix(client.client_secret_expires_at),
        else: 0
      )
    )
    |> Map.put(:dpop_bound_access_tokens, client.dpop_policy == :dpop)
    |> Map.put(:registration_client_uri, Config.issuer!() <> "/register/" <> client.client_id)
    |> maybe_put_token_endpoint_auth_signing_alg(client)
    |> maybe_put_logout_metadata(client)
  end

  defp maybe_put_token_endpoint_auth_signing_alg(payload, %Client{
         token_endpoint_auth_signing_alg: nil
       }),
       do: payload

  defp maybe_put_token_endpoint_auth_signing_alg(payload, %Client{} = client) do
    Map.put(
      payload,
      :token_endpoint_auth_signing_alg,
      stringify_signing_alg(client.token_endpoint_auth_signing_alg)
    )
  end

  defp maybe_put_logout_metadata(payload, %Client{} = client) do
    payload
    |> maybe_put_logout_field(:backchannel_logout_uri, client.backchannel_logout_uri)
    |> maybe_put_logout_field(
      :backchannel_logout_session_required,
      client.backchannel_logout_uri && client.backchannel_logout_session_required
    )
    |> maybe_put_logout_field(:frontchannel_logout_uri, client.frontchannel_logout_uri)
    |> maybe_put_logout_field(
      :frontchannel_logout_session_required,
      client.frontchannel_logout_uri && client.frontchannel_logout_session_required
    )
  end

  defp maybe_put_logout_field(payload, _field, nil), do: payload
  defp maybe_put_logout_field(payload, field, value), do: Map.put(payload, field, value)

  defp stringify_auth_method(method) when is_atom(method), do: Atom.to_string(method)
  defp stringify_auth_method(method), do: method

  defp stringify_signing_alg(alg) when is_atom(alg), do: Atom.to_string(alg)
  defp stringify_signing_alg(alg), do: alg

  defp build_error_description(field, reason) do
    cond do
      field && reason -> "#{reason} for #{field}"
      field -> "invalid #{field}"
      reason -> "#{reason}"
      true -> ""
    end
  end
end
