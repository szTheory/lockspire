defmodule Lockspire.TestSupport.ClientVerifierMaintenanceConcurrency do
  @moduledoc false

  alias Ecto.Adapters.SQL.Sandbox

  def run(repo, parent, name, fun) when is_function(fun, 0) do
    Task.async(fn ->
      Sandbox.unboxed_run(repo, fn ->
        backend_pid = backend_pid(repo)
        send(parent, {:operation_ready, name, self(), backend_pid})
        result = fun.()
        send(parent, {:operation_done, name, result})
        result
      end)
    end)
  end

  def hold_transaction(repo, parent, name, fun) when is_function(fun, 0) do
    Task.async(fn ->
      Sandbox.unboxed_run(repo, fn ->
        backend_pid = backend_pid(repo)

        result =
          repo.transaction(fn ->
            send(parent, {:transaction_ready, name, self(), backend_pid})
            provisional = fun.()
            send(parent, {:transaction_provisional, name, provisional})

            receive do
              {:release_transaction, ^name, :commit} -> provisional
              {:release_transaction, ^name, {:rollback, reason}} -> repo.rollback(reason)
            after
              30_000 -> repo.rollback(:test_barrier_timeout)
            end
          end)

        send(parent, {:transaction_done, name, result})
        result
      end)
    end)
  end

  def wait_for_blocker(repo, contender_pid, blocker_pid, attempts \\ 100)
      when is_integer(contender_pid) and is_integer(blocker_pid) do
    blockers =
      Sandbox.unboxed_run(repo, fn ->
        %{rows: [[pids]]} =
          repo.query!("SELECT pg_blocking_pids($1)", [contender_pid],
            log: false,
            telemetry_event: nil
          )

        pids
      end)

    cond do
      blocker_pid in blockers ->
        {:ok, blockers}

      attempts > 0 ->
        Process.sleep(25)
        wait_for_blocker(repo, contender_pid, blocker_pid, attempts - 1)

      true ->
        {:error, blockers}
    end
  end

  def backend_pid(repo) do
    %{rows: [[pid]]} =
      repo.query!("SELECT pg_backend_pid()", [], log: false, telemetry_event: nil)

    pid
  end
end

defmodule Lockspire.TestSupport.UncertainVerifierTransactionStore do
  @moduledoc false

  @behaviour Lockspire.Storage.ClientStore
  @behaviour Lockspire.Storage.TransactionStore
  @behaviour Lockspire.Storage.ClientVerifierMaintenance

  alias Lockspire.Storage.Ecto.Repository

  def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

  def transaction_authority do
    authority = Repository.transaction_authority()

    %{
      authority
      | participants:
          authority.participants
          |> Map.put(:client_store, __MODULE__)
          |> Map.put(:transaction_store, __MODULE__)
    }
  end

  def verifier_maintenance_contract do
    {:ok,
     %{
       version: 1,
       transaction_authority: transaction_authority(),
       participants: %{
         client_store: __MODULE__,
         transaction_store: __MODULE__,
         audit_store: Repository
       }
     }}
  end

  def verifier_inventory_page(after_client_id, limit) do
    case Application.get_env(:lockspire, :test_verifier_inventory_page) do
      {:fixed, page} -> {:ok, page}
      _ -> Repository.verifier_inventory_page(after_client_id, limit)
    end
  end

  def compare_and_rewrap(client_id, hash, expected, replacement, audit),
    do: Repository.compare_and_rewrap(client_id, hash, expected, replacement, audit)

  def transact(fun) when is_function(fun, 0) do
    case Repository.transact(fun) do
      {:ok, :changed} -> {:error, :simulated_commit_response_lost}
      other -> other
    end
  end

  defdelegate rollback(reason), to: Repository
  defdelegate lock_clients(ids), to: Repository
  defdelegate register_client(client), to: Repository
  defdelegate list_clients(opts \\ []), to: Repository
  defdelegate fetch_client_by_id(client_id), to: Repository
  defdelegate get_client_by_registration_access_token_hash(hash), to: Repository

  defdelegate replace_client_registration(client, replacement, hash, audit),
    to: Repository

  defdelegate rotate_registration_access_token(client, hash, audit), to: Repository
  defdelegate rotate_client_secret(client, hash, verifier, rotated_at), to: Repository
  defdelegate set_client_active(client, active, attrs), to: Repository
  defdelegate update_client(client, attrs), to: Repository
end
