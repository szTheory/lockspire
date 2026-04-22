import Config

config :lockspire, Lockspire.TestRepo,
  username: System.get_env("LOCKSPIRE_TEST_DB_USER") || System.get_env("LOCKSPIRE_DB_USER") || System.get_env("PGUSER") || System.get_env("USER"),
  password: System.get_env("LOCKSPIRE_TEST_DB_PASSWORD") || System.get_env("LOCKSPIRE_DB_PASSWORD") || System.get_env("PGPASSWORD") || "",
  hostname: System.get_env("LOCKSPIRE_TEST_DB_HOST") || System.get_env("LOCKSPIRE_DB_HOST") || System.get_env("PGHOST") || "localhost",
  port: String.to_integer(System.get_env("LOCKSPIRE_TEST_DB_PORT") || System.get_env("LOCKSPIRE_DB_PORT") || System.get_env("PGPORT") || "5432"),
  database: System.get_env("LOCKSPIRE_TEST_DB_NAME") || "lockspire_test",
  priv: "priv/repo",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :lockspire,
  ecto_repos: [Lockspire.TestRepo],
  repo: Lockspire.TestRepo,
  account_resolver: Lockspire.TestAccountResolver,
  issuer: "https://example.test"
