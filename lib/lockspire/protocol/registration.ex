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

  alias Lockspire.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.InitialAccessToken, as: IatDomain
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.DcrPolicy.Resolved
  alias Lockspire.Protocol.InitialAccessToken

  defmodule Success do
    @type t :: %__MODULE__{
            client: Client.t(),
            client_secret_plaintext: String.t() | nil,
            registration_access_token_plaintext: String.t()
          }
    defstruct [:client, :client_secret_plaintext, :registration_access_token_plaintext]
  end

  defmodule Error do
    @type t :: %__MODULE__{
            code: atom(),
            field: atom() | nil,
            reason: atom() | nil,
            allowed: list() | nil
          }
    defstruct [:code, :field, :reason, :allowed]
  end

  @type result :: {:ok, Success.t()} | {:error, Error.t()}

  @spec register(map()) :: result()
  def register(%{metadata: metadata, server_policy: %ServerPolicy{} = server_policy} = request)
      when is_map(metadata) do
    iat = Map.get(request, :iat)
    source = Map.get(request, :source, %{ip: nil, user_agent: nil})

    with :ok <- require_iat_when_policy_demands(server_policy, iat),
         {:ok, iat_record} <- maybe_redeem_iat(iat),
         {:ok, %Resolved{} = resolved} <- resolve_policy(server_policy, iat_record, metadata),
         :ok <- validate_intake_metadata(metadata, resolved),
         credentials <- generate_credentials(),
         {:ok, %Client{} = client} <- persist_client(metadata, resolved, iat_record, credentials, source) do
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
  defp require_iat_when_policy_demands(%ServerPolicy{registration_policy: :initial_access_token}, nil) do
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
  @spec validate_intake_metadata(map(), Resolved.t()) :: :ok | {:error, Error.t()}
  def validate_intake_metadata(metadata, %Resolved{} = _resolved) when is_map(metadata) do
    with :ok <- validate_jwks(metadata),
         :ok <- validate_grant_response_coherence(metadata),
         :ok <- validate_redirect_uris(metadata),
         :ok <- validate_pkce_floor(metadata) do
      :ok
    end
  end

  # D-14: jwks_uri rejected first (mutual-exclusion check is shadowed when both present
  # because jwks_uri rule fires first; we still keep the explicit rule for spec clarity).
  defp validate_jwks(metadata) do
    cond do
      Map.has_key?(metadata, "jwks_uri") ->
        {:error, %Error{code: :invalid_client_metadata, field: :jwks_uri, reason: :unsupported_in_slice}}

      Map.has_key?(metadata, "jwks") and Map.has_key?(metadata, "jwks_uri") ->
        {:error, %Error{code: :invalid_client_metadata, field: :jwks, reason: :mutually_exclusive_with_jwks_uri}}

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
        {:error, %Error{code: :invalid_client_metadata, field: :grant_types, reason: :incoherent_pair}}

      "code" in response_types and "authorization_code" not in grant_types ->
        {:error, %Error{code: :invalid_client_metadata, field: :response_types, reason: :incoherent_pair}}

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
        {:error, %Error{code: :invalid_client_metadata, field: :redirect_uris, reason: :invalid_uri}}
    end
  end

  # D-15: explicit `pkce_required: false` is rejected (not silently coerced).
  defp validate_pkce_floor(metadata) do
    case Map.get(metadata, "pkce_required") do
      false -> {:error, %Error{code: :invalid_client_metadata, field: :pkce_required, reason: :pkce_floor_required_for_dcr}}
      _ -> :ok
    end
  end

  defp generate_credentials do
    # Task 2b: full implementation
    raise "generate_credentials/0 stub — Task 2b implements"
  end

  defp persist_client(_metadata, _resolved, _iat_record, _credentials, _source) do
    # Task 2b: full implementation
    {:error, %Error{code: :persistence_error, reason: :not_implemented}}
  end

  defp emit_succeeded(_client, _iat_record, _source), do: :ok
  defp emit_rejected(_error, _source), do: :ok
end
