defmodule LockspireCompatibilityFixture.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :host_operator do
    plug(:accepts, ["html"])
  end

  scope "/lockspire/admin" do
    pipe_through(:host_operator)
    forward("/", Lockspire.Web.AdminRouter)
  end

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
