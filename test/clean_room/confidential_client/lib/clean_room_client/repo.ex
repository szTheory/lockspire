defmodule CleanRoomClient.Repo do
  use Ecto.Repo,
    otp_app: :clean_room_confidential_client,
    adapter: Ecto.Adapters.Postgres
end
