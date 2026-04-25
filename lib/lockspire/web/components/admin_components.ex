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

  attr(:value, :any, default: nil)

  def timestamp(assigns) do
    ~H"""
    <span>{format_datetime(@value)}</span>
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
  defp badge_class(:upcoming), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
  defp badge_class(:retiring), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
  defp badge_class(:retired), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
  defp badge_class(:reuse_detected), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
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

  defp badge_label(value) when is_atom(value),
    do: value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp badge_label(value), do: to_string(value)

  defp format_datetime(nil), do: "Not recorded"
  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp format_error(%{field: field, reason: reason, detail: detail}) do
    "#{field} #{reason} #{inspect(detail)}"
  end

  defp format_error(error), do: inspect(error)
end
