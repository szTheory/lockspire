defmodule Mix.Tasks.Lockspire.Client.CreateColdTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  require Logger

  import Ecto.Query
  import Lockspire.MixRepoHelpers

  alias Lockspire.MixRepoHelpers.RaisingRepo
  alias Lockspire.Storage.Ecto.ClientRecord

  @task "lockspire.client.create"
  @prefix_root "mix-cold-create-"

  setup do
    assert_repo_stopped!()

    sweep_stale_cold_clients!()

    assert foreign_client_count() == 0,
           "the test database holds clients this test did not create; reset the committed test database"

    Mix.Task.reenable(@task)

    on_exit(fn ->
      Mix.Task.reenable(@task)
      cleanup_clients_by_prefix!(@prefix_root)
    end)

    {:ok, prefix: @prefix_root <> Base.url_encode64(:crypto.strong_rand_bytes(6), padding: false)}
  end

  defp args(client_id) do
    [
      "--client-type",
      "confidential",
      "--client-id",
      client_id,
      "--redirect-uri",
      "https://client.example.com/callback",
      "--scope",
      "profile",
      "--grant-type",
      "authorization_code"
    ]
  end

  defp fetch_row(client_id) do
    with_temp_repo(fn ->
      Lockspire.TestRepo.all(from(c in ClientRecord, where: c.client_id == ^client_id))
    end)
  end

  test "creates a confidential client with the repo stopped and prints the secret once",
       %{prefix: prefix} do
    client_id = prefix <> "-ok"

    {output, result} = run_task(@task, args(client_id))

    assert result == :ok
    assert output =~ "client_id=#{client_id}"
    assert length(String.split(output, "client_secret=")) - 1 == 1
    assert_repo_stopped!()

    assert [row] = fetch_row(client_id)
    refute output =~ row.client_secret_hash
  end

  test "a duplicate client id fails with a domain error and no secret", %{prefix: prefix} do
    client_id = prefix <> "-dup"

    assert {_output, :ok} = run_task(@task, args(client_id))
    assert_repo_stopped!()

    {output, result} = run_task(@task, args(client_id))

    refute output =~ "client_secret="
    assert {:error, %Mix.Error{message: message}} = result
    refute message =~ "could not start the repo"
    assert message =~ "  - client_id: has already been taken"
    assert length(fetch_row(client_id)) == 1
    assert_repo_stopped!()
  end

  test "an invalid redirect URI names the field and saves nothing", %{prefix: prefix} do
    client_id = prefix <> "-bad"

    args =
      List.replace_at(args(client_id), 5, "https://client.example.com/cb#frag")

    {output, result} = run_task(@task, args)

    refute output =~ "client_secret="
    assert {:error, %Mix.Error{message: message}} = result
    assert String.starts_with?(message, "client registration failed; nothing was saved:")
    assert message =~ "\n  - redirect_uris:"
    refute message =~ "could not start the repo"
    assert fetch_row(client_id) == []
    assert_repo_stopped!()
  end

  test "no options at all lists every problem and saves nothing" do
    {output, result} = run_task(@task, [])

    refute output =~ "client_secret="
    assert {:error, %Mix.Error{message: message}} = result
    assert String.starts_with?(message, "client registration failed; nothing was saved:")
    assert message =~ "\n  - "
    refute message =~ "could not start the repo"
    assert_repo_stopped!()
  end

  test "a repo that cannot start is reported as a repo start failure" do
    original = Application.get_env(:lockspire, :repo)
    Application.put_env(:lockspire, :repo, RaisingRepo)
    on_exit(fn -> Application.put_env(:lockspire, :repo, original) end)

    {output, result} = run_task(@task, args("mix-cold-create-raising"))

    refute output =~ "client_secret="
    assert {:error, %Mix.Error{message: message}} = result

    assert message ==
             "client registration failed: could not start the repo; check database connectivity and config :lockspire, :repo"
  end

  for ecto_level <- [:debug, :info] do
    test "#{ecto_level} query logs carry no insert statement or secret material",
         %{prefix: prefix} do
      ecto_level = unquote(ecto_level)
      client_id = prefix <> "-log-#{ecto_level}"
      original_repo_config = Application.get_env(:lockspire, Lockspire.TestRepo)
      original_level = Logger.level()

      Application.put_env(
        :lockspire,
        Lockspire.TestRepo,
        Keyword.put(original_repo_config, :log, ecto_level)
      )

      Logger.configure(level: :debug)

      on_exit(fn ->
        Application.put_env(:lockspire, Lockspire.TestRepo, original_repo_config)
        Logger.configure(level: original_level)
      end)

      log =
        ExUnit.CaptureLog.capture_log([level: :debug], fn ->
          Logger.debug("lockspire-log-control")
          {output, result} = run_task(@task, args(client_id))
          send(self(), {:run, output, result})
        end)

      assert_received {:run, output, :ok}
      Application.put_env(:lockspire, Lockspire.TestRepo, original_repo_config)
      Logger.configure(level: original_level)
      [_, secret] = Regex.run(~r/client_secret=(\S+)/, output)

      assert log =~ "lockspire-log-control"
      refute log =~ "INSERT"
      refute log =~ secret

      assert [row] = fetch_row(client_id)

      for value <- [row.client_secret_hash, Map.get(row, :client_secret_jwt_verifier_encrypted)],
          is_binary(value) do
        refute log =~ value
      end
    end
  end

  test "control: a harmless query is logged at debug when the logger is enabled", %{} do
    original_repo_config = Application.get_env(:lockspire, Lockspire.TestRepo)
    original_level = Logger.level()

    Application.put_env(
      :lockspire,
      Lockspire.TestRepo,
      Keyword.put(original_repo_config, :log, :debug)
    )

    Logger.configure(level: :debug)

    on_exit(fn ->
      Application.put_env(:lockspire, Lockspire.TestRepo, original_repo_config)
      Logger.configure(level: original_level)
    end)

    {:ok, _apps} = Application.ensure_all_started(:plug_crypto)

    log =
      ExUnit.CaptureLog.capture_log([level: :debug], fn ->
        with_temp_repo(fn ->
          assert %{rows: [[1]]} = Lockspire.TestRepo.query!("SELECT 1")
        end)
      end)

    Application.put_env(:lockspire, Lockspire.TestRepo, original_repo_config)
    Logger.configure(level: original_level)

    # Prove capture is active without issuing a second credential-bearing write.
    assert log =~ "SELECT 1"
  end

  test "a public client is created with the repo stopped and prints no secret", %{prefix: prefix} do
    client_id = prefix <> "-pub"

    args =
      args(client_id)
      |> List.replace_at(1, "public")

    {output, result} = run_task(@task, args)

    assert result == :ok
    assert output =~ "client_id=#{client_id}"
    refute output =~ "client_secret="
    assert length(fetch_row(client_id)) == 1
    assert_repo_stopped!()
  end
end
