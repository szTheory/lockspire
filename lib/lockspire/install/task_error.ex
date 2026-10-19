defmodule Lockspire.Install.TaskError do
  @moduledoc false

  # Shared failure handling for Lockspire Mix tasks that touch the host repo.
  #
  # `run/2` wraps `Lockspire.Install.RepoRunner.run/2`. RepoRunner converts anything raised inside
  # its fun into `{:error, :repo_unavailable}`, which would mislabel a database or config failure
  # as a repo start failure. `run/2` therefore classifies every exception, exit and throw raised
  # inside the fun into a fixed, safe phrase first, so `RepoRunner` only reports
  # `:repo_unavailable` when the repo itself did not start.
  #
  # Phrases never include the underlying exception text: Postgrex and DBConnection messages embed
  # SQL, host and port, and other ArgumentErrors can embed argument values. Only
  # Lockspire-authored config messages (they name config keys, never values) pass through.
  #
  # Nothing here prints or raises through Mix; callers print after `run/2` returns.

  alias Lockspire.Install.RepoRunner

  @repo_unavailable_phrase "could not start the repo; check database connectivity and config :lockspire, :repo"

  @unexpected_phrase "an unexpected error stopped the task; details are withheld to keep secrets out of the output; rerun the task, and if it fails again check the application logs"

  @config_message_prefixes [
    "missing Lockspire endpoint secret_key_base",
    "invalid :issuer for :lockspire.",
    "invalid :signing_alg for :lockspire.",
    "invalid config :key_encryption"
  ]

  @config_message_regex ~r/\Amissing required config :[a-z_]+ for :lockspire\./

  @spec repo_unavailable_phrase() :: String.t()
  def repo_unavailable_phrase, do: @repo_unavailable_phrase

  @spec unexpected_phrase() :: String.t()
  def unexpected_phrase, do: @unexpected_phrase

  @spec classify(term()) :: String.t()
  def classify({:error, inner}), do: classify(inner)
  def classify(:repo_unavailable), do: @repo_unavailable_phrase

  def classify(%Postgrex.Error{postgres: %{code: code}})
      when code in [:undefined_table, :undefined_column] do
    "the Lockspire tables are missing; run mix ecto.migrate, then rerun"
  end

  # Other Postgres codes (unique_violation, insufficient_privilege, ...) are not migration
  # problems, so no migrate advice here. The code name is a fixed atom, never message text.
  def classify(%Postgrex.Error{postgres: %{code: code}}) when is_atom(code) do
    "the database rejected the request (#{Atom.to_string(code)}); check the application logs"
  end

  def classify(%DBConnection.ConnectionError{reason: :queue_timeout}) do
    "the database connection pool timed out; rerun, and if it fails again check database load and config :lockspire, :repo"
  end

  def classify(%DBConnection.ConnectionError{}) do
    "could not reach the database or it timed out; check database connectivity and config :lockspire, :repo"
  end

  def classify(%ArgumentError{message: message}) when is_binary(message) do
    if lockspire_config_message?(message), do: message, else: @unexpected_phrase
  end

  def classify(_other), do: @unexpected_phrase

  @spec run(module(), (module() -> term())) :: {:ok, term()} | {:error, String.t()}
  def run(repo, fun) when is_atom(repo) and is_function(fun, 1) do
    case RepoRunner.run(repo, fn started_repo -> guarded(started_repo, fun) end) do
      {:ok, {:__task_error__, phrase}} -> {:error, phrase}
      {:ok, value} -> {:ok, value}
      {:error, :repo_unavailable} -> {:error, @repo_unavailable_phrase}
    end
  end

  # Raising the calling process's level to :warning drops its :debug and :info events, which is
  # where Ecto's query log (SQL and params, possibly sealed secret material) is emitted whether
  # the host sets `log: :debug` or `log: :info`. Limitation: this only covers events logged by
  # the calling process. Logs from the DBConnection and Postgrex connection processes (for
  # example an unreachable-database host:port error) are not covered; that is a documented
  # limitation, not something this guard can fix.
  defp guarded(repo, fun) do
    previous_level = Logger.get_process_level(self())
    Logger.put_process_level(self(), :warning)

    try do
      fun.(repo)
    rescue
      error -> {:__task_error__, classify(error)}
    catch
      _kind, _reason -> {:__task_error__, @unexpected_phrase}
    after
      restore_level(previous_level)
    end
  end

  defp restore_level(nil), do: Logger.delete_process_level(self())
  defp restore_level(level), do: Logger.put_process_level(self(), level)

  defp lockspire_config_message?(message) do
    Enum.any?(@config_message_prefixes, &String.starts_with?(message, &1)) or
      Regex.match?(@config_message_regex, message)
  end
end
