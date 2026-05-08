defmodule Lockspire.ErrorView do
  @moduledoc """
  Minimal error view used by the Lockspire endpoint when a controller or LiveView
  raises during dispatch.

  Rendering a plain HTTP status phrase keeps the underlying failure visible in
  tests and avoids a secondary missing-template crash.
  """

  @spec render(binary(), map()) :: String.t()
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
