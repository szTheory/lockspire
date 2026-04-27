defmodule Lockspire.Web.DiscoveryJSON do
  @moduledoc false

  @spec openid_configuration(map()) :: map()
  def openid_configuration(document) when is_map(document), do: document
end
