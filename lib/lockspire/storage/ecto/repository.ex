defmodule Lockspire.Storage.Ecto.Repository do
  @moduledoc """
  Default Ecto-backed implementation for Lockspire's domain storage contracts.
  """

  import Ecto.Query

  alias Lockspire.Config
  alias Lockspire.Audit.Event
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.AuditEventRecord
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
  def list_clients(opts \\ []) when is_list(opts) do
    ClientRecord
    |> maybe_filter_client_search(Keyword.get(opts, :search))
    |> maybe_filter_client_status(Keyword.get(opts, :active))
    |> order_by([client], asc: client.name, asc: client.client_id)
    |> maybe_limit_clients(Keyword.get(opts, :limit))
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
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

  @impl ClientStore
  def update_client(%Client{id: id}, attrs) when is_integer(id) and is_map(attrs) do
    transact(fn ->
      ClientRecord
      |> where([client], client.id == ^id)
      |> lock("FOR UPDATE")
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %ClientRecord{} = record ->
          record
          |> ClientRecord.update_changeset(Map.put(attrs, :updated_at, DateTime.utc_now()))
          |> repo().update()
          |> map_one(&ClientRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
  end

  @impl ClientStore
  def rotate_client_secret(%Client{id: id}, secret_hash, rotated_at)
      when is_integer(id) and is_binary(secret_hash) and is_struct(rotated_at, DateTime) do
    update_client_record(id, %{
      client_secret_hash: secret_hash,
      last_secret_rotated_at: rotated_at,
      updated_at: DateTime.utc_now()
    })
  end

  @impl ClientStore
  def set_client_active(%Client{id: id}, active, attrs)
      when is_integer(id) and is_boolean(active) and is_map(attrs) do
    lifecycle_attrs =
      attrs
      |> Map.take([:disabled_at, :disabled_by])
      |> Map.put(:active, active)
      |> Map.put(:updated_at, DateTime.utc_now())

    update_client_record(id, lifecycle_attrs)
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

  @spec append_audit_event(Event.t() | map()) :: {:ok, Event.t()} | {:error, term()}
  def append_audit_event(%Event{} = event) do
    %AuditEventRecord{}
    |> AuditEventRecord.changeset(event)
    |> repo().insert()
    |> map_one(&AuditEventRecord.to_domain/1)
  end

  def append_audit_event(attrs) when is_map(attrs) do
    attrs
    |> Event.normalize()
    |> append_audit_event()
  rescue
    error -> {:error, error}
  end

  @spec transact_with_audit(Event.t() | map(), (() -> term())) ::
          {:ok, term()} | {:error, term()}
  def transact_with_audit(audit_event, fun) when is_function(fun, 0) do
    transact(fn ->
      result =
        case fun.() do
          {:ok, value} -> value
          {:error, reason} -> repo().rollback(reason)
          value -> value
        end

      case append_audit_event(audit_event) do
        {:ok, _event} -> result
        {:error, reason} -> repo().rollback(reason)
      end
    end)
  end

  @impl ConsentStore
  def grant_consent(%ConsentGrant{} = grant) do
    %ConsentGrantRecord{}
    |> ConsentGrantRecord.changeset(grant)
    |> repo().insert()
    |> map_one(&ConsentGrantRecord.to_domain/1)
  end

  @impl ConsentStore
  def list_consents(opts \\ []) when is_list(opts) do
    ConsentGrantRecord
    |> maybe_filter_consent_account(Keyword.get(opts, :account_id))
    |> maybe_filter_consent_client(Keyword.get(opts, :client_id))
    |> maybe_filter_consent_status(Keyword.get(opts, :status))
    |> order_by([grant], desc: grant.granted_at, desc: grant.id)
    |> maybe_limit_consents(Keyword.get(opts, :limit))
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl ConsentStore
  def list_consents_for_account(account_id) when is_binary(account_id) do
    list_consents(account_id: account_id)
  end

  @impl ConsentStore
  def fetch_consent_grant(grant_id) when is_integer(grant_id) do
    ConsentGrantRecord
    |> where([grant], grant.id == ^grant_id)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &ConsentGrantRecord.to_domain/1)} end)
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

        %ConsentGrantRecord{revoked_at: %DateTime{}} = record ->
          ConsentGrantRecord.to_domain(record)

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
  def list_lifecycle_tokens(opts \\ []) when is_list(opts) do
    now = DateTime.utc_now()

    TokenRecord
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> maybe_filter_token_account(Keyword.get(opts, :account_id))
    |> maybe_filter_token_client(Keyword.get(opts, :client_id))
    |> maybe_filter_token_status(Keyword.get(opts, :status), now)
    |> order_by([token], desc: token.issued_at, desc: token.id)
    |> maybe_limit_tokens(Keyword.get(opts, :limit))
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_lifecycle_token_by_id(token_id) when is_integer(token_id) do
    TokenRecord
    |> where([token], token.id == ^token_id)
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def list_token_family(family_id) when is_binary(family_id) do
    TokenRecord
    |> where([token], token.family_id == ^family_id)
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> order_by([token], asc: token.generation, asc: token.issued_at, asc: token.id)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
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
  def fetch_lifecycle_token(token_hash) when is_binary(token_hash) do
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_refresh_token(token_hash) when is_binary(token_hash) do
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :refresh_token)
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
  def fetch_active_access_token(token_hash) when is_binary(token_hash) do
    now = DateTime.utc_now()

    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :access_token)
    |> where([token], is_nil(token.revoked_at))
    |> where([token], token.expires_at > ^now)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def revoke_lifecycle_token(token_hash, client_id, revoked_at)
      when is_binary(token_hash) and is_binary(client_id) and is_struct(revoked_at, DateTime) do
    transact(fn ->
      TokenRecord
      |> where([token], token.token_hash == ^token_hash)
      |> where([token], token.token_type in [:access_token, :refresh_token])
      |> lock("FOR UPDATE")
      |> repo().one()
      |> case do
        nil ->
          nil

        %TokenRecord{client_id: ^client_id} = record ->
          if is_nil(record.revoked_at) do
            record
            |> Ecto.Changeset.change(revoked_at: revoked_at, updated_at: DateTime.utc_now())
            |> repo().update()
            |> map_one(&TokenRecord.to_domain/1)
            |> unwrap_or_rollback()
          else
            TokenRecord.to_domain(record)
          end

        %TokenRecord{} ->
          nil
      end
    end)
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

  @impl KeyStore
  def list_signing_keys(opts \\ []) when is_list(opts) do
    SigningKeyRecord
    |> maybe_filter_signing_key_status(Keyword.get(opts, :status))
    |> order_by([key], desc: key.inserted_at, desc: key.id)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &SigningKeyRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl KeyStore
  def list_publishable_keys do
    SigningKeyRecord
    |> where(
      [key],
      key.status in [:active, :retiring] or
        (key.status == :upcoming and not is_nil(key.published_at))
    )
    |> order_by([key], asc: key.inserted_at)
    |> repo().all()
    |> then(fn records ->
      {:ok, Enum.map(records, &(SigningKeyRecord.to_domain(&1) |> strip_private_key_material()))}
    end)
  rescue
    error -> {:error, error}
  end

  @impl KeyStore
  def fetch_active_signing_key do
    SigningKeyRecord
    |> where([key], key.status == :active)
    |> order_by([key], asc: key.inserted_at)
    |> limit(1)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &SigningKeyRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl KeyStore
  def fetch_signing_key_by_id(id) when is_integer(id) do
    SigningKeyRecord
    |> where([key], key.id == ^id)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &SigningKeyRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl KeyStore
  def publish_signing_key(id, published_at)
      when is_integer(id) and is_struct(published_at, DateTime) do
    transact(fn ->
      id
      |> locked_signing_key_query()
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %SigningKeyRecord{status: :upcoming, published_at: nil} = record ->
          record
          |> SigningKeyRecord.update_changeset(%{published_at: published_at})
          |> repo().update()
          |> map_one(&SigningKeyRecord.to_domain/1)
          |> unwrap_or_rollback()

        %SigningKeyRecord{status: :upcoming} ->
          repo().rollback(:already_published)

        %SigningKeyRecord{} ->
          repo().rollback(:invalid_state)
      end
    end)
  end

  @impl KeyStore
  def activate_signing_key(id, activated_at)
      when is_integer(id) and is_struct(activated_at, DateTime) do
    transact(fn ->
      selected =
        id
        |> locked_signing_key_query()
        |> repo().one()

      case selected do
        nil ->
          repo().rollback(:not_found)

        %SigningKeyRecord{status: status} when status != :upcoming ->
          repo().rollback(:invalid_state)

        %SigningKeyRecord{published_at: nil} ->
          repo().rollback(:not_published)

        %SigningKeyRecord{} = selected_record ->
          active_records =
            SigningKeyRecord
            |> where([key], key.status == :active)
            |> lock("FOR UPDATE")
            |> repo().all()

          case active_records do
            [] ->
              activated_key =
                selected_record
                |> SigningKeyRecord.update_changeset(%{
                  status: :active,
                  activated_at: activated_at,
                  retiring_at: nil,
                  retired_at: nil
                })
                |> repo().update()
                |> map_one(&SigningKeyRecord.to_domain/1)
                |> unwrap_or_rollback()

              %{activated_key: activated_key, retiring_key: nil}

            [%SigningKeyRecord{} = active_record] ->
              retiring_key =
                active_record
                |> SigningKeyRecord.update_changeset(%{
                  status: :retiring,
                  retiring_at: activated_at,
                  retired_at: nil
                })
                |> repo().update()
                |> map_one(&SigningKeyRecord.to_domain/1)
                |> unwrap_or_rollback()

              activated_key =
                selected_record
                |> SigningKeyRecord.update_changeset(%{
                  status: :active,
                  activated_at: activated_at,
                  retiring_at: nil,
                  retired_at: nil
                })
                |> repo().update()
                |> map_one(&SigningKeyRecord.to_domain/1)
                |> unwrap_or_rollback()

              %{activated_key: activated_key, retiring_key: retiring_key}

            _multiple ->
              repo().rollback(:multiple_active_keys)
          end
      end
    end)
  end

  @impl KeyStore
  def retire_signing_key(id, retired_at)
      when is_integer(id) and is_struct(retired_at, DateTime) do
    transact(fn ->
      id
      |> locked_signing_key_query()
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %SigningKeyRecord{status: :retiring} = record ->
          record
          |> SigningKeyRecord.update_changeset(%{
            status: :retired,
            retired_at: retired_at
          })
          |> repo().update()
          |> map_one(&SigningKeyRecord.to_domain/1)
          |> unwrap_or_rollback()

        %SigningKeyRecord{status: :retired} ->
          repo().rollback(:already_retired)

        %SigningKeyRecord{} ->
          repo().rollback(:invalid_state)
      end
    end)
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

  @impl TokenStore
  def rotate_refresh_token(
        token_hash,
        client_id,
        rotated_at,
        %Token{} = refresh_token,
        %Token{} = access_token
      )
      when is_binary(token_hash) and is_binary(client_id) and is_struct(rotated_at, DateTime) do
    case repo().transaction(fn ->
           token_hash
           |> locked_refresh_token_query()
           |> repo().one()
           |> case do
             nil ->
               {:error, :not_found}

             %TokenRecord{} = record ->
               rotate_refresh_token_record(
                 record,
                 client_id,
                 rotated_at,
                 refresh_token,
                 access_token
               )
           end
         end) do
      {:ok, {:ok, result}} -> {:ok, result}
      {:ok, {:error, reason}} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  defp repo do
    Config.repo!()
  end

  defp update_client_record(id, attrs) do
    transact(fn ->
      ClientRecord
      |> where([client], client.id == ^id)
      |> lock("FOR UPDATE")
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %ClientRecord{} = record ->
          record
          |> ClientRecord.update_changeset(attrs)
          |> repo().update()
          |> map_one(&ClientRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
  end

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}

  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)

  defp maybe_filter_client_search(query, nil), do: query
  defp maybe_filter_client_search(query, ""), do: query

  defp maybe_filter_client_search(query, search) when is_binary(search) do
    pattern = "%#{search}%"

    where(
      query,
      [client],
      ilike(client.client_id, ^pattern) or ilike(client.name, ^pattern)
    )
  end

  defp maybe_filter_client_status(query, nil), do: query

  defp maybe_filter_client_status(query, active) when is_boolean(active) do
    where(query, [client], client.active == ^active)
  end

  defp maybe_filter_consent_account(query, nil), do: query
  defp maybe_filter_consent_account(query, ""), do: query

  defp maybe_filter_consent_account(query, account_id) when is_binary(account_id) do
    where(query, [grant], grant.account_id == ^account_id)
  end

  defp maybe_filter_consent_client(query, nil), do: query
  defp maybe_filter_consent_client(query, ""), do: query

  defp maybe_filter_consent_client(query, client_id) when is_binary(client_id) do
    where(query, [grant], grant.client_id == ^client_id)
  end

  defp maybe_filter_consent_status(query, nil), do: query

  defp maybe_filter_consent_status(query, status) when status in [:active, :revoked] do
    where(query, [grant], grant.status == ^status)
  end

  defp maybe_filter_token_account(query, nil), do: query
  defp maybe_filter_token_account(query, ""), do: query

  defp maybe_filter_token_account(query, account_id) when is_binary(account_id) do
    where(query, [token], token.account_id == ^account_id)
  end

  defp maybe_filter_token_client(query, nil), do: query
  defp maybe_filter_token_client(query, ""), do: query

  defp maybe_filter_token_client(query, client_id) when is_binary(client_id) do
    where(query, [token], token.client_id == ^client_id)
  end

  defp maybe_filter_token_status(query, nil, _now), do: query

  defp maybe_filter_token_status(query, :active, now) do
    where(query, [token], is_nil(token.revoked_at) and token.expires_at > ^now)
  end

  defp maybe_filter_token_status(query, :revoked, _now) do
    where(query, [token], not is_nil(token.revoked_at))
  end

  defp maybe_filter_token_status(query, :expired, now) do
    where(query, [token], is_nil(token.revoked_at) and token.expires_at <= ^now)
  end

  defp maybe_filter_token_status(query, :reuse_detected, _now) do
    where(query, [token], not is_nil(token.reuse_detected_at))
  end

  defp maybe_filter_token_status(query, _status, _now), do: query

  defp maybe_filter_signing_key_status(query, nil), do: query

  defp maybe_filter_signing_key_status(query, status)
       when status in [:upcoming, :active, :retiring, :retired] do
    where(query, [key], key.status == ^status)
  end

  defp maybe_filter_signing_key_status(query, _status), do: query

  defp maybe_limit_clients(query, nil), do: query

  defp maybe_limit_clients(query, limit) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp maybe_limit_clients(query, _limit), do: query

  defp maybe_limit_consents(query, nil), do: query

  defp maybe_limit_consents(query, limit) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp maybe_limit_consents(query, _limit), do: query

  defp maybe_limit_tokens(query, nil), do: query

  defp maybe_limit_tokens(query, limit) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp maybe_limit_tokens(query, _limit), do: query

  defp locked_interaction_query(interaction_id) do
    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> lock("FOR UPDATE")
  end

  defp locked_refresh_token_query(token_hash) do
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :refresh_token)
    |> lock("FOR UPDATE")
  end

  defp locked_signing_key_query(id) do
    SigningKeyRecord
    |> where([key], key.id == ^id)
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

  defp rotate_refresh_token_record(
         %TokenRecord{} = record,
         client_id,
         rotated_at,
         %Token{} = refresh_token,
         %Token{} = access_token
       ) do
    now = DateTime.utc_now()

    cond do
      record.client_id != client_id ->
        {:error, :client_mismatch}

      is_nil(record.family_id) ->
        {:error, :missing_family_id}

      DateTime.compare(record.expires_at, rotated_at) != :gt ->
        {:error, :expired}

      not is_nil(record.redeemed_at) or not is_nil(record.revoked_at) ->
        with {:ok, _presented} <- mark_refresh_token_reuse(record, rotated_at, now),
             {:ok, _count} <- revoke_token_family_records(record.family_id, rotated_at, now) do
          {:error, :reuse_detected}
        else
          {:error, reason} -> repo().rollback(reason)
        end

      true ->
        with {:ok, presented_refresh_token} <- revoke_presented_refresh_token(record, rotated_at),
             {:ok, stored_refresh_token} <-
               store_rotated_refresh_token(record, refresh_token, rotated_at),
             {:ok, stored_access_token} <-
               store_rotated_access_token(record, stored_refresh_token, access_token, rotated_at) do
          {:ok,
           %{
             presented_refresh_token: presented_refresh_token,
             refresh_token: stored_refresh_token,
             access_token: stored_access_token
           }}
        else
          {:error, reason} -> repo().rollback(reason)
        end
    end
  end

  defp revoke_presented_refresh_token(%TokenRecord{} = record, rotated_at) do
    record
    |> Ecto.Changeset.change(
      redeemed_at: rotated_at,
      revoked_at: rotated_at,
      updated_at: DateTime.utc_now()
    )
    |> repo().update()
    |> map_one(&TokenRecord.to_domain/1)
  end

  defp mark_refresh_token_reuse(%TokenRecord{} = record, detected_at, updated_at) do
    record
    |> Ecto.Changeset.change(
      reuse_detected_at: record.reuse_detected_at || detected_at,
      updated_at: updated_at
    )
    |> repo().update()
    |> map_one(&TokenRecord.to_domain/1)
  end

  defp revoke_token_family_records(family_id, revoked_at, updated_at) do
    {count, _records} =
      TokenRecord
      |> where([token], token.family_id == ^family_id)
      |> repo().update_all(
        set: [revoked_at: revoked_at, updated_at: updated_at],
        inc: []
      )

    {:ok, count}
  rescue
    error -> {:error, error}
  end

  defp store_rotated_refresh_token(%TokenRecord{} = record, %Token{} = refresh_token, rotated_at) do
    %Token{
      refresh_token
      | family_id: record.family_id,
        generation: record.generation + 1,
        parent_token_id: record.id,
        client_id: record.client_id,
        account_id: refresh_token.account_id || record.account_id,
        interaction_id: refresh_token.interaction_id || record.interaction_id,
        scopes: if(refresh_token.scopes == [], do: record.scopes, else: refresh_token.scopes),
        audience:
          if(refresh_token.audience == [], do: record.audience, else: refresh_token.audience),
        issued_at: refresh_token.issued_at || rotated_at
    }
    |> store_token_record()
  end

  defp store_rotated_access_token(
         %TokenRecord{} = record,
         %Token{} = stored_refresh_token,
         %Token{} = access_token,
         rotated_at
       ) do
    %Token{
      access_token
      | family_id: record.family_id,
        generation: stored_refresh_token.generation,
        parent_token_id: stored_refresh_token.id,
        client_id: record.client_id,
        account_id: access_token.account_id || record.account_id,
        interaction_id: access_token.interaction_id || record.interaction_id,
        scopes: if(access_token.scopes == [], do: record.scopes, else: access_token.scopes),
        audience:
          if(access_token.audience == [], do: record.audience, else: access_token.audience),
        issued_at: access_token.issued_at || rotated_at
    }
    |> store_token_record()
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
