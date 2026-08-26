defmodule Lockspire.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using options do
    quote do
      use ExUnit.Case, unquote(options)
    end
  end

  setup tags do
    Lockspire.ConfigCase.preserve_lockspire_env!()

    repo = Lockspire.TestRepo

    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(repo, shared: not tags.async)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

    {:ok, repo: repo}
  end
end
