defmodule <%= @verification_html_module %> do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: <%= @web_module %>.Endpoint,
    router: <%= @router_module %>,
    statics: <%= @web_module %>.static_paths()

  embed_templates("lockspire_verification_html/*")
end
