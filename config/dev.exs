import Config

config :lockspire, Lockspire.TestRepo,
  username:
    System.get_env("LOCKSPIRE_DB_USER") || System.get_env("PGUSER") || System.get_env("USER") ||
      "postgres",
  password: System.get_env("LOCKSPIRE_DB_PASSWORD") || System.get_env("PGPASSWORD") || "",
  hostname: System.get_env("LOCKSPIRE_DB_HOST") || System.get_env("PGHOST") || "localhost",
  port:
    String.to_integer(System.get_env("LOCKSPIRE_DB_PORT") || System.get_env("PGPORT") || "5432"),
  database: System.get_env("LOCKSPIRE_DB_NAME") || "lockspire_dev",
  priv: "priv/repo",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 5

config :lockspire,
  ecto_repos: [Lockspire.TestRepo],
  repo: Lockspire.TestRepo
