defmodule Mix.Tasks.Lockspire.Clients.Verifier.RewrapOperationContextTest do
  use ExUnit.Case, async: false

  @moduletag :operation_context

  @tag :operation_context_api
  test "bare config resolves signing and endpoint exclusions without starting Lockspire" do
    assert {:module, Lockspire.Security.ClientSecretVerifier.OperationContext} =
             Code.ensure_loaded(Lockspire.Security.ClientSecretVerifier.OperationContext)

    assert function_exported?(
             Lockspire.Security.ClientSecretVerifier.OperationContext,
             :resolve,
             0
           )

    verifier_key = :crypto.hash(:sha256, "task-local-verifier-key")
    signing_key = :crypto.hash(:sha256, "task-local-signing-key")
    endpoint_secret = "endpoint secret sentinel"

    script = """
    verifier_key = Base.decode64!(#{inspect(Base.encode64(verifier_key))})
    signing_key = Base.decode64!(#{inspect(Base.encode64(signing_key))})
    endpoint_secret = #{inspect(endpoint_secret)}
    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier,
      keys: [{"verifier", Base.url_encode64(verifier_key, padding: false)}],
      current: "verifier", write_mode: :dedicated, legacy_read: :allow)
    Application.put_env(:lockspire, :key_encryption,
      keys: [{"signing", {:system, "LOCKSPIRE_TASK_SIGNING_KEY"}}], current: "signing")
    Application.put_env(:lockspire, Lockspire.Web.Endpoint, secret_key_base: endpoint_secret)
    before_context = :persistent_term.get(Lockspire.Config.client_secret_verifier_cache_key(), :missing)
    before_signing = :persistent_term.get(Lockspire.Config.key_encryption_cache_key(), :missing)
    result = Lockspire.Security.ClientSecretVerifier.OperationContext.resolve()
    after_context = :persistent_term.get(Lockspire.Config.client_secret_verifier_cache_key(), :missing)
    after_signing = :persistent_term.get(Lockspire.Config.key_encryption_cache_key(), :missing)
    case result do
      {:ok, context} ->
        IO.puts("RESOLVED=\#{context.state == :valid and signing_key in context.forbidden_key_bytes and endpoint_secret in context.forbidden_key_bytes}")
      _ -> IO.puts("RESOLVED=false")
    end
    IO.puts("UNCHANGED=\#{before_context == after_context and before_signing == after_signing}")
    IO.puts("SUPERVISOR=\#{is_pid(Process.whereis(Lockspire.Supervisor))}")
    """

    {output, status} = run_bare(script, "LOCKSPIRE_TASK_SIGNING_KEY", Base.encode64(signing_key))

    assert status == 0, output
    assert output =~ "RESOLVED=true"
    assert output =~ "UNCHANGED=true"
    assert output =~ "SUPERVISOR=false"
  end

  test "bare config rejects signing key reuse without exposing key bytes" do
    reused_key = :crypto.hash(:sha256, "purpose-reuse-sentinel")

    script = """
    key = Base.decode64!(#{inspect(Base.encode64(reused_key))})
    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier,
      keys: [{"verifier", Base.url_encode64(key, padding: false)}],
      current: "verifier", write_mode: :dedicated, legacy_read: :allow)
    Application.put_env(:lockspire, :key_encryption,
      keys: [{"signing", {:system, "LOCKSPIRE_TASK_SIGNING_KEY"}}], current: "signing")
    IO.inspect(Lockspire.Security.ClientSecretVerifier.OperationContext.resolve(), label: "RESULT")
    """

    {output, status} = run_bare(script, "LOCKSPIRE_TASK_SIGNING_KEY", Base.encode64(reused_key))

    assert status == 0, output
    assert output =~ "client_secret_verifier_configuration_invalid"
    refute output =~ Base.encode64(reused_key)
  end

  test "bare config fails closed when a signing system environment entry is invalid" do
    verifier_key = :crypto.hash(:sha256, "valid-verifier-key")
    signing_key = :crypto.hash(:sha256, "signing-invalid-env-sentinel")

    script = """
    verifier_key = Base.decode64!(#{inspect(Base.encode64(verifier_key))})
    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier,
      keys: [{"verifier", Base.url_encode64(verifier_key, padding: false)}],
      current: "verifier", write_mode: :dedicated, legacy_read: :allow)
    Application.put_env(:lockspire, :key_encryption,
      keys: [{"signing", {:system, "LOCKSPIRE_TASK_MISSING_SIGNING_KEY"}}], current: "signing")
    IO.inspect(Lockspire.Security.ClientSecretVerifier.OperationContext.resolve(), label: "RESULT")
    """

    {output, status} = run_bare(script, "LOCKSPIRE_TASK_UNUSED", Base.encode64(signing_key))

    assert status == 0, output
    assert output =~ "client_secret_verifier_configuration_invalid"
    refute output =~ Base.encode64(signing_key)
  end

  defp run_bare(script, variable, value) do
    System.cmd("mix", ["run", "--no-start", "-e", script],
      env: [{variable, value}, {"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
  end
end

defmodule Mix.Tasks.Lockspire.Clients.Verifier.RewrapCLITest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Domain.Client
  alias Lockspire.MixRepoHelpers
  alias Lockspire.Storage.Ecto.Repository

  @task "lockspire.clients.verifier.rewrap"

  setup do
    Mix.Task.reenable(@task)
    on_exit(fn -> Mix.Task.reenable(@task) end)
    :ok
  end

  @tag :cli_api
  test "verifier maintenance has a dedicated Mix task" do
    assert {:module, Mix.Tasks.Lockspire.Clients.Verifier.Rewrap} =
             Code.ensure_loaded(Mix.Tasks.Lockspire.Clients.Verifier.Rewrap)
  end

  for {args, expected} <- [
        {["--unknown"], "invalid arguments for mix lockspire.clients.verifier.rewrap"},
        {["positional"], "invalid arguments for mix lockspire.clients.verifier.rewrap"},
        {["--check", "--dry-run"], "--check and --dry-run cannot be combined"},
        {["--check", "--after-client-id", "cursor"],
         "--check requires a fresh scan and cannot use --after-client-id"},
        {["--dry-run", "--dry-run"], "duplicate options are not allowed"},
        {["--limit", "0"], "--limit must be an integer from 1 through 500"},
        {["--limit", "not-a-number"],
         "invalid arguments for mix lockspire.clients.verifier.rewrap"}
      ] do
    test "#{inspect(args)} is rejected before database work" do
      error = assert_raise Mix.Error, fn -> Mix.Task.run(@task, unquote(args)) end

      assert error.message == unquote(expected)
      refute Process.whereis(Lockspire.TestRepo)
    end
  end

  test "invalid argument errors never echo hostile values" do
    hostile = "SECRET\n--check\n"

    error =
      assert_raise Mix.Error, fn ->
        Mix.Task.run(@task, ["--after-client-id", hostile, "--check"])
      end

    refute error.message =~ hostile
    refute error.message =~ "SECRET"
    refute Process.whereis(Lockspire.TestRepo)
  end

  test "help describes bare Mix, release RPC, modes, and safe progress options" do
    output = capture_io(fn -> Mix.Task.run(@task, ["--help"]) end)

    assert output =~ "mix lockspire.clients.verifier.rewrap"
    assert output =~ "--dry-run"
    assert output =~ "--check"
    assert output =~ "--after-client-id"
    assert output =~ "bin/app rpc"
    assert output =~ "startup"
    refute Process.whereis(Lockspire.TestRepo)
  end

  @tag :integration
  test "bare task previews, applies, and checks while stopping only its temporary Repo" do
    refute Process.whereis(Lockspire.TestRepo)

    prefix = "mix-verifier-rewrap-#{System.unique_integer([:positive])}-"
    client_id = prefix <> "client"
    old_key = :crypto.hash(:sha256, "mix task old verifier key")
    current_key = :crypto.hash(:sha256, "mix task current verifier key")
    old_encoded = Base.encode64(old_key)
    current_encoded = Base.encode64(current_key)

    verifier_config = [
      keys: [{"old-task", old_encoded}, {"current-task", current_encoded}],
      current: "current-task",
      write_mode: :dedicated,
      legacy_read: :allow
    ]

    previous_repo = Application.fetch_env(:lockspire, :repo)
    previous_client_store = Application.fetch_env(:lockspire, :client_store)
    previous_transaction_store = Application.fetch_env(:lockspire, :transaction_store)

    previous_verifier_config =
      Application.fetch_env(:lockspire, Lockspire.Security.ClientSecretVerifier)

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :client_store, Repository)
    Application.put_env(:lockspire, :transaction_store, Repository)
    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier, verifier_config)

    on_exit(fn ->
      MixRepoHelpers.cleanup_clients_by_prefix!(prefix)
      restore_env(:repo, previous_repo)
      restore_env(:client_store, previous_client_store)
      restore_env(:transaction_store, previous_transaction_store)
      restore_env(Lockspire.Security.ClientSecretVerifier, previous_verifier_config)
    end)

    {:ok, old_context} =
      Lockspire.Security.ClientSecretVerifier.Context.resolve(
        {:present,
         [
           keys: [{"old-task", old_encoded}],
           current: "old-task",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {hash, secret} = Lockspire.Clients.rotate_secret_hash()

    {:ok, verifier} =
      Lockspire.Security.ClientSecretVerifier.seal(old_context, client_id, secret)

    assert {:ok, %Client{}} =
             MixRepoHelpers.with_temp_repo(fn ->
               Repository.register_client(secret_client(client_id, hash, verifier))
             end)

    assert Process.whereis(Lockspire.TestRepo) == nil
    assert {preview_output, :ok} = run_task(["--dry-run"])
    assert preview_output =~ "context_source=task_local"
    assert preview_output =~ "mode=dry_run"
    assert preview_output =~ "pending=1"
    assert Process.whereis(Lockspire.TestRepo) == nil

    assert {apply_output, :ok} = run_task([])
    assert apply_output =~ "mode=apply context_source=task_local"
    assert apply_output =~ "committed_changed=1"
    assert apply_output =~ "separate fresh --check"
    assert Process.whereis(Lockspire.TestRepo) == nil

    assert {check_output, :ok} = run_task(["--check"])
    assert check_output =~ "mode=check context_source=task_local"
    assert check_output =~ "custody_condition_met=true"
    assert Process.whereis(Lockspire.TestRepo) == nil

    {:ok, persisted} =
      MixRepoHelpers.with_temp_repo(fn -> Repository.fetch_client_by_id(client_id) end)

    {:ok, task_context} =
      Lockspire.Security.ClientSecretVerifier.OperationContext.resolve()

    assert {:ok, %{key_id: "current-task", authenticated?: true}} =
             Lockspire.Security.ClientSecretVerifier.inspect_custody(
               task_context,
               client_id,
               persisted.client_secret_jwt_verifier_encrypted,
               persisted.client_secret_hash,
               []
             )

    {:ok, running_repo_pid} = Lockspire.TestRepo.start_link()
    running_pool_pid = Ecto.Adapter.lookup_meta(Lockspire.TestRepo).pid

    try do
      assert {warm_output, :ok} = run_task(["--check"])
      assert warm_output =~ "custody_condition_met=true"
      assert Process.whereis(Lockspire.TestRepo) == running_repo_pid
      assert Ecto.Adapter.lookup_meta(Lockspire.TestRepo).pid == running_pool_pid
    after
      GenServer.stop(running_repo_pid)
    end

    assert {:ok, %Client{}} =
             MixRepoHelpers.with_temp_repo(fn ->
               Repository.register_client(
                 secret_client(client_id <> "-orphan", nil, "do-not-display-sentinel")
               )
             end)

    assert {failed_output, {:error, %Mix.Error{message: failure_message}}} =
             run_task(["--check"])

    assert failure_message =~ "--check failed"
    assert failed_output =~ "classification=orphan_verifier"
    refute failed_output =~ "do-not-display-sentinel"
    assert Process.whereis(Lockspire.TestRepo) == nil
  end

  defp run_task(args) do
    Mix.Task.reenable(@task)
    test_pid = self()

    output =
      capture_io(fn ->
        result =
          try do
            Mix.Task.run(@task, args)
            :ok
          rescue
            error in Mix.Error -> {:error, error}
          end

        send(test_pid, {:task_result, result})
      end)

    assert_received {:task_result, result}
    {output, result}
  end

  defp secret_client(client_id, hash, verifier) do
    %Client{
      lifetime_version: 0,
      client_id: client_id,
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: :confidential,
      name: "Verifier maintenance task client",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now()
    }
  end

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)
end
