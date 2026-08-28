defmodule CleanRoomClientWeb.ErrorHTML do
  @moduledoc false

  # The acceptance client intentionally exposes no application error details.
  # Rendering the standard status phrase lets Phoenix preserve Plug's 403 CSRF
  # response instead of turning a missing template into a 500.
  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end
