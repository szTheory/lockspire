defmodule Lockspire.Web.AuthorizeHTML do
  @moduledoc """
  First-party HTML rendering for unsafe authorization errors.
  """

  alias Lockspire.Protocol.AuthorizationRequest.Error

  def error_page(%Error{} = error) do
    description = Plug.HTML.html_escape_to_iodata(error.error_description)
    reason = Plug.HTML.html_escape_to_iodata(to_string(error.reason_code))

    [
      "<!doctype html><html><head><meta charset=\"utf-8\"><title>Authorization Error</title></head><body>",
      "<main><h1>Authorization request rejected</h1>",
      "<p>",
      description,
      "</p>",
      "<p>Reason: <code>",
      reason,
      "</code></p>",
      "</main></body></html>"
    ]
    |> IO.iodata_to_binary()
  end
end
