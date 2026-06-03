defmodule Lockspire.Web.Components.AdminComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:status, :atom, required: true)

  def status_badge(assigns) do
    assigns =
      assign(assigns, :label, badge_label(assigns.status))

    ~H"""
    <span class={badge_class(@status)}>{@label}</span>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  slot(:inner_block, required: true)

  def section_card(assigns) do
    ~H"""
    <section class="lockspire-admin-card">
      <header>
        <h2>{@title}</h2>
        <p :if={@subtitle}>{@subtitle}</p>
      </header>
      <div>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr(:variant, :atom, default: :secondary)
  attr(:type, :string, default: "button")
  attr(:href, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def admin_button(assigns) do
    assigns = assign(assigns, :class, button_class(assigns.variant))

    ~H"""
    <a
      :if={@href}
      href={@href}
      aria-disabled={to_string(@disabled)}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    <button :if={!@href} type={@type} disabled={@disabled} class={@class} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def action_bar(assigns) do
    ~H"""
    <div class={["lockspire-admin-action-bar", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:variant, :atom, default: :info)
  attr(:title, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def alert(assigns) do
    assigns = assign(assigns, :class, alert_class(assigns.variant))

    ~H"""
    <section class={@class} {@rest}>
      <h3 :if={@title}>{@title}</h3>
      {render_slot(@inner_block)}
    </section>
    """
  end

  slot :item, required: true do
    attr(:label, :string, required: true)
  end

  def description_list(assigns) do
    ~H"""
    <dl class="lockspire-admin-description-list">
      <%= for item <- @item do %>
        <div>
          <dt>{item.label}</dt>
          <dd>{render_slot(item)}</dd>
        </div>
      <% end %>
    </dl>
    """
  end

  attr(:value, :any, required: true)
  attr(:label, :string, required: true)

  def summary_stat(assigns) do
    ~H"""
    <div class="lockspire-admin-summary-stat">
      <span class="lockspire-admin-summary-value">{@value}</span>
      <span class="lockspire-admin-summary-label">{@label}</span>
    </div>
    """
  end

  slot(:inner_block, required: true)

  def resource_list(assigns) do
    ~H"""
    <ul class="lockspire-admin-resource-list">
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr(:href, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  slot(:meta)
  slot(:actions)

  def resource_item(assigns) do
    ~H"""
    <li class="lockspire-admin-resource-list__item">
      <div class="lockspire-admin-resource-list__main">
        <a :if={@href} href={@href} class="lockspire-admin-resource-list__title">{@title}</a>
        <strong :if={!@href} class="lockspire-admin-resource-list__title">{@title}</strong>
        <span :if={@subtitle} class="lockspire-admin-resource-list__subtitle">{@subtitle}</span>
      </div>
      <div :if={@meta != []} class="lockspire-admin-resource-list__meta">
        {render_slot(@meta)}
      </div>
      <div :if={@actions != []} class="lockspire-admin-resource-list__actions">
        {render_slot(@actions)}
      </div>
    </li>
    """
  end

  slot(:inner_block, required: true)

  def badge_group(assigns) do
    ~H"""
    <div class="lockspire-admin-badge-group">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:variant, :atom, default: :warning)
  attr(:errors, :list, default: [])
  slot(:body, required: true)
  slot(:actions)

  def confirmation_panel(assigns) do
    assigns = assign(assigns, :class, confirmation_panel_class(assigns.variant))

    ~H"""
    <section class={@class}>
      <header>
        <h3>{@title}</h3>
      </header>
      <div class="lockspire-admin-confirmation-panel__body">
        {render_slot(@body)}
      </div>
      <.error_list errors={@errors} />
      <div :if={@actions != []} class="lockspire-admin-confirmation-panel__actions">
        {render_slot(@actions)}
      </div>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:body, :string, required: true)

  def empty_state(assigns) do
    ~H"""
    <section class="lockspire-admin-empty">
      <h2>{@title}</h2>
      <p>{@body}</p>
    </section>
    """
  end

  def policy_nav(assigns) do
    assigns =
      assign(assigns, :items, [
        %{label: "Overview", href: policy_path("")},
        %{label: "PAR", href: policy_path("/par")},
        %{label: "Security Profile", href: policy_path("/security-profile")},
        %{label: "DPoP", href: policy_path("/dpop")},
        %{label: "DCR", href: policy_path("/dcr")}
      ])

    ~H"""
    <nav aria-label="Policy sections" class="lockspire-admin-secondary-nav">
      <%= for item <- @items do %>
        <.link href={item.href}>{item.label}</.link>
      <% end %>
    </nav>
    """
  end

  defp policy_path(path), do: Lockspire.mount_path() <> "/admin/policies" <> path

  attr(:value, :any, default: nil)

  def timestamp(assigns) do
    ~H"""
    <span class="lockspire-admin-tabular">{format_datetime(@value)}</span>
    """
  end

  attr(:errors, :list, required: true)

  def error_list(assigns) do
    ~H"""
    <ul :if={@errors != []} class="lockspire-admin-errors">
      <%= for error <- @errors do %>
        <li>{format_error(error)}</li>
      <% end %>
    </ul>
    """
  end

  defp badge_class(:active), do: "lockspire-admin-badge lockspire-admin-badge-active"
  defp badge_class(:upcoming), do: "lockspire-admin-badge lockspire-admin-badge-info"
  defp badge_class(:retiring), do: "lockspire-admin-badge lockspire-admin-badge-warning"
  defp badge_class(:retired), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
  defp badge_class(:revoked), do: "lockspire-admin-badge lockspire-admin-badge-danger"
  defp badge_class(:expired), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
  defp badge_class(:reuse_detected), do: "lockspire-admin-badge lockspire-admin-badge-danger"
  defp badge_class(_other), do: "lockspire-admin-badge lockspire-admin-badge-disabled"

  defp badge_label(:active), do: "Active"
  defp badge_label(:upcoming), do: "Upcoming"
  defp badge_label(:retiring), do: "Retiring"
  defp badge_label(:retired), do: "Retired"
  defp badge_label(:disabled), do: "Disabled"
  defp badge_label(:revoked), do: "Revoked"
  defp badge_label(:expired), do: "Expired"
  defp badge_label(:reuse_detected), do: "Reuse detected"
  defp badge_label(:remembered), do: "Remembered"
  defp badge_label(:one_time), do: "One-time"
  defp badge_label(:pending_login), do: "Pending login"
  defp badge_label(:pending_consent), do: "Pending consent"

  defp badge_label(value) when is_atom(value),
    do: value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp badge_label(value), do: to_string(value)

  defp button_class(:primary), do: "lockspire-admin-btn lockspire-admin-btn-primary"
  defp button_class(:danger), do: "lockspire-admin-btn lockspire-admin-btn-danger"
  defp button_class(_variant), do: "lockspire-admin-btn lockspire-admin-btn-secondary"

  defp alert_class(:warning), do: "lockspire-admin-alert lockspire-admin-alert-warning"
  defp alert_class(:danger), do: "lockspire-admin-alert lockspire-admin-alert-danger"
  defp alert_class(_variant), do: "lockspire-admin-alert lockspire-admin-alert-info"

  defp confirmation_panel_class(:danger),
    do: "lockspire-admin-confirmation-panel lockspire-admin-confirmation-panel-danger"

  defp confirmation_panel_class(_variant),
    do: "lockspire-admin-confirmation-panel lockspire-admin-confirmation-panel-warning"

  defp format_datetime(nil), do: "Not recorded"
  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp format_error(%{field: field, reason: reason, detail: detail}) do
    "#{field} #{reason} #{inspect(detail)}"
  end

  defp format_error(error), do: inspect(error)
end
