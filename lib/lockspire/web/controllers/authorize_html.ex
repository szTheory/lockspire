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

  def form_post_page(action, params) do
    inputs =
      params
      |> Enum.map_join("", fn {k, v} ->
        ~s(<input type="hidden" name="#{Plug.HTML.html_escape(k)}" value="#{Plug.HTML.html_escape(v)}"/>)
      end)

    [
      "<!doctype html><html><head><meta charset=\"utf-8\"><title>Submit</title></head>",
      "<body onload=\"document.forms[0].submit()\">",
      "<noscript><p>Your browser does not support JavaScript. Please click the button below to proceed.</p></noscript>",
      "<form method=\"post\" action=\"#{Plug.HTML.html_escape(action)}\">",
      inputs,
      "<noscript><button type=\"submit\">Submit</button></noscript>",
      "</form></body></html>"
    ]
    |> IO.iodata_to_binary()
  end
end
