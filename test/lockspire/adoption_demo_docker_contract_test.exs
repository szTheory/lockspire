defmodule Lockspire.AdoptionDemoDockerContractTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @compose_file "examples/adoption_demo/docker-compose.yml"
  @db_host_compose_file "examples/adoption_demo/docker-compose.db-host.yml"
  @docker_reset_path Path.join(@repo_root, "examples/adoption_demo/bin/docker-reset")
  @adoption_demo_docs_path Path.join(@repo_root, "docs/adoption-demo.md")

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

      assert_port(web, "4101", 4101)
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

      assert_port(db, "15432", 5432)
      assert env_value(web, "LOCKSPIRE_DEMO_DB_PORT") == "5432"
    end)
  end

  test "reset helper targets only the active demo project volumes" do
    source = File.read!(@docker_reset_path)

    assert source =~ "lockspire-adoption-demo"
    assert source =~ "COMPOSE_PROJECT_NAME"
    assert source =~ "--project"
    assert source =~ ~r/docker compose .*--project-name "\$project".* down/

    volume_suffixes =
      ~r/\b(db_data|deps_volume|build_volume)\b/
      |> Regex.scan(source, capture: :all_but_first)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    assert volume_suffixes == ["build_volume", "db_data", "deps_volume"]

    refute source =~ "docker volume prune"
    refute source =~ "docker system prune"
    refute source =~ "docker compose down -v"
    refute source =~ "adoption_demo_"
  end

  test "docs explain direct conflict controls and scoped reset" do
    docs = File.read!(@adoption_demo_docs_path)

    assert docs =~ "COMPOSE_PROJECT_NAME"
    assert docs =~ "LOCKSPIRE_DEMO_APP_PORT"
    assert docs =~ "LOCKSPIRE_DEMO_BASE_URL"
    assert docs =~ "examples/adoption_demo/docker-compose.db-host.yml"
    assert docs =~ "LOCKSPIRE_DEMO_DB_HOST_PORT"
    assert docs =~ "examples/adoption_demo/bin/docker-reset"
    assert docs =~
             "LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 python3 scripts/demo/adoption_smoke.py"
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

  defp assert_port(service, published, target) do
    assert Enum.any?(service["ports"], fn port ->
             port["published"] == published and port["target"] == target
           end)
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
