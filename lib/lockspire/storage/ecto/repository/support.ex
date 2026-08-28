defmodule Lockspire.Storage.Ecto.Repository.Support do
  @moduledoc false

  @spec all(module(), Ecto.Queryable.t(), keyword()) :: [term()]
  def all(repo, query, opts \\ []), do: repo.all(query, repo_options(opts))

  @spec one(module(), Ecto.Queryable.t(), keyword()) :: term()
  def one(repo, query, opts \\ []), do: repo.one(query, repo_options(opts))

  @spec insert(module(), Ecto.Changeset.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def insert(repo, changeset, opts \\ []), do: repo.insert(changeset, repo_options(opts))

  @spec insert_all(module(), Ecto.Queryable.t(), [map()], keyword()) ::
          {non_neg_integer(), nil | [term()]}
  def insert_all(repo, schema_or_source, entries, opts),
    do: repo.insert_all(schema_or_source, entries, repo_options(opts))

  @spec update(module(), Ecto.Changeset.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def update(repo, changeset, opts \\ []), do: repo.update(changeset, repo_options(opts))

  @spec update_all(module(), Ecto.Queryable.t(), keyword(), keyword(), keyword()) ::
          {non_neg_integer(), nil | [term()]}
  def update_all(repo, query, updates, opts \\ [], keyword_opts \\ []),
    do: repo.update_all(query, Keyword.merge(updates, keyword_opts), repo_options(opts))

  @spec delete(module(), Ecto.Schema.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def delete(repo, record, opts \\ []), do: repo.delete(record, repo_options(opts))

  @spec delete_all(module(), Ecto.Queryable.t(), keyword()) :: {non_neg_integer(), nil | [term()]}
  def delete_all(repo, query, opts \\ []), do: repo.delete_all(query, repo_options(opts))

  @spec repo_options(keyword()) :: keyword()
  def repo_options(opts \\ []) do
    opts
    |> Keyword.drop([:sensitive])
    |> maybe_disable_sensitive_logging(opts)
    |> Keyword.merge(Lockspire.Storage.Ecto.Prefix.prefix_opts())
  end

  defp maybe_disable_sensitive_logging(options, opts) do
    if Keyword.get(opts, :sensitive, false), do: Keyword.put(options, :log, false), else: options
  end
end
