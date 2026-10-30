defmodule Lockspire.Domain.Client do
  @moduledoc """
  Durable client registration state owned by Lockspire.
  """

  @type client_type :: :public | :confidential
  @type token_endpoint_auth_method ::
          :client_secret_basic
          | :client_secret_post
          | :client_secret_jwt
          | :private_key_jwt
          | :tls_client_auth
          | :self_signed_tls_client_auth
          | :none
  @type token_endpoint_auth_signing_alg :: :HS256 | signing_alg()
  @type subject_type :: :public | :pairwise
  @type signing_alg :: :RS256 | :ES256 | :PS256 | :EdDSA
  @type authorization_encrypted_response_alg :: :RSA_OAEP_256 | :ECDH_ES
  @type authorization_encrypted_response_enc :: :A256GCM | :A128GCM
  @type par_policy :: :inherit | :required | :optional
  @type dpop_policy :: :inherit | :bearer | :dpop
  @type security_profile :: :inherit | :fapi_2_0_security | :fapi_2_0_message_signing | :none
  @type backchannel_token_delivery_mode :: :poll | :ping | :push
  @type provenance :: :operator | :self_registered
  @type access_token_format :: :jwt | :opaque
  @type management_lifetime_context :: %__MODULE__{provenance: provenance()}
  @type secret_lifetime_context :: %__MODULE__{
          provenance: provenance(),
          token_endpoint_auth_method: token_endpoint_auth_method(),
          client_secret_hash: String.t() | nil
        }

  @secret_auth_methods [:client_secret_basic, :client_secret_post, :client_secret_jwt]

  @derive {Inspect,
           except: [
             :client_secret_hash,
             :client_secret_jwt_verifier_encrypted,
             :registration_access_token_hash
           ]}

  @type t :: %__MODULE__{
          id: integer() | nil,
          client_id: String.t(),
          client_secret_hash: String.t() | nil,
          client_secret_jwt_verifier_encrypted: String.t() | nil,
          client_type: client_type(),
          name: String.t() | nil,
          redirect_uris: [String.t()],
          post_logout_redirect_uris: [String.t()],
          backchannel_logout_uri: String.t() | nil,
          backchannel_logout_session_required: boolean(),
          frontchannel_logout_uri: String.t() | nil,
          frontchannel_logout_session_required: boolean(),
          allowed_scopes: [String.t()],
          allowed_grant_types: [String.t()],
          allowed_response_types: [String.t()],
          token_endpoint_auth_method: token_endpoint_auth_method(),
          token_endpoint_auth_signing_alg: token_endpoint_auth_signing_alg() | nil,
          pkce_required: boolean(),
          par_policy: par_policy(),
          dpop_policy: dpop_policy(),
          security_profile: security_profile(),
          subject_type: subject_type(),
          sector_identifier_uri: String.t() | nil,
          id_token_signed_response_alg: signing_alg() | nil,
          access_token_format: access_token_format() | nil,
          authorization_signed_response_alg: signing_alg() | nil,
          authorization_encrypted_response_alg: authorization_encrypted_response_alg() | nil,
          authorization_encrypted_response_enc: authorization_encrypted_response_enc() | nil,
          tls_client_auth_subject_dn: String.t() | nil,
          tls_client_auth_san_dns: String.t() | nil,
          tls_client_auth_san_uri: String.t() | nil,
          tls_client_auth_san_ip: String.t() | nil,
          tls_client_auth_san_email: String.t() | nil,
          jwks: map() | nil,
          jwks_uri: String.t() | nil,
          logo_uri: String.t() | nil,
          tos_uri: String.t() | nil,
          policy_uri: String.t() | nil,
          contacts: [String.t()],
          tenant_id: String.t() | nil,
          created_by: String.t() | nil,
          created_at: DateTime.t() | nil,
          active: boolean(),
          disabled_at: DateTime.t() | nil,
          disabled_by: String.t() | nil,
          last_secret_rotated_at: DateTime.t() | nil,
          metadata: map(),
          provenance: provenance(),
          registration_access_token_hash: String.t() | nil,
          registration_client_uri: String.t() | nil,
          initial_access_token_id: integer() | nil,
          client_id_issued_at: DateTime.t() | nil,
          client_secret_expires_at: DateTime.t() | nil,
          lifetime_version: 0 | 1 | nil,
          client_expires_at: DateTime.t() | nil,
          registration_access_token_expires_at: DateTime.t() | nil,
          backchannel_user_code_parameter: boolean(),
          backchannel_token_delivery_mode: backchannel_token_delivery_mode(),
          backchannel_client_notification_endpoint: String.t() | nil,
          max_delegation_depth: non_neg_integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  # A client registration is one durable protocol boundary; splitting it risks divergent defaults.
  # credo:disable-for-next-line Credo.Check.Warning.StructFieldAmount
  defstruct [
    :id,
    :client_id,
    :client_secret_hash,
    :client_secret_jwt_verifier_encrypted,
    :client_type,
    :name,
    redirect_uris: [],
    post_logout_redirect_uris: [],
    backchannel_logout_uri: nil,
    backchannel_logout_session_required: false,
    frontchannel_logout_uri: nil,
    frontchannel_logout_session_required: false,
    allowed_scopes: [],
    allowed_grant_types: [],
    allowed_response_types: [],
    token_endpoint_auth_method: :client_secret_basic,
    token_endpoint_auth_signing_alg: nil,
    pkce_required: true,
    par_policy: :inherit,
    dpop_policy: :inherit,
    security_profile: :inherit,
    subject_type: :public,
    sector_identifier_uri: nil,
    id_token_signed_response_alg: nil,
    access_token_format: nil,
    authorization_signed_response_alg: nil,
    authorization_encrypted_response_alg: nil,
    authorization_encrypted_response_enc: nil,
    tls_client_auth_subject_dn: nil,
    tls_client_auth_san_dns: nil,
    tls_client_auth_san_uri: nil,
    tls_client_auth_san_ip: nil,
    tls_client_auth_san_email: nil,
    jwks: nil,
    jwks_uri: nil,
    logo_uri: nil,
    tos_uri: nil,
    policy_uri: nil,
    contacts: [],
    tenant_id: nil,
    created_by: nil,
    created_at: nil,
    active: true,
    disabled_at: nil,
    disabled_by: nil,
    last_secret_rotated_at: nil,
    metadata: %{},
    provenance: :operator,
    registration_access_token_hash: nil,
    registration_client_uri: nil,
    initial_access_token_id: nil,
    client_id_issued_at: nil,
    client_secret_expires_at: nil,
    lifetime_version: nil,
    client_expires_at: nil,
    registration_access_token_expires_at: nil,
    backchannel_user_code_parameter: false,
    backchannel_token_delivery_mode: :poll,
    backchannel_client_notification_endpoint: nil,
    max_delegation_depth: nil,
    inserted_at: nil,
    updated_at: nil
  ]

  @doc """
  Decides whether a current client row remains eligible as an application.

  The consumer is explicit so callers can map the result to their own protocol error.
  Legacy rows (version 0) and authoritative unlimited rows (version 1 with no deadline)
  have no app expiry. Unknown versions and malformed authoritative dates fail closed.
  """
  @spec app_eligibility(t(), DateTime.t(), atom()) ::
          :ok | {:error, :disabled | :expired | :invalid_lifetime_state}
  def app_eligibility(%__MODULE__{active: false}, %DateTime{}, _consumer),
    do: {:error, :disabled}

  def app_eligibility(%__MODULE__{lifetime_version: 0}, %DateTime{}, _), do: :ok

  def app_eligibility(%__MODULE__{lifetime_version: 1, client_expires_at: nil}, %DateTime{}, _),
    do: :ok

  def app_eligibility(
        %__MODULE__{lifetime_version: 1, client_expires_at: deadline},
        %DateTime{} = now,
        _
      ) do
    if utc_second?(deadline) do
      case decision_instant(now) do
        {:ok, instant} ->
          if DateTime.compare(instant, deadline) == :lt, do: :ok, else: {:error, :expired}

        :error ->
          {:error, :invalid_lifetime_state}
      end
    else
      {:error, :invalid_lifetime_state}
    end
  end

  def app_eligibility(%__MODULE__{}, %DateTime{}, _),
    do: {:error, :invalid_lifetime_state}

  def app_eligibility(%__MODULE__{}, _, _),
    do: {:error, :invalid_lifetime_state}

  @doc "Returns the authoritative app deadline, treating legacy rows as unlimited."
  @spec effective_app_deadline(t()) ::
          {:ok, nil | DateTime.t()} | {:error, :invalid_lifetime_state}
  def effective_app_deadline(%__MODULE__{lifetime_version: 0}), do: {:ok, nil}

  def effective_app_deadline(%__MODULE__{lifetime_version: 1, client_expires_at: nil}),
    do: {:ok, nil}

  def effective_app_deadline(%__MODULE__{
        lifetime_version: 1,
        client_expires_at: %DateTime{} = deadline
      }) do
    if utc_second?(deadline), do: {:ok, deadline}, else: invalid_lifetime()
  end

  def effective_app_deadline(%__MODULE__{}), do: invalid_lifetime()

  @doc "Returns the authoritative app-management-token deadline, treating legacy rows as unlimited."
  @spec effective_management_deadline(t()) ::
          {:ok, nil | DateTime.t()} | {:error, :invalid_lifetime_state}
  def effective_management_deadline(%__MODULE__{lifetime_version: 0}), do: {:ok, nil}

  def effective_management_deadline(%__MODULE__{
        lifetime_version: 1,
        registration_access_token_expires_at: nil
      }),
      do: {:ok, nil}

  def effective_management_deadline(%__MODULE__{
        lifetime_version: 1,
        registration_access_token_expires_at: %DateTime{} = deadline
      }) do
    if utc_second?(deadline), do: {:ok, deadline}, else: invalid_lifetime()
  end

  def effective_management_deadline(%__MODULE__{}), do: invalid_lifetime()

  @doc "Checks a management credential against the final whole-second decision time."
  @spec management_eligibility(t(), DateTime.t(), atom()) ::
          :ok | {:error, :expired | :invalid_lifetime_state}
  def management_eligibility(%__MODULE__{} = client, %DateTime{} = now, _consumer) do
    with {:ok, deadline} <- effective_management_deadline(client),
         {:ok, instant} <- decision_instant(now) do
      case deadline do
        nil ->
          :ok

        %DateTime{} ->
          if DateTime.compare(instant, deadline) == :lt, do: :ok, else: {:error, :expired}
      end
    else
      _ -> {:error, :invalid_lifetime_state}
    end
  end

  def management_eligibility(%__MODULE__{}, _, _),
    do: {:error, :invalid_lifetime_state}

  @doc "Decides whether a shared-secret credential remains eligible at the current instant."
  @spec secret_eligibility(t(), DateTime.t(), atom()) ::
          :ok | {:error, :expired | :invalid_lifetime_state}
  def secret_eligibility(
        %__MODULE__{token_endpoint_auth_method: method} = client,
        %DateTime{} = now,
        _consumer
      )
      when method in @secret_auth_methods do
    with {:ok, deadline} when is_struct(deadline, DateTime) <- effective_secret_deadline(client),
         {:ok, instant} <- decision_instant(now) do
      if DateTime.compare(instant, deadline) == :lt, do: :ok, else: {:error, :expired}
    else
      {:ok, nil} -> :ok
      {:error, :invalid_lifetime_state} -> {:error, :invalid_lifetime_state}
      _other -> {:error, :invalid_lifetime_state}
    end
  end

  def secret_eligibility(%__MODULE__{} = client, %DateTime{}, _consumer) do
    case effective_secret_deadline(client) do
      {:ok, :inapplicable} -> :ok
      {:ok, nil} -> :ok
      {:ok, %DateTime{}} -> :ok
      {:error, :invalid_lifetime_state} -> {:error, :invalid_lifetime_state}
    end
  end

  def secret_eligibility(%__MODULE__{}, _, _),
    do: {:error, :invalid_lifetime_state}

  @doc "Returns the effective secret deadline, unlimited state, or method inapplicability."
  @spec effective_secret_deadline(t()) ::
          {:ok, :inapplicable | nil | DateTime.t()} | {:error, :invalid_lifetime_state}
  def effective_secret_deadline(%__MODULE__{token_endpoint_auth_method: method})
      when method in [:none, :private_key_jwt, :tls_client_auth, :self_signed_tls_client_auth],
      do: {:ok, :inapplicable}

  def effective_secret_deadline(%__MODULE__{
        token_endpoint_auth_method: method,
        lifetime_version: 0
      })
      when method in @secret_auth_methods,
      do: {:ok, nil}

  def effective_secret_deadline(
        %__MODULE__{token_endpoint_auth_method: method, lifetime_version: 1} = client
      )
      when method in @secret_auth_methods do
    case client.client_secret_expires_at do
      nil ->
        {:ok, nil}

      %DateTime{} = deadline ->
        if utc_second?(deadline), do: {:ok, deadline}, else: invalid_lifetime()

      _other ->
        invalid_lifetime()
    end
  end

  def effective_secret_deadline(%__MODULE__{}), do: invalid_lifetime()

  @doc "Calculates a validated, whole-second secret deadline for self-registered clients."
  @spec secret_deadline(secret_lifetime_context(), DateTime.t(), term()) ::
          {:ok, DateTime.t() | nil}
          | {:error, :invalid_secret_lifetime_policy | :invalid_lifetime_state}
  def secret_deadline(%__MODULE__{} = client, %DateTime{} = issued_at, duration) do
    with :ok <- validate_secret_duration(duration),
         {:ok, issued_second} <- decision_instant(issued_at) do
      if client.provenance == :self_registered and
           client.token_endpoint_auth_method in @secret_auth_methods and
           is_integer(duration) and duration > 0 do
        {:ok, DateTime.add(issued_second, duration, :second)}
      else
        {:ok, nil}
      end
    else
      {:error, reason}
      when reason in [:invalid_secret_lifetime_policy, :invalid_lifetime_state] ->
        {:error, reason}

      _other ->
        {:error, :invalid_lifetime_state}
    end
  rescue
    _error -> {:error, :invalid_lifetime_state}
  end

  def secret_deadline(%__MODULE__{}, _, _), do: {:error, :invalid_lifetime_state}

  @doc "Calculates the validated management-token deadline for self-registered clients."
  @spec management_deadline(management_lifetime_context(), DateTime.t(), term()) ::
          {:ok, DateTime.t() | nil}
          | {:error, :invalid_management_lifetime_policy | :invalid_lifetime_state}
  def management_deadline(%__MODULE__{provenance: provenance}, %DateTime{} = issued_at, duration)
      when provenance in [:operator, :self_registered] do
    with :ok <- validate_management_duration(duration),
         {:ok, issued_second} <- decision_instant(issued_at) do
      if provenance == :self_registered and is_integer(duration) and duration > 0 do
        {:ok, DateTime.add(issued_second, duration, :second)}
      else
        {:ok, nil}
      end
    else
      {:error, reason}
      when reason in [:invalid_management_lifetime_policy, :invalid_lifetime_state] ->
        {:error, reason}

      _other ->
        {:error, :invalid_lifetime_state}
    end
  rescue
    _error -> {:error, :invalid_lifetime_state}
  end

  def management_deadline(%__MODULE__{}, _, _), do: {:error, :invalid_lifetime_state}

  defp validate_secret_duration(value)
       when is_nil(value) or (is_integer(value) and value >= 0 and value <= 2_147_483_647),
       do: :ok

  defp validate_secret_duration(_value), do: {:error, :invalid_secret_lifetime_policy}

  defp validate_management_duration(value)
       when is_nil(value) or (is_integer(value) and value >= 0 and value <= 2_147_483_647),
       do: :ok

  defp validate_management_duration(_value),
    do: {:error, :invalid_management_lifetime_policy}

  defp invalid_lifetime, do: {:error, :invalid_lifetime_state}

  @doc """
  Returns the lifetime fields to write when a credential replacement promotes a legacy row.

  Historical v0 timestamps are advisory. Promotion clears all unrelated deadlines and only
  assigns a deadline to the credential being replaced. Authoritative v1 rows retain their
  unrelated deadlines.
  """
  @spec credential_lifetime_changes(t(), :secret | :management, DateTime.t() | nil) ::
          {:ok, map()} | {:error, :invalid_lifetime_state}
  def credential_lifetime_changes(%__MODULE__{lifetime_version: 0}, kind, deadline)
      when kind in [:secret, :management] and (is_nil(deadline) or is_struct(deadline, DateTime)) do
    credential_deadlines =
      case kind do
        :secret -> %{client_secret_expires_at: deadline}
        :management -> %{registration_access_token_expires_at: deadline}
      end

    {:ok,
     Map.merge(
       %{lifetime_version: 1, client_expires_at: nil},
       Map.merge(
         %{client_secret_expires_at: nil, registration_access_token_expires_at: nil},
         credential_deadlines
       )
     )}
  end

  def credential_lifetime_changes(%__MODULE__{lifetime_version: 1}, :secret, deadline)
      when is_nil(deadline) or is_struct(deadline, DateTime),
      do: {:ok, %{client_secret_expires_at: deadline}}

  def credential_lifetime_changes(%__MODULE__{lifetime_version: 1}, :management, deadline)
      when is_nil(deadline) or is_struct(deadline, DateTime),
      do: {:ok, %{registration_access_token_expires_at: deadline}}

  def credential_lifetime_changes(%__MODULE__{}, _, _),
    do: {:error, :invalid_lifetime_state}

  defp utc_second?(%DateTime{time_zone: "Etc/UTC", microsecond: {0, _precision}}), do: true
  defp utc_second?(%DateTime{time_zone: "UTC", microsecond: {0, _precision}}), do: true
  defp utc_second?(_), do: false

  defp decision_instant(%DateTime{} = now) do
    case DateTime.from_unix(DateTime.to_unix(now, :second), :second) do
      {:ok, instant} -> {:ok, instant}
      {:error, _reason} -> :error
    end
  rescue
    _error -> :error
  end
end
