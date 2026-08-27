defmodule Lockspire.Web.AdminProof.RouteAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.Web.AdminProof.Paths

  @operate_sources %{
    "/interactions" => "lib/lockspire/web/live/admin/interactions_live/index.ex",
    "/device_authorizations" => "lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
    "/logouts" => "lib/lockspire/web/live/admin/logout_deliveries_live/index.ex"
  }

  @configure_sources [
    "lib/lockspire/web/live/admin/clients_live/show.ex",
    "lib/lockspire/web/live/admin/dcr_live/index.ex",
    "lib/lockspire/web/live/admin/iat_live/index.html.heex",
    "lib/lockspire/web/live/admin/keys_live/index.ex",
    "lib/lockspire/web/live/admin/policies_live/dcr.html.heex"
  ]

  def assert_mounted_routes! do
    router = File.read!(Paths.admin_router())
    mounted = Lockspire.Web.AdminRouter |> Phoenix.Router.routes() |> Enum.map(& &1.path)

    for route <- [
          "/",
          "/clients",
          "/policies",
          "/keys",
          "/dcr",
          "/consents",
          "/tokens",
          "/interactions",
          "/device_authorizations",
          "/logouts"
        ] do
      assert route in mounted
      assert router =~ route
    end
  end

  def assert_operator_boundary! do
    guide = File.read!(Paths.operator_admin_doc())

    assert guide =~ "Lockspire owns protocol and operator state after the request reaches its LiveViews"

    assert guide =~
             "the host owns staff sessions, MFA, role checks, tenant policy, layouts, branding, product-specific authorization"
  end

  def assert_read_only_operate_surfaces! do
    router = File.read!(Paths.admin_router())

    for {route, relative_path} <- @operate_sources do
      source = source(relative_path)

      assert router =~ String.replace_prefix(route, "/admin", "")
      assert source =~ "Operate"
      assert source =~ "Read-only"
      assert source =~ "redacted_handle"
      refute source =~ "def handle_event"
      refute source =~ ~r/phx-(click|submit)=/
      refute source =~ "<table"

      for command <- ["Retry now", "Discard", "Approve", "Deny", "Logout now", "Run worker", "Pause worker"] do
        refute Regex.match?(~r/\b#{Regex.escape(command)}\b/i, source)
      end
    end
  end

  def assert_configure_actions! do
    sources = Enum.map_join(@configure_sources, "\n", &source/1)

    for action <- [
          "Rotate client secret",
          "Rotate registration access token",
          "Mint initial access token",
          "Generate signing key",
          "Save global DCR policy"
        ] do
      assert sources =~ action
    end

    assert sources =~ "AdminComponents.action_group"
    assert sources =~ "AdminComponents.confirmation_panel"
    refute sources =~ "data-confirm="
  end

  def assert_redaction_boundary! do
    sources = Paths.admin_live_sources() |> Enum.join("\n")
    components = File.read!(Paths.admin_components())

    assert sources =~ "redacted_handle"
    assert sources =~ "copy_once_secret_panel"
    assert components =~ "lockspire-admin-redacted-value"

    for forbidden <- [
          "device_code_hash",
          "user_code_hash",
          "client_secret_hash",
          "authorization_code",
          "refresh_token",
          "access_token",
          "private_key",
          "verifier_material"
        ] do
      for {route, relative_path} <- @operate_sources do
        refute source(relative_path) =~ forbidden, "#{route} renders #{forbidden}"
      end
    end
  end

  def assert_public_package_ceiling! do
    public_inputs =
      [Paths.admin_router(), Paths.supported_surface_doc(), Paths.mix_file()]
      |> Enum.map_join("\n", &File.read!/1)
      |> String.downcase()

    for forbidden <- ["component_lab", "browser_proof", "storybook", "design_system", "theme_lab"] do
      refute public_inputs =~ forbidden
    end

    refute File.read!(Paths.mix_file()) =~ ~r/files:\s+~w\([^)]*test\/support/
  end

  defp source(relative_path), do: Paths.root() |> Path.join(relative_path) |> File.read!()
end
