defmodule Lockspire.Host.DefaultDenyTokenExchangeValidator do
  @moduledoc """
  Default implementation of the token exchange validator that denies all requests.
  """
  @behaviour Lockspire.Host.TokenExchangeValidator

  require Logger
  alias Lockspire.Host.TokenExchangeContext

  @impl true
  def validate(%TokenExchangeContext{} = context) do
    Logger.warning(
      "Token exchange requested by client #{context.client_id} but no validator is configured. Denying."
    )

    {:error, :exchange_not_configured}
  end
end
