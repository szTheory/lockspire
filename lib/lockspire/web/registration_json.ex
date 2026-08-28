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
    |> maybe_put_client_secret(client_secret)
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
    |> put_registered_metadata(client)
    |> Map.put(
      :token_endpoint_auth_method,
      stringify_auth_method(client.token_endpoint_auth_method)
    )
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

  defp maybe_put_client_secret(payload, nil), do: payload

  defp maybe_put_client_secret(payload, client_secret),
    do: Map.put(payload, :client_secret, client_secret)

  defp put_registered_metadata(payload, %Client{} = client) do
    payload
    |> maybe_put(:client_name, client.name)
    |> Map.put(:redirect_uris, client.redirect_uris)
    |> Map.put(:grant_types, client.allowed_grant_types)
    |> Map.put(:response_types, client.allowed_response_types)
    |> maybe_put_scope(client.allowed_scopes)
    |> maybe_put(:subject_type, stringify_signing_alg(client.subject_type))
    |> maybe_put(:jwks, client.jwks)
    |> maybe_put(:jwks_uri, client.jwks_uri)
    |> maybe_put(:logo_uri, client.logo_uri)
    |> maybe_put(:tos_uri, client.tos_uri)
    |> maybe_put(:policy_uri, client.policy_uri)
    |> maybe_put_contacts(client.contacts)
    |> maybe_put(
      :id_token_signed_response_alg,
      stringify_signing_alg(client.id_token_signed_response_alg)
    )
    |> maybe_put(
      :authorization_signed_response_alg,
      stringify_signing_alg(client.authorization_signed_response_alg)
    )
    |> maybe_put(
      :authorization_encrypted_response_alg,
      stringify_encryption_alg(client.authorization_encrypted_response_alg)
    )
    |> maybe_put(
      :authorization_encrypted_response_enc,
      stringify_signing_alg(client.authorization_encrypted_response_enc)
    )
  end

  defp maybe_put(payload, _field, nil), do: payload
  defp maybe_put(payload, field, value), do: Map.put(payload, field, value)

  defp maybe_put_scope(payload, []), do: payload
  defp maybe_put_scope(payload, scopes), do: Map.put(payload, :scope, Enum.join(scopes, " "))

  defp maybe_put_contacts(payload, []), do: payload
  defp maybe_put_contacts(payload, contacts), do: Map.put(payload, :contacts, contacts)

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

  defp stringify_signing_alg(nil), do: nil
  defp stringify_signing_alg(alg) when is_atom(alg), do: Atom.to_string(alg)
  defp stringify_signing_alg(alg), do: alg

  defp stringify_encryption_alg(:RSA_OAEP_256), do: "RSA-OAEP-256"
  defp stringify_encryption_alg(:ECDH_ES), do: "ECDH-ES"
  defp stringify_encryption_alg(alg), do: stringify_signing_alg(alg)

  defp build_error_description(field, reason) do
    cond do
      field && reason -> "#{reason} for #{field}"
      field -> "invalid #{field}"
      reason -> "#{reason}"
      true -> ""
    end
  end
end
