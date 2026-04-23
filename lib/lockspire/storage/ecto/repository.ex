defmodule Lockspire.Storage.Ecto.Repository do
  @moduledoc """
  Default Ecto-backed implementation for Lockspire's domain storage contracts.
  """

  import Ecto.Query

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.ClientStore
  alias Lockspire.Storage.ConsentStore
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.ConsentGrantRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Storage.InteractionStore
  alias Lockspire.Storage.KeyStore
  alias Lockspire.Storage.TokenStore

  @behaviour ClientStore
  @behaviour InteractionStore
  @behaviour ConsentStore
  @behaviour TokenStore
  @behaviour KeyStore

  @active_interaction_statuses InteractionRecord.active_statuses()

  @impl ClientStore
  def register_client(%Client{} = client) do
    %ClientRecord{}
    |> ClientRecord.changeset(client)
    |> repo().insert()
    |> map_one(&ClientRecord.to_domain/1)
  end

  @impl ClientStore
  def fetch_client_by_id(client_id) when is_binary(client_id) do
    ClientRecord
    |> where([client], client.client_id == ^client_id)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl InteractionStore
  def put_interaction(%Interaction{} = interaction) do
    %InteractionRecord{}
    |> InteractionRecord.changeset(interaction)
    |> repo().insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:interaction_id]
    )
    |> map_one(&InteractionRecord.to_domain/1)
  end

  @impl InteractionStore
  def fetch_interaction(interaction_id) when is_binary(interaction_id) do
    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &InteractionRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl InteractionStore
  def fetch_active_interaction(interaction_id) when is_binary(interaction_id) do
    now = DateTime.utc_now()

    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> where([interaction], interaction.status in ^@active_interaction_statuses)
    |> where([interaction], interaction.expires_at > ^now)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &InteractionRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl InteractionStore
  def transition_interaction(interaction_id, expected_statuses, attrs)
      when is_binary(interaction_id) and is_list(expected_statuses) and is_map(attrs) do
    transact(fn ->
      interaction_id
      |> locked_interaction_query()
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %InteractionRecord{} = record ->
          if record.status in expected_statuses do
            record
            |> InteractionRecord.update_changeset(Map.put(attrs, :updated_at, DateTime.utc_now()))
            |> repo().update()
            |> map_one(&InteractionRecord.to_domain/1)
            |> unwrap_or_rollback()
          else
            repo().rollback(:invalid_state)
          end
      end
    end)
  end

  @impl InteractionStore
  def transact(fun) when is_function(fun, 0) do
    case repo().transaction(fn ->
           case fun.() do
             {:error, reason} -> repo().rollback(reason)
             result -> result
           end
         end) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  @impl ConsentStore
  def grant_consent(%ConsentGrant{} = grant) do
    %ConsentGrantRecord{}
    |> ConsentGrantRecord.changeset(grant)
    |> repo().insert()
    |> map_one(&ConsentGrantRecord.to_domain/1)
  end

  @impl ConsentStore
  def list_consents_for_account(account_id) when is_binary(account_id) do
    ConsentGrantRecord
    |> where([grant], grant.account_id == ^account_id)
    |> order_by([grant], desc: grant.granted_at, desc: grant.id)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl ConsentStore
  def list_reusable_consents(account_id, client_id)
      when is_binary(account_id) and is_binary(client_id) do
    ConsentGrantRecord
    |> where([grant], grant.account_id == ^account_id and grant.client_id == ^client_id)
    |> where([grant], grant.kind == :remembered and grant.status == :active)
    |> where([grant], is_nil(grant.revoked_at))
    |> order_by([grant], desc: grant.granted_at, desc: grant.id)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl ConsentStore
  def revoke_consent_grant(grant_id, attrs) when is_integer(grant_id) and is_map(attrs) do
    transact(fn ->
      ConsentGrantRecord
      |> where([grant], grant.id == ^grant_id)
      |> lock("FOR UPDATE")
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %ConsentGrantRecord{} = record ->
          record
          |> ConsentGrantRecord.update_changeset(
            attrs
            |> Map.put_new(:status, :revoked)
            |> Map.put(:updated_at, DateTime.utc_now())
          )
          |> repo().update()
          |> map_one(&ConsentGrantRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
  end

  @impl TokenStore
  def store_token(%Token{} = token) do
    %TokenRecord{}
    |> TokenRecord.changeset(token)
    |> repo().insert()
    |> map_one(&TokenRecord.to_domain/1)
  end

  @impl TokenStore
  def revoke_token_family(family_id) when is_binary(family_id) do
    {count, _records} =
      TokenRecord
      |> where([token], token.family_id == ^family_id)
      |> where([token], is_nil(token.revoked_at))
      |> repo().update_all(set: [revoked_at: DateTime.utc_now(), updated_at: DateTime.utc_now()])

    {:ok, count}
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_authorization_code(token_hash) when is_binary(token_hash) do
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :authorization_code)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_active_authorization_code(token_hash) when is_binary(token_hash) do
    now = DateTime.utc_now()

    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :authorization_code)
    |> where([token], is_nil(token.redeemed_at) and is_nil(token.revoked_at))
    |> where([token], token.expires_at > ^now)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def mark_authorization_code_redeemed(token_hash, redeemed_at)
      when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
    transact(fn ->
      TokenRecord
      |> where([token], token.token_hash == ^token_hash)
      |> where([token], token.token_type == :authorization_code)
      |> lock("FOR UPDATE")
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %TokenRecord{redeemed_at: %DateTime{}} ->
          repo().rollback(:already_redeemed)

        %TokenRecord{} = record ->
          record
          |> Ecto.Changeset.change(redeemed_at: redeemed_at, updated_at: DateTime.utc_now())
          |> repo().update()
          |> map_one(&TokenRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
  end

  @impl KeyStore
  def publish_key(%SigningKey{} = key) do
    %SigningKeyRecord{}
    |> SigningKeyRecord.changeset(key)
    |> repo().insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:kid]
    )
    |> map_one(&SigningKeyRecord.to_domain/1)
  end

  @impl KeyStore
  def list_active_keys do
    list_publishable_keys()
  end

  @impl KeyStore
  def list_publishable_keys do
    SigningKeyRecord
    |> where([key], key.status in [:active, :retiring])
    |> order_by([key], asc: key.inserted_at)
    |> repo().all()
    |> then(fn records ->
      {:ok, Enum.map(records, &(SigningKeyRecord.to_domain(&1) |> strip_private_key_material()))}
    end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def redeem_authorization_code(token_hash, redeemed_at, %Token{} = access_token)
      when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
    transact(fn ->
      TokenRecord
      |> where([token], token.token_hash == ^token_hash)
      |> where([token], token.token_type == :authorization_code)
      |> lock("FOR UPDATE")
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %TokenRecord{redeemed_at: %DateTime{}} ->
          repo().rollback(:already_redeemed)

        %TokenRecord{} = record ->
          with {:ok, redeemed_code} <- redeem_code_record(record, redeemed_at),
               {:ok, stored_access_token} <- store_token_record(access_token) do
            %{authorization_code: redeemed_code, access_token: stored_access_token}
          else
            {:error, reason} -> repo().rollback(reason)
          end
      end
    end)
  end

  defp repo do
    Config.repo!()
  end

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}

  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)

  defp locked_interaction_query(interaction_id) do
    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> lock("FOR UPDATE")
  end

  defp unwrap_or_rollback({:ok, result}), do: result
  defp unwrap_or_rollback({:error, reason}), do: repo().rollback(reason)

  defp redeem_code_record(%TokenRecord{} = record, redeemed_at) do
    record
    |> Ecto.Changeset.change(redeemed_at: redeemed_at, updated_at: DateTime.utc_now())
    |> repo().update()
    |> map_one(&TokenRecord.to_domain/1)
  end

  defp store_token_record(%Token{} = token) do
    %TokenRecord{}
    |> TokenRecord.changeset(token)
    |> repo().insert()
    |> map_one(&TokenRecord.to_domain/1)
  end

  defp strip_private_key_material(%SigningKey{} = key) do
    %SigningKey{key | private_jwk_encrypted: nil}
  end
end
