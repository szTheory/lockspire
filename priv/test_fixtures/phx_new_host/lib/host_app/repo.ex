defmodule HostApp.Repo do
  use Ecto.Repo,
    otp_app: :host_app,
    adapter: Ecto.Adapters.Postgres
end
