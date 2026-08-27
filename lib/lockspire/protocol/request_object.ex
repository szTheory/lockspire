defmodule Lockspire.Protocol.RequestObject do
  @moduledoc """
  Orchestrates JAR (RFC 9101) request-object consumption for `/authorize` and `/par`.

  Composes `Lockspire.Protocol.Jar.{decode/1, verify_signature/2, validate_claims/2}`
  into a single pipeline step that:

  1. Rejects outer-parameter conflicts and `request` / `request_uri` collisions.
  2. Asserts the client has inline `jwks` registered.
  3. Decodes, verifies the signature, and validates the request JWT claims with the
     configured `:max_age` ceiling.
  4. Projects JAR claims into the flat authorization-parameter shape consumed by both
     authorization entrypoints, so their existing validation runs unchanged.

  ## Out of scope

  - JAR-by-reference (`request_uri` pointing to an external JWT URL)
  - `jwks_uri` HTTP fetch
  - JAR substituting as client authentication at `/par`
  - JTI replay cache
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.Jar
  alias Lockspire.Protocol.RequestObject.Claims
  alias Lockspire.Protocol.RequestObject.Retrieval
  alias Lockspire.Protocol.RequestObject.Result
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Storage.Ecto.Repository

  @type result ::
          {:ok, map()}
          | {:browser_error, Lockspire.Protocol.AuthorizationRequest.Error.t()}
          | {:redirect_error, Lockspire.Protocol.AuthorizationRequest.Error.t()}

  @spec consume(map(), Client.t(), keyword()) :: result()
  def consume(params, %Client{} = client, opts \\ []) when is_map(params) and is_list(opts) do
    case consume_result(params, client, opts) do
      {:ok, projected} ->
        {:ok, projected}

      {disposition, %Result{} = issue}
      when disposition in [:browser_error, :redirect_error] ->
        {disposition, public_error(issue)}
    end
  end

  defp consume_result(params, %Client{} = client, opts) do
    security_profile = Keyword.get(opts, :security_profile, %SecurityProfile.Resolved{})

    with {:ok, jwt} <- fetch_request(params),
         {:ok, jws_string} <- decrypt_request(jwt),
         :ok <- require_client_jwks(client),
         {:ok, %Jar{} = jar} <- decode_and_verify(jws_string, client, security_profile),
         :ok <- validate(jar, client, opts) do
      project_to_params(jar, client)
    end
  end

  defp fetch_request(params) do
    case Retrieval.fetch(params) do
      {:ok, jwt} ->
        {:ok, jwt}

      {:error, :request_object_and_request_uri_conflict} ->
        {:browser_error,
         browser_error(
           :invalid_request,
           "request and request_uri cannot both be supplied",
           :request_object_and_request_uri_conflict
         )}

      {:error, :request_object_conflict} ->
        {:browser_error,
         browser_error(
           :invalid_request,
           "request cannot be combined with raw authorization parameters",
           :request_object_conflict
         )}

      {:error, :missing_request} ->
        {:browser_error,
         browser_error(:invalid_request, "request parameter is required", :missing_request)}
    end
  end

  defp decrypt_request(jwt) do
    with {:ok, dec_keys} <- Repository.list_decryption_keys(),
         {:ok, jws_string} <- Jar.decrypt(jwt, dec_keys) do
      {:ok, jws_string}
    else
      _ ->
        {:browser_error,
         browser_error(
           :invalid_request_object,
           "Request object decryption failed",
           :invalid_request_object_decryption
         )}
    end
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

  defp decode_and_verify(jwt, %Client{} = client, security_profile) do
    with {:ok, %Jar{} = _decoded} <- decode_step(jwt),
         {:ok, %Jar{} = verified_jar} <- verify_step(jwt, client, security_profile) do
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

  defp verify_step(jwt, client, security_profile) do
    allowed_algs = SecurityProfile.allowed_signing_algorithms(security_profile.effective_profile)

    case Jar.verify_signature(jwt, client, allowed_algs) do
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
      :ok -> :ok
      {:error, reason} -> {:browser_error, validation_error(reason)}
    end
  end

  @validation_errors %{
    invalid_issuer:
      {"Request object issuer does not match the client", :invalid_request_object_iss},
    missing_issuer: {"Request object issuer is missing", :invalid_request_object_iss},
    invalid_audience: {"Request object audience is invalid", :invalid_request_object_aud},
    missing_audience: {"Request object audience is missing", :invalid_request_object_aud},
    missing_expiration: {"Request object expiration is missing", :invalid_request_object_expired},
    invalid_expiration: {"Request object expiration is invalid", :invalid_request_object_expired},
    expired_token: {"Request object has expired", :invalid_request_object_expired},
    expiration_too_far:
      {"Request object exceeds the configured maximum age", :invalid_request_object_max_age},
    invalid_not_before: {"Request object claims are invalid", :invalid_request_object_claims},
    invalid_issued_at: {"Request object claims are invalid", :invalid_request_object_claims},
    invalid_claims_options: {"Request object claims are invalid", :invalid_request_object_claims}
  }

  defp validation_error(reason) do
    {description, reason_code} = Map.fetch!(@validation_errors, reason)
    browser_error(:invalid_request_object, description, reason_code)
  end

  defp project_to_params(%Jar{claims: claims}, %Client{} = client) do
    Claims.project(claims, client)
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
    Result.browser_error(error, description, reason_code)
  end

  # Keep the neutral construction value below this public facade, but retain the
  # v1.x AuthorizationRequest.Error struct at the externally callable boundary.
  # Module.concat prevents the internal JAR pipeline from becoming a compile-time
  # dependency of AuthorizationRequest, which itself consumes this facade.
  defp public_error(%Result{} = issue) do
    error_module = Module.concat(["Lockspire", "Protocol", "AuthorizationRequest", "Error"])

    struct(error_module,
      error: issue.error,
      error_description: issue.error_description,
      reason_code: issue.reason_code,
      state: issue.state,
      redirect_uri: issue.redirect_uri
    )
  end
end
