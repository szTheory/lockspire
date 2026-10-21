defmodule Lockspire.Storage.Ecto.Repository.InteractionStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.Interaction
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore

  @active_statuses InteractionRecord.active_statuses()

  @spec put_interaction(module(), Interaction.t()) :: {:ok, Interaction.t()} | {:error, term()}
  def put_interaction(repo, %Interaction{} = interaction) do
    %InteractionRecord{}
    |> InteractionRecord.changeset(interaction)
    |> then(
      &Support.insert(repo, &1,
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:interaction_id]
      )
    )
    |> map_one(&InteractionRecord.to_domain/1)
  end

  @spec fetch_interaction(module(), String.t()) :: {:ok, Interaction.t() | nil} | {:error, term()}
  def fetch_interaction(repo, interaction_id) when is_binary(interaction_id) do
    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> then(&Support.one(repo, &1))
    |> then(fn record -> {:ok, maybe_map(record, &InteractionRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec fetch_active_interaction(module(), String.t()) ::
          {:ok, Interaction.t() | nil} | {:error, term()}
  def fetch_active_interaction(repo, interaction_id) when is_binary(interaction_id) do
    now = DateTime.utc_now()

    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> where([interaction], interaction.status in ^@active_statuses)
    |> where([interaction], interaction.expires_at > ^now)
    |> then(&Support.one(repo, &1))
    |> then(fn record -> {:ok, maybe_map(record, &InteractionRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec list_interactions(module(), keyword()) :: {:ok, [Interaction.t()]} | {:error, term()}
  def list_interactions(repo, _opts \\ []) do
    InteractionRecord
    |> order_by(desc: :inserted_at)
    |> then(&Support.all(repo, &1))
    |> then(fn records -> {:ok, Enum.map(records, &InteractionRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec transition_interaction(
          module(),
          String.t(),
          [atom()],
          map() | (Interaction.t() -> {:ok, map()} | {:error, term()})
        ) ::
          {:ok, Interaction.t()} | {:error, term()}
  def transition_interaction(repo, interaction_id, expected_statuses, attrs)
      when is_binary(interaction_id) and is_list(expected_statuses) and
             (is_map(attrs) or is_function(attrs, 1)) do
    TransactionStore.transact(repo, fn ->
      interaction_id
      |> locked_query()
      |> then(&Support.one(repo, &1))
      |> transition_record(repo, expected_statuses, attrs)
    end)
  end

  defp locked_query(interaction_id) do
    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> lock("FOR UPDATE")
  end

  defp transition_record(nil, repo, _expected_statuses, _attrs),
    do: TransactionStore.rollback(repo, :not_found)

  defp transition_record(%InteractionRecord{} = record, repo, expected_statuses, attrs) do
    if record.status in expected_statuses do
      with {:ok, attrs} <- resolve_mutation(attrs, InteractionRecord.to_domain(record)),
           {:ok, updated} <-
             record
             |> InteractionRecord.update_changeset(
               Map.put(attrs, :updated_at, DateTime.utc_now())
             )
             |> then(&Support.update(repo, &1)) do
        {:ok, InteractionRecord.to_domain(updated)}
      else
        {:error, reason} -> TransactionStore.rollback(repo, reason)
      end
    else
      TransactionStore.rollback(repo, :invalid_state)
    end
  end

  defp resolve_mutation(attrs, _interaction) when is_map(attrs), do: {:ok, attrs}

  defp resolve_mutation(fun, %Interaction{} = interaction) when is_function(fun, 1) do
    case fun.(interaction) do
      {:ok, attrs} when is_map(attrs) -> {:ok, attrs}
      {:error, reason} -> {:error, reason}
      _other -> {:error, :invalid_transition_mutation}
    end
  rescue
    error -> {:error, error}
  end

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}
  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)
end
