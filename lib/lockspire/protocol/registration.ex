defmodule Lockspire.Protocol.Registration do
  @moduledoc """
  RFC 7591 dynamic client registration intake — `Plug.Conn`-free orchestrator.

  Pipeline (per Phase 26 D-13, refined per RESEARCH Q5 RESOLVED):
    1. Precondition gate — when `server_policy.registration_policy == :initial_access_token`
       and `iat == nil`, reject with `%Error{code: :invalid_token, field: :iat, reason: :missing}`
       BEFORE any other step.
    2. IAT redemption via `Lockspire.Protocol.InitialAccessToken.redeem/1` (skipped if `iat` is nil).
    3. DcrPolicy resolution via `Lockspire.Protocol.DcrPolicy.resolve/3` (Phase 25).
    4. Slice-specific intake validation (D-14 jwks/coherence/redirect + D-15 PKCE floor).
    5. Credential generation (`client_id`, `client_secret`, `registration_access_token`).
    6. Persistence via `Lockspire.Admin.Clients.create_dcr_client/1` (DCR-aware persistence
       helper from plan 26-01 task 4 — preserves provenance/RAT-hash/IAT-FK/issued_at/expires_at
       verbatim, unlike the legacy `Lockspire.Clients.register_client/1` which strips them).
    7. Post-commit audit + telemetry emission (`:dcr_registration_succeeded` /
       `:dcr_registration_rejected`).

  Per D-11 IAT-style enumeration defense, IAT redemption failures collapse to
  `%Error{code: :invalid_token}` (the discriminator stays in telemetry).
  """

  alias Lockspire.Admin
  alias Lockspire.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.InitialAccessToken, as: IatDomain
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Observability
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.DcrPolicy.Resolved
  alias Lockspire.Protocol.InitialAccessToken
  alias Lockspire.Protocol.RegistrationAccessToken

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
         :ok <- validate_intake_metadata(metadata, resolved, server_policy),
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
  def validate_intake_metadata(metadata, %Resolved{} = _resolved, server_policy)
      when is_map(metadata) do
    with :ok <- validate_unsupported_logout_metadata(metadata),
         :ok <- validate_jwks(metadata),
         :ok <- validate_authorization_response_encryption_metadata(metadata),
         :ok <- validate_grant_response_coherence(metadata),
         :ok <- validate_redirect_uris(metadata),
         :ok <- validate_fapi_2_0_readiness(metadata, server_policy) do
      validate_pkce_floor(metadata)
    end
  end

  defp validate_fapi_2_0_readiness(metadata, server_policy) do
    client_profile = atomize_security_profile(Map.get(metadata, "security_profile", "inherit"))

    resolved_profile =
      Lockspire.Protocol.SecurityProfile.resolve_effective_profile(server_policy, %{
        security_profile: client_profile
      })

    if resolved_profile.fapi_2_0_security? do
      alg = atomize_alg(Map.get(metadata, "id_token_signed_response_alg"))

      if alg in [:ES256, :PS256] do
        case Lockspire.Admin.Clients.check_fapi_signing_readiness(:none, :fapi_2_0_security) do
          :ok ->
            :ok

          {:error, reason}
          when reason in [:missing_compliant_active_key, :missing_compliant_publishable_key] ->
            {:error,
             %Error{
               code: :invalid_client_metadata,
               field: :security_profile,
               reason: reason
             }}
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

  defp validate_unsupported_logout_metadata(metadata) do
    cond do
      Map.has_key?(metadata, "backchannel_logout_uri") ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :backchannel_logout_uri,
           reason: :unsupported_in_slice
         }}

      Map.has_key?(metadata, "backchannel_logout_session_required") ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :backchannel_logout_session_required,
           reason: :unsupported_in_slice
         }}

      Map.has_key?(metadata, "frontchannel_logout_uri") ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :frontchannel_logout_uri,
           reason: :unsupported_in_slice
         }}

      Map.has_key?(metadata, "frontchannel_logout_session_required") ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :frontchannel_logout_session_required,
           reason: :unsupported_in_slice
         }}

      true ->
        :ok
    end
  end

  defp validate_jwks(metadata) do
    has_jwks = Map.has_key?(metadata, "jwks")
    has_jwks_uri = Map.has_key?(metadata, "jwks_uri")
    auth_method = Map.get(metadata, "token_endpoint_auth_method", "client_secret_basic")
    jwks_uri = Map.get(metadata, "jwks_uri")
    encrypted_jarm_requested? = encrypted_jarm_requested?(metadata)

    cond do
      has_jwks and has_jwks_uri ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :jwks,
           reason: :mutually_exclusive_with_jwks_uri
         }}

      auth_method == "private_key_jwt" and not has_jwks and not has_jwks_uri ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :token_endpoint_auth_method,
           reason: :missing_cryptographic_material
         }}

      has_jwks_uri and auth_method != "private_key_jwt" and not encrypted_jarm_requested? ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :jwks_uri,
           reason: :unsupported_token_endpoint_auth_method
         }}

      has_jwks_uri and not https_uri?(jwks_uri) ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :jwks_uri,
           reason: :invalid_uri_scheme
         }}

      true ->
        :ok
    end
  end

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

  # D-14: RFC 7591 §2 grant_types/response_types coherence.
  defp validate_grant_response_coherence(metadata) do
    grant_types = Map.get(metadata, "grant_types", []) |> List.wrap()
    response_types = Map.get(metadata, "response_types", []) |> List.wrap()

    cond do
      "refresh_token" in grant_types and "authorization_code" not in grant_types ->
        {:error,
         %Error{code: :invalid_client_metadata, field: :grant_types, reason: :incoherent_pair}}

      "code" in response_types and "authorization_code" not in grant_types ->
        {:error,
         %Error{code: :invalid_client_metadata, field: :response_types, reason: :incoherent_pair}}

      true ->
        :ok
    end
  end

  defp validate_redirect_uris(metadata) do
    redirect_uris = Map.get(metadata, "redirect_uris", [])

    case Clients.validate_redirect_uris(redirect_uris) do
      :ok ->
        :ok

      {:error, _reason} ->
        {:error,
         %Error{code: :invalid_client_metadata, field: :redirect_uris, reason: :invalid_uri}}
    end
  end

  # D-15: explicit `pkce_required: false` is rejected (not silently coerced).
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
    {client_secret_hash, client_secret} = Clients.rotate_secret_hash()
    {rat_plaintext, rat_hash} = RegistrationAccessToken.generate()
    client_id = Clients.generate_client_id()

    %{
      client_id: client_id,
      client_secret: client_secret,
      client_secret_hash: client_secret_hash,
      rat: rat_plaintext,
      rat_hash: rat_hash
    }
  end

  defp persist_client(metadata, %Resolved{} = resolved, iat_record, credentials, source) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    iat_id =
      case iat_record do
        %{id: id} -> id
        _ -> nil
      end

    auth_method =
      atomize_auth_method(Map.get(metadata, "token_endpoint_auth_method", "client_secret_basic"))

    client_type = client_type_from_auth_method(auth_method)

    client = %Client{
      client_id: credentials.client_id,
      client_secret_hash: credentials.client_secret_hash,
      client_type: client_type,
      name: Map.get(metadata, "client_name"),
      redirect_uris: Map.get(metadata, "redirect_uris", []),
      allowed_scopes: parse_scope(Map.get(metadata, "scope", "")),
      allowed_grant_types: Map.get(metadata, "grant_types", ["authorization_code"]),
      allowed_response_types: Map.get(metadata, "response_types", ["code"]),
      token_endpoint_auth_method: auth_method,
      pkce_required: true,
      subject_type: :public,
      logo_uri: Map.get(metadata, "logo_uri"),
      tos_uri: Map.get(metadata, "tos_uri"),
      policy_uri: Map.get(metadata, "policy_uri"),
      contacts: Map.get(metadata, "contacts", []),
      jwks: Map.get(metadata, "jwks"),
      jwks_uri: Map.get(metadata, "jwks_uri"),
      active: true,
      dpop_policy: dpop_policy_from_metadata(metadata),
      provenance: :self_registered,
      registration_access_token_hash: credentials.rat_hash,
      initial_access_token_id: iat_id,
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
      client_secret_expires_at:
        DateTime.add(now, resolved.default_client_secret_lifetime_seconds || 0, :second),
      metadata: build_extension_metadata(metadata)
    }

    attrs = %{
      client: client,
      actor: %{
        type: :dcr,
        id: iat_id_or_anonymous(iat_id),
        display: source[:ip] || source["ip"]
      }
    }

    case Admin.Clients.create_dcr_client(attrs) do
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

  defp atomize_authorization_encryption_alg("RSA-OAEP-256"), do: :RSA_OAEP_256
  defp atomize_authorization_encryption_alg("ECDH-ES"), do: :ECDH_ES
  defp atomize_authorization_encryption_alg(_), do: nil

  defp atomize_authorization_encryption_enc("A256GCM"), do: :A256GCM
  defp atomize_authorization_encryption_enc("A128GCM"), do: :A128GCM
  defp atomize_authorization_encryption_enc(_), do: nil

  defp atomize_security_profile("fapi_2_0_security"), do: :fapi_2_0_security
  defp atomize_security_profile("none"), do: :none
  defp atomize_security_profile(_), do: :inherit

  defp atomize_auth_method("client_secret_basic"), do: :client_secret_basic
  defp atomize_auth_method("client_secret_post"), do: :client_secret_post
  defp atomize_auth_method("private_key_jwt"), do: :private_key_jwt
  defp atomize_auth_method("none"), do: :none
  defp atomize_auth_method(_), do: :client_secret_basic

  defp client_type_from_auth_method(:none), do: :public
  defp client_type_from_auth_method(_), do: :confidential

  defp parse_scope(scope) when is_binary(scope) do
    scope |> String.split(" ", trim: true) |> Enum.uniq()
  end

  defp parse_scope(_), do: []

  defp https_uri?(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{scheme: "https", host: host} when is_binary(host) and host != "" -> true
      _ -> false
    end
  end

  defp https_uri?(_uri), do: false

  defp encrypted_jarm_requested?(metadata) when is_map(metadata) do
    Map.has_key?(metadata, "authorization_encrypted_response_alg") or
      Map.has_key?(metadata, "authorization_encrypted_response_enc")
  end

  defp supported_authorization_signing_algs, do: ["RS256", "ES256", "EdDSA"]
  defp supported_authorization_encryption_algs, do: ["RSA-OAEP-256", "ECDH-ES"]
  defp supported_authorization_encryption_encs, do: ["A256GCM", "A128GCM"]

  defp dpop_policy_from_metadata(metadata) when is_map(metadata) do
    case Map.get(metadata, "dpop_bound_access_tokens", false) do
      true -> :dpop
      _other -> :bearer
    end
  end

  # RFC 7591 §2.3 software_statement is silently ignored (RESEARCH Q6 RESOLVED).
  # Only RFC 7591 extension fields we explicitly support land in :metadata JSONB.
  defp build_extension_metadata(metadata) when is_map(metadata) do
    metadata
    |> Map.take(["client_uri"])
    |> Map.reject(fn {_k, v} -> is_nil(v) end)
  end

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
