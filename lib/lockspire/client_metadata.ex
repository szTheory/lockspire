defmodule Lockspire.ClientMetadata do
  @moduledoc false

  alias Lockspire.ClientRegistration.Shape
  alias Lockspire.Domain.Client

  @type issue :: %{field: atom(), reason: atom(), detail: term()}

  @spec validate_direct(map()) :: :ok | {:error, [issue()]}
  def validate_direct(attrs) when is_map(attrs), do: Shape.validate(attrs)

  @spec validate_logout_metadata(map(), [String.t()], keyword()) :: :ok | {:error, [issue()]}
  def validate_logout_metadata(attrs, redirect_uris, opts \\ [])
      when is_map(attrs) and is_list(redirect_uris) do
    strict_booleans? = Keyword.get(opts, :strict_booleans, false)
    normalized = normalize_logout_metadata(attrs)

    errors =
      []
      |> append_errors(validate_logout_boolean_shapes(attrs, strict_booleans?))
      |> append_errors(validate_logout_propagation(normalized, redirect_uris))

    case errors do
      [] -> :ok
      issues -> {:error, issues}
    end
  end

  @spec normalize_logout_metadata(map()) :: map()
  def normalize_logout_metadata(attrs) when is_map(attrs) do
    %{
      backchannel_logout_uri: normalize_string(fetch_attr(attrs, :backchannel_logout_uri)),
      backchannel_logout_session_required:
        normalize_boolean(fetch_attr(attrs, :backchannel_logout_session_required)),
      frontchannel_logout_uri: normalize_string(fetch_attr(attrs, :frontchannel_logout_uri)),
      frontchannel_logout_session_required:
        normalize_boolean(fetch_attr(attrs, :frontchannel_logout_session_required))
    }
  end

  @spec build_dcr_client(map(), map(), term(), map()) :: Client.t()
  def build_dcr_client(metadata, resolved, iat_record, credentials)
      when is_map(metadata) and is_map(credentials) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    logout_metadata = normalize_logout_metadata(metadata)

    auth_method =
      metadata
      |> Map.get("token_endpoint_auth_method", "client_secret_basic")
      |> atomize_auth_method()

    %Client{
      client_id: credentials.client_id,
      client_secret_hash: credentials.client_secret_hash,
      client_secret_jwt_verifier_encrypted: credentials.client_secret_jwt_verifier_encrypted,
      client_type: client_type_from_auth_method(auth_method),
      name: Map.get(metadata, "client_name"),
      redirect_uris: Map.get(metadata, "redirect_uris", []),
      allowed_scopes: parse_scope(Map.get(metadata, "scope", "")),
      allowed_grant_types: Map.get(metadata, "grant_types", ["authorization_code"]),
      allowed_response_types: Map.get(metadata, "response_types", ["code"]),
      token_endpoint_auth_method: auth_method,
      token_endpoint_auth_signing_alg:
        atomize_token_endpoint_auth_signing_alg(
          Map.get(metadata, "token_endpoint_auth_signing_alg")
        ),
      pkce_required: true,
      subject_type: :public,
      logo_uri: Map.get(metadata, "logo_uri"),
      tos_uri: Map.get(metadata, "tos_uri"),
      policy_uri: Map.get(metadata, "policy_uri"),
      contacts: Map.get(metadata, "contacts", []),
      jwks: Map.get(metadata, "jwks"),
      jwks_uri: Map.get(metadata, "jwks_uri"),
      backchannel_logout_uri: logout_metadata.backchannel_logout_uri,
      backchannel_logout_session_required: logout_metadata.backchannel_logout_session_required,
      frontchannel_logout_uri: logout_metadata.frontchannel_logout_uri,
      frontchannel_logout_session_required: logout_metadata.frontchannel_logout_session_required,
      active: true,
      dpop_policy:
        if(Map.get(metadata, "dpop_bound_access_tokens", false), do: :dpop, else: :bearer),
      provenance: :self_registered,
      registration_access_token_hash: credentials.rat_hash,
      initial_access_token_id: iat_id(iat_record),
      id_token_signed_response_alg:
        atomize_alg(Map.get(metadata, "id_token_signed_response_alg")),
      authorization_signed_response_alg:
        atomize_alg(Map.get(metadata, "authorization_signed_response_alg")),
      authorization_encrypted_response_alg:
        atomize_authorization_encryption_alg(
          Map.get(metadata, "authorization_encrypted_response_alg")
        ),
      authorization_encrypted_response_enc:
        atomize_authorization_encryption_enc(
          Map.get(metadata, "authorization_encrypted_response_enc")
        ),
      security_profile:
        atomize_security_profile(Map.get(metadata, "security_profile", "inherit")),
      client_id_issued_at: now,
      client_secret_expires_at: client_secret_expires_at(now, resolved, credentials),
      metadata:
        metadata |> Map.take(["client_uri"]) |> Map.reject(fn {_key, value} -> is_nil(value) end)
    }
  end

  @spec apply_dcr_metadata(Client.t(), map()) :: Client.t()
  def apply_dcr_metadata(%Client{} = client, metadata) when is_map(metadata) do
    candidate =
      build_dcr_client(metadata, %{}, %{id: client.initial_access_token_id}, %{
        client_id: client.client_id,
        client_secret_hash: client.client_secret_hash,
        client_secret_jwt_verifier_encrypted: client.client_secret_jwt_verifier_encrypted,
        rat_hash: client.registration_access_token_hash
      })

    fields = [
      :client_type,
      :name,
      :redirect_uris,
      :allowed_scopes,
      :allowed_grant_types,
      :allowed_response_types,
      :token_endpoint_auth_method,
      :token_endpoint_auth_signing_alg,
      :logo_uri,
      :tos_uri,
      :policy_uri,
      :contacts,
      :jwks,
      :jwks_uri,
      :id_token_signed_response_alg,
      :authorization_signed_response_alg,
      :authorization_encrypted_response_alg,
      :authorization_encrypted_response_enc,
      :security_profile,
      :dpop_policy,
      :backchannel_logout_uri,
      :backchannel_logout_session_required,
      :frontchannel_logout_uri,
      :frontchannel_logout_session_required,
      :metadata
    ]

    struct(client, Map.take(Map.from_struct(candidate), fields))
  end

  @spec check_fapi_signing_readiness(atom(), atom()) :: :ok | {:error, atom()}
  def check_fapi_signing_readiness(:fapi_2_0_security, :fapi_2_0_security), do: :ok
  def check_fapi_signing_readiness(:fapi_2_0_message_signing, :fapi_2_0_message_signing), do: :ok

  def check_fapi_signing_readiness(_old, :fapi_2_0_message_signing),
    do: {:error, :missing_compliant_active_key}

  def check_fapi_signing_readiness(_old, :fapi_2_0_security),
    do: {:error, :missing_compliant_publishable_key}

  def check_fapi_signing_readiness(_old, _new), do: :ok

  defp validate_logout_boolean_shapes(_attrs, false), do: :ok

  defp validate_logout_boolean_shapes(attrs, true) do
    [:backchannel_logout_session_required, :frontchannel_logout_session_required]
    |> Enum.reduce([], fn field, errors ->
      case Map.fetch(attrs, field) do
        {:ok, value} when is_boolean(value) ->
          errors

        {:ok, value} ->
          [issue(field, :invalid_boolean, value) | errors]

        :error ->
          case Map.fetch(attrs, Atom.to_string(field)) do
            {:ok, value} when is_boolean(value) -> errors
            {:ok, value} -> [issue(field, :invalid_boolean, value) | errors]
            :error -> errors
          end
      end
    end)
    |> Enum.reverse()
  end

  defp validate_logout_propagation(attrs, redirect_uris) do
    []
    |> maybe_logout_uri_error(attrs, :backchannel_logout_uri)
    |> maybe_logout_uri_error(attrs, :frontchannel_logout_uri)
    |> maybe_session_required_error(
      attrs,
      :backchannel_logout_uri,
      :backchannel_logout_session_required
    )
    |> maybe_session_required_error(
      attrs,
      :frontchannel_logout_uri,
      :frontchannel_logout_session_required
    )
    |> maybe_frontchannel_origin_error(attrs, redirect_uris)
    |> Enum.reverse()
  end

  defp maybe_logout_uri_error(errors, attrs, field) do
    case fetch_attr(attrs, field) do
      nil ->
        errors

      uri ->
        case Shape.valid_redirect_uri?(uri) do
          :ok -> errors
          reason -> [issue(field, :invalid_logout_uri, reason) | errors]
        end
    end
  end

  defp maybe_session_required_error(errors, attrs, uri_field, session_field) do
    if normalize_boolean(fetch_attr(attrs, session_field)) and
         is_nil(normalize_string(fetch_attr(attrs, uri_field))) do
      [issue(session_field, :logout_uri_required, uri_field) | errors]
    else
      errors
    end
  end

  defp maybe_frontchannel_origin_error(errors, attrs, redirect_uris) do
    case normalize_string(fetch_attr(attrs, :frontchannel_logout_uri)) do
      nil ->
        errors

      uri ->
        if origin_matches?(uri, redirect_uris),
          do: errors,
          else: [
            issue(:frontchannel_logout_uri, :frontchannel_logout_origin_mismatch, uri) | errors
          ]
    end
  end

  defp origin_matches?(uri, redirect_uris),
    do:
      Enum.any?(
        redirect_uris,
        &(uri_origin(&1) == uri_origin(uri) and uri_origin(uri) != :invalid)
      )

  defp uri_origin(uri) do
    case URI.parse(uri) do
      %URI{scheme: scheme, host: host, port: port}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        {scheme, host, port || if(scheme == "https", do: 443, else: 80)}

      _ ->
        :invalid
    end
  end

  defp append_errors(errors, :ok), do: errors
  defp append_errors(errors, issues) when is_list(issues), do: errors ++ issues
  defp issue(field, reason, detail), do: %{field: field, reason: reason, detail: detail}
  defp fetch_attr(attrs, key), do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(_), do: nil
  defp normalize_boolean(value) when value in [true, "true", 1, "1"], do: true
  defp normalize_boolean(_), do: false
  defp iat_id(%{id: id}), do: id
  defp iat_id(_), do: nil

  defp parse_scope(scope) when is_binary(scope),
    do: scope |> String.split(" ", trim: true) |> Enum.uniq()

  defp parse_scope(_), do: []

  defp client_secret_expires_at(_now, _resolved, %{client_secret_hash: nil}), do: nil

  defp client_secret_expires_at(now, resolved, _credentials) do
    DateTime.add(
      now,
      Map.get(resolved, :default_client_secret_lifetime_seconds, 0) || 0,
      :second
    )
  end

  defp atomize_auth_method("client_secret_post"), do: :client_secret_post
  defp atomize_auth_method("client_secret_jwt"), do: :client_secret_jwt
  defp atomize_auth_method("private_key_jwt"), do: :private_key_jwt
  defp atomize_auth_method("none"), do: :none
  defp atomize_auth_method(_), do: :client_secret_basic
  defp client_type_from_auth_method(:none), do: :public
  defp client_type_from_auth_method(_), do: :confidential
  defp atomize_alg("RS256"), do: :RS256
  defp atomize_alg("ES256"), do: :ES256
  defp atomize_alg("PS256"), do: :PS256
  defp atomize_alg("EdDSA"), do: :EdDSA
  defp atomize_alg(_), do: nil
  defp atomize_token_endpoint_auth_signing_alg("HS256"), do: :HS256
  defp atomize_token_endpoint_auth_signing_alg(value), do: atomize_alg(value)
  defp atomize_authorization_encryption_alg("RSA-OAEP-256"), do: :RSA_OAEP_256
  defp atomize_authorization_encryption_alg("ECDH-ES"), do: :ECDH_ES
  defp atomize_authorization_encryption_alg(_), do: nil
  defp atomize_authorization_encryption_enc("A256GCM"), do: :A256GCM
  defp atomize_authorization_encryption_enc("A128GCM"), do: :A128GCM
  defp atomize_authorization_encryption_enc(_), do: nil
  defp atomize_security_profile("fapi_2_0_security"), do: :fapi_2_0_security
  defp atomize_security_profile("fapi_2_0_message_signing"), do: :fapi_2_0_message_signing
  defp atomize_security_profile("none"), do: :none
  defp atomize_security_profile(_), do: :inherit
end
