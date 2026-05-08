defmodule Lockspire.Test.Rar.PassthroughValidator do
  @moduledoc false

  def validate(detail, _ctx) when is_map(detail), do: {:ok, detail}
end
