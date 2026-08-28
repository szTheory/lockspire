defmodule Lockspire.Clients do
  @moduledoc """
  Durable client registration API for secure client onboarding.
  """

  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.ClientLifecycle
  alias Lockspire.ClientMetadata
  alias Lockspire.Domain.Client
  alias Lockspire.Observability
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @secret_bytes 32
  @client_id_bytes 24

  @type validation_error ::
          :invalid_client_type
          | :invalid_token_endpoint_auth_method
          | :invalid_token_endpoint_auth_signing_alg
          | :invalid_redirect_uri
          | :invalid_logout_uri
          | :invalid_scope
          | :invalid_grant_type
          | :invalid_response_type
          | :incoherent_pair
          | :missing_cryptographic_material
          | :mutually_exclusive_with_jwks_uri
          | :invalid_uri_scheme
          | :pkce_required
          | :client_secret_not_allowed
          | :persistence_failed

  @type error_detail :: %{field: atom(), reason: validation_error(), detail: term()}

  @spec validate_redirect_uris([String.t()] | String.t() | nil) ::
          :ok | {:error, [error_detail()]}
  def validate_redirect_uris(redirect_uris) do
    errors = validate_redirect_uris([], normalize_string_list(redirect_uris))

    case Enum.reverse(errors) do
      [] -> :ok
      invalid -> {:error, invalid}
    end
  end

  @spec validate_allowed_scopes([String.t()] | String.t() | nil) ::
          :ok | {:error, [error_detail()]}
  def validate_allowed_scopes(scopes) do
    errors = validate_scopes([], normalize_string_list(scopes))

    case Enum.reverse(errors) do
      [] -> :ok
      invalid -> {:error, invalid}
    end
  end

  @spec validate_logout_uri(String.t() | nil) :: :ok | {:error, error_detail()}
  def validate_logout_uri(uri) do
    case validate_redirect_uri(normalize_optional_string(uri || "")) do
      :ok ->
        :ok

      reason ->
        {:error, %{field: :logout_uri, reason: :invalid_logout_uri, detail: reason}}
    end
  end

  @spec frontchannel_logout_origin_matches_redirect_uri?(String.t(), [String.t()]) :: boolean()
  def frontchannel_logout_origin_matches_redirect_uri?(logout_uri, redirect_uris)
      when is_binary(logout_uri) and is_list(redirect_uris) do
    case uri_origin(logout_uri) do
      {:ok, logout_origin} ->
        Enum.any?(redirect_uris, fn redirect_uri ->
          case uri_origin(redirect_uri) do
            {:ok, redirect_origin} -> redirect_origin == logout_origin
            :error -> false
          end
        end)

      :error ->
        false
    end
  end

  @spec rotate_secret_hash() :: {String.t(), String.t()}
  def rotate_secret_hash do
    material = rotate_secret_material()
    {material.client_secret_hash, material.client_secret}
  end

  @spec rotate_secret_material(keyword()) :: %{
          client_secret: String.t(),
          client_secret_hash: String.t(),
          client_secret_jwt_verifier_encrypted: String.t()
        }
  def rotate_secret_material(opts \\ []) when is_list(opts) do
    secret = generate_token(@secret_bytes)

    %{
      client_secret: secret,
      client_secret_hash: Policy.hash_client_secret(secret),
      client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(secret, opts)
    }
  end

  @spec register_client(map() | keyword()) ::
          {:ok, RegistrationResult.t()} | {:error, [error_detail()]}
  def register_client(attrs) when is_list(attrs) do
    attrs |> Enum.into(%{}) |> register_client()
  end

  def register_client(attrs) when is_map(attrs) do
    with {:ok, normalized} <- normalize(attrs),
         {:ok, persisted_client} <- persist_client(normalized.client) do
      result = %RegistrationResult{
        client: persisted_client,
        client_secret: normalized.plaintext_secret
      }

      Observability.emit(:client, :registration_succeeded, %{}, %{
        client_id: persisted_client.client_id,
        client_type: persisted_client.client_type,
        token_endpoint_auth_method: persisted_client.token_endpoint_auth_method
      })

      {:ok, result}
    else
      {:error, errors} ->
        Observability.emit(:client, :registration_rejected, %{}, %{
          reason_codes: Enum.map(errors, & &1.reason),
          field_errors: Enum.map(errors, &Map.take(&1, [:field, :reason]))
        })

        {:error, errors}
    end
  end

  defp normalize(attrs) do
    normalized = normalize_client_attrs(attrs)
    errors = validation_errors(normalized)

    case errors do
      [] ->
        client = %Client{
          client_id:
            normalize_optional_string(Map.get(attrs, :client_id) || Map.get(attrs, "client_id")) ||
              generate_client_id(),
          client_secret_hash: normalized.client_secret_hash,
          client_secret_jwt_verifier_encrypted: normalized.client_secret_jwt_verifier_encrypted,
          client_type: normalized.client_type,
          name: normalize_optional_string(Map.get(attrs, :name) || Map.get(attrs, "name")),
          redirect_uris: normalized.redirect_uris,
          allowed_scopes: normalized.allowed_scopes,
          allowed_grant_types: normalized.allowed_grant_types,
          allowed_response_types: normalized.allowed_response_types,
          token_endpoint_auth_method: normalized.auth_method,
          token_endpoint_auth_signing_alg: normalized.token_endpoint_auth_signing_alg,
          jwks: normalized.jwks,
          jwks_uri: normalized.jwks_uri,
          pkce_required: true,
          subject_type: :public,
          created_by:
            normalize_optional_string(Map.get(attrs, :created_by) || Map.get(attrs, "created_by")),
          created_at: DateTime.utc_now(),
          metadata: normalize_metadata(Map.get(attrs, :metadata) || Map.get(attrs, "metadata"))
        }

        {:ok, %{client: client, plaintext_secret: normalized.plaintext_secret}}

      _errors ->
        {:error, Enum.reverse(errors)}
    end
  end

  defp persist_client(%Client{} = client) do
    case ClientLifecycle.persist_direct(client) do
      {:ok, persisted_client} ->
        {:ok, persisted_client}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset_errors(changeset)}

      {:error, error} ->
        {:error, [%{field: :base, reason: :persistence_failed, detail: inspect(error)}]}
    end
  end

  defp normalize_client_attrs(attrs) do
    client_type =
      normalize_client_type(Map.get(attrs, :client_type) || Map.get(attrs, "client_type"))

    auth_method = normalize_auth_method(fetch_auth_method(attrs))
    secret_material = secret_values(client_type)

    allowed_grant_types =
      attrs |> fetch_required_list(:allowed_grant_types) |> normalize_string_list()

    %{
      client_type: client_type,
      auth_method: auth_method,
      token_endpoint_auth_signing_alg:
        normalize_signing_alg(
          Map.get(attrs, :token_endpoint_auth_signing_alg) ||
            Map.get(attrs, "token_endpoint_auth_signing_alg")
        ),
      redirect_uris: attrs |> fetch_required_list(:redirect_uris) |> normalize_string_list(),
      allowed_scopes: attrs |> fetch_required_list(:allowed_scopes) |> normalize_string_list(),
      allowed_grant_types: allowed_grant_types,
      allowed_response_types:
        attrs
        |> Map.get(
          :allowed_response_types,
          Map.get(attrs, "allowed_response_types", default_response_types(allowed_grant_types))
        )
        |> normalize_string_list(),
      jwks: normalize_jwks(Map.get(attrs, :jwks) || Map.get(attrs, "jwks")),
      jwks_uri:
        normalize_optional_string(Map.get(attrs, :jwks_uri) || Map.get(attrs, "jwks_uri")),
      pkce_required: Map.get(attrs, :pkce_required, Map.get(attrs, "pkce_required", true)),
      client_secret_hash: secret_material.client_secret_hash,
      client_secret_jwt_verifier_encrypted: secret_material.client_secret_jwt_verifier_encrypted,
      plaintext_secret: secret_material.client_secret
    }
  end

  defp validation_errors(normalized) do
    shape_errors =
      case ClientMetadata.validate_direct(normalized) do
        :ok -> []
        {:error, errors} -> errors
      end

    shape_errors
    |> validate_auth_signing_alg(normalized)
    |> validate_pkce_required(normalized.pkce_required)
  end

  defp fetch_auth_method(attrs) do
    Map.get(attrs, :token_endpoint_auth_method) || Map.get(attrs, "token_endpoint_auth_method")
  end

  defp secret_values(:confidential), do: rotate_secret_material()

  defp secret_values(:public) do
    %{client_secret_hash: nil, client_secret_jwt_verifier_encrypted: nil, client_secret: nil}
  end

  defp secret_values(_other) do
    %{client_secret_hash: nil, client_secret_jwt_verifier_encrypted: nil, client_secret: nil}
  end

  defp validate_auth_signing_alg(errors, %{auth_method: :client_secret_jwt} = normalized) do
    errors
    |> validate_client_secret_jwt_signing_alg(normalized.token_endpoint_auth_signing_alg)
    |> validate_client_secret_jwt_security_profile()
  end

  defp validate_auth_signing_alg(errors, %{auth_method: :private_key_jwt} = normalized) do
    if normalized.token_endpoint_auth_signing_alg in [nil, :RS256, :ES256, :PS256, :EdDSA] do
      errors
    else
      [
        %{
          field: :token_endpoint_auth_signing_alg,
          reason: :invalid_token_endpoint_auth_signing_alg,
          detail: normalized.token_endpoint_auth_signing_alg
        }
        | errors
      ]
    end
  end

  defp validate_auth_signing_alg(errors, %{token_endpoint_auth_signing_alg: nil}), do: errors

  defp validate_auth_signing_alg(errors, %{token_endpoint_auth_signing_alg: alg}) do
    [
      %{
        field: :token_endpoint_auth_signing_alg,
        reason: :invalid_token_endpoint_auth_signing_alg,
        detail: alg
      }
      | errors
    ]
  end

  defp validate_client_secret_jwt_signing_alg(errors, :HS256), do: errors

  defp validate_client_secret_jwt_signing_alg(errors, alg) do
    [
      %{
        field: :token_endpoint_auth_signing_alg,
        reason: :invalid_token_endpoint_auth_signing_alg,
        detail: alg || :missing
      }
      | errors
    ]
  end

  defp validate_client_secret_jwt_security_profile(errors) do
    case effective_server_security_profile() do
      profile when profile in [:fapi_2_0_security, :fapi_2_0_message_signing] ->
        [
          %{
            field: :token_endpoint_auth_method,
            reason: :invalid_token_endpoint_auth_method,
            detail: :incompatible_with_fapi_2_0
          }
          | errors
        ]

      _other ->
        errors
    end
  end

  defp validate_redirect_uris(errors, []),
    do: [%{field: :redirect_uris, reason: :invalid_redirect_uri, detail: :empty} | errors]

  defp validate_redirect_uris(errors, redirect_uris) do
    Enum.reduce(redirect_uris, errors, fn redirect_uri, acc ->
      case validate_redirect_uri(redirect_uri) do
        :ok -> acc
        reason -> [%{field: :redirect_uris, reason: :invalid_redirect_uri, detail: reason} | acc]
      end
    end)
  end

  defp validate_scopes(errors, []),
    do: [%{field: :allowed_scopes, reason: :invalid_scope, detail: :empty} | errors]

  defp validate_scopes(errors, scopes) do
    Enum.reduce(scopes, errors, fn scope, acc ->
      if scope == "openid" or valid_scope_token?(scope),
        do: acc,
        else: [%{field: :allowed_scopes, reason: :invalid_scope, detail: scope} | acc]
    end)
  end

  defp validate_pkce_required(errors, true), do: errors
  defp validate_pkce_required(errors, "true"), do: errors

  defp validate_pkce_required(errors, false),
    do: [%{field: :pkce_required, reason: :pkce_required, detail: false} | errors]

  defp validate_pkce_required(errors, "false"),
    do: [%{field: :pkce_required, reason: :pkce_required, detail: false} | errors]

  defp validate_pkce_required(errors, other),
    do: [%{field: :pkce_required, reason: :pkce_required, detail: other} | errors]

  defp validate_redirect_uri(""), do: :blank

  defp validate_redirect_uri(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{scheme: nil} ->
        :missing_scheme

      %URI{host: nil, scheme: scheme} when scheme not in ["http", "https"] ->
        :invalid_scheme

      %URI{scheme: scheme} when scheme not in ["http", "https"] ->
        :invalid_scheme

      %URI{host: host} when host in [nil, ""] ->
        :missing_host

      %URI{fragment: fragment} when fragment not in [nil, ""] ->
        :fragment_not_allowed

      %URI{} ->
        if String.contains?(uri, "*") do
          :wildcard_not_allowed
        else
          :ok
        end
    end
  end

  defp validate_redirect_uri(_other), do: :invalid

  defp valid_scope_token?(scope) do
    Regex.match?(~r/^[A-Za-z0-9._:-]+$/, scope)
  end

  defp normalize_client_type(value) when value in [:public, :confidential], do: value

  defp normalize_client_type(value) when is_binary(value) do
    case value do
      "public" -> :public
      "confidential" -> :confidential
      _other -> :invalid
    end
  end

  defp normalize_client_type(_value), do: nil

  defp normalize_auth_method(nil), do: nil

  defp normalize_auth_method(value)
       when value in [
              :none,
              :client_secret_basic,
              :client_secret_post,
              :client_secret_jwt,
              :private_key_jwt
            ],
       do: value

  defp normalize_auth_method(value) when is_binary(value) do
    case value do
      "none" -> :none
      "client_secret_basic" -> :client_secret_basic
      "client_secret_post" -> :client_secret_post
      "client_secret_jwt" -> :client_secret_jwt
      "private_key_jwt" -> :private_key_jwt
      _other -> nil
    end
  end

  defp normalize_auth_method(_value), do: nil

  defp normalize_signing_alg(value) when value in [:HS256, :RS256, :ES256, :PS256, :EdDSA],
    do: value

  defp normalize_signing_alg(value) when is_binary(value) do
    case String.trim(value) do
      "HS256" -> :HS256
      "RS256" -> :RS256
      "ES256" -> :ES256
      "PS256" -> :PS256
      "EdDSA" -> :EdDSA
      "" -> nil
      _other -> :invalid
    end
  end

  defp normalize_signing_alg(_value), do: nil

  defp normalize_string_list(nil), do: []

  defp normalize_string_list(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_string_list(value) when is_list(value) do
    value
    |> Enum.map(&normalize_optional_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp normalize_string_list(_other), do: []

  defp default_response_types(["urn:ietf:params:oauth:grant-type:device_code"]), do: []
  defp default_response_types(_grant_types), do: ["code"]

  defp normalize_jwks(value) when is_map(value), do: value
  defp normalize_jwks(_value), do: nil

  defp normalize_optional_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp normalize_metadata(value) when is_map(value), do: value
  defp normalize_metadata(_value), do: %{}

  defp effective_server_security_profile do
    case Repository.get_server_policy() do
      {:ok, %{security_profile: profile}} -> profile
      _ -> :none
    end
  end

  defp uri_origin(uri) do
    case URI.parse(uri) do
      %URI{scheme: scheme, host: host, port: port}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        {:ok, {scheme, host, port || default_port(scheme)}}

      _other ->
        :error
    end
  end

  defp default_port("http"), do: 80
  defp default_port("https"), do: 443

  defp fetch_required_list(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  @spec generate_client_id() :: String.t()
  def generate_client_id do
    "ls_" <> generate_token(@client_id_bytes)
  end

  defp generate_token(size) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message ->
        %{field: field, reason: :persistence_failed, detail: message}
      end)
    end)
  end
end
