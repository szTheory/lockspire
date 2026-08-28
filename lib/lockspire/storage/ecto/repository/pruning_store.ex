defmodule Lockspire.Storage.Ecto.Repository.PruningStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Storage.Ecto.Repository.Support

  @spec prune_expired_records(module(), module(), DateTime.t(), non_neg_integer()) ::
          non_neg_integer()
  def prune_expired_records(repo, schema, now \\ DateTime.utc_now(), count \\ 0) do
    ids =
      schema
      |> where([record], record.expires_at < ^now)
      |> select([record], record.id)
      |> limit(1000)
      |> then(&Support.all(repo, &1, log: false))

    if ids == [] do
      count
    else
      {deleted, _} =
        schema
        |> where([record], record.id in ^ids)
        |> then(&Support.delete_all(repo, &1, log: false))

      prune_expired_records(repo, schema, now, count + deleted)
    end
  end
end
