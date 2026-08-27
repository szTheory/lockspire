defmodule Lockspire.Protocol.Registration do
  @moduledoc """
  RFC 7591 dynamic client registration intake — `Plug.Conn`-free orchestrator.

  Pipeline:
    1. Precondition gate — when `server_policy.registration_policy == :initial_access_token`
       and `iat == nil`, reject with `%Error{code: :invalid_token, field: :iat, reason: :missing}`
       BEFORE any other step.
    2. IAT redemption via `Lockspire.Protocol.InitialAccessToken.redeem/1` (skipped if `iat` is nil).
    3. DCR policy resolution via `Lockspire.Protocol.DcrPolicy.resolve/3`.
    4. Intake validation for JWKS coherence, redirect URIs, and the PKCE floor.
    5. Credential generation (`client_id`, `client_secret`, `registration_access_token`).
    6. Persistence via the internal DCR-aware lifecycle helper (DCR-aware persistence
       helper — preserves provenance/RAT-hash/IAT-FK/issued_at/expires_at
       verbatim while keeping protocol orchestration independent of operator delivery).
    7. Post-commit audit + telemetry emission (`:dcr_registration_succeeded` /
       `:dcr_registration_rejected`).

  To prevent IAT enumeration, redemption failures collapse to
  `%Error{code: :invalid_token}` (the discriminator stays in telemetry).
  """

  alias Lockspire.ClientLifecycle
  alias Lockspire.ClientMetadata
  alias Lockspire.ClientRegistration.Shape, as: RegistrationShape
  alias Lockspire.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.InitialAccessToken, as: IatDomain
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Observability
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.DcrPolicy.Resolved
  alias Lockspire.Protocol.InitialAccessToken
  alias Lockspire.Protocol.MessageSigningProfile
  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Protocol.SecurityProfile

  defmodule Success do
    @moduledoc false
    @type t :: %__MODULE__{
            client: Client.t(),
            client_secret_plaintext: String.t() | nil,
            registration_access_token_plaintext: String.t()
          }
    defstruct [:client, :client_secret_plaintext, :registration_access_token_plaintext]
  end

  defmodule Error do
    @moduledoc false
    @type t :: %__MODULE__{
            code: atom(),
            field: atom() | nil,
            reason: atom() | nil,
            allowed: list() | nil
          }
    defstruct [:code, :field, :reason, :allowed]
  end

  @type result :: {:ok, struct()} | {:error, struct()}

  @spec register(map()) :: result()
  def register(%{metadata: metadata, server_policy: %ServerPolicy{} = server_policy} = request)
      when is_map(metadata) do
    iat = Map.get(request, :iat)
    source = Map.get(request, :source, %{ip: nil, user_agent: nil})

    with :ok <- require_iat_when_policy_demands(server_policy, iat),
         {:ok, iat_record} <- maybe_redeem_iat(iat),
         {:ok, %Resolved{} = resolved} <- resolve_policy(server_policy, iat_record, metadata),
         :ok <- validate_intake_metadata(metadata, resolved, server_policy, nil),
         credentials <- generate_credentials(),
         {:ok, %Client{} = client} <-
           persist_client(metadata, resolved, iat_record, credentials, source) do
      emit_succeeded(client, iat_record, source)

      {:ok,
       %Success{
         client: client,
         client_secret_plaintext: credentials.client_secret,
         registration_access_token_plaintext: credentials.rat
       }}
    else
      {:error, %Error{} = error} ->
        emit_rejected(error, source)
        {:error, error}
    end
  end

  # Reject anonymous registration when server policy demands an IAT.
  # Fired BEFORE maybe_redeem_iat/1 so no IAT-redemption-failure telemetry is emitted on this axis.
  defp require_iat_when_policy_demands(
         %ServerPolicy{registration_policy: :initial_access_token},
         nil
       ) do
    {:error, %Error{code: :invalid_token, field: :iat, reason: :missing}}
  end

  defp require_iat_when_policy_demands(%ServerPolicy{}, _iat), do: :ok

  defp maybe_redeem_iat(nil), do: {:ok, nil}

  defp maybe_redeem_iat(plaintext) when is_binary(plaintext) do
    case InitialAccessToken.redeem(plaintext) do
      {:ok, %IatDomain{} = iat} -> {:ok, iat}
      {:error, :invalid_token} -> {:error, %Error{code: :invalid_token}}
    end
  end

  defp resolve_policy(server_policy, iat_record, metadata) do
    iat_overrides = iat_record && Map.get(iat_record, :policy_overrides)

    case DcrPolicy.resolve(server_policy, iat_overrides, metadata) do
      {:ok, %Resolved{} = resolved} ->
        {:ok, resolved}

      {:error, :invalid_client_metadata, %{field: field, reason: reason} = info} ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: field,
           reason: reason,
           allowed: Map.get(info, :allowed)
         }}
    end
  end

  @doc false
  @spec validate_intake_metadata(map(), Resolved.t(), ServerPolicy.t()) ::
          :ok | {:error, Error.t()}
  def validate_intake_metadata(metadata, %Resolved{} = resolved, server_policy)
      when is_map(metadata) do
    validate_intake_metadata(metadata, resolved, server_policy, nil)
  end

  @doc false
  @spec validate_intake_metadata(map(), Resolved.t(), ServerPolicy.t(), Client.t() | nil) ::
          :ok | {:error, Error.t()}
  def validate_intake_metadata(metadata, %Resolved{} = _resolved, server_policy, current_client)
      when is_map(metadata) do
    with :ok <- validate_registration_shape(metadata, server_policy),
         :ok <- validate_authorization_response_encryption_metadata(metadata),
         :ok <- validate_logout_metadata(metadata),
         :ok <- validate_token_endpoint_auth_metadata(metadata, server_policy),
         :ok <- validate_fapi_2_0_readiness(metadata, server_policy, current_client) do
      validate_pkce_floor(metadata)
    end
  end

  defp validate_registration_shape(metadata, server_policy) do
    resolved_profile =
      SecurityProfile.resolve_effective_profile(server_policy, %{
        security_profile:
          atomize_security_profile(Map.get(metadata, "security_profile", "inherit"))
      })

    attrs = %{
      client_type:
        metadata
        |> Map.get("token_endpoint_auth_method", "client_secret_basic")
        |> atomize_auth_method()
        |> client_type_from_auth_method(),
      auth_method:
        atomize_auth_method(
          Map.get(metadata, "token_endpoint_auth_method", "client_secret_basic")
        ),
      token_endpoint_auth_signing_alg:
        atomize_token_endpoint_auth_signing_alg(
          Map.get(metadata, "token_endpoint_auth_signing_alg")
        ),
      redirect_uris: Map.get(metadata, "redirect_uris", []) |> List.wrap(),
      allowed_scopes: parse_scope(Map.get(metadata, "scope", "")),
      allowed_grant_types:
        Map.get(metadata, "grant_types", ["authorization_code"]) |> List.wrap(),
      allowed_response_types: Map.get(metadata, "response_types", ["code"]) |> List.wrap(),
      jwks: Map.get(metadata, "jwks"),
      jwks_uri: Map.get(metadata, "jwks_uri")
    }

    case RegistrationShape.validate(attrs,
           require_scopes: false,
           allow_jwks_uri_for_encryption: encrypted_jarm_requested?(metadata),
           private_key_jwt_algs:
             SecurityProfile.allowed_signing_algorithms(resolved_profile.effective_profile)
             |> Enum.map(&atomize_alg/1)
         ) do
      :ok ->
        :ok

      {:error, [%{field: field, reason: reason} | _]} ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: dcr_shape_field(field),
           reason: dcr_shape_reason(reason)
         }}
    end
  end

  defp dcr_shape_field(:allowed_grant_types), do: :grant_types
  defp dcr_shape_field(:allowed_response_types), do: :response_types
  defp dcr_shape_field(field), do: field

  defp dcr_shape_reason(:invalid_redirect_uri), do: :invalid_uri
  defp dcr_shape_reason(:invalid_token_endpoint_auth_signing_alg), do: :unsupported
  defp dcr_shape_reason(reason), do: reason

  defp validate_token_endpoint_auth_metadata(metadata, server_policy) do
    auth_method = Map.get(metadata, "token_endpoint_auth_method", "client_secret_basic")
    signing_alg = Map.get(metadata, "token_endpoint_auth_signing_alg")

    resolved_profile =
      SecurityProfile.resolve_effective_profile(server_policy, %{
        security_profile:
          atomize_security_profile(Map.get(metadata, "security_profile", "inherit"))
      })

    case auth_method do
      "client_secret_jwt" ->
        validate_client_secret_jwt_metadata(signing_alg, resolved_profile)

      "private_key_jwt" ->
        validate_private_key_jwt_metadata(signing_alg, resolved_profile)

      _other ->
        validate_non_jwt_signing_alg(signing_alg)
    end
  end

  defp validate_client_secret_jwt_metadata(_signing_alg, %{fapi_2_0_security?: true}) do
    invalid_client_metadata(:token_endpoint_auth_method, :incompatible_with_fapi_2_0)
  end

  defp validate_client_secret_jwt_metadata(nil, _resolved_profile) do
    invalid_client_metadata(:token_endpoint_auth_signing_alg, :required)
  end

  defp validate_client_secret_jwt_metadata("HS256", _resolved_profile), do: :ok

  defp validate_client_secret_jwt_metadata(_signing_alg, _resolved_profile) do
    invalid_client_metadata(:token_endpoint_auth_signing_alg, :unsupported)
  end

  defp validate_private_key_jwt_metadata(nil, _resolved_profile), do: :ok

  defp validate_private_key_jwt_metadata(signing_alg, resolved_profile) do
    allowed_algs =
      SecurityProfile.allowed_signing_algorithms(resolved_profile.effective_profile)

    if signing_alg in allowed_algs do
      :ok
    else
      invalid_client_metadata(:token_endpoint_auth_signing_alg, :unsupported)
    end
  end

  defp validate_non_jwt_signing_alg(nil), do: :ok

  defp validate_non_jwt_signing_alg(_signing_alg) do
    invalid_client_metadata(
      :token_endpoint_auth_signing_alg,
      :unsupported_token_endpoint_auth_method
    )
  end

  defp invalid_client_metadata(field, reason) do
    {:error,
     %Error{
       code: :invalid_client_metadata,
       field: field,
       reason: reason
     }}
  end

  defp validate_fapi_2_0_readiness(metadata, server_policy, current_client) do
    client_profile = atomize_security_profile(Map.get(metadata, "security_profile", "inherit"))

    resolved_profile =
      Lockspire.Protocol.SecurityProfile.resolve_effective_profile(server_policy, %{
        security_profile: client_profile
      })

    current_effective_profile =
      case current_client do
        nil ->
          :none

        client ->
          Lockspire.Protocol.SecurityProfile.resolve_effective_profile(server_policy, client)
          |> Map.fetch!(:effective_profile)
      end

    if resolved_profile.fapi_2_0_security? do
      alg = atomize_alg(Map.get(metadata, "id_token_signed_response_alg"))

      if alg in [:ES256, :PS256] do
        with :ok <-
               validate_effective_profile_transition(
                 current_effective_profile,
                 resolved_profile.effective_profile
               ),
             :ok <-
               validate_strict_authorization_signing_alg(
                 metadata,
                 resolved_profile.effective_profile
               ) do
          :ok
        else
          {:error, reason}
          when reason in [:missing_compliant_active_key, :missing_compliant_publishable_key] ->
            {:error,
             %Error{
               code: :invalid_client_metadata,
               field: :security_profile,
               reason: reason
             }}

          {:error, %Error{} = error} ->
            {:error, error}
        end
      else
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :id_token_signed_response_alg,
           reason: :incompatible_with_fapi_2_0
         }}
      end
    else
      :ok
    end
  end

  defp validate_strict_authorization_signing_alg(metadata, :fapi_2_0_message_signing) do
    case Map.get(metadata, "authorization_signed_response_alg") do
      alg ->
        if alg in SecurityProfile.allowed_signing_algorithms(:fapi_2_0_message_signing) do
          :ok
        else
          {:error,
           %Error{
             code: :invalid_client_metadata,
             field: :authorization_signed_response_alg,
             reason: :incompatible_with_fapi_2_0
           }}
        end
    end
  end

  defp validate_strict_authorization_signing_alg(_metadata, _effective_profile), do: :ok

  defp validate_logout_metadata(metadata) do
    redirect_uris = Map.get(metadata, "redirect_uris", [])

    case ClientMetadata.validate_logout_metadata(metadata, redirect_uris, strict_booleans: true) do
      :ok ->
        :ok

      {:error, [%{field: field, reason: reason} | _rest]} ->
        {:error, %Error{code: :invalid_client_metadata, field: field, reason: reason}}
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp validate_authorization_response_encryption_metadata(metadata) do
    signing_alg = Map.get(metadata, "authorization_signed_response_alg")
    encryption_alg = Map.get(metadata, "authorization_encrypted_response_alg")
    encryption_enc = Map.get(metadata, "authorization_encrypted_response_enc")
    has_jwks = Map.has_key?(metadata, "jwks")
    has_jwks_uri = Map.has_key?(metadata, "jwks_uri")

    cond do
      is_nil(encryption_alg) and is_nil(encryption_enc) ->
        :ok

      is_nil(encryption_alg) ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :authorization_encrypted_response_alg,
           reason: :missing_for_encrypted_response
         }}

      is_nil(encryption_enc) ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :authorization_encrypted_response_enc,
           reason: :missing_for_encrypted_response
         }}

      signing_alg not in supported_authorization_signing_algs() ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :authorization_signed_response_alg,
           reason: :missing_for_encrypted_response
         }}

      encryption_alg not in supported_authorization_encryption_algs() ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :authorization_encrypted_response_alg,
           reason: :unsupported
         }}

      encryption_enc not in supported_authorization_encryption_encs() ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :authorization_encrypted_response_enc,
           reason: :unsupported
         }}

      not has_jwks and not has_jwks_uri ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :authorization_encrypted_response_alg,
           reason: :missing_cryptographic_material
         }}

      true ->
        :ok
    end
  end

  # explicit `pkce_required: false` is rejected (not silently coerced).
  defp validate_pkce_floor(metadata) do
    case Map.get(metadata, "pkce_required") do
      false ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :pkce_required,
           reason: :pkce_floor_required_for_dcr
         }}

      _ ->
        :ok
    end
  end

  defp generate_credentials do
    secret_material = Clients.rotate_secret_material()
    {rat_plaintext, rat_hash} = RegistrationAccessToken.generate()
    client_id = Clients.generate_client_id()

    %{
      client_id: client_id,
      client_secret: secret_material.client_secret,
      client_secret_hash: secret_material.client_secret_hash,
      client_secret_jwt_verifier_encrypted: secret_material.client_secret_jwt_verifier_encrypted,
      rat: rat_plaintext,
      rat_hash: rat_hash
    }
  end

  defp persist_client(metadata, %Resolved{} = resolved, iat_record, credentials, source) do
    iat_id =
      case iat_record do
        %{id: id} -> id
        _ -> nil
      end

    client = ClientMetadata.build_dcr_client(metadata, resolved, iat_record, credentials)

    attrs = %{
      client: client,
      actor: %{
        type: :dcr,
        id: iat_id_or_anonymous(iat_id),
        display: source[:ip] || source["ip"]
      }
    }

    case ClientLifecycle.create_dcr(attrs) do
      {:ok, %Client{} = persisted} ->
        {:ok, persisted}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, %Error{code: :persistence_error, reason: changeset}}

      {:error, reason} ->
        {:error, %Error{code: :persistence_error, reason: reason}}
    end
  end

  defp iat_id_or_anonymous(nil), do: "anonymous"
  defp iat_id_or_anonymous(id), do: to_string(id)

  defp atomize_alg("RS256"), do: :RS256
  defp atomize_alg("ES256"), do: :ES256
  defp atomize_alg("PS256"), do: :PS256
  defp atomize_alg("EdDSA"), do: :EdDSA
  defp atomize_alg(_), do: nil

  defp atomize_token_endpoint_auth_signing_alg("HS256"), do: :HS256
  defp atomize_token_endpoint_auth_signing_alg(value), do: atomize_alg(value)

  defp atomize_security_profile("fapi_2_0_security"), do: :fapi_2_0_security
  defp atomize_security_profile("fapi_2_0_message_signing"), do: :fapi_2_0_message_signing
  defp atomize_security_profile("none"), do: :none
  defp atomize_security_profile(_), do: :inherit

  defp validate_effective_profile_transition(
         :fapi_2_0_message_signing,
         :fapi_2_0_message_signing
       ),
       do: :ok

  defp validate_effective_profile_transition(_old_profile, :fapi_2_0_message_signing) do
    MessageSigningProfile.validate_transition(:none, :fapi_2_0_message_signing)
  end

  defp validate_effective_profile_transition(_old_profile, :fapi_2_0_security) do
    ClientMetadata.check_fapi_signing_readiness(:none, :fapi_2_0_security)
  end

  defp validate_effective_profile_transition(_old_profile, _new_profile), do: :ok

  defp atomize_auth_method("client_secret_basic"), do: :client_secret_basic
  defp atomize_auth_method("client_secret_post"), do: :client_secret_post
  defp atomize_auth_method("client_secret_jwt"), do: :client_secret_jwt
  defp atomize_auth_method("private_key_jwt"), do: :private_key_jwt
  defp atomize_auth_method("none"), do: :none
  defp atomize_auth_method(_), do: :client_secret_basic

  defp client_type_from_auth_method(:none), do: :public
  defp client_type_from_auth_method(_), do: :confidential

  defp parse_scope(scope) when is_binary(scope) do
    scope |> String.split(" ", trim: true) |> Enum.uniq()
  end

  defp parse_scope(_), do: []

  defp encrypted_jarm_requested?(metadata) when is_map(metadata) do
    Map.has_key?(metadata, "authorization_encrypted_response_alg") or
      Map.has_key?(metadata, "authorization_encrypted_response_enc")
  end

  defp supported_authorization_signing_algs, do: ["RS256", "ES256", "EdDSA"]
  defp supported_authorization_encryption_algs, do: ["RSA-OAEP-256", "ECDH-ES"]
  defp supported_authorization_encryption_encs, do: ["A256GCM", "A128GCM"]

  defp emit_succeeded(%Client{} = client, iat_record, source) do
    iat_id =
      case iat_record do
        %{id: id} -> id
        _ -> nil
      end

    Observability.emit(:dcr, :register, %{count: 1}, %{
      status: :success,
      actor_type: :dcr,
      actor_id: iat_id_or_anonymous(iat_id),
      client_id: client.client_id,
      iat_id: iat_id,
      source_ip: source[:ip] || source["ip"]
    })
  end

  defp emit_rejected(%Error{} = error, source) do
    Observability.emit(:dcr, :register, %{count: 1}, %{
      status: :failure,
      actor_type: :dcr,
      reason_code: error.code,
      field: error.field,
      reason: error.reason,
      source_ip: source[:ip] || source["ip"]
    })
  end
end
