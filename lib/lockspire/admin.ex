defmodule Lockspire.Admin do
  @moduledoc """
  Operator-facing service boundary for Lockspire admin workflows.
  """

  alias Lockspire.Admin.Clients
  alias Lockspire.Admin.Consents
  alias Lockspire.Admin.Keys
  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Admin.Tokens

  defdelegate list_clients(opts \\ []), to: Clients
  defdelegate get_client(client_id), to: Clients
  defdelegate create_client(attrs), to: Clients
  defdelegate update_client(client_id, attrs), to: Clients
  defdelegate rotate_client_secret(client_id, attrs \\ %{}), to: Clients
  defdelegate disable_client(client_id, attrs \\ %{}), to: Clients
  defdelegate enable_client(client_id, attrs \\ %{}), to: Clients
  defdelegate get_server_policy(), to: ServerPolicy
  defdelegate put_server_policy(mode), to: ServerPolicy
  defdelegate put_dpop_policy(mode), to: ServerPolicy
  defdelegate put_security_profile(profile), to: ServerPolicy
  defdelegate get_dcr_policy(), to: ServerPolicy
  defdelegate put_dcr_policy(attrs), to: ServerPolicy
  defdelegate list_consents(opts \\ []), to: Consents
  defdelegate list_consents_for_account(account_id), to: Consents
  defdelegate get_consent(grant_id), to: Consents
  defdelegate revoke_consent(grant_id, attrs \\ %{}), to: Consents
  defdelegate list_tokens(opts \\ []), to: Tokens
  defdelegate get_token(token_id), to: Tokens
  defdelegate revoke_token(token_id, attrs \\ %{}), to: Tokens
  defdelegate revoke_token_family(token_id, attrs \\ %{}), to: Tokens
  defdelegate list_keys(opts \\ []), to: Keys
  defdelegate get_key(key_id), to: Keys
  defdelegate generate_key(use \\ :sig), to: Keys
  defdelegate publish_key(key_id, attrs \\ %{}), to: Keys
  defdelegate activate_key(key_id, attrs \\ %{}), to: Keys
  defdelegate retire_key(key_id, attrs \\ %{}), to: Keys
end
