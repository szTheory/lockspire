defmodule Lockspire.Protocol.AuthorizationRequest do
  @moduledoc """
  Validates `/authorize` request parameters before any web or host handoff occurs.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Observability
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @allowed_prompts MapSet.new(["login", "consent"])
  @unsupported_params ~w(claims request request_uri resource response_mode)

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
            code_challenge: String.t(),
            code_challenge_method: :S256
          }

    defstruct [
      :client,
      :client_id,
      :redirect_uri,
      :nonce,
      :state,
      :code_challenge,
      :code_challenge_method,
      scopes: [],
      prompt: []
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
         {:ok, redirect_uri} <- validate_redirect_uri(client, params),
         {:ok, scopes} <- validate_scopes(client, params),
         {:ok, prompt} <- validate_prompt(params),
         :ok <- validate_response_type(params),
         :ok <- validate_nonce(params, scopes),
         :ok <- validate_pkce(client, params),
         :ok <- reject_unsupported_params(params) do
      validated = %Validated{
        client: client,
        client_id: client.client_id,
        redirect_uri: redirect_uri,
        scopes: scopes,
        prompt: prompt,
        nonce: normalize_optional_string(params["nonce"]),
        state: normalize_optional_string(params["state"]),
        code_challenge: params["code_challenge"],
        code_challenge_method: :S256
      }

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

      Enum.any?(prompt, &(&1 in ["none", "select_account"])) ->
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
         client,
         %{"code_challenge" => challenge, "code_challenge_method" => "S256"} = params
       )
       when is_binary(challenge) and challenge != "" do
    cond do
      not client.pkce_required ->
        {:redirect_error,
         redirect_error(params, :invalid_request, "PKCE is required", :pkce_required)}

      not valid_code_challenge?(challenge) ->
        {:redirect_error,
         redirect_error(
           params,
           :invalid_request,
           "code_challenge is invalid",
           :invalid_code_challenge
         )}

      true ->
        :ok
    end
  end

  defp validate_pkce(_client, params) do
    {:redirect_error,
     redirect_error(params, :invalid_request, "PKCE S256 is required", :missing_pkce)}
  end

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
