defmodule Lockspire.Web.ErrorView do
  @moduledoc """
  Minimal error view used by the test endpoint when a LiveView/controller
  pipeline raises during a test dispatch. Returns the standard HTTP status
  message (e.g. "Internal Server Error") so the underlying test failure is
  not masked by a missing-template error from `render_errors`.
  """

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
