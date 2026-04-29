defmodule Lockspire.Protocol.AuthorizationRequest do
  @moduledoc """
  Validates `/authorize` request parameters before any web or host handoff occurs.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.PushedAuthorizationRequest
  alias Lockspire.Observability
  alias Lockspire.Protocol.ParPolicy
  alias Lockspire.Protocol.RequestObject
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @allowed_prompts MapSet.new(["login", "consent"])
  @unsupported_params ~w(resource response_mode)

  defmodule Validated do
    @moduledoc """
    Canonical validated `/authorize` request state.
    """

    alias Lockspire.Domain.Client

    @type t :: %__MODULE__{
            client: Client.t(),
            client_id: String.t(),
            redirect_uri: String.t(),
            scopes: [String.t()],
            prompt: [String.t()],
            nonce: String.t() | nil,
            state: String.t() | nil,
            max_age: non_neg_integer() | nil,
            auth_time_requested?: boolean(),
            code_challenge: String.t(),
            code_challenge_method: :S256
          }

    defstruct [
      :client,
      :client_id,
      :redirect_uri,
      :nonce,
      :state,
      :max_age,
      :code_challenge,
      :code_challenge_method,
      scopes: [],
      prompt: [],
      auth_time_requested?: false
    ]
  end

  defmodule Error do
    @moduledoc """
    Browser-safe or redirect-safe authorization request validation error.
    """

    @type t :: %__MODULE__{
            error: String.t(),
            error_description: String.t(),
            reason_code: atom(),
            state: String.t() | nil,
            redirect_uri: String.t() | nil
          }

    defstruct [:error, :error_description, :reason_code, :state, :redirect_uri]
  end

  @type result ::
          {:ok, Validated.t()} | {:browser_error, Error.t()} | {:redirect_error, Error.t()}

  @spec validate(map()) :: result()
  def validate(params) when is_map(params) do
    with {:ok, %Client{} = client} <- fetch_client(params),
         {:ok, resolved_par_policy} <- resolve_effective_par_policy(client),
         :ok <- maybe_require_pushed_authorization_request(params, client, resolved_par_policy),
         {:ok, resolved_params} <- resolve_authorization_params(params, client),
         {:ok, resolved_params} <- maybe_consume_request_object(resolved_params, client),
         {:ok, %Validated{} = validated} <- validate_with_client(resolved_params, client) do
      validated = %Validated{validated | client: client}

      Observability.emit(:authorization_request_accepted, %{}, %{
        client_id: client.client_id,
        redirect_safe: true
      })

      {:ok, validated}
    else
      {:browser_error, %Error{} = error} ->
        emit_rejection(params["client_id"], error, false)
        {:browser_error, error}

      {:redirect_error, %Error{} = error} ->
        emit_rejection(params["client_id"], error, true)
        {:redirect_error, error}
    end
  end

  @spec validate_pushed(map(), Client.t()) :: {:ok, Validated.t()} | {:error, Error.t()}
  def validate_pushed(params, %Client{} = client) when is_map(params) do
    case validate_with_client(params, client, pushed?: true) do
      {:ok, %Validated{} = validated} ->
        {:ok, validated}

      {:browser_error, %Error{} = error} ->
        {:error, error}

      {:redirect_error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp fetch_client(%{"client_id" => client_id}) when is_binary(client_id) and client_id != "" do
    case Repository.fetch_client_by_id(client_id) do
      {:ok, %Client{} = client} ->
        {:ok, client}

      {:ok, nil} ->
        {:browser_error, browser_error(:invalid_client, "Unknown client_id", :invalid_client)}

      {:error, _reason} ->
        {:browser_error,
         browser_error(:invalid_request, "Unable to load client", :client_lookup_failed)}
    end
  end

  defp fetch_client(_params) do
    {:browser_error, browser_error(:invalid_request, "Missing client_id", :missing_client_id)}
  end

  defp resolve_effective_par_policy(%Client{} = client) do
    case Repository.get_server_policy() do
      {:ok, server_policy} ->
        {:ok, ParPolicy.resolve_effective_policy(server_policy, client)}

      {:error, _reason} ->
        {:browser_error,
         browser_error(
           :invalid_request,
           "Unable to load server policy",
           :server_policy_lookup_failed
         )}
    end
  end

  defp maybe_require_pushed_authorization_request(
         %{"request_uri" => request_uri},
         %Client{},
         _resolved_par_policy
       )
       when is_binary(request_uri) and request_uri != "" do
    :ok
  end

  defp maybe_require_pushed_authorization_request(params, %Client{} = client, resolved_par_policy) do
    if resolved_par_policy.par_required? do
      par_required_error(params, client)
    else
      :ok
    end
  end

  defp resolve_authorization_params(%{"request_uri" => request_uri} = params, %Client{} = client)
       when is_binary(request_uri) and request_uri != "" do
    with :ok <- reject_request_uri_and_request_conflict(params),
         :ok <- reject_request_uri_conflicts(params),
         :ok <- validate_lockspire_request_uri(request_uri),
         {:ok, %PushedAuthorizationRequest{} = request} <-
           consume_pushed_authorization_request(request_uri, client.client_id) do
      {:ok, pushed_request_to_params(request)}
    end
  end

  defp resolve_authorization_params(params, %Client{}), do: {:ok, params}

  defp reject_request_uri_and_request_conflict(%{
         "request_uri" => request_uri,
         "request" => request
       }) do
    if present?(request_uri) and present?(request) do
      {:browser_error,
       browser_error(
         :invalid_request,
         "request and request_uri cannot both be supplied",
         :request_object_and_request_uri_conflict
       )}
    else
      :ok
    end
  end

  defp reject_request_uri_and_request_conflict(_params), do: :ok

  defp par_required_error(params, %Client{} = client) do
    case validate_redirect_uri(client, params) do
      {:ok, _redirect_uri} ->
        {:redirect_error,
         redirect_error(
           params,
           :invalid_request,
           "request_uri from the PAR endpoint is required",
           :par_required_request_uri
         )}

      {:browser_error, %Error{}} ->
        {:browser_error,
         browser_error(
           :invalid_request,
           "request_uri from the PAR endpoint is required",
           :par_required_request_uri
         )}
    end
  end

  defp validate_redirect_uri(client, %{"redirect_uri" => redirect_uri})
       when is_binary(redirect_uri) and redirect_uri != "" do
    if redirect_uri in client.redirect_uris do
      {:ok, redirect_uri}
    else
      {:browser_error,
       browser_error(
         :invalid_request,
         "redirect_uri must match a registered URI",
         :invalid_redirect_uri
       )}
    end
  end

  defp validate_redirect_uri(_client, _params) do
    {:browser_error,
     browser_error(:invalid_request, "Missing redirect_uri", :missing_redirect_uri)}
  end

  defp validate_with_client(params, %Client{} = client, opts \\ []) do
    pushed? = Keyword.get(opts, :pushed?, false)

    with :ok <- maybe_validate_pushed_client_id(params, client, pushed?),
         :ok <- maybe_reject_inbound_request_uri(params, pushed?),
         {:ok, redirect_uri} <- validate_redirect_uri(client, params),
         {:ok, scopes} <- validate_scopes(client, params),
         {:ok, prompt} <- validate_prompt(params),
         {:ok, max_age} <- validate_max_age(params),
         :ok <- validate_response_type(params),
         :ok <- validate_nonce(params, scopes),
         :ok <- validate_pkce(client, params),
         {:ok, auth_time_requested?} <- validate_claims_parameter(params),
         :ok <- reject_unsupported_params(params) do
      {:ok, build_validated(params, client, redirect_uri, scopes, prompt, max_age, auth_time_requested?)}
    end
  end

  defp maybe_consume_request_object(%{"request" => request} = params, %Client{} = client)
       when is_binary(request) and request != "" do
    RequestObject.consume(params, client, jar_opts())
  end

  defp maybe_consume_request_object(params, _client), do: {:ok, params}

  defp jar_opts do
    [
      expected_audience: Config.issuer!(),
      max_age: Config.jar_max_age_seconds(),
      leeway: 5
    ]
  end

  defp validate_scopes(client, params) do
    scope_param = normalize_optional_string(params["scope"])

    scopes =
      scope_param
      |> to_scope_list()

    cond do
      scopes == [] ->
        {:redirect_error, redirect_error(params, :invalid_scope, "Missing scope", :missing_scope)}

      Enum.any?(scopes, &(not valid_scope_token?(&1))) ->
        {:redirect_error,
         redirect_error(params, :invalid_scope, "Scope syntax is invalid", :malformed_scope)}

      Enum.any?(scopes, &unknown_scope?(&1)) ->
        {:redirect_error,
         redirect_error(params, :invalid_scope, "Requested scope is unknown", :unknown_scope)}

      Enum.any?(scopes, &disallowed_scope?(client, &1)) ->
        {:redirect_error,
         redirect_error(
           params,
           :invalid_scope,
           "Requested scope is not allowed for this client",
           :disallowed_scope
         )}

      true ->
        {:ok, scopes}
    end
  end

  defp validate_prompt(params) do
    prompt =
      params["prompt"]
      |> normalize_optional_string()
      |> case do
        nil -> []
        value -> String.split(value, " ", trim: true)
      end

    cond do
      prompt == [] ->
        {:ok, []}

      length(prompt) != length(Enum.uniq(prompt)) ->
        {:redirect_error,
         redirect_error(
           params,
           :invalid_request,
           "prompt values must be unique",
           :duplicate_prompt
         )}

      "none" in prompt and length(prompt) > 1 ->
        {:redirect_error,
         redirect_error(
           params,
           :invalid_request,
           "prompt=none must not be combined with other prompt values",
           :prompt_none_conflict
         )}

      prompt == ["none"] ->
        {:ok, ["none"]}

      "select_account" in prompt ->
        {:redirect_error,
         redirect_error(
           params,
           :invalid_request,
           "prompt value is not supported",
           :unsupported_prompt
         )}

      Enum.all?(prompt, &MapSet.member?(@allowed_prompts, &1)) ->
        {:ok, prompt}

      true ->
        {:redirect_error,
         redirect_error(params, :invalid_request, "prompt value is invalid", :invalid_prompt)}
    end
  end

  defp validate_max_age(params) do
    case Map.get(params, "max_age") do
      nil ->
        {:ok, nil}

      max_age when is_binary(max_age) ->
        if max_age != String.trim(max_age) do
          invalid_max_age(params)
        else
          case normalize_optional_string(max_age) do
            nil ->
              invalid_max_age(params)

            normalized ->
              if Regex.match?(~r/^\d+$/, normalized) do
                {:ok, String.to_integer(normalized)}
              else
                invalid_max_age(params)
              end
          end
        end

      _other ->
        invalid_max_age(params)
    end
  end

  defp validate_response_type(params) do
    case Policy.ensure_supported_response_type(params["response_type"]) do
      :ok ->
        :ok

      {:error, :unsupported_response_type} ->
        {:redirect_error,
         redirect_error(
           params,
           :unsupported_response_type,
           "Only response_type=code is supported",
           :unsupported_response_type
         )}
    end
  end

  defp validate_nonce(params, scopes) do
    if "openid" in scopes do
      case normalize_optional_string(params["nonce"]) do
        nil ->
          {:redirect_error,
           redirect_error(
             params,
             :invalid_request,
             "nonce is required for openid requests",
             :missing_nonce
           )}

        _nonce ->
          :ok
      end
    else
      :ok
    end
  end

  defp validate_pkce(
         _client,
         %{"code_challenge" => challenge, "code_challenge_method" => "S256"} = params
       )
       when is_binary(challenge) and challenge != "" do
    if valid_code_challenge?(challenge) do
      :ok
    else
      {:redirect_error,
       redirect_error(
         params,
         :invalid_request,
         "code_challenge is invalid",
         :invalid_code_challenge
       )}
    end
  end

  defp validate_pkce(client, params) do
    if client.pkce_required do
      {:redirect_error,
       redirect_error(params, :invalid_request, "PKCE S256 is required", :missing_pkce)}
    else
      :ok
    end
  end

  defp validate_claims_parameter(params) do
    case Map.get(params, "claims") do
      nil ->
        {:ok, false}

      claims when is_binary(claims) ->
        with {:ok, decoded} <- Jason.decode(claims),
             :ok <- ensure_supported_claims_structure(decoded) do
          {:ok, true}
        else
          _reason -> invalid_claims_parameter(params)
        end

      _other ->
        invalid_claims_parameter(params)
    end
  end

  defp maybe_validate_pushed_client_id(_params, _client, false), do: :ok

  defp maybe_validate_pushed_client_id(%{"client_id" => client_id}, %Client{} = client, true)
       when is_binary(client_id) and client_id != "" do
    if client_id == client.client_id do
      :ok
    else
      {:browser_error,
       browser_error(
         :invalid_client,
         "client_id does not match authenticated client",
         :client_id_mismatch
       )}
    end
  end

  defp maybe_validate_pushed_client_id(_params, _client, true), do: :ok

  defp maybe_reject_inbound_request_uri(params, true) do
    if present?(params["request_uri"]) do
      {:browser_error,
       browser_error(:invalid_request, "request_uri is not supported", :unsupported_request_uri)}
    else
      :ok
    end
  end

  defp maybe_reject_inbound_request_uri(_params, false), do: :ok

  defp reject_request_uri_conflicts(params) do
    conflict_keys =
      params
      |> Enum.reject(fn {key, _value} -> key in ["client_id", "request_uri"] end)
      |> Enum.filter(fn {_key, value} -> present?(value) end)

    case conflict_keys do
      [] ->
        :ok

      _other ->
        {:browser_error,
         browser_error(
           :invalid_request,
           "request_uri cannot be combined with raw authorization parameters",
           :request_uri_conflict
         )}
    end
  end

  defp validate_lockspire_request_uri(request_uri) do
    if String.starts_with?(request_uri, PushedAuthorizationRequest.request_uri_prefix()) do
      :ok
    else
      {:browser_error,
       browser_error(
         :invalid_request,
         "request_uri is invalid, expired, or already used",
         :invalid_request_uri
       )}
    end
  end

  defp consume_pushed_authorization_request(request_uri, client_id) do
    request_uri
    |> Policy.hash_token()
    |> Repository.consume_pushed_authorization_request(client_id)
    |> case do
      {:ok, %PushedAuthorizationRequest{} = request} ->
        {:ok, request}

      {:ok, nil} ->
        {:browser_error,
         browser_error(
           :invalid_request,
           "request_uri is invalid, expired, or already used",
           :invalid_request_uri
         )}

      {:error, _reason} ->
        {:browser_error,
         browser_error(
           :invalid_request,
           "Unable to resolve request_uri",
           :request_uri_lookup_failed
         )}
    end
  end

  defp pushed_request_to_params(%PushedAuthorizationRequest{} = request) do
    %{
      "client_id" => request.client_id,
      "redirect_uri" => request.redirect_uri,
      "response_type" => "code",
      "scope" => Enum.join(request.scopes, " "),
      "prompt" => prompt_param(request.prompt),
      "nonce" => request.nonce,
      "state" => request.state,
      "code_challenge" => request.code_challenge,
      "code_challenge_method" => Atom.to_string(request.code_challenge_method)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp prompt_param(nil), do: nil
  defp prompt_param(prompt) when is_binary(prompt), do: prompt
  defp prompt_param(prompt) when is_list(prompt), do: Enum.join(prompt, " ")

  defp reject_unsupported_params(params) do
    case Enum.find(@unsupported_params, &present?(params[&1])) do
      nil ->
        :ok

      param ->
        {:redirect_error,
         redirect_error(
           params,
           :invalid_request,
           "#{param} is not supported",
           String.to_atom("unsupported_#{param}")
         )}
    end
  end

  defp browser_error(error, description, reason_code) do
    %Error{
      error: to_string(error),
      error_description: description,
      reason_code: reason_code,
      redirect_uri: nil,
      state: nil
    }
  end

  defp redirect_error(params, error, description, reason_code) do
    %Error{
      error: to_string(error),
      error_description: description,
      reason_code: reason_code,
      redirect_uri: params["redirect_uri"],
      state: normalize_optional_string(params["state"])
    }
  end

  defp emit_rejection(client_id, %Error{} = error, redirect_safe) do
    Observability.emit(:authorization_request_rejected, %{}, %{
      client_id: client_id,
      reason_code: error.reason_code,
      redirect_safe: redirect_safe
    })
  end

  defp build_validated(
         params,
         %Client{} = client,
         redirect_uri,
         scopes,
         prompt,
         max_age,
         auth_time_requested?
       ) do
    %Validated{
      client: client,
      client_id: client.client_id,
      redirect_uri: redirect_uri,
      scopes: scopes,
      prompt: prompt,
      nonce: normalize_optional_string(params["nonce"]),
      state: normalize_optional_string(params["state"]),
      max_age: max_age,
      auth_time_requested?: auth_time_requested?,
      code_challenge: params["code_challenge"],
      code_challenge_method: :S256
    }
  end

  defp ensure_supported_claims_structure(%{
         "id_token" => %{"auth_time" => %{"essential" => true}}
       } = claims)
       when map_size(claims) == 1 do
    :ok
  end

  defp ensure_supported_claims_structure(_claims), do: :unsupported

  defp invalid_max_age(params) do
    {:redirect_error,
     redirect_error(params, :invalid_request, "max_age must be a non-negative integer", :invalid_max_age)}
  end

  defp invalid_claims_parameter(params) do
    {:redirect_error,
     redirect_error(
       params,
       :invalid_request,
       "claims supports only id_token.auth_time.essential=true",
       :invalid_claims_parameter
     )}
  end

  defp to_scope_list(nil), do: []

  defp to_scope_list(value) do
    String.split(value, " ", trim: true)
  end

  defp normalize_optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp unknown_scope?("openid"), do: false
  defp unknown_scope?(scope), do: scope not in Config.known_scopes()

  defp disallowed_scope?(_client, "openid"), do: false
  defp disallowed_scope?(client, scope), do: scope not in client.allowed_scopes

  defp valid_scope_token?(scope) do
    Regex.match?(~r/^[A-Za-z0-9._:-]+$/, scope)
  end

  defp valid_code_challenge?(challenge) do
    Regex.match?(~r/^[A-Za-z0-9._~-]{43,128}$/, challenge)
  end

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true
end
