defmodule Lockspire.Generators.Templates do
  @moduledoc """
  Template inventory for generated host-owned Lockspire integration files.
  """

  @spec all(map()) :: [map()]
  def all(assigns \\ %{}) do
    base_templates() ++ optional_templates(assigns)
  end

  defp base_templates do
    [
      %{
        template: "router.ex",
        output: &"lib/#{&1.web_path}/router/lockspire.ex",
        ownership: :managed
      },
      %{
        template: "config.exs",
        output: fn _assigns -> "config/lockspire.exs" end,
        ownership: :managed
      },
      %{
        template: "account_resolver.ex",
        output: &"lib/#{&1.scope_path}/account_resolver.ex",
        ownership: :host_owned
      },
      %{
        template: "interaction_handler.ex",
        output: &"lib/#{&1.scope_path}/interaction_handler.ex",
        ownership: :host_owned
      },
      %{
        template: "consent_live.ex",
        output: &"lib/#{&1.web_path}/live/lockspire_consent_live.ex",
        ownership: :host_owned
      },
      %{
        template: "authorized_apps_controller.ex",
        output: &"lib/#{&1.web_path}/controllers/authorized_apps_controller.ex",
        ownership: :host_owned
      },
      %{
        template: "authorized_apps_html.ex",
        output: &"lib/#{&1.web_path}/controllers/authorized_apps_html.ex",
        ownership: :host_owned
      },
      %{
        template: "authorized_apps/index.html.heex",
        output: &"lib/#{&1.web_path}/controllers/authorized_apps_html/index.html.heex",
        ownership: :host_owned
      },
      %{
        template: "verification_controller.ex",
        output: &"lib/#{&1.web_path}/controllers/lockspire_verification_controller.ex",
        ownership: :host_owned
      },
      %{
        template: "verification_html.ex",
        output: &"lib/#{&1.web_path}/controllers/lockspire_verification_html.ex",
        ownership: :host_owned
      },
      %{
        template: "verification_html/index.html.heex",
        output: &"lib/#{&1.web_path}/controllers/lockspire_verification_html/index.html.heex",
        ownership: :host_owned
      },
      # Keep the template inventory assertion in install_generator_test.exs synchronized.
      %{
        template: "default_smoke_e2e_test.exs",
        output: fn assigns ->
          host_app_path =
            assigns.scope_module
            |> String.split(".")
            |> List.first()
            |> Macro.underscore()

          "test/#{host_app_path}/lockspire_smoke_e2e_test.exs"
        end,
        ownership: :managed
      }
    ]
  end

  defp optional_templates(%{with_fapi_smoke: true}) do
    [
      %{
        template: "fapi_smoke_e2e_test.exs",
        output: fn assigns ->
          host_app_path =
            assigns.scope_module
            |> String.split(".")
            |> List.first()
            |> Macro.underscore()

          "test/#{host_app_path}/lockspire_fapi_smoke_e2e.exs"
        end,
        ownership: :managed
      }
    ]
  end

  defp optional_templates(_assigns), do: []

  @spec managed(map()) :: [map()]
  def managed(assigns \\ %{}) do
    Enum.filter(all(assigns), &(&1.ownership == :managed))
  end
end
