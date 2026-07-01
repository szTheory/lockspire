defmodule Lockspire.Web.Live.AdminLayoutLive do
  @moduledoc false

  use Phoenix.Component

  # Brand lockup (faceted tower + wordmark). Letters use currentColor so they
  # follow the theme via .lockspire-admin-brand; the tower/diamond stay Signal
  # Cyan. Source of truth: brandbook/logo/lockspire-horizontal-adaptive.svg
  @brand_lockup ~S(<svg xmlns="http://www.w3.org/2000/svg" aria-label="Lockspire" viewBox="0 0 5507.6 1046"><path fill="#0e7490" d="M42.546 845.985h382.91l-42.546-85.091H85.091ZM234 37.618l85.092 212.728 42.546 510.548H234Z"/><path fill="#22d3ee" d="m234 37.618-85.09 212.728-42.546 510.548h127.637Z"/><path fill="#67e8f9" d="m234 80.164-42.545 170.182 10.637 510.548H234Z"/><path fill="#a5f3fc" d="m234 37.618-42.545 212.728h42.546Z"/><path fill="currentColor" d="M660 846V66h154v657.5h336.5V846Zm812.35 15q-146 0-217.75-85.5T1182.85 546t71.75-229.5 217.75-85.5 217.75 85.5 71.75 229.5-71.75 229.5-217.75 85.5m0-103q70.55 0 103.275-54.25t32.725-158.125-32.725-157.75T1472.35 334t-103.275 53.875-32.725 157.75 32.725 158.125T1472.35 758m628.1 103q-136.75 0-207.875-85.375T1821.45 546q0-150.75 74.75-232.875T2101.95 231q115.5 0 182.625 61.875T2364.95 463.5H2218.7q-7.5-60.25-37.25-92.625t-78-32.375q-63.25 0-95.875 54.25T1974.95 546t32.25 153.25 95.5 54.25q49 0 78.75-32.75t37.25-92.25h146.25q-14.5 107.5-81.875 170T2100.45 861m360.35-15V46h148v433.75h48l175-233.75h159v6l-210.75 274.5L3014.8 840v6h-174.75L2656.8 592.25h-48V846Zm827.1 15q-95.75 0-153.875-31t-85.5-78.875T3017.4 654h142q4.5 27 20.875 50.25t44.75 36.75 69.625 13.5q49.25 0 72.25-18t23-46.75q0-26-20.25-44t-65-32.75l-71.75-24.25q-51-18-93.625-39.5t-68.25-55.125T3045.4 407.5q0-79.25 59.5-127.875T3272.4 231q78 0 128 24.75t75.5 66.25 29.5 92h-136.5q-4.75-36.5-30-58.75T3266.65 333q-41 0-61.875 16.375T3183.9 394q0 28 21.75 46.25t66 33.25l71.75 23.25q51 16.5 93.125 38t67 55.375 24.875 87.625q0 82.25-61.625 132.75T3287.9 861m331.6 185V246H3756v78h24q19.75-37.5 60-64.125t107.75-26.625q80.75 0 134 40t79.875 110.625 26.625 162.875q0 92.75-27 163.375t-80.5 109.625-132.5 39q-58.75 0-96.75-21.75t-59.5-58.5h-24V1046Zm289-295.25q59.5 0 92.875-51.875T4034.75 546t-33.375-152.875-92.875-51.875q-64.5 0-102.875 55.25T3767.25 546q0 93.5 38.375 149.125T3908.5 750.75M4288.1 846V246h148.5v600Zm287.6 0V246h135v108h24q6-28.75 22.125-54.875T4806.7 256.5t91.5-16.5h29v135h-40.5q-86.25 0-124.375 43.875T4724.2 552v294Zm662.85 15q-139.5 0-212.5-85.375t-73-230.375q0-97 32.75-167.125t96-108.625 155-38.5q131.25 0 201 80.75t69.75 236.5v33.25H5097.8q5 79 41 125.75t100 46.75q49.5 0 79.625-29t40.625-71h141q-10 56.5-40.75 103.375t-85.25 75.25T5238.55 861m-140.5-375.5h264.75q-3.75-72.75-36-112.375t-91-39.625q-59 0-94.25 38.375t-43.5 113.625"/><path fill="#22d3ee" d="m4362.6 180 90-90-90-90-90 90Z"/><path fill="#0e7490" d="m4362.6 180-90-90 90-90Z"/></svg>)

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
    <script>
      (() => {
        const storageKey = "lockspire-admin-theme";
        const root = document.documentElement;
        const applyTheme = (theme) => {
          if (theme === "light" || theme === "dark") {
            root.dataset.theme = theme;
          } else {
            root.removeAttribute("data-theme");
          }
          document.querySelectorAll("[data-lockspire-theme-select]").forEach((select) => {
            select.value = theme || "system";
          });
        };

        let savedTheme = "system";
        try {
          savedTheme = window.localStorage.getItem(storageKey) || "system";
        } catch (_error) {}

        applyTheme(savedTheme);

        document.addEventListener("change", (event) => {
          const select = event.target.closest("[data-lockspire-theme-select]");
          if (!select) return;

          const nextTheme = select.value;
          try {
            if (nextTheme === "system") {
              window.localStorage.removeItem(storageKey);
            } else {
              window.localStorage.setItem(storageKey, nextTheme);
            }
          } catch (_error) {}

          applyTheme(nextTheme);
        });
      })();
    </script>
    <section class="lockspire-admin-shell">
      <header class="lockspire-admin-header">
        <div class="lockspire-admin-header-row">
          <div class="lockspire-admin-header-title">
            <div class="lockspire-admin-brand">
              <span aria-label="Lockspire Admin">{Phoenix.HTML.raw(brand_lockup())}</span>
            </div>
            <h1>{@page_title}</h1>
          </div>
          <div class="lockspire-admin-theme-control">
            <label for="lockspire-admin-theme-select">Theme</label>
            <select id="lockspire-admin-theme-select" data-lockspire-theme-select>
              <option value="system">System</option>
              <option value="light">Light</option>
              <option value="dark">Dark</option>
            </select>
          </div>
        </div>
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

  defp brand_lockup, do: @brand_lockup
end
