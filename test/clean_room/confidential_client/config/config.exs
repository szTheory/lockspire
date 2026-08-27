import Config

config :clean_room_confidential_client, ecto_repos: [CleanRoomClient.Repo]

config :clean_room_confidential_client, CleanRoomClient.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: 2

config :clean_room_confidential_client,
       :transaction_cipher_secret,
       System.get_env(
         "CLEAN_ROOM_CLIENT_CIPHER_SECRET",
         "clean-room-client-ephemeral-secret-0123456789"
       )

config :clean_room_confidential_client,
       :provider_issuer,
       System.get_env("CLEAN_ROOM_PROVIDER_ISSUER", "http://127.0.0.1:4100/lockspire")

config :clean_room_confidential_client,
       :client_origin,
       System.get_env("CLEAN_ROOM_CLIENT_ORIGIN", "http://127.0.0.1:4101")

config :clean_room_confidential_client, CleanRoomClientWeb.Endpoint,
  url: [host: "127.0.0.1"],
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "4101"))],
  secret_key_base:
    System.get_env(
      "SECRET_KEY_BASE",
      "clean-room-client-secret-key-base-0123456789-abcdefghijklmnopqrstuvwxyz-0123456789"
    ),
  server: true
