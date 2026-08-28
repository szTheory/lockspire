defmodule CleanRoomProvider.Accounts do
  @moduledoc false

  def fetch(id) when is_binary(id) and id != "" do
    {:ok, %{id: id, email: "#{id}@provider.test", name: "Clean Room User"}}
  end

  def fetch(_id), do: {:error, :not_found}
end
