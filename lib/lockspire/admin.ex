defmodule Lockspire.Admin do
  @moduledoc """
  Operator-facing service boundary for Lockspire admin workflows.
  """

  alias Lockspire.Admin.Clients
  alias Lockspire.Admin.Consents
  alias Lockspire.Admin.Keys
  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Admin.Tokens

  @spec list_clients(keyword()) :: {:ok, [Lockspire.Domain.Client.t()]} | {:error, term()}
  defdelegate list_clients(opts \\ []), to: Clients

  @spec get_client(String.t()) :: {:ok, Lockspire.Domain.Client.t()} | {:error, :not_found | term()}
  defdelegate get_client(client_id), to: Clients

  @spec create_client(map() | keyword()) ::
          {:ok, Lockspire.Clients.RegistrationResult.t()} | {:error, [Lockspire.Clients.error_detail()]}
  defdelegate create_client(attrs), to: Clients

  @spec update_client(String.t(), map() | keyword()) ::
          {:ok, Lockspire.Domain.Client.t()} | {:error, [Lockspire.Clients.error_detail()]} | {:error, term()}
  defdelegate update_client(client_id, attrs), to: Clients

  @spec rotate_client_secret(String.t(), map() | keyword()) ::
          {:ok, %{client: Lockspire.Domain.Client.t(), client_secret: String.t()}}
          | {:error, [Lockspire.Clients.error_detail()]}
          | {:error, term()}
  defdelegate rotate_client_secret(client_id, attrs \\ %{}), to: Clients

  @spec disable_client(String.t(), map() | keyword()) ::
          {:ok, Lockspire.Domain.Client.t()} | {:error, :not_found | term()}
  defdelegate disable_client(client_id, attrs \\ %{}), to: Clients

  @spec enable_client(String.t(), map() | keyword()) ::
          {:ok, Lockspire.Domain.Client.t()} | {:error, :not_found | term()}
  defdelegate enable_client(client_id, attrs \\ %{}), to: Clients

  @spec get_server_policy() :: {:ok, Lockspire.Domain.ServerPolicy.t()} | {:error, term()}
  defdelegate get_server_policy(), to: ServerPolicy

  @spec put_server_policy(atom() | String.t()) ::
          {:ok, Lockspire.Domain.ServerPolicy.t()} | {:error, [Lockspire.Admin.ServerPolicy.error_detail()]} | {:error, term()}
  defdelegate put_server_policy(mode), to: ServerPolicy

  @spec put_dpop_policy(atom() | String.t()) ::
          {:ok, Lockspire.Domain.ServerPolicy.t()} | {:error, [Lockspire.Admin.ServerPolicy.error_detail()]} | {:error, term()}
  defdelegate put_dpop_policy(mode), to: ServerPolicy

  @spec put_security_profile(atom() | String.t()) ::
          {:ok, Lockspire.Domain.ServerPolicy.t()} | {:error, [Lockspire.Admin.ServerPolicy.error_detail()]} | {:error, term()}
  defdelegate put_security_profile(profile), to: ServerPolicy

  @spec get_dcr_policy() :: {:ok, Lockspire.Domain.ServerPolicy.t()} | {:error, term()}
  defdelegate get_dcr_policy(), to: ServerPolicy

  @spec put_dcr_policy(map()) ::
          {:ok, Lockspire.Domain.ServerPolicy.t()} | {:error, [Lockspire.Admin.ServerPolicy.error_detail()]} | {:error, term()}
  defdelegate put_dcr_policy(attrs), to: ServerPolicy

  @spec list_consents(keyword()) :: {:ok, [Lockspire.Admin.Consents.consent_view()]} | {:error, term()}
  defdelegate list_consents(opts \\ []), to: Consents

  @spec list_consents_for_account(String.t()) :: {:ok, [Lockspire.Admin.Consents.consent_view()]} | {:error, term()}
  defdelegate list_consents_for_account(account_id), to: Consents

  @spec get_consent(integer()) :: {:ok, Lockspire.Admin.Consents.consent_view() | nil} | {:error, term()}
  defdelegate get_consent(grant_id), to: Consents

  @spec revoke_consent(integer(), map()) :: {:ok, Lockspire.Admin.Consents.consent_view()} | {:error, term()}
  defdelegate revoke_consent(grant_id, attrs \\ %{}), to: Consents

  @spec list_tokens(keyword()) :: {:ok, [Lockspire.Admin.Tokens.token_view()]} | {:error, term()}
  defdelegate list_tokens(opts \\ []), to: Tokens

  @spec get_token(integer()) :: {:ok, Lockspire.Admin.Tokens.token_detail() | nil} | {:error, term()}
  defdelegate get_token(token_id), to: Tokens

  @spec revoke_token(integer(), map()) :: {:ok, Lockspire.Admin.Tokens.token_detail()} | {:error, term()}
  defdelegate revoke_token(token_id, attrs \\ %{}), to: Tokens

  @spec revoke_token_family(integer(), map()) ::
          {:ok, %{count: non_neg_integer(), token: Lockspire.Admin.Tokens.token_detail()}} | {:error, term()}
  defdelegate revoke_token_family(token_id, attrs \\ %{}), to: Tokens

  @spec list_keys(keyword()) :: {:ok, [Lockspire.Admin.Keys.key_view()]} | {:error, term()}
  defdelegate list_keys(opts \\ []), to: Keys

  @spec get_key(integer()) :: {:ok, Lockspire.Admin.Keys.key_view() | nil} | {:error, term()}
  defdelegate get_key(key_id), to: Keys

  @spec generate_key(Lockspire.Domain.SigningKey.use_type()) :: {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
  defdelegate generate_key(use \\ :sig), to: Keys

  @spec publish_key(integer(), map() | keyword()) :: {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
  defdelegate publish_key(key_id, attrs \\ %{}), to: Keys

  @spec activate_key(integer(), map() | keyword()) :: {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
  defdelegate activate_key(key_id, attrs \\ %{}), to: Keys

  @spec retire_key(integer(), map() | keyword()) :: {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
  defdelegate retire_key(key_id, attrs \\ %{}), to: Keys
end
