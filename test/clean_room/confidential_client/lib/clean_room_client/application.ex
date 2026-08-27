defmodule CleanRoomClient.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link(
      [
        CleanRoomClient.Repo,
        {Phoenix.PubSub, name: CleanRoomClient.PubSub},
        CleanRoomClientWeb.Endpoint
      ],
      strategy: :one_for_one,
      name: CleanRoomClient.Supervisor
    )
  end
end
