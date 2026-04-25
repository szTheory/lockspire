defmodule Lockspire.Web.Live.AdminLayoutLive do
  @moduledoc false

  use Phoenix.Component

  attr(:current_section, :atom, default: :clients)
  attr(:page_title, :string, required: true)
  slot(:inner_block, required: true)

  def shell(assigns) do
    assigns =
      assign(assigns, :nav_items, [
        %{label: "Clients", key: :clients, href: admin_path("/clients"), enabled: true},
        %{label: "Policies", key: :policies, href: admin_path("/policies/par"), enabled: true},
        %{label: "Consents", key: :consents, href: admin_path("/consents"), enabled: true},
        %{label: "Tokens", key: :tokens, href: admin_path("/tokens"), enabled: true},
        %{label: "Keys", key: :keys, href: admin_path("/keys"), enabled: true}
      ])

    ~H"""
    <section class="lockspire-admin-shell">
      <header class="lockspire-admin-header">
        <p class="lockspire-admin-eyebrow">Lockspire Admin</p>
        <h1>{@page_title}</h1>
      </header>

      <nav aria-label="Operator navigation" class="lockspire-admin-nav">
        <%= for item <- @nav_items do %>
          <.nav_item item={item} current_section={@current_section} />
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
