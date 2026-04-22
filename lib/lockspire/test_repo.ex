defmodule Lockspire.TestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :lockspire,
    adapter: Ecto.Adapters.Postgres
end
