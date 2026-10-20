defmodule Lockspire.Install.RepoRunner do
  @moduledoc false

  # Runs a function against the host repo from a Mix task or a verification call. This covers
  # reads and the client.create write.
  #
  # When the repo is already running the function is called directly. `Ecto.Migrator.with_repo/3`
  # restarts the pool of a repo that is already running, which would break a live node, so it is
  # only used when no process holds the repo name. Startup failures never raise and never expose
  # the underlying exception, which can carry connection details.
  #
  # `{:error, :repo_unavailable}` means only that the repo could not start. Mix tasks wrap their
  # work with `Lockspire.Install.TaskError.run/2`, which turns exceptions, exits and throws raised
  # by the work into fixed phrases first.

  @spec run(module(), (module() -> result)) :: {:ok, result} | {:error, :repo_unavailable}
        when result: term()
  def run(repo, fun) when is_atom(repo) and is_function(fun, 1) do
    if is_pid(Process.whereis(repo)) do
      {:ok, fun.(repo)}
    else
      start_and_run(repo, fun)
    end
  rescue
    _error -> {:error, :repo_unavailable}
  catch
    _kind, _reason -> {:error, :repo_unavailable}
  end

  defp start_and_run(repo, fun) do
    {:ok, _apps} = Application.ensure_all_started(:ecto_sql)

    case Ecto.Migrator.with_repo(repo, fun, mode: :temporary) do
      {:ok, result, _apps} -> {:ok, result}
      {:error, _reason} -> {:error, :repo_unavailable}
    end
  end
end
