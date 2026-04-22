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
    |> then(&{:ok, maybe_map(&1, &ClientRecord.to_domain/1)})
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
  def fetch_active_interaction(interaction_id) when is_binary(interaction_id) do
    now = DateTime.utc_now()

    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> where([interaction], interaction.expires_at > ^now)
    |> repo().one()
    |> then(&{:ok, maybe_map(&1, &InteractionRecord.to_domain/1)})
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
    |> then(&{:ok, Enum.map(&1, &ConsentGrantRecord.to_domain/1)})
  rescue
    error -> {:error, error}
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
    SigningKeyRecord
    |> where([key], key.status in [:active, :retiring])
    |> order_by([key], asc: key.inserted_at)
    |> repo().all()
    |> then(&{:ok, Enum.map(&1, &SigningKeyRecord.to_domain/1)})
  rescue
    error -> {:error, error}
  end

  defp repo do
    Config.repo!()
  end

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}

  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)
end
