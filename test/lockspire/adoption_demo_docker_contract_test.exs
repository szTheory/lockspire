defmodule Lockspire.AdoptionDemoDockerContractTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @compose_file "examples/adoption_demo/docker-compose.yml"
  @db_host_compose_file "examples/adoption_demo/docker-compose.db-host.yml"

  test "direct Compose uses a stable default project namespace" do
    with_compose_config(["-f", @compose_file], fn config ->
      assert config["name"] == "lockspire-adoption-demo"
      assert_volume_names(config, "lockspire-adoption-demo")
    end)
  end

  test "direct Compose project namespace remains configurable" do
    with_compose_config(
      ["--project-name", "lockspire-adoption-demo-alt", "-f", @compose_file],
      fn config ->
        assert config["name"] == "lockspire-adoption-demo-alt"
        assert_volume_names(config, "lockspire-adoption-demo-alt")
      end
    )
  end

  test "direct app port and browser-visible base URL stay aligned" do
    env = [
      {"LOCKSPIRE_DEMO_APP_PORT", "4101"},
      {"LOCKSPIRE_DEMO_BASE_URL", "http://127.0.0.1:4101"}
    ]

    with_compose_config(["-f", @compose_file], [env: env], fn config ->
      web = get_in(config, ["services", "web"])

      assert %{"published" => "4101", "target" => 4101} in web["ports"]
      assert env_value(web, "PORT") == "4101"
      assert env_value(web, "LOCKSPIRE_DEMO_BASE_URL") == "http://127.0.0.1:4101"
    end)
  end

  test "default database service remains internal-only" do
    with_compose_config(["-f", @compose_file], fn config ->
      db = get_in(config, ["services", "db"])

      refute Map.has_key?(db, "ports")
    end)
  end

  test "database host-port exposure is opt-in and keeps app DB wiring internal" do
    env = [{"LOCKSPIRE_DEMO_DB_HOST_PORT", "15432"}]

    with_compose_config(["-f", @compose_file, "-f", @db_host_compose_file], [env: env], fn config ->
      db = get_in(config, ["services", "db"])
      web = get_in(config, ["services", "web"])

      assert %{"published" => "15432", "target" => 5432} in db["ports"]
      assert env_value(web, "LOCKSPIRE_DEMO_DB_PORT") == "5432"
    end)
  end

  defp with_compose_config(args, opts \\ [], fun) do
    case compose_config(args, opts) do
      {:ok, config} ->
        fun.(config)

      :skip ->
        IO.puts("Skipping adoption demo Docker contract assertions: docker compose is unavailable")
    end
  end

  defp compose_config(args, opts) do
    env = Keyword.get(opts, :env, [])

    case System.cmd(
           "docker",
           ["compose"] ++ args ++ ["config", "--format", "json"],
           cd: @repo_root,
           env: env,
           stderr_to_stdout: true
         ) do
      {json, 0} ->
        {:ok, Jason.decode!(json)}

      {output, _status} ->
        raise output
    end
  rescue
    ErlangError -> :skip
  end

  defp assert_volume_names(config, project) do
    assert get_in(config, ["volumes", "db_data", "name"]) == "#{project}_db_data"
    assert get_in(config, ["volumes", "deps_volume", "name"]) == "#{project}_deps_volume"
    assert get_in(config, ["volumes", "build_volume", "name"]) == "#{project}_build_volume"
  end

  defp env_value(service, key) do
    service
    |> Map.fetch!("environment")
    |> case do
      values when is_list(values) ->
        values
        |> Enum.find_value(fn value ->
          case String.split(value, "=", parts: 2) do
            [^key, env_value] -> env_value
            _ -> nil
          end
        end)

      values when is_map(values) ->
        Map.fetch!(values, key)
    end
  end
end
