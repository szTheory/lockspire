defmodule Lockspire.Generators.Templates do
  @moduledoc """
  Template inventory for generated host-owned Lockspire integration files.
  """

  @spec all() :: [map()]
  def all do
    [
      %{
        template: "router.ex",
        output: &"lib/#{&1.web_path}/router/lockspire.ex"
      },
      %{
        template: "config.exs",
        output: fn _assigns -> "config/lockspire.exs" end
      },
      %{
        template: "account_resolver.ex",
        output: &"lib/#{&1.scope_path}/account_resolver.ex"
      },
      %{
        template: "interaction_handler.ex",
        output: &"lib/#{&1.scope_path}/interaction_handler.ex"
      },
      %{
        template: "consent_live.ex",
        output: &"lib/#{&1.web_path}/live/lockspire_consent_live.ex"
      },
      %{
        template: "authorized_apps_controller.ex",
        output: &"lib/#{&1.web_path}/controllers/authorized_apps_controller.ex"
      },
      %{
        template: "authorized_apps_html.ex",
        output: &"lib/#{&1.web_path}/controllers/authorized_apps_html.ex"
      },
      %{
        template: "authorized_apps/index.html.heex",
        output: &"lib/#{&1.web_path}/controllers/authorized_apps_html/index.html.heex"
      }
    ]
  end
end
