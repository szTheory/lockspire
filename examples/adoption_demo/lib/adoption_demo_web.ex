defmodule AdoptionDemoWeb do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: []

      import Plug.Conn
      import AdoptionDemoWeb.Router.Helpers
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AdoptionDemoWeb.Endpoint,
        router: AdoptionDemoWeb.Router,
        statics: AdoptionDemoWeb.static_paths()
    end
  end

  def static_paths, do: ~w()

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
