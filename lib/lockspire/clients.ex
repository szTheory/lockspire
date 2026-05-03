defmodule Lockspire.Clients do
  @moduledoc """
  Durable client registration API for secure Phase 2 client onboarding.
  """

  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client
  alias Lockspire.Observability
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @allowed_grant_types MapSet.new(["authorization_code", "refresh_token"])
  @allowed_response_types MapSet.new(["code"])
  @secret_bytes 32
  @client_id_bytes 24

  @type validation_error ::
          :invalid_client_type
          | :invalid_token_endpoint_auth_method
          | :invalid_redirect_uri
          | :invalid_logout_uri
          | :invalid_scope
          | :invalid_grant_type
          | :invalid_response_type
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
    with {:ok, logout_origin} <- uri_origin(logout_uri) do
      Enum.any?(redirect_uris, fn redirect_uri ->
        case uri_origin(redirect_uri) do
          {:ok, redirect_origin} -> redirect_origin == logout_origin
          :error -> false
        end
      end)
    else
      :error -> false
    end
  end

  @spec rotate_secret_hash() :: {String.t(), String.t()}
  def rotate_secret_hash do
    secret = generate_token(@secret_bytes)
    {Policy.hash_client_secret(secret), secret}
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
          client_type: normalized.client_type,
          name: normalize_optional_string(Map.get(attrs, :name) || Map.get(attrs, "name")),
          redirect_uris: normalized.redirect_uris,
          allowed_scopes: normalized.allowed_scopes,
          allowed_grant_types: normalized.allowed_grant_types,
          allowed_response_types: normalized.allowed_response_types,
          token_endpoint_auth_method: normalized.auth_method,
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
    case Repository.register_client(client) do
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
    {client_secret_hash, plaintext_secret} = secret_values(client_type)

    %{
      client_type: client_type,
      auth_method: auth_method,
      redirect_uris: attrs |> fetch_required_list(:redirect_uris) |> normalize_string_list(),
      allowed_scopes: attrs |> fetch_required_list(:allowed_scopes) |> normalize_string_list(),
      allowed_grant_types:
        attrs |> fetch_required_list(:allowed_grant_types) |> normalize_string_list(),
      allowed_response_types:
        attrs
        |> Map.get(:allowed_response_types, Map.get(attrs, "allowed_response_types", ["code"]))
        |> normalize_string_list(),
      pkce_required: Map.get(attrs, :pkce_required, Map.get(attrs, "pkce_required", true)),
      client_secret_hash: client_secret_hash,
      plaintext_secret: plaintext_secret
    }
  end

  defp validation_errors(normalized) do
    []
    |> validate_client_type(normalized.client_type)
    |> validate_auth_method(normalized.client_type, normalized.auth_method)
    |> validate_redirect_uris(normalized.redirect_uris)
    |> validate_scopes(normalized.allowed_scopes)
    |> validate_grant_types(normalized.allowed_grant_types)
    |> validate_response_types(normalized.allowed_response_types)
    |> validate_pkce_required(normalized.pkce_required)
  end

  defp fetch_auth_method(attrs) do
    Map.get(attrs, :token_endpoint_auth_method) || Map.get(attrs, "token_endpoint_auth_method")
  end

  defp secret_values(:confidential), do: rotate_secret_hash()
  defp secret_values(:public), do: {nil, nil}
  defp secret_values(_other), do: {nil, nil}

  defp validate_client_type(errors, type) when type in [:public, :confidential], do: errors

  defp validate_client_type(errors, nil) do
    [%{field: :client_type, reason: :invalid_client_type, detail: nil} | errors]
  end

  defp validate_client_type(errors, type) do
    [%{field: :client_type, reason: :invalid_client_type, detail: type} | errors]
  end

  defp validate_auth_method(errors, :public, :none), do: errors

  defp validate_auth_method(errors, :public, method) do
    [
      %{
        field: :token_endpoint_auth_method,
        reason: :invalid_token_endpoint_auth_method,
        detail: method
      }
      | errors
    ]
  end

  defp validate_auth_method(errors, :confidential, method)
       when method in [:client_secret_basic, :client_secret_post], do: errors

  defp validate_auth_method(errors, :confidential, method) do
    [
      %{
        field: :token_endpoint_auth_method,
        reason: :invalid_token_endpoint_auth_method,
        detail: method
      }
      | errors
    ]
  end

  defp validate_auth_method(errors, _client_type, _method), do: errors

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
      cond do
        scope == "openid" ->
          [%{field: :allowed_scopes, reason: :invalid_scope, detail: scope} | acc]

        valid_scope_token?(scope) ->
          acc

        true ->
          [%{field: :allowed_scopes, reason: :invalid_scope, detail: scope} | acc]
      end
    end)
  end

  defp validate_grant_types(errors, grant_types) do
    Enum.reduce(grant_types, errors, fn grant_type, acc ->
      if MapSet.member?(@allowed_grant_types, grant_type) do
        acc
      else
        [%{field: :allowed_grant_types, reason: :invalid_grant_type, detail: grant_type} | acc]
      end
    end)
  end

  defp validate_response_types(errors, response_types) do
    Enum.reduce(response_types, errors, fn response_type, acc ->
      if MapSet.member?(@allowed_response_types, response_type) do
        acc
      else
        [
          %{field: :allowed_response_types, reason: :invalid_response_type, detail: response_type}
          | acc
        ]
      end
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
      _other -> nil
    end
  end

  defp normalize_client_type(_value), do: nil

  defp normalize_auth_method(nil), do: nil

  defp normalize_auth_method(value)
       when value in [:none, :client_secret_basic, :client_secret_post, :private_key_jwt],
       do: value

  defp normalize_auth_method(value) when is_binary(value) do
    case value do
      "none" -> :none
      "client_secret_basic" -> :client_secret_basic
      "client_secret_post" -> :client_secret_post
      "private_key_jwt" -> :private_key_jwt
      _other -> nil
    end
  end

  defp normalize_auth_method(_value), do: nil

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
