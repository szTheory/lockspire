defmodule Lockspire.Admin.Logouts do
  @moduledoc false

  alias Lockspire.Storage.Ecto.Repository

  @spec list_logout_deliveries() ::
          {:ok, [Lockspire.Domain.LogoutDelivery.t()]} | {:error, term()}
  def list_logout_deliveries, do: Repository.list_all_logout_deliveries()
end
