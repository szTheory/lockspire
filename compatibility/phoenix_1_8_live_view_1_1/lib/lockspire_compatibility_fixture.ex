defmodule LockspireCompatibilityFixture.RequireStaff do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> send_resp(:forbidden, "Forbidden")
    |> halt()
  end
end

defmodule LockspireCompatibilityFixture.LiveAuthorization do
  @moduledoc false

  def on_mount(_name, _params, _session, socket), do: {:halt, socket}
end

defmodule LockspireCompatibilityFixture.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :host_operator do
    plug(:accepts, ["html"])
    plug(LockspireCompatibilityFixture.RequireStaff)
  end

  require Lockspire.Web.AdminRoutes

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
    pipe_through: [:host_operator],
    on_mount: LockspireCompatibilityFixture.LiveAuthorization
  )

  scope "/lockspire" do
    forward("/", Lockspire.Web.Router)
  end

  live("/compatibility", LockspireCompatibilityFixture.CompatibilityLive, :show)
end

defmodule LockspireCompatibilityFixture.CompatibilityLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <main id="lockspire-compatibility-fixture">Phoenix and LiveView lower-bound fixture</main>
    """
  end
end
