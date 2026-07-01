defmodule Lockspire.AdoptionDemoDockerContractTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @compose_file "examples/adoption_demo/docker-compose.yml"
  @db_host_compose_file "examples/adoption_demo/docker-compose.db-host.yml"
  @traefik_compose_file "examples/adoption_demo/docker-compose.traefik.yml"
  @makefile_path Path.join(@repo_root, "Makefile")
  @admin_ui_path Path.join(@repo_root, "scripts/demo/admin-ui")
  @docker_info_path Path.join(@repo_root, "examples/adoption_demo/bin/docker-info")
  @docker_up_path Path.join(@repo_root, "examples/adoption_demo/bin/docker-up")
  @docker_reset_path Path.join(@repo_root, "examples/adoption_demo/bin/docker-reset")
  @docker_stop_path Path.join(@repo_root, "examples/adoption_demo/bin/docker-stop")
  @docker_cleanup_path Path.join(@repo_root, "examples/adoption_demo/bin/docker-cleanup")
  @dockerignore_path Path.join(@repo_root, ".dockerignore")
  @adoption_smoke_wrapper_path Path.join(@repo_root, "scripts/demo/adoption_smoke.sh")
  @adoption_demo_docs_path Path.join(@repo_root, "docs/adoption-demo.md")

  test "docker-info prints base URL derived startup links and exact smoke command" do
    output = docker_info_output("http://127.0.0.1:4101/")

    assert output =~ "Lockspire admin demo"
    assert output =~ "Adoption demo ready at http://127.0.0.1:4101"
    assert output =~ "Operator admin: http://127.0.0.1:4101/lockspire/admin"
    assert output =~ "Login: ops"
    assert output =~ "Smoke: make demo-smoke"
    assert output =~ "Info: make demo-info"
    assert output =~ "Logs: make demo-logs"
    assert output =~ "Stop: make demo-stop"
    assert output =~ "Base URL: http://127.0.0.1:4101"
    assert output =~ "Issuer: http://127.0.0.1:4101/lockspire"
    assert output =~ "Discovery: http://127.0.0.1:4101/lockspire/.well-known/openid-configuration"
    assert output =~ "JWKS: http://127.0.0.1:4101/lockspire/jwks"
    assert output =~ "Admin: http://127.0.0.1:4101/lockspire/admin"
    assert output =~ "Device verification: http://127.0.0.1:4101/verify"
    assert output =~ "Developer apps: http://127.0.0.1:4101/developer/apps"
    assert output =~ "OAuth callback: http://127.0.0.1:4101/oauth/callback"
    assert output =~ "Protected API: http://127.0.0.1:4101/api/billing/summary"

    assert output =~
             "LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 scripts/demo/adoption_smoke.sh"

    assert_ordered(output, [
      "Operator admin: http://127.0.0.1:4101/lockspire/admin",
      "Base URL: http://127.0.0.1:4101",
      "Issuer: http://127.0.0.1:4101/lockspire"
    ])

    refute output =~ "http://127.0.0.1:4101//"
    refute output =~ "python3 scripts/demo/adoption_smoke.py"
  end

  test "docker-info prints seeded account allowlist with operator account marked" do
    output = docker_info_output()

    assert output =~ "alice"
    assert output =~ "alice@acme.test"
    assert output =~ "bob"
    assert output =~ "bob@globex.test"
    assert output =~ "ops"
    assert output =~ "ops@acme.test"
    assert output =~ "operator account"
  end

  test "docker-info prints seeded client allowlist without sensitive material" do
    output = docker_info_output()
    source = File.read!(@docker_info_path)

    assert output =~ "acme-ledger-public"
    assert output =~ "public"
    assert output =~ "authorization_code,refresh_token"
    assert output =~ "none"
    assert output =~ "PKCE required"

    assert output =~ "acme-tv-device"
    assert output =~ "device_code"

    assert output =~ "acme-ledger-backend"
    assert output =~ "confidential"
    assert output =~ "client_secret_basic"

    assert output =~ "northstar-dcr-self-registered"
    assert output =~ "self-registered"
    assert output =~ "PAR required"
    assert output =~ "DPoP required"

    assert output =~ "legacy-disabled-reporter"
    assert output =~ "disabled"

    refute_sensitive_demo_material(output)
    refute_sensitive_demo_material(source)
  end

  test "docker-info prints canonical reprint command for running web service" do
    output = docker_info_output()
    source = File.read!(@docker_info_path)

    reprint_command =
      "docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info"

    project_reprint_command =
      "COMPOSE_PROJECT_NAME=lockspire-adoption-demo-alt docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info"

    assert output =~ "Reprint:"
    assert output =~ reprint_command
    assert output =~ project_reprint_command
    assert output =~ "examples/adoption_demo/bin/docker-up"
    assert output =~ "examples/adoption_demo/bin/docker-up --direct"
    assert output =~ "make demo"
    assert output =~ "make demo-smoke"
    assert output =~ "make demo-stop"
    assert output =~ "scripts/demo/admin-ui up"
    assert output =~ "scripts/demo/admin-ui smoke"
    assert output =~ "scripts/demo/admin-ui stop"
    assert source =~ reprint_command
    assert source =~ project_reprint_command
    assert source =~ "examples/adoption_demo/bin/docker-up"
    assert source =~ "scripts/demo/admin-ui up"

    refute output =~ "docker compose -f examples/adoption_demo/docker-compose.yml up"
    refute output =~ "docker compose -f examples/adoption_demo/docker-compose.yml run"
  end

  test "top-level Makefile exposes simple admin UI demo targets" do
    assert File.regular?(@makefile_path)

    source = File.read!(@makefile_path)

    for target <- [
          "demo:",
          "demo-info:",
          "demo-smoke:",
          "demo-logs:",
          "demo-stop:",
          "demo-reset:",
          "demo-clean:",
          "demo-clean-execute:"
        ] do
      assert source =~ target
    end

    assert source =~ "scripts/demo/admin-ui up"
    assert source =~ "scripts/demo/admin-ui smoke"
    assert source =~ "scripts/demo/admin-ui stop"
    refute source =~ "docker compose"
  end

  test "admin-ui wrapper owns simple detached lifecycle commands" do
    assert File.regular?(@admin_ui_path)
    assert executable?(@admin_ui_path)

    source = File.read!(@admin_ui_path)
    help = command_output(@admin_ui_path, ["--help"])

    for expected <- [
          "up",
          "info",
          "smoke",
          "logs",
          "stop",
          "reset",
          "cleanup",
          "status",
          "--project NAME"
        ] do
      assert source =~ expected
      assert help =~ expected
    end

    assert source =~ "examples/adoption_demo/bin/docker-up --project \"$project\" --detach"
    assert source =~ "scripts/demo/adoption_smoke.sh"
    assert source =~ "docker-reset --project \"$project\" --db-only"
    assert source =~ "docker-cleanup --project \"$project\""
    assert source =~ "label=com.docker.compose.project=${project}"
    refute source =~ "docker system prune"
    refute source =~ "docker volume prune"
  end

  test "docker-up launcher supports direct and Traefik startup modes" do
    assert File.regular?(@docker_up_path)
    assert executable?(@docker_up_path)

    source = File.read!(@docker_up_path)
    help = command_output(@docker_up_path, ["--help"])

    for expected <- [
          "--direct",
          "--traefik",
          "--project NAME",
          "--host HOST",
          "--port PORT",
          "--no-proxy-start",
          "--detach",
          "--print-command",
          "http://lockspire-demo.localhost"
        ] do
      assert source =~ expected
      assert help =~ expected
    end

    for expected <- [
          "LOCKSPIRE_DEMO_BASE_URL",
          "LOCKSPIRE_DEMO_TRAEFIK_HOST",
          "docker compose -f examples/adoption_demo/docker-compose.yml up --build",
          "docker compose -f examples/adoption_demo/docker-compose.yml up --build -d",
          "docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.traefik.yml up --build"
        ] do
      assert source =~ expected
    end

    assert source =~
             "docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.traefik.yml up --build -d"

    assert source =~ "docker network inspect \"$network\""
    assert source =~ "docker network create \"$network\""
    assert source =~ "tcp_port_has_listener"
    assert source =~ "lsof -nP -iTCP"
    assert source =~ "compatible_traefik_networks"
    assert source =~ "docker port \"$container\" 80/tcp"
    assert source =~ "--providers\\.docker"
    assert source =~ "Detected existing compatible Traefik proxy"
    assert source =~ "Multiple compatible Traefik proxy networks"
    assert source =~ "Cannot use --no-proxy-start"
    assert source =~ "wait_for_public_url"
    assert source =~ "print_running_info"
    assert source =~ "does not match the Traefik host"
    assert source =~ "Open after readiness:"
    assert source =~ "/lockspire/admin"
    assert source =~ "COMPOSE_PROJECT_NAME=${project} make demo-smoke"
    assert source =~ "COMPOSE_PROJECT_NAME=${project} make demo-stop"
    assert source =~ "scripts/demo/adoption_smoke.sh"
  end

  test "adoption smoke wrapper normalizes base URL and delegates to Python smoke" do
    assert File.regular?(@adoption_smoke_wrapper_path)
    assert executable?(@adoption_smoke_wrapper_path)

    source = File.read!(@adoption_smoke_wrapper_path)

    assert source =~ "http://127.0.0.1:4100"
    assert source =~ "BASE_URL="
    assert source =~ ~r/BASE_URL=.*LOCKSPIRE_DEMO_BASE_URL/
    assert source =~ ~r/BASE_URL=.*%\//
    assert source =~ "Running adoption demo smoke against ${BASE_URL}"
    assert source =~ ~r/LOCKSPIRE_DEMO_BASE_URL="?\$\{BASE_URL\}"?/
    assert source =~ "exec python3 scripts/demo/adoption_smoke.py"

    refute source =~ "lockspire-demo.localhost" <> "\n" <> "exec"
  end

  test "adoption smoke wrapper keeps OAuth proof logic in Python smoke" do
    source = File.read!(@adoption_smoke_wrapper_path)

    assert source =~ "scripts/demo/adoption_smoke.py"
    refute source =~ "oauth/callback"
    refute source =~ "code_verifier"
    refute source =~ "code_challenge"
    refute source =~ "SimpleCookie"
    refute source =~ "_csrf_token"
    refute source =~ "device_code"
    refute source =~ "user_code"
    refute source =~ "access_token"
    refute source =~ "id_token"
  end

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

      assert_port(web, "4101", 4101, "127.0.0.1")
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

    with_compose_config(
      ["-f", @compose_file, "-f", @db_host_compose_file],
      [env: env],
      fn config ->
        db = get_in(config, ["services", "db"])
        web = get_in(config, ["services", "web"])

        assert_port(db, "15432", 5432, "127.0.0.1")
        assert env_value(web, "LOCKSPIRE_DEMO_DB_PORT") == "5432"
      end
    )
  end

  test "direct Compose has no Traefik labels or external proxy dependency" do
    with_compose_config(["-f", @compose_file], fn config ->
      web = get_in(config, ["services", "web"])
      encoded_config = Jason.encode!(config)

      refute labels(web)
             |> Enum.any?(fn {key, _value} -> String.starts_with?(key, "traefik.") end)

      refute encoded_config =~ "traefik.enable"
      refute encoded_config =~ "traefik.http"
      refute encoded_config =~ "local-dev-proxy"
    end)
  end

  test "Traefik override renders configured hostname router service network and port labels" do
    env = traefik_env()

    with_compose_config(
      ["-f", @compose_file, "-f", @traefik_compose_file],
      [env: env],
      fn config ->
        web = get_in(config, ["services", "web"])

        assert label_value(web, "traefik.enable") == "true"
        assert label_value(web, "traefik.docker.network") == "lockspire-alt-proxy"

        assert label_value(web, "traefik.http.routers.lockspire-alt-router.rule") ==
                 "Host(`lockspire-alt.localhost`)"

        assert label_value(web, "traefik.http.routers.lockspire-alt-router.service") ==
                 "lockspire-alt-service"

        assert label_value(
                 web,
                 "traefik.http.services.lockspire-alt-service.loadbalancer.server.port"
               ) == "4102"

        refute Map.has_key?(web, "ports")
      end
    )
  end

  test "Traefik override attaches only web to the external proxy network" do
    env = traefik_env()

    with_compose_config(
      ["-f", @compose_file, "-f", @traefik_compose_file],
      [env: env],
      fn config ->
        web = get_in(config, ["services", "web"])
        db = get_in(config, ["services", "db"])

        assert get_in(config, ["networks", "traefik_proxy", "external"]) == true
        assert get_in(config, ["networks", "traefik_proxy", "name"]) == "lockspire-alt-proxy"
        assert "traefik_proxy" in service_network_keys(web)
        refute "traefik_proxy" in service_network_keys(db)
      end
    )
  end

  test "reset helper targets only the active demo project volumes" do
    source = File.read!(@docker_reset_path)

    assert source =~ "lockspire-adoption-demo"
    assert source =~ "COMPOSE_PROJECT_NAME"
    assert source =~ "--project"
    assert source =~ "--db-only"
    assert source =~ "--cache-only"
    assert source =~ "--all"
    assert source =~ ~r/docker compose .*--project-name "\$project".* down/

    volume_suffixes =
      ~r/\b(db_data|deps_volume|build_volume)\b/
      |> Regex.scan(source, capture: :all_but_first)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    assert volume_suffixes == ["build_volume", "db_data", "deps_volume"]
    assert source =~ "reset_db=1"
    assert source =~ "reset_cache=1"

    refute source =~ "docker volume prune"
    refute source =~ "docker system prune"
    refute source =~ "docker compose down -v"
    refute source =~ "adoption_demo_"
  end

  test "stop helper preserves active demo project volumes" do
    assert File.regular?(@docker_stop_path)
    assert executable?(@docker_stop_path)

    source = File.read!(@docker_stop_path)
    help = command_output(@docker_stop_path, ["--help"])

    assert source =~ "lockspire-adoption-demo"
    assert source =~ "COMPOSE_PROJECT_NAME"
    assert source =~ "--project"

    assert source =~
             ~r/docker compose .*--project-name "\$project".*-f examples\/adoption_demo\/docker-compose\.yml down/

    assert help =~ "--project NAME"
    assert help =~ "COMPOSE_PROJECT_NAME"
    assert help =~ "lockspire-adoption-demo"
    assert help =~ "preserve"
    assert help =~ "volumes"

    refute_broad_docker_cleanup(source)
    refute source =~ "docker volume rm"
    refute source =~ "adoption_demo_"
  end

  test "cleanup helper is dry-run first and exact allowlist scoped" do
    assert File.regular?(@docker_cleanup_path)
    assert executable?(@docker_cleanup_path)

    source = File.read!(@docker_cleanup_path)
    help = command_output(@docker_cleanup_path, ["--help"])

    for expected <- [
          "docker-cleanup",
          "--project",
          "--execute",
          "db_data",
          "deps_volume",
          "build_volume",
          "tmp/adoption_demo.log",
          "examples/adoption_demo/_build",
          "examples/adoption_demo/deps",
          "tmp/admin-ui-polish/"
        ] do
      assert source =~ expected
      assert help =~ expected
    end

    assert source =~ "COMPOSE_PROJECT_NAME"
    assert source =~ "lockspire-adoption-demo"
    assert source =~ ~r/execute=0/
    assert source =~ ~r/execute=1/
    assert source =~ ~r/\$\{project\}_db_data/
    assert source =~ ~r/\$\{project\}_deps_volume/
    assert source =~ ~r/\$\{project\}_build_volume/
    assert source =~ "com.docker.compose.project=${project}"
    assert source =~ "Refusing cleanup while project containers still exist"
    assert source =~ "removed_volumes=0"
    assert source =~ "removed_artifacts=0"
    assert help =~ "Dry run"
    assert help =~ "default"
    assert help =~ "Preserved"

    refute_broad_docker_cleanup(source)
    refute source =~ ~r/rm -rf "?tmp"?/
    refute source =~ ~r/rm -rf "?tmp\/"?/
    refute source =~ ~r/rm -rf .*admin-ui-polish/
    refute source =~ "adoption_demo_"
  end

  test "Docker build context excludes generated repo artifacts" do
    assert File.regular?(@dockerignore_path)

    dockerignore = File.read!(@dockerignore_path)

    for expected <- [
          ".git",
          "_build",
          "deps",
          "doc",
          "tmp",
          ".planning/research/.cache",
          "examples/adoption_demo/_build",
          "examples/adoption_demo/deps",
          "*.tar",
          "erl_crash.dump"
        ] do
      assert dockerignore =~ expected
    end
  end

  test "cleanup helper explicitly preserves admin UI polish evidence" do
    source = File.read!(@docker_cleanup_path)
    help = command_output(@docker_cleanup_path, ["--help"])

    assert source =~ "tmp/admin-ui-polish/"
    assert help =~ "tmp/admin-ui-polish/"
    assert source =~ ~r/(preserv|out of cleanup scope|not removed)/i
    assert help =~ ~r/(Preserved|out of cleanup scope|not removed)/i

    refute source =~ ~r/rm -rf .*tmp\/admin-ui-polish/
  end

  test "docker-start prints docker-info only after HTTP readiness" do
    source = File.read!(Path.join(@repo_root, "examples/adoption_demo/bin/docker-start"))

    assert source =~ ~r/wait_for_http\s+\.\/bin\/docker-info/
    refute source =~ ~r/seed_database\s+\.\/bin\/docker-info/
    refute source =~ ~r/create_database\s+\.\/bin\/docker-info/
  end

  test "docker-start uses container-local readiness separate from public base URL" do
    source = File.read!(Path.join(@repo_root, "examples/adoption_demo/bin/docker-start"))

    assert source =~ "READINESS_URL="
    assert source =~ "LOCKSPIRE_DEMO_READINESS_URL"
    assert source =~ "http://127.0.0.1:${PORT}"
    assert source =~ ~r/curl -fsS "\$\{READINESS_URL\}\/"/
    refute source =~ ~r/curl -fsS "\$\{BASE_URL\}\/"/
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
             "LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 scripts/demo/adoption_smoke.sh"
  end

  test "docs present Docker startup before host-local fallback" do
    docs = File.read!(@adoption_demo_docs_path)

    docker_position = docs_position!(docs, "## Quick Start")
    host_local_position = docs_position!(docs, "## Run It Host-Local")

    assert docker_position < host_local_position
    assert docs =~ "Docker is the default maintainer path"
    assert docs =~ "Host-local Mix/Postgres remains a fallback"
    assert docs =~ "make demo"
    assert docs =~ "examples/adoption_demo/bin/docker-up"
    assert docs =~ "docker compose -f examples/adoption_demo/docker-compose.yml up --build"
  end

  test "docs cover startup output reprint smoke stop reset cleanup and troubleshooting" do
    docs = File.read!(@adoption_demo_docs_path)

    assert docs =~ "## Startup Output"
    assert docs =~ "`LOCKSPIRE_DEMO_BASE_URL` is the single public URL truth"

    assert docs =~
             "docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info"

    assert docs =~
             "COMPOSE_PROJECT_NAME=lockspire-adoption-demo-alt docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info"

    assert docs =~ "If the demo was started with an alternate Compose project"
    assert docs =~ "LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 scripts/demo/adoption_smoke.sh"

    assert docs =~
             "LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost scripts/demo/adoption_smoke.sh"

    assert docs =~ "examples/adoption_demo/bin/docker-stop"
    assert docs =~ "examples/adoption_demo/bin/docker-reset"
    assert docs =~ "examples/adoption_demo/bin/docker-cleanup --execute"
    assert docs =~ "repo_hygiene_check.sh --ci"
    assert docs =~ "## Environment Overrides"
    assert docs =~ "LOCKSPIRE_DEMO_DB_HOST_PORT"
    assert docs =~ "LOCKSPIRE_DEMO_TRAEFIK_HOST"
    assert docs =~ "## Troubleshooting"
    assert docs =~ "Port Conflict"
    assert docs =~ "Readiness Failure"
    assert docs =~ "LOCKSPIRE_DEMO_READINESS_URL"
    assert docs =~ "`LOCKSPIRE_DEMO_BASE_URL` remains the public issuer/browser URL"
    assert docs =~ "Traefik Network"
    assert docs =~ "Base URL Drift"
  end

  test "docs present the final Phase 115 lifecycle command surface" do
    docs = File.read!(@adoption_demo_docs_path)

    lifecycle_commands = [
      "make demo",
      "make demo-smoke",
      "make demo-stop",
      "make demo-clean-execute",
      "./scripts/maintainer/repo_hygiene_check.sh --project lockspire-adoption-demo --skip-mix-ci"
    ]

    Enum.each(lifecycle_commands, fn command ->
      assert docs =~ command
    end)

    assert_ordered(docs, lifecycle_commands)
    assert docs =~ "start -> smoke -> stop -> cleanup -> hygiene"
    assert docs =~ "no demo-owned `BLOCK` findings"
    refute docs =~ "Phase 115 owns broader cleanup and hygiene commands"
  end

  test "docs align stop reset cleanup and hygiene semantics with scripts" do
    docs = File.read!(@adoption_demo_docs_path)

    assert docs =~ "examples/adoption_demo/bin/docker-stop"
    assert docs =~ "preserve"
    assert docs =~ "volumes"
    assert docs =~ "db_data"
    assert docs =~ "deps_volume"
    assert docs =~ "build_volume"
    assert docs =~ "--db-only"
    assert docs =~ "--cache-only"
    assert docs =~ "--all"
    assert docs =~ "Dry run"
    assert docs =~ "--execute"
    assert docs =~ "--project"
    assert docs =~ "COMPOSE_PROJECT_NAME"
    assert docs =~ "tmp/adoption_demo.log"
    assert docs =~ "examples/adoption_demo/_build"
    assert docs =~ "examples/adoption_demo/deps"
    assert docs =~ "tmp/admin-ui-polish/"
    assert docs =~ "preserved by default"
    assert docs =~ "does not delete broad `tmp/`"
    assert docs =~ "unrelated ignored files"
    assert docs =~ "unrelated Docker resources"
    assert docs =~ "host-wide Docker state"
    assert docs =~ "repo_hygiene_check.sh --ci"
    assert docs =~ "Running active-project demo containers"
    assert docs =~ "BLOCK"

    refute docs =~ "docker system prune"
    refute docs =~ "docker volume prune"
    refute docs =~ "docker compose down -v"
    refute docs =~ "docker compose down --volumes"
  end

  test "docs use wrapper and docker-info for Phase 114 proof commands" do
    docs = File.read!(@adoption_demo_docs_path)

    assert docs =~ "scripts/demo/adoption_smoke.sh"
    assert docs =~ "delegates to `scripts/demo/adoption_smoke.py`"
    assert docs =~ "examples/adoption_demo/bin/docker-info"

    refute docs =~
             "LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 python3 scripts/demo/adoption_smoke.py"

    refute docs =~
             "LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost python3 scripts/demo/adoption_smoke.py"
  end

  test "docs explain optional Traefik hostname routing and smoke base URL" do
    docs = File.read!(@adoption_demo_docs_path)

    assert docs =~ "docker network inspect \"${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}\""
    assert docs =~ "docker network create \"${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}\""
    assert docs =~ "tools/traefik/docker-compose.yml"
    assert docs =~ "examples/adoption_demo/docker-compose.traefik.yml"
    assert docs =~ "auto-reuses a compatible existing Docker Traefik"

    assert docs =~
             "LOCKSPIRE_DEMO_TRAEFIK_NETWORK=proxy examples/adoption_demo/bin/docker-up --no-proxy-start --host lockspire-demo.localhost"

    assert docs =~ "LOCKSPIRE_DEMO_TRAEFIK_HOST"
    assert docs =~ "LOCKSPIRE_DEMO_TRAEFIK_ROUTER"
    assert docs =~ "LOCKSPIRE_DEMO_TRAEFIK_SERVICE"
    assert docs =~ "LOCKSPIRE_DEMO_TRAEFIK_NETWORK"

    assert docs =~
             "LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost scripts/demo/adoption_smoke.sh"
  end

  defp docs_position!(docs, text) do
    case :binary.match(docs, text) do
      {position, _length} -> position
      :nomatch -> flunk("Expected docs to contain #{inspect(text)}")
    end
  end

  defp assert_ordered(text, ordered_fragments) do
    ordered_fragments
    |> Enum.map(&docs_position!(text, &1))
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.each(fn [left, right] -> assert left < right end)
  end

  defp with_compose_config(args, opts \\ [], fun) do
    case compose_config(args, opts) do
      {:ok, config} ->
        fun.(config)

      :skip ->
        IO.puts(
          "Skipping adoption demo Docker contract assertions: docker compose is unavailable"
        )
    end
  end

  defp docker_info_output(base_url \\ "http://127.0.0.1:4101/") do
    assert File.regular?(@docker_info_path)

    {output, 0} =
      System.cmd(
        @docker_info_path,
        [],
        cd: @repo_root,
        env: [{"LOCKSPIRE_DEMO_BASE_URL", base_url}],
        stderr_to_stdout: true
      )

    output
  end

  defp refute_sensitive_demo_material(text) do
    sensitive_fragments = [
      "demo-backend-secret",
      "demo-rat-secret",
      "demo-rat-northstar",
      "client_secret_hash",
      "registration_access_token_hash",
      "private_jwk",
      "private_jwk_encrypted",
      "authorization code material",
      "refresh token material",
      "access token material",
      "Set-Cookie",
      "cookie material"
    ]

    Enum.each(sensitive_fragments, fn fragment ->
      refute text =~ fragment
    end)
  end

  defp refute_broad_docker_cleanup(source) do
    refute source =~ "docker volume prune"
    refute source =~ "docker system prune"
    refute source =~ "docker compose down -v"
    refute source =~ "docker compose down --volumes"
    refute source =~ ~r/docker compose .* down .* -v/
    refute source =~ ~r/docker compose .* down .* --volumes/
  end

  defp command_output(path, args) do
    {output, 0} = System.cmd(path, args, cd: @repo_root, stderr_to_stdout: true)
    output
  end

  defp executable?(path) do
    path
    |> File.stat!()
    |> Map.fetch!(:mode)
    |> Bitwise.band(0o111)
    |> Kernel.!=(0)
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

  defp assert_port(service, published, target, host_ip) do
    assert Enum.any?(service["ports"], fn port ->
             port["published"] == published and
               port["target"] == target and
               port["host_ip"] == host_ip
           end)
  end

  defp labels(service) do
    service
    |> Map.get("labels", %{})
    |> case do
      values when is_list(values) ->
        Map.new(values, fn value ->
          [key, label_value] = String.split(value, "=", parts: 2)
          {key, label_value}
        end)

      values when is_map(values) ->
        values

      nil ->
        %{}
    end
  end

  defp label_value(service, key) do
    service
    |> labels()
    |> Map.fetch!(key)
  end

  defp service_network_keys(service) do
    service
    |> Map.get("networks", %{})
    |> case do
      values when is_list(values) -> values
      values when is_map(values) -> Map.keys(values)
      nil -> []
    end
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

  defp traefik_env do
    [
      {"LOCKSPIRE_DEMO_APP_PORT", "4102"},
      {"LOCKSPIRE_DEMO_BASE_URL", "http://lockspire-alt.localhost"},
      {"LOCKSPIRE_DEMO_TRAEFIK_HOST", "lockspire-alt.localhost"},
      {"LOCKSPIRE_DEMO_TRAEFIK_ROUTER", "lockspire-alt-router"},
      {"LOCKSPIRE_DEMO_TRAEFIK_SERVICE", "lockspire-alt-service"},
      {"LOCKSPIRE_DEMO_TRAEFIK_NETWORK", "lockspire-alt-proxy"}
    ]
  end
end
