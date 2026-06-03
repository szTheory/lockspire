defmodule Lockspire.Web.Live.AdminLayoutLive do
  @moduledoc false

  use Phoenix.Component

  attr(:current_section, :atom, default: :overview)
  attr(:page_title, :string, required: true)
  slot(:inner_block, required: true)

  def shell(assigns) do
    assigns =
      assign(assigns, :nav_groups, [
        %{
          label: "Orient",
          items: [
            %{label: "Overview", key: :overview, href: admin_path("/"), enabled: true}
          ]
        },
        %{
          label: "Configure",
          items: [
            %{label: "Clients", key: :clients, href: admin_path("/clients"), enabled: true},
            %{label: "Security", key: :policies, href: admin_path("/policies"), enabled: true},
            %{label: "Keys", key: :keys, href: admin_path("/keys"), enabled: true},
            %{label: "DCR", key: :dcr, href: admin_path("/dcr"), enabled: true}
          ]
        },
        %{
          label: "Support",
          items: [
            %{label: "Consents", key: :consents, href: admin_path("/consents"), enabled: true},
            %{label: "Tokens", key: :tokens, href: admin_path("/tokens"), enabled: true}
          ]
        },
        %{
          label: "Operate",
          items: [
            %{
              label: "Device Auth",
              key: :device_authorizations,
              href: admin_path("/device_authorizations"),
              enabled: true
            },
            %{
              label: "Interactions",
              key: :interactions,
              href: admin_path("/interactions"),
              enabled: true
            },
            %{label: "Logouts", key: :logouts, href: admin_path("/logouts"), enabled: true}
          ]
        }
      ])

    ~H"""
    <style>
      <%= Phoenix.HTML.raw(Lockspire.Web.Admin.CSS.get()) %>
    </style>
    <section class="lockspire-admin-shell">
      <header class="lockspire-admin-header">
        <p class="lockspire-admin-eyebrow">Lockspire Admin</p>
        <h1>{@page_title}</h1>
      </header>

      <nav aria-label="Operator navigation" class="lockspire-admin-nav">
        <%= for group <- @nav_groups do %>
          <section class="lockspire-admin-nav-group" aria-label={group.label}>
            <span class="lockspire-admin-nav-group-label">{group.label}</span>
            <div class="lockspire-admin-nav-group-items">
              <%= for item <- group.items do %>
                <.nav_item item={item} current_section={@current_section} />
              <% end %>
            </div>
          </section>
        <% end %>
      </nav>

      <div class="lockspire-admin-body">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr(:item, :map, required: true)
  attr(:current_section, :atom, required: true)

  defp nav_item(assigns) do
    assigns =
      assign(assigns, :class, nav_class(assigns.item, assigns.current_section))

    ~H"""
    <a
      href={if @item.enabled, do: @item.href, else: "#"}
      aria-disabled={if @item.enabled, do: "false", else: "true"}
      aria-current={if @item.key == @current_section, do: "page", else: nil}
      class={@class}
    >
      {@item.label}
    </a>
    """
  end

  defp nav_class(%{enabled: false}, _current_section),
    do: "lockspire-admin-nav-item lockspire-admin-nav-item-disabled"

  defp nav_class(%{key: key}, current_section) when key == current_section,
    do: "lockspire-admin-nav-item lockspire-admin-nav-item-current"

  defp nav_class(_item, _current_section), do: "lockspire-admin-nav-item"

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
