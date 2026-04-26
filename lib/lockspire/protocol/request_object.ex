defmodule Lockspire.Protocol.RequestObject do
  @moduledoc """
  Orchestrates JAR (RFC 9101) request-object consumption for `/authorize` and `/par`.

  Composes `Lockspire.Protocol.Jar.{decode/1, verify_signature/2, validate_claims/2}`
  into a single pipeline step that:

  1. Rejects outer-param conflicts (D-04) and `request` / `request_uri` collisions (D-06).
  2. Asserts the client has inline `jwks` registered (D-08).
  3. Decodes, verifies the signature, and validates the request JWT claims with the
     configured `:max_age` ceiling (D-13).
  4. Projects JAR claims into the same flat-params shape `pushed_request_to_params/1`
     produces in `Lockspire.Protocol.AuthorizationRequest`, so `validate_with_client/3`
     runs unchanged.

  ## Out of scope (v1.4)

  - JAR-by-reference (`request_uri` pointing to an external JWT URL)
  - JAR decryption (RFC 9101 §6 nested JWE)
  - `jwks_uri` HTTP fetch
  - JAR substituting as client authentication at `/par`
  - JTI replay cache
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.Jar

  @type result ::
          {:ok, map()}
          | {:browser_error, Error.t()}
          | {:redirect_error, Error.t()}

  @allowed_outer_keys ~w(client_id request)

  @spec consume(map(), Client.t(), keyword()) :: result()
  def consume(params, %Client{} = client, opts \\ []) when is_map(params) and is_list(opts) do
    with :ok <- reject_request_uri_collision(params),
         :ok <- reject_outer_param_conflicts(params),
         {:ok, jwt} <- fetch_request(params),
         :ok <- require_client_jwks(client),
         {:ok, %Jar{} = jar} <- decode_and_verify(jwt, client),
         :ok <- validate(jar, client, opts),
         {:ok, projected} <- project_to_params(jar, client) do
      {:ok, projected}
    end
  end

  defp reject_request_uri_collision(%{"request_uri" => request_uri}) do
    if present?(request_uri) do
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

  defp reject_request_uri_collision(_params), do: :ok

  defp reject_outer_param_conflicts(params) do
    conflict_keys =
      params
      |> Enum.reject(fn {key, _value} -> key in @allowed_outer_keys end)
      |> Enum.filter(fn {_key, value} -> present?(value) end)

    case conflict_keys do
      [] ->
        :ok

      _ ->
        {:browser_error,
         browser_error(
           :invalid_request,
           "request cannot be combined with raw authorization parameters",
           :request_object_conflict
         )}
    end
  end

  defp fetch_request(%{"request" => request}) when is_binary(request) and request != "",
    do: {:ok, request}

  defp fetch_request(_params) do
    {:browser_error,
     browser_error(:invalid_request, "request parameter is required", :missing_request)}
  end

  defp require_client_jwks(%Client{jwks: jwks}) when is_map(jwks) and map_size(jwks) > 0, do: :ok

  defp require_client_jwks(%Client{}) do
    {:browser_error,
     browser_error(
       :invalid_request_object,
       "Client has no registered jwks for request object signature verification",
       :client_jwks_missing
     )}
  end

  defp decode_and_verify(jwt, %Client{} = client) do
    with {:ok, %Jar{} = _decoded} <- decode_step(jwt),
         {:ok, %Jar{} = verified_jar} <- verify_step(jwt, client) do
      {:ok, verified_jar}
    end
  end

  defp decode_step(jwt) do
    case Jar.decode(jwt) do
      {:ok, %Jar{} = jar} ->
        {:ok, jar}

      {:error, :invalid_jwt} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object is not a valid JWT",
           :invalid_request_object_jwt
         )}
    end
  end

  defp verify_step(jwt, client) do
    case Jar.verify_signature(jwt, client) do
      {:ok, %Jar{} = jar} ->
        {:ok, jar}

      {:error, :invalid_signature} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object signature is invalid",
           :invalid_request_object_signature
         )}

      {:error, :no_matching_key} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object signature is invalid",
           :invalid_request_object_signature
         )}

      {:error, :invalid_typ} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object typ header is invalid",
           :invalid_request_object_typ
         )}

      {:error, :invalid_client_keys} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object signature is invalid",
           :invalid_request_object_signature
         )}
    end
  end

  defp validate(%Jar{} = jar, %Client{} = client, opts) do
    case Jar.validate_claims(jar, jar_opts(client, opts)) do
      :ok ->
        :ok

      {:error, :invalid_issuer} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object issuer does not match the client",
           :invalid_request_object_iss
         )}

      {:error, :missing_issuer} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object issuer is missing",
           :invalid_request_object_iss
         )}

      {:error, :invalid_audience} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object audience is invalid",
           :invalid_request_object_aud
         )}

      {:error, :missing_audience} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object audience is missing",
           :invalid_request_object_aud
         )}

      {:error, :missing_expiration} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object expiration is missing",
           :invalid_request_object_expired
         )}

      {:error, :invalid_expiration} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object expiration is invalid",
           :invalid_request_object_expired
         )}

      {:error, :expired_token} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object has expired",
           :invalid_request_object_expired
         )}

      {:error, :expiration_too_far} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object exceeds the configured maximum age",
           :invalid_request_object_max_age
         )}

      {:error, :invalid_not_before} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object claims are invalid",
           :invalid_request_object_claims
         )}

      {:error, :invalid_issued_at} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object claims are invalid",
           :invalid_request_object_claims
         )}

      {:error, :invalid_claims_options} ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object claims are invalid",
           :invalid_request_object_claims
         )}
    end
  end

  defp project_to_params(%Jar{claims: claims}, %Client{client_id: client_id}) do
    {:ok,
     %{
       "client_id" => client_id,
       "redirect_uri" => claims["redirect_uri"],
       "response_type" => claims["response_type"],
       "scope" => claims["scope"],
       "prompt" => claims["prompt"],
       "nonce" => claims["nonce"],
       "state" => claims["state"],
       "code_challenge" => claims["code_challenge"],
       "code_challenge_method" => claims["code_challenge_method"]
     }
     |> Enum.reject(fn {_key, value} -> is_nil(value) end)
     |> Map.new()}
  end

  defp jar_opts(%Client{} = client, opts) do
    Keyword.merge(
      [
        expected_client_id: client.client_id,
        expected_audience: Config.issuer!(),
        max_age: Config.jar_max_age_seconds(),
        leeway: 5
      ],
      opts
    )
  end

  defp browser_error(error, description, reason_code) do
    %Error{
      error: to_string(error),
      error_description: description,
      reason_code: reason_code,
      state: nil,
      redirect_uri: nil
    }
  end

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true
end
