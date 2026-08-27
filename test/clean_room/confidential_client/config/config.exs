import Config

config :clean_room_confidential_client, ecto_repos: [CleanRoomClient.Repo]

config :clean_room_confidential_client, CleanRoomClient.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: 2

config :clean_room_confidential_client, :transaction_cipher_secret,
  System.get_env("CLEAN_ROOM_CLIENT_CIPHER_SECRET", "clean-room-client-ephemeral-secret-0123456789")
