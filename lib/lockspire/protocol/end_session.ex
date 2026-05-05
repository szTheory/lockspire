defmodule Lockspire.Protocol.EndSession do
  @moduledoc """
  Validates RP-initiated logout requests before any host logout redirect occurs.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey

  @public_jwk_members ~w(alg crv e kid key_ops kty n use x x5c x5t x5t#S256 y)

  defmodule Error do
    @moduledoc """
    End-session validation error payload.
    """

    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom()
          }

    defstruct [:status, :error, :error_description, :reason_code]
  end

  defmodule Result do
    @moduledoc """
    Canonical validated end-session state.
    """

    @type t :: %__MODULE__{
            sid: String.t() | nil,
            account_id: String.t() | nil,
            post_logout_redirect_uri: String.t() | nil,
            state: String.t() | nil
          }

    defstruct [:sid, :account_id, :post_logout_redirect_uri, :state]
  end

  @type result :: {:ok, Result.t()} | {:error, Error.t()}

  @spec validate(map()) :: result()
  def validate(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))

    with {:ok, claims} <- validate_id_token_hint(params, request),
         {:ok, client} <- maybe_fetch_client(params, claims, request),
         :ok <- validate_aud_if_client_id(params, claims, client),
         {:ok, post_logout_redirect_uri} <- validate_post_logout_redirect_uri(params, client) do
      {:ok,
       %Result{
         sid: claim_value(claims, "sid"),
         account_id: claim_value(claims, "sub"),
         post_logout_redirect_uri: post_logout_redirect_uri,
         state: normalize_optional_string(params["state"])
       }}
    end
  end

  defp validate_id_token_hint(%{"id_token_hint" => hint}, request) when is_binary(hint) do
    compact_jwt = String.trim(hint)

    if compact_jwt == "" do
      {:ok, nil}
    else
      verify_id_token_hint(compact_jwt, request)
    end
  end

  defp validate_id_token_hint(_params, _request), do: {:ok, nil}

  defp verify_id_token_hint(compact_jwt, request) do
    security_profile =
      request
      |> request_opts()
      |> Keyword.get(:security_profile, %Lockspire.Protocol.SecurityProfile.Resolved{})

    allowed_algorithms =
      Lockspire.Protocol.SecurityProfile.allowed_signing_algorithms(
        security_profile.effective_profile
      )

    case key_store(request).list_publishable_keys() do
      {:ok, signing_keys} when is_list(signing_keys) ->
        default_error =
          invalid_request("id_token_hint signature is invalid", :invalid_id_token_hint)

        Enum.reduce_while(signing_keys, {:error, default_error}, fn key, _acc ->
          case build_public_jwk(key) do
            {:ok, public_jwk} ->
              try do
                case JOSE.JWT.verify_strict(public_jwk, allowed_algorithms, compact_jwt) do
                  {true, %JOSE.JWT{} = jwt_struct, _jws} ->
                    {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
                    {:halt, {:ok, claims}}

                  {false, _, _} ->
                    {:cont, {:error, default_error}}
                end
              rescue
                _ -> {:cont, {:error, default_error}}
              catch
                _, _ -> {:cont, {:error, default_error}}
              end

            :error ->
              {:cont, {:error, default_error}}
          end
        end)

      {:error, _reason} ->
        {:error, invalid_request("Unable to load signing keys", :signing_key_lookup_failed)}
    end
  end

  defp maybe_fetch_client(params, claims, request) do
    case client_identifier(params, claims) do
      nil ->
        {:ok, nil}

      client_id ->
        case client_store(request).fetch_client_by_id(client_id) do
          {:ok, %Client{} = client} ->
            {:ok, client}

          {:ok, nil} ->
            {:ok, nil}

          {:error, _reason} ->
            {:error, invalid_request("Unable to load client", :client_lookup_failed)}
        end
    end
  end

  defp validate_aud_if_client_id(params, claims, _client) do
    client_id = normalize_optional_string(params["client_id"])

    cond do
      is_nil(client_id) or is_nil(claims) ->
        :ok

      audience_includes?(claims["aud"], client_id) ->
        :ok

      true ->
        {:error, invalid_request("client_id not in id_token_hint aud", :client_id_not_in_aud)}
    end
  end

  defp validate_post_logout_redirect_uri(%{"post_logout_redirect_uri" => uri}, %Client{} = client)
       when is_binary(uri) do
    normalized_uri = String.trim(uri)

    cond do
      normalized_uri == "" ->
        {:ok, nil}

      normalized_uri in client.post_logout_redirect_uris ->
        {:ok, normalized_uri}

      true ->
        {:error,
         invalid_request(
           "post_logout_redirect_uri not registered",
           :unregistered_post_logout_redirect_uri
         )}
    end
  end

  defp validate_post_logout_redirect_uri(%{"post_logout_redirect_uri" => uri}, nil)
       when is_binary(uri) and uri != "" do
    {:error, invalid_request("no client to validate post_logout_redirect_uri", :missing_client)}
  end

  defp validate_post_logout_redirect_uri(_params, _client), do: {:ok, nil}

  defp audience_includes?(audience, client_id) when is_binary(audience), do: audience == client_id
  defp audience_includes?(audience, client_id) when is_list(audience), do: client_id in audience
  defp audience_includes?(_audience, _client_id), do: false

  defp client_identifier(params, claims) do
    normalize_optional_string(params["client_id"]) || infer_client_id_from_aud(claims)
  end

  defp infer_client_id_from_aud(nil), do: nil

  defp infer_client_id_from_aud(%{"aud" => audience}) when is_binary(audience),
    do: normalize_optional_string(audience)

  defp infer_client_id_from_aud(%{"aud" => [audience]}) when is_binary(audience),
    do: normalize_optional_string(audience)

  defp infer_client_id_from_aud(_claims), do: nil

  defp build_public_jwk(%SigningKey{} = key) do
    public_jwk =
      key.public_jwk
      |> Map.take(@public_jwk_members)
      |> Map.put_new("kid", key.kid)
      |> Map.put_new("kty", Atom.to_string(key.kty))
      |> Map.put_new("alg", key.alg)
      |> Map.put_new("use", Atom.to_string(key.use))
      |> JOSE.JWK.from_map()

    {:ok, public_jwk}
  rescue
    _ -> :error
  catch
    _, _ -> :error
  end

  defp build_public_jwk(_key), do: :error

  defp claim_value(nil, _key), do: nil
  defp claim_value(claims, key) when is_map(claims), do: normalize_optional_string(claims[key])

  defp invalid_request(description, reason_code) do
    %Error{
      status: 400,
      error: "invalid_request",
      error_description: description,
      reason_code: reason_code
    }
  end

  defp normalize_optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp client_store(request),
    do: request |> request_opts() |> Keyword.get(:client_store, Lockspire.Storage.Ecto.Repository)

  defp key_store(request),
    do: request |> request_opts() |> Keyword.get(:key_store, Lockspire.Storage.Ecto.Repository)

  defp request_opts(request) do
    Map.get(request, :opts, Map.get(request, "opts", []))
  end
end
