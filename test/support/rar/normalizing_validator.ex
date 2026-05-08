defmodule Lockspire.Test.Rar.NormalizingValidator do
  @moduledoc false

  def validate(%{"type" => type, "actions" => actions}, _ctx)
      when is_binary(type) and is_list(actions) do
    {:ok, %{"type" => type, "actions" => actions, "validated" => true}}
  end

  def validate(_detail, _ctx), do: {:error, "invalid authorization details"}
end
