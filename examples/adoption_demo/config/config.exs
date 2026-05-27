import Config

config :adoption_demo,
  ecto_repos: [AdoptionDemo.Repo]

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
    ip: {127, 0, 0, 1},
    port: String.to_integer(System.get_env("PORT") || "4100")
  ],
  url: [
    scheme: "http",
    host: System.get_env("LOCKSPIRE_DEMO_HOST") || "127.0.0.1",
    port: String.to_integer(System.get_env("PORT") || "4100")
  ],
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      "a3e20c7a13116f2415ef29e0714cc5901d0d0ed48390b78781625d0ef4dbfd328ed05f017f89cc3c0eb579d9fb3af16b",
  server: true,
  live_view: [signing_salt: "adoption_demo_live"]

config :lockspire,
  repo: AdoptionDemo.Repo,
  issuer: "http://127.0.0.1:4100/lockspire",
  mount_path: "/lockspire",
  known_scopes: ["openid", "email", "profile", "read:billing", "write:reports"],
  account_resolver: AdoptionDemo.Lockspire.AccountResolver,
  signing_alg: "RS256",
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      "a3e20c7a13116f2415ef29e0714cc5901d0d0ed48390b78781625d0ef4dbfd328ed05f017f89cc3c0eb579d9fb3af16b",
  oban: [queues: false, plugins: false]

config :phoenix, :json_library, Jason
