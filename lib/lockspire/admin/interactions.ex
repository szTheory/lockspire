defmodule Lockspire.Admin.Interactions do
  @moduledoc false

  alias Lockspire.Storage.Ecto.Repository

  @spec list_interactions(keyword()) ::
          {:ok, [Lockspire.Domain.Interaction.t()]} | {:error, term()}
  def list_interactions(opts \\ []), do: Repository.list_interactions(opts)
end
