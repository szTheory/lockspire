defmodule Lockspire.Web.JwksJSON do
  @moduledoc false

  @spec jwk_set(map()) :: map()
  def jwk_set(document) when is_map(document), do: document
end
