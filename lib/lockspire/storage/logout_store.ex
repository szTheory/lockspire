defmodule Lockspire.Storage.LogoutStore do
  @moduledoc """
  Domain-level persistence contract for durable logout propagation state.
  """

  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent

  @type store_error :: term()

  @callback persist_logout_propagation(LogoutEvent.t()) ::
              {:ok, %{event: LogoutEvent.t(), deliveries: [LogoutDelivery.t()]}}
              | {:error, store_error()}
end
