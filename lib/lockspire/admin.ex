defmodule Lockspire.Admin do
  @moduledoc """
  Operator-facing service boundary for Lockspire admin workflows.
  """

  alias Lockspire.Admin.Clients
  alias Lockspire.Admin.Consents
  alias Lockspire.Admin.DeviceAuthorizations
  alias Lockspire.Admin.Keys
  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Admin.Tokens

  @doc """
  Lists device authorizations.
  """
  @spec list_device_authorizations(keyword()) ::
          {:ok, [Lockspire.Domain.DeviceAuthorization.t()]} | {:error, term()}
  defdelegate list_device_authorizations(opts \\ []), to: DeviceAuthorizations

  @doc """
  Lists registered clients.
  """
  @spec list_clients(keyword()) :: {:ok, [Lockspire.Domain.Client.t()]} | {:error, term()}
  defdelegate list_clients(opts \\ []), to: Clients

  @doc """
  Gets a client by ID.
  """
  @spec get_client(String.t()) ::
          {:ok, Lockspire.Domain.Client.t()} | {:error, :not_found | term()}
  defdelegate get_client(client_id), to: Clients

  @doc """
  Creates a new client.
  """
  @spec create_client(map() | keyword()) ::
          {:ok, Lockspire.Clients.RegistrationResult.t()}
          | {:error, [Lockspire.Clients.error_detail()]}
  defdelegate create_client(attrs), to: Clients

  @doc """
  Updates an existing client.
  """
  @spec update_client(String.t(), map() | keyword()) ::
          {:ok, Lockspire.Domain.Client.t()}
          | {:error, [Lockspire.Clients.error_detail()]}
          | {:error, term()}
  defdelegate update_client(client_id, attrs), to: Clients

  @doc """
  Rotates the client secret for a given client.
  """
  @spec rotate_client_secret(String.t(), map() | keyword()) ::
          {:ok, %{client: Lockspire.Domain.Client.t(), client_secret: String.t()}}
          | {:error, [Lockspire.Clients.error_detail()]}
          | {:error, term()}
  defdelegate rotate_client_secret(client_id, attrs \\ %{}), to: Clients

  @doc """
  Disables a client.
  """
  @spec disable_client(String.t(), map() | keyword()) ::
          {:ok, Lockspire.Domain.Client.t()} | {:error, :not_found | term()}
  defdelegate disable_client(client_id, attrs \\ %{}), to: Clients

  @doc """
  Enables a client.
  """
  @spec enable_client(String.t(), map() | keyword()) ::
          {:ok, Lockspire.Domain.Client.t()} | {:error, :not_found | term()}
  defdelegate enable_client(client_id, attrs \\ %{}), to: Clients

  @doc """
  Gets the server policy.
  """
  @spec get_server_policy() :: {:ok, Lockspire.Domain.ServerPolicy.t()} | {:error, term()}
  defdelegate get_server_policy(), to: ServerPolicy

  @doc """
  Updates the server policy mode.
  """
  @spec put_server_policy(atom() | String.t()) ::
          {:ok, Lockspire.Domain.ServerPolicy.t()}
          | {:error, [Lockspire.Admin.ServerPolicy.error_detail()]}
          | {:error, term()}
  defdelegate put_server_policy(mode), to: ServerPolicy

  @doc """
  Updates the DPoP policy mode.
  """
  @spec put_dpop_policy(atom() | String.t()) ::
          {:ok, Lockspire.Domain.ServerPolicy.t()}
          | {:error, [Lockspire.Admin.ServerPolicy.error_detail()]}
          | {:error, term()}
  defdelegate put_dpop_policy(mode), to: ServerPolicy

  @doc """
  Updates the security profile.
  """
  @spec put_security_profile(atom() | String.t()) ::
          {:ok, Lockspire.Domain.ServerPolicy.t()}
          | {:error, [Lockspire.Admin.ServerPolicy.error_detail()]}
          | {:error, term()}
  defdelegate put_security_profile(profile), to: ServerPolicy

  @doc """
  Gets the Dynamic Client Registration (DCR) policy.
  """
  @spec get_dcr_policy() :: {:ok, Lockspire.Domain.ServerPolicy.t()} | {:error, term()}
  defdelegate get_dcr_policy(), to: ServerPolicy

  @doc """
  Updates the DCR policy.
  """
  @spec put_dcr_policy(map()) ::
          {:ok, Lockspire.Domain.ServerPolicy.t()}
          | {:error, [Lockspire.Admin.ServerPolicy.error_detail()]}
          | {:error, term()}
  defdelegate put_dcr_policy(attrs), to: ServerPolicy

  @doc """
  Lists all consents.
  """
  @spec list_consents(keyword()) ::
          {:ok, [Lockspire.Admin.Consents.consent_view()]} | {:error, term()}
  defdelegate list_consents(opts \\ []), to: Consents

  @doc """
  Lists consents for a specific account.
  """
  @spec list_consents_for_account(String.t()) ::
          {:ok, [Lockspire.Admin.Consents.consent_view()]} | {:error, term()}
  defdelegate list_consents_for_account(account_id), to: Consents

  @doc """
  Gets a consent by ID.
  """
  @spec get_consent(integer()) ::
          {:ok, Lockspire.Admin.Consents.consent_view() | nil} | {:error, term()}
  defdelegate get_consent(grant_id), to: Consents

  @doc """
  Revokes a specific consent.
  """
  @spec revoke_consent(integer(), map()) ::
          {:ok, Lockspire.Admin.Consents.consent_view()} | {:error, term()}
  defdelegate revoke_consent(grant_id, attrs \\ %{}), to: Consents

  @doc """
  Lists all active tokens.
  """
  @spec list_tokens(keyword()) :: {:ok, [Lockspire.Admin.Tokens.token_view()]} | {:error, term()}
  defdelegate list_tokens(opts \\ []), to: Tokens

  @doc """
  Gets token details by ID.
  """
  @spec get_token(integer()) ::
          {:ok, Lockspire.Admin.Tokens.token_detail() | nil} | {:error, term()}
  defdelegate get_token(token_id), to: Tokens

  @doc """
  Revokes a specific token.
  """
  @spec revoke_token(integer(), map()) ::
          {:ok, Lockspire.Admin.Tokens.token_detail()} | {:error, term()}
  defdelegate revoke_token(token_id, attrs \\ %{}), to: Tokens

  @doc """
  Revokes a token and its entire family (e.g. refresh token chains).
  """
  @spec revoke_token_family(integer(), map()) ::
          {:ok, %{count: non_neg_integer(), token: Lockspire.Admin.Tokens.token_detail()}}
          | {:error, term()}
  defdelegate revoke_token_family(token_id, attrs \\ %{}), to: Tokens

  @doc """
  Lists all signing keys.
  """
  @spec list_keys(keyword()) :: {:ok, [Lockspire.Admin.Keys.key_view()]} | {:error, term()}
  defdelegate list_keys(opts \\ []), to: Keys

  @doc """
  Gets a key by its ID.
  """
  @spec get_key(integer()) :: {:ok, Lockspire.Admin.Keys.key_view() | nil} | {:error, term()}
  defdelegate get_key(key_id), to: Keys

  @doc """
  Generates a new signing key.
  """
  @spec generate_key(Lockspire.Domain.SigningKey.use_type()) ::
          {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
  defdelegate generate_key(use \\ :sig), to: Keys

  @doc """
  Publishes a key for external use.
  """
  @spec publish_key(integer(), map() | keyword()) ::
          {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
  defdelegate publish_key(key_id, attrs \\ %{}), to: Keys

  @doc """
  Activates a key as the current active signing key.
  """
  @spec activate_key(integer(), map() | keyword()) ::
          {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
  defdelegate activate_key(key_id, attrs \\ %{}), to: Keys

  @doc """
  Retires a key so it is no longer used for signing.
  """
  @spec retire_key(integer(), map() | keyword()) ::
          {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
  defdelegate retire_key(key_id, attrs \\ %{}), to: Keys
end
