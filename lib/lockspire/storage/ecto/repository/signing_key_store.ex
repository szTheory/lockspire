defmodule Lockspire.Storage.Ecto.Repository.SigningKeyStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository.{Support, TransactionStore}
  alias Lockspire.Storage.Ecto.SigningKeyRecord

  def publish_key(repo, %SigningKey{} = key) do
    %SigningKeyRecord{}
    |> SigningKeyRecord.changeset(key)
    |> then(
      &Support.insert(repo, &1,
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:kid]
      )
    )
    |> map_one()
  end

  def list_active_keys(repo) do
    SigningKeyRecord
    |> where([key], key.status in [:active, :retiring])
    |> order_by([key], asc: key.inserted_at)
    |> then(&Support.all(repo, &1))
    |> Enum.map(&(SigningKeyRecord.to_domain(&1) |> strip_private_key_material()))
    |> then(&{:ok, &1})
  rescue
    error -> {:error, error}
  end

  def list_signing_keys(repo, opts \\ []) when is_list(opts) do
    SigningKeyRecord
    |> maybe_filter_status(Keyword.get(opts, :status))
    |> order_by([key], desc: key.inserted_at, desc: key.id)
    |> then(&Support.all(repo, &1))
    |> Enum.map(&SigningKeyRecord.to_domain/1)
    |> then(&{:ok, &1})
  rescue
    error -> {:error, error}
  end

  def list_publishable_keys(repo, opts \\ []) when is_list(opts) do
    SigningKeyRecord
    |> where(
      [key],
      key.status in [:active, :retiring] or
        (key.status == :upcoming and not is_nil(key.published_at))
    )
    |> order_by([key], asc: key.inserted_at)
    |> then(&Support.all(repo, &1))
    |> Enum.map(&(SigningKeyRecord.to_domain(&1) |> strip_private_key_material()))
    |> filter_keys_for_security_profile(Keyword.get(opts, :security_profile, :none))
    |> then(&{:ok, &1})
  rescue
    error -> {:error, error}
  end

  def list_decryption_keys(repo) do
    SigningKeyRecord
    |> where([key], key.use == :enc)
    |> where([key], key.status in [:active, :retiring])
    |> order_by([key], asc: key.inserted_at)
    |> then(&Support.all(repo, &1))
    |> Enum.map(&SigningKeyRecord.to_domain/1)
    |> then(&{:ok, &1})
  rescue
    error -> {:error, error}
  end

  def validate_fapi_signing_readiness(repo), do: validate_message_signing_readiness(repo)

  def validate_message_signing_readiness(repo) do
    with {:publishable, {:ok, [_ | _]}} <-
           {:publishable, list_publishable_keys(repo, security_profile: :fapi_2_0_security)},
         {:active, {:ok, %SigningKey{}}} <-
           {:active, fetch_active_signing_key(repo, security_profile: :fapi_2_0_security)} do
      :ok
    else
      {:publishable, {:ok, []}} -> {:error, :missing_compliant_publishable_key}
      {:active, {:ok, nil}} -> {:error, :missing_compliant_active_key}
      {_, {:error, reason}} -> {:error, reason}
    end
  end

  def fetch_active_signing_key(repo, opts \\ []) when is_list(opts) do
    SigningKeyRecord
    |> where([key], key.status == :active)
    |> where([key], key.use == :sig)
    |> order_by([key], asc: key.inserted_at)
    |> then(&Support.all(repo, &1))
    |> Enum.map(&SigningKeyRecord.to_domain/1)
    |> filter_keys_for_security_profile(Keyword.get(opts, :security_profile, :none))
    |> filter_keys_for_alg(Keyword.get(opts, :alg))
    |> List.first()
    |> then(&{:ok, &1})
  rescue
    error -> {:error, error}
  end

  def fetch_signing_key_by_id(repo, id) when is_integer(id) do
    SigningKeyRecord
    |> where([key], key.id == ^id)
    |> then(&Support.one(repo, &1))
    |> then(&{:ok, maybe_map(&1)})
  rescue
    error -> {:error, error}
  end

  def publish_signing_key(repo, id, published_at)
      when is_integer(id) and is_struct(published_at, DateTime) do
    TransactionStore.transact(repo, fn ->
      case locked_key(repo, id) do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %SigningKeyRecord{status: :upcoming, published_at: nil} = record ->
          record
          |> SigningKeyRecord.update_changeset(%{published_at: published_at})
          |> update_one(repo)

        %SigningKeyRecord{status: :upcoming} ->
          TransactionStore.rollback(repo, :already_published)

        %SigningKeyRecord{} ->
          TransactionStore.rollback(repo, :invalid_state)
      end
    end)
  end

  def activate_signing_key(repo, id, activated_at)
      when is_integer(id) and is_struct(activated_at, DateTime) do
    TransactionStore.transact(repo, fn ->
      case locked_key(repo, id) do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %SigningKeyRecord{status: status} when status != :upcoming ->
          TransactionStore.rollback(repo, :invalid_state)

        %SigningKeyRecord{published_at: nil} ->
          TransactionStore.rollback(repo, :not_published)

        %SigningKeyRecord{} = selected ->
          activate_selected(repo, selected, activated_at)
      end
    end)
  end

  def retire_signing_key(repo, id, retired_at)
      when is_integer(id) and is_struct(retired_at, DateTime) do
    TransactionStore.transact(repo, fn ->
      case locked_key(repo, id) do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %SigningKeyRecord{status: :retiring} = record ->
          record
          |> SigningKeyRecord.update_changeset(%{status: :retired, retired_at: retired_at})
          |> update_one(repo)

        %SigningKeyRecord{status: :retired} ->
          TransactionStore.rollback(repo, :already_retired)

        %SigningKeyRecord{} ->
          TransactionStore.rollback(repo, :invalid_state)
      end
    end)
  end

  defp activate_selected(repo, selected, activated_at) do
    case active_keys_for_update(repo, selected.use) do
      [] ->
        %{activated_key: promote(repo, selected, activated_at), retiring_key: nil}

      [active] ->
        %{
          activated_key: promote(repo, selected, activated_at),
          retiring_key: retire_active(repo, active, activated_at)
        }

      _ ->
        TransactionStore.rollback(repo, :multiple_active_keys)
    end
  end

  defp locked_key(repo, id),
    do:
      SigningKeyRecord
      |> where([key], key.id == ^id)
      |> lock("FOR UPDATE")
      |> then(&Support.one(repo, &1))

  defp active_keys_for_update(repo, use),
    do:
      SigningKeyRecord
      |> where([key], key.status == :active and key.use == ^use)
      |> lock("FOR UPDATE")
      |> then(&Support.all(repo, &1))

  defp promote(repo, record, at),
    do:
      record
      |> SigningKeyRecord.update_changeset(%{
        status: :active,
        activated_at: at,
        retiring_at: nil,
        retired_at: nil
      })
      |> update_one(repo)

  defp retire_active(repo, record, at),
    do:
      record
      |> SigningKeyRecord.update_changeset(%{status: :retiring, retiring_at: at, retired_at: nil})
      |> update_one(repo)

  defp update_one(changeset, repo) do
    case Support.update(repo, changeset) do
      {:ok, record} -> SigningKeyRecord.to_domain(record)
      {:error, reason} -> TransactionStore.rollback(repo, reason)
    end
  end

  defp maybe_filter_status(query, nil), do: query

  defp maybe_filter_status(query, status)
       when status in [:upcoming, :active, :retiring, :retired],
       do: where(query, [key], key.status == ^status)

  defp maybe_filter_status(query, _status), do: query
  defp filter_keys_for_alg(keys, nil), do: keys
  defp filter_keys_for_alg(keys, alg) when is_binary(alg), do: Enum.filter(keys, &(&1.alg == alg))

  defp filter_keys_for_security_profile(keys, :fapi_2_0_security) do
    allowed_algs = SecurityProfile.allowed_signing_algorithms(:fapi_2_0_security)

    Enum.filter(keys, fn %SigningKey{alg: alg, use: use} = key ->
      use == :sig and alg in allowed_algs and
        Policy.validate_key_compliance(key, :fapi_2_0_security) == :ok
    end)
  end

  defp filter_keys_for_security_profile(keys, _profile), do: keys
  defp map_one({:ok, record}), do: {:ok, SigningKeyRecord.to_domain(record)}
  defp map_one({:error, error}), do: {:error, error}
  defp maybe_map(nil), do: nil
  defp maybe_map(record), do: SigningKeyRecord.to_domain(record)

  defp strip_private_key_material(%SigningKey{} = key),
    do: %SigningKey{key | private_jwk_encrypted: nil}
end
