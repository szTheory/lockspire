defmodule <%= @authorized_apps_html_module %> do
  use Phoenix.Component
  use Phoenix.VerifiedRoutes,
    endpoint: <%= @web_module %>.Endpoint,
    router: <%= @router_module %>,
    statics: <%= @web_module %>.static_paths()

  embed_templates "authorized_apps_html/*"
end
