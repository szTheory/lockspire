defmodule Lockspire.Web.Components.AdminComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:status, :atom, required: true)
  attr(:domain, :atom, default: nil)
  attr(:title, :string, default: nil)
  attr(:class, :string, default: "")
  attr(:rest, :global)

  def status_badge(assigns) do
    metadata = status_metadata(assigns.status, assigns.domain)

    assigns =
      assigns
      |> assign(:label, metadata.label)
      |> assign(:class_name, [
        "lockspire-admin-badge",
        status_tone_class(metadata.tone),
        assigns.class
      ])
      |> assign(:title_text, assigns.title || metadata.title)

    ~H"""
    <span class={@class_name} title={@title_text} data-status-tone={@domain || "global"} {@rest}>
      {@label}
    </span>
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

  attr(:eyebrow, :string, required: true)
  attr(:title, :string, required: true)
  attr(:body, :string, default: nil)
  attr(:class, :string, default: "")
  slot(:summary)
  slot(:actions)

  def page_hero(assigns) do
    ~H"""
    <section class={["lockspire-admin-hero lockspire-admin-page-hero", @class]}>
      <div class="lockspire-admin-page-hero__main">
        <p class="lockspire-admin-eyebrow">{@eyebrow}</p>
        <h2>{@title}</h2>
        <p :if={@body}>{@body}</p>
        <div :if={@summary != []} class="lockspire-admin-page-hero__summary">
          {render_slot(@summary)}
        </div>
      </div>
      <div :if={@actions != []} class="lockspire-admin-page-hero__actions">
        {render_slot(@actions)}
      </div>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:class, :string, default: "")
  attr(:rest, :global)
  slot(:status)
  slot(:actions)
  slot(:inner_block, required: true)

  def pane(assigns) do
    ~H"""
    <section class={["lockspire-admin-pane", @class]} {@rest}>
      <header class="lockspire-admin-pane__header">
        <div>
          <h2>{@title}</h2>
          <p :if={@subtitle}>{@subtitle}</p>
        </div>
        <div :if={@status != []} class="lockspire-admin-pane__status">{render_slot(@status)}</div>
        <div :if={@actions != []} class="lockspire-admin-pane__actions">{render_slot(@actions)}</div>
      </header>
      <div class="lockspire-admin-pane__body">{render_slot(@inner_block)}</div>
    </section>
    """
  end

  attr(:eyebrow, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:identifier, :any, default: nil)
  attr(:class, :string, default: "")
  attr(:rest, :global)
  slot(:status)
  slot(:actions)
  slot(:meta)

  def entity_header(assigns) do
    ~H"""
    <header class={["lockspire-admin-entity-header", @class]} {@rest}>
      <div class="lockspire-admin-entity-header__main">
        <p :if={@eyebrow} class="lockspire-admin-eyebrow">{@eyebrow}</p>
        <h2>{@title}</h2>
        <p :if={@subtitle}>{@subtitle}</p>
        <.long_value
          :if={@identifier}
          class="lockspire-admin-entity-header__identifier"
          kind={:id}
          value={@identifier}
        />
        <div :if={@meta != []} class="lockspire-admin-entity-header__meta">{render_slot(@meta)}</div>
      </div>
      <div :if={@status != []} class="lockspire-admin-status-cluster">{render_slot(@status)}</div>
      <div :if={@actions != []} class="lockspire-admin-entity-header__actions">{render_slot(@actions)}</div>
    </header>
    """
  end

  attr(:title, :string, required: true)
  attr(:help, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: "")
  attr(:rest, :global)
  slot(:body)
  slot(:actions)
  slot(:inner_block)

  def workflow_shell(assigns) do
    ~H"""
    <section class={["lockspire-admin-workflow-shell", @class]} {@rest}>
      <header>
        <h2>{@title}</h2>
        <p :if={@help} class="lockspire-admin-help">{@help}</p>
      </header>
      <.error_summary errors={@errors} />
      <div class="lockspire-admin-workflow-shell__body">
        {render_slot(@inner_block)}
        {render_slot(@body)}
      </div>
      <div :if={@actions != []} class="lockspire-admin-workflow-shell__actions">
        {render_slot(@actions)}
      </div>
    </section>
    """
  end

  attr(:class, :string, default: "")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def status_cluster(assigns) do
    ~H"""
    <div class={["lockspire-admin-status-cluster", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:wide, :boolean, default: false)
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def metric_grid(assigns) do
    ~H"""
    <div class={[
      "lockspire-admin-summary-grid lockspire-admin-metric-grid",
      @wide && "lockspire-admin-summary-grid-wide lockspire-admin-metric-grid-wide",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :string, default: "")

  slot :item, required: true do
    attr(:label, :string, required: true)
    attr(:value, :string, required: true)
    attr(:detail, :string)
    attr(:tone, :atom)
  end

  def decision_summary(assigns) do
    ~H"""
    <dl class={["lockspire-admin-decision-summary", @class]}>
      <%= for item <- @item do %>
        <div class={decision_summary_item_class(Map.get(item, :tone, :neutral))}>
          <dt>{item.label}</dt>
          <dd>{item.value}</dd>
          <p :if={Map.get(item, :detail)}>{item.detail}</p>
          <div :if={item.inner_block != []} class="lockspire-admin-decision-summary__extra">
            {render_slot(item)}
          </div>
        </div>
      <% end %>
    </dl>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:state, :string, default: nil)
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)
  slot(:actions)

  def task_card(assigns) do
    ~H"""
    <section class={["lockspire-admin-task-card", @class]}>
      <header class="lockspire-admin-task-card__header">
        <div>
          <h3>{@title}</h3>
          <p :if={@subtitle}>{@subtitle}</p>
        </div>
        <span :if={@state} class="lockspire-admin-task-card__state">{@state}</span>
      </header>
      <div class="lockspire-admin-task-card__body">
        {render_slot(@inner_block)}
      </div>
      <div :if={@actions != []} class="lockspire-admin-task-card__actions">
        {render_slot(@actions)}
      </div>
    </section>
    """
  end

  attr(:action, :string, required: true)
  attr(:method, :string, default: "get")
  attr(:class, :string, default: "")
  slot(:fields, required: true)
  slot(:help)
  slot(:actions)

  def filter_bar(assigns) do
    ~H"""
    <form method={@method} action={@action} class={["lockspire-admin-filter-bar", @class]}>
      <div class="lockspire-admin-filter-bar__fields">
        {render_slot(@fields)}
      </div>
      <div :if={@help != []} class="lockspire-admin-filter-bar__help">
        {render_slot(@help)}
      </div>
      <div :if={@actions != []} class="lockspire-admin-filter-bar__actions">
        {render_slot(@actions)}
      </div>
    </form>
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
      :if={@href && !@disabled}
      href={@href}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    <span
      :if={@href && @disabled}
      role="link"
      aria-disabled="true"
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    <button :if={!@href} type={@type} disabled={@disabled} class={@class} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:help, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:required, :boolean, default: false)
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def form_field(assigns) do
    assigns =
      assigns
      |> assign(:help_id, "#{assigns.id}-help")
      |> assign(:error_id, "#{assigns.id}-error")

    ~H"""
    <div class={["lockspire-admin-field", @errors != [] && "lockspire-admin-field-error", @class]}>
      <label for={@id}>
        {@label}
        <span :if={@required} aria-hidden="true" class="lockspire-admin-required-marker">*</span>
      </label>
      <p :if={@help} id={@help_id} class="lockspire-admin-help">{@help}</p>
      {render_slot(@inner_block)}
      <ul :if={@errors != []} id={@error_id} class="lockspire-admin-field-errors">
        <%= for error <- @errors do %>
          <li>{format_error(error)}</li>
        <% end %>
      </ul>
    </div>
    """
  end

  attr(:title, :string, default: "Review the highlighted fields")
  attr(:errors, :list, default: [])

  def error_summary(assigns) do
    ~H"""
    <section :if={@errors != []} class="lockspire-admin-error-summary" role="alert" tabindex="-1">
      <h2>{@title}</h2>
      <ul>
        <%= for error <- @errors do %>
          <li>{format_error(error)}</li>
        <% end %>
      </ul>
    </section>
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
  attr(:class, :string, default: "")
  slot(:meta)
  slot(:status)
  slot(:actions)

  def resource_item(assigns) do
    ~H"""
    <li class={["lockspire-admin-resource-list__item", @class]}>
      <div class="lockspire-admin-resource-list__main">
        <a :if={@href} href={@href} class="lockspire-admin-resource-list__title">{@title}</a>
        <strong :if={!@href} class="lockspire-admin-resource-list__title">{@title}</strong>
        <span :if={@subtitle} class="lockspire-admin-resource-list__subtitle">{@subtitle}</span>
      </div>
      <div :if={@meta != []} class="lockspire-admin-resource-list__meta">
        {render_slot(@meta)}
      </div>
      <div :if={@status != []} class="lockspire-admin-status-cluster">
        {render_slot(@status)}
      </div>
      <div :if={@actions != []} class="lockspire-admin-resource-list__actions">
        {render_slot(@actions)}
      </div>
    </li>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:class, :string, default: "")
  slot(:meta)
  slot(:status)
  slot(:actions)

  def dense_resource_row(assigns) do
    ~H"""
    <li class={["lockspire-admin-dense-resource-row", @class]}>
      <div class="lockspire-admin-dense-resource-row__main">
        <strong>{@title}</strong>
        <span :if={@subtitle}>{@subtitle}</span>
      </div>
      <div :if={@meta != []} class="lockspire-admin-dense-resource-row__meta">{render_slot(@meta)}</div>
      <div :if={@status != []} class="lockspire-admin-status-cluster">{render_slot(@status)}</div>
      <div :if={@actions != []} class="lockspire-admin-dense-resource-row__actions">
        {render_slot(@actions)}
      </div>
    </li>
    """
  end

  attr(:title, :string, required: true)
  attr(:state, :atom, default: nil)
  attr(:domain, :atom, default: nil)
  attr(:timestamp, :any, default: nil)
  attr(:actor, :string, default: nil)
  attr(:consequence, :string, default: nil)
  attr(:class, :string, default: "")
  slot(:actions)

  def lifecycle_row(assigns) do
    ~H"""
    <div class={["lockspire-admin-lifecycle-row", @class]}>
      <div class="lockspire-admin-lifecycle-row__main">
        <strong>{@title}</strong>
        <p :if={@consequence}>{@consequence}</p>
      </div>
      <div class="lockspire-admin-lifecycle-row__meta">
        <.status_badge :if={@state} status={@state} domain={@domain} />
        <.timestamp :if={@timestamp} value={@timestamp} />
        <span :if={@actor}>{@actor}</span>
      </div>
      <div :if={@actions != []} class="lockspire-admin-lifecycle-row__actions">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  attr(:caption, :string, default: nil)
  attr(:class, :string, default: "")
  slot(:thead)
  slot(:tbody)
  slot(:list)
  slot(:empty)

  def responsive_table(assigns) do
    ~H"""
    <div class={["lockspire-admin-responsive-table", @class]}>
      <div class="lockspire-admin-table-wrap">
        <table class="lockspire-admin-table">
          <caption :if={@caption}>{@caption}</caption>
          <thead :if={@thead != []}>{render_slot(@thead)}</thead>
          <tbody>{render_slot(@tbody)}</tbody>
        </table>
      </div>
      <div class="lockspire-admin-responsive-table__list">
        {render_slot(@list)}
        <div :if={@list == [] && @empty != []}>{render_slot(@empty)}</div>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:body, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:redacted, :boolean, default: false)
  attr(:label, :string, default: "Copy-once value")
  attr(:class, :string, default: "")

  def copy_once_secret_panel(assigns) do
    ~H"""
    <section class={["lockspire-admin-secret-reveal lockspire-admin-copy-once-secret", @class]}>
      <h3>{@title}</h3>
      <p :if={@body}>{@body}</p>
      <div class="lockspire-admin-copy-once-secret__value">
        <span class="lockspire-admin-copy-once-secret__label">{@label}</span>
        <code :if={@value && !@redacted}>{@value}</code>
        <span :if={!@value || @redacted} class="lockspire-admin-redacted-value">Redacted</span>
      </div>
    </section>
    """
  end

  attr(:value, :any, required: true)
  attr(:kind, :atom, default: :text)
  attr(:redacted, :boolean, default: false)
  attr(:class, :string, default: "")

  def long_value(assigns) do
    assigns = assign(assigns, :class_name, long_value_class(assigns.kind, assigns.class))

    ~H"""
    <span class={@class_name}>
      <%= if @redacted do %>
        <span class="lockspire-admin-redacted-value">Redacted</span>
      <% else %>
        {@value}
      <% end %>
    </span>
    """
  end

  attr(:class, :string, default: "")
  slot(:primary)
  slot(:secondary)
  slot(:destructive)

  def action_group(assigns) do
    ~H"""
    <div class={["lockspire-admin-action-group", @class]}>
      <div :if={@primary != []} class="lockspire-admin-action-group__primary">
        {render_slot(@primary)}
      </div>
      <div :if={@secondary != []} class="lockspire-admin-action-group__secondary">
        {render_slot(@secondary)}
      </div>
      <div :if={@destructive != []} class="lockspire-admin-action-group__destructive">
        {render_slot(@destructive)}
      </div>
    </div>
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
  slot(:actions)

  def empty_state(assigns) do
    ~H"""
    <section class="lockspire-admin-empty">
      <h2>{@title}</h2>
      <p>{@body}</p>
      <div :if={@actions != []} class="lockspire-admin-empty__actions">{render_slot(@actions)}</div>
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

  defp status_metadata(:approved, :device_authorization),
    do: %{
      label: "Approved, waiting",
      tone: :waiting,
      title: "Approved device authorization awaiting completion"
    }

  defp status_metadata(status, _domain) when status in [:active, :open, :approved],
    do: %{label: status_label(status), tone: :healthy, title: "Healthy or available state"}

  defp status_metadata(status, _domain)
       when status in [
              :pending,
              :pending_login,
              :pending_consent,
              :enqueued,
              :attempted,
              :upcoming
            ],
       do: %{
         label: status_label(status),
         tone: :waiting,
         title: "Waiting for protocol or queue progress"
       }

  defp status_metadata(status, _domain) when status in [:retiring, :retryable, :denied],
    do: %{
      label: status_label(status),
      tone: :warning,
      title: "Operator attention may be required"
    }

  defp status_metadata(status, _domain) when status in [:reuse_detected, :discarded, :revoked],
    do: %{
      label: status_label(status),
      tone: :danger,
      title: "Terminal or security-sensitive state"
    }

  defp status_metadata(status, _domain) when status in [:disabled, :retired, :expired],
    do: %{label: status_label(status), tone: :disabled, title: "Closed or unavailable state"}

  defp status_metadata(status, _domain)
       when status in [:completed, :consumed, :used, :succeeded, :rendered, :skipped],
       do: %{label: status_label(status), tone: :completed, title: "Completed state"}

  defp status_metadata(status, _domain)
       when status in [
              :operator,
              :self_registered,
              :self_registered_client,
              :system,
              :host_app,
              :dcr,
              :one_time,
              :remembered,
              :initial_access_token
            ],
       do: %{label: status_label(status), tone: :provenance, title: "Origin or provenance"}

  defp status_metadata(status, _domain),
    do: %{label: status_label(status), tone: :disabled, title: "Unknown status"}

  defp status_tone_class(:healthy), do: "lockspire-admin-badge-healthy"
  defp status_tone_class(:waiting), do: "lockspire-admin-badge-waiting"
  defp status_tone_class(:warning), do: "lockspire-admin-badge-warning"
  defp status_tone_class(:danger), do: "lockspire-admin-badge-danger"
  defp status_tone_class(:completed), do: "lockspire-admin-badge-completed"
  defp status_tone_class(:provenance), do: "lockspire-admin-badge-provenance"
  defp status_tone_class(_tone), do: "lockspire-admin-badge-disabled"

  defp status_label(:reuse_detected), do: "Reuse detected"
  defp status_label(:self_registered), do: "Self-registered"
  defp status_label(:self_registered_client), do: "Self-registered client"
  defp status_label(:host_app), do: "Host app"
  defp status_label(:dcr), do: "DCR"
  defp status_label(:one_time), do: "One-time"
  defp status_label(:initial_access_token), do: "Initial access token"
  defp status_label(:pending_login), do: "Pending login"
  defp status_label(:pending_consent), do: "Pending consent"

  defp status_label(value) when is_atom(value),
    do: value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp status_label(value), do: to_string(value)

  defp button_class(:primary), do: "lockspire-admin-btn lockspire-admin-btn-primary"
  defp button_class(:danger), do: "lockspire-admin-btn lockspire-admin-btn-danger"
  defp button_class(_variant), do: "lockspire-admin-btn lockspire-admin-btn-secondary"

  defp decision_summary_item_class(:danger),
    do: "lockspire-admin-decision-summary__item lockspire-admin-decision-summary__item-danger"

  defp decision_summary_item_class(:warning),
    do: "lockspire-admin-decision-summary__item lockspire-admin-decision-summary__item-warning"

  defp decision_summary_item_class(:success),
    do: "lockspire-admin-decision-summary__item lockspire-admin-decision-summary__item-success"

  defp decision_summary_item_class(:info),
    do: "lockspire-admin-decision-summary__item lockspire-admin-decision-summary__item-info"

  defp decision_summary_item_class(_tone),
    do: "lockspire-admin-decision-summary__item"

  defp long_value_class(kind, class) do
    [
      "lockspire-admin-long-value",
      kind in [:id, :url, :token, :timestamp, :mono] && "lockspire-admin-long-value-mono",
      class
    ]
  end

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
