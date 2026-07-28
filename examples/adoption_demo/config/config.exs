import Config

config :adoption_demo,
  ecto_repos: [AdoptionDemo.Repo]

demo_base_url =
  "LOCKSPIRE_DEMO_BASE_URL"
  |> System.get_env("http://127.0.0.1:4100")
  |> String.trim()
  |> String.trim_trailing("/")

demo_uri = URI.parse(demo_base_url)

if demo_uri.scheme in [nil, ""] or demo_uri.host in [nil, ""] or
     demo_uri.query not in [nil, ""] or demo_uri.fragment not in [nil, ""] or
     demo_uri.path not in [nil, "", "/"] do
  raise ArgumentError,
        "LOCKSPIRE_DEMO_BASE_URL must be an absolute root URL without query or fragment"
end

config :adoption_demo, :demo_base_url, demo_base_url

demo_bind_ip =
  case System.get_env("LOCKSPIRE_DEMO_BIND_IP", "127.0.0.1") do
    "127.0.0.1" -> {127, 0, 0, 1}
    "0.0.0.0" -> {0, 0, 0, 0}
    other -> raise ArgumentError, "unsupported LOCKSPIRE_DEMO_BIND_IP=#{inspect(other)}"
  end

config :adoption_demo, AdoptionDemo.Repo,
  username:
    System.get_env("LOCKSPIRE_DEMO_DB_USER") || System.get_env("PGUSER") ||
      System.get_env("USER") || "postgres",
  password: System.get_env("LOCKSPIRE_DEMO_DB_PASSWORD") || System.get_env("PGPASSWORD") || "",
  hostname: System.get_env("LOCKSPIRE_DEMO_DB_HOST") || System.get_env("PGHOST") || "localhost",
  port:
    String.to_integer(
      System.get_env("LOCKSPIRE_DEMO_DB_PORT") || System.get_env("PGPORT") || "5432"
    ),
  database: System.get_env("LOCKSPIRE_DEMO_DB_NAME") || "lockspire_adoption_demo",
  priv: "priv/repo",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :adoption_demo, AdoptionDemoWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [
    ip: demo_bind_ip,
    port: String.to_integer(System.get_env("PORT") || "4100")
  ],
  url: [
    scheme: demo_uri.scheme,
    host: demo_uri.host,
    port: demo_uri.port
  ],
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      "a3e20c7a13116f2415ef29e0714cc5901d0d0ed48390b78781625d0ef4dbfd328ed05f017f89cc3c0eb579d9fb3af16b",
  server: true,
  render_errors: [formats: [html: AdoptionDemoWeb.ErrorHTML], layout: false],
  live_view: [signing_salt: "adoption_demo_live"]

config :lockspire,
  repo: AdoptionDemo.Repo,
  issuer: demo_base_url <> "/lockspire",
  mount_path: "/lockspire",
  storage_prefix: "lockspire",
  oban_prefix: "lockspire",
  known_scopes: ["openid", "email", "profile", "read:billing", "write:reports"],
  account_resolver: AdoptionDemo.Lockspire.AccountResolver,
  signing_alg: "RS256",
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      "a3e20c7a13116f2415ef29e0714cc5901d0d0ed48390b78781625d0ef4dbfd328ed05f017f89cc3c0eb579d9fb3af16b",
  oban: [queues: false, plugins: false]

config :phoenix, :json_library, Jason
