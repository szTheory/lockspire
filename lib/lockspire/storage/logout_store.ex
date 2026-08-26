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
  @callback fetch_logout_event_by_event_id(String.t()) ::
              {:ok, LogoutEvent.t() | nil} | {:error, store_error()}
  @callback list_all_logout_deliveries() ::
              {:ok, [LogoutDelivery.t()]} | {:error, store_error()}
  @callback list_logout_deliveries(integer()) ::
              {:ok, [LogoutDelivery.t()]} | {:error, store_error()}
  @callback mark_logout_delivery_enqueued(integer(), integer()) ::
              {:ok, LogoutDelivery.t()} | {:error, store_error()}
end
