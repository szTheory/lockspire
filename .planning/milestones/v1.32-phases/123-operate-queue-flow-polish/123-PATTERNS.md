# Phase 123: Operate Queue Flow Polish - Pattern Map

**Mapped:** 2026-06-29
**Files analyzed:** 13 planned or conditional files
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/live/admin/interactions_live/index.ex` | LiveView component | request-response, read-only CRUD read, transform | `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | LiveView component | request-response, read-only CRUD read, transform | `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | LiveView component | request-response, read-only CRUD read, transform | `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | exact |
| `lib/lockspire/web/components/admin_components.ex` | component | transform | `lib/lockspire/web/components/admin_components.ex` | exact, conditional |
| `lib/lockspire/web/admin_css.ex` | config/component style | transform, responsive/theme/motion | `lib/lockspire/web/admin_css.ex` | exact, conditional |
| `test/lockspire/web/live/admin/interactions_live_test.exs` | test | rendered HTML, request-response proof | `test/lockspire/web/live/admin/interactions_live_test.exs` | exact |
| `test/lockspire/web/live/admin/device_authorizations_live_test.exs` | test | rendered HTML, request-response proof | `test/lockspire/web/live/admin/device_authorizations_live_test.exs` | exact |
| `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | test | rendered HTML, request-response proof | `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | exact |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | source contract, rendered/source fence | `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact, conditional |
| `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | test | rendered HTML, component stress transform | `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | exact, conditional |
| `test/support/lockspire/web/admin_lab/fixtures.ex` | test fixture | batch fixture transform | `test/support/lockspire/web/admin_lab/fixtures.ex` | exact, conditional |
| `test/support/lockspire/web/admin_lab/stress_surface.ex` | component/test fixture | rendered HTML transform | `test/support/lockspire/web/admin_lab/stress_surface.ex` | exact, conditional |
| `docs/operator-admin.md` | documentation | static docs | `docs/operator-admin.md` | exact, conditional |

## Pattern Assignments

### `lib/lockspire/web/live/admin/interactions_live/index.ex` (LiveView component, request-response/read-only)

**Analog:** `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex`, plus current `interactions_live/index.ex`.

**Imports pattern** (`interactions_live/index.ex` lines 4-9):

```elixir
use Phoenix.LiveView

alias Lockspire.Redaction
alias Lockspire.Storage.Ecto.Repository
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive
```

**Auth/guard pattern:** no staff auth in this file. Preserve host-mounted guard boundary from `docs/operator-admin.md` lines 18-35 and `lib/lockspire/web/admin_router.ex` lines 1-7. Do not add Lockspire-owned staff auth, roles, MFA, or tenant policy here.

**Read/load pattern** (`interactions_live/index.ex` lines 12-21):

```elixir
@impl true
def mount(_params, _session, socket) do
  {:ok, interactions} = Repository.list_interactions()

  {:ok,
   assign(socket,
     page_title: "Active interactions",
     current_section: :interactions,
     interactions: interactions
   )}
end
```

**Core page spine pattern** (`logout_deliveries_live/index.ex` lines 33-49):

```elixir
<AdminComponents.page_hero
  eyebrow="Operate"
  title="Logout propagation queue"
  body="Triage waiting, retrying, failed, discarded, and completed logout delivery work without adding worker controls."
/>

<AdminComponents.pane
  title="Review logout deliveries"
  subtitle="Read-only delivery rows expose status pressure, client, endpoint, attempts, and durable delivery context."
>
  <AdminComponents.metric_grid>
    <AdminComponents.summary_stat value={@delivery_metrics.waiting} label="Waiting" />
    <AdminComponents.summary_stat value={@delivery_metrics.retrying} label="Retrying" />
    <AdminComponents.summary_stat value={@delivery_metrics.failed} label="Failed" />
    <AdminComponents.summary_stat value={@delivery_metrics.discarded} label="Discarded" />
    <AdminComponents.summary_stat value={@delivery_metrics.completed} label="Completed" />
  </AdminComponents.metric_grid>
```

**Dense row pattern to copy/adapt** (`logout_deliveries_live/index.ex` lines 57-77):

```elixir
<AdminComponents.resource_list>
  <%= for delivery <- @deliveries do %>
    <AdminComponents.dense_resource_row
      title={"#{channel_label(delivery.channel)} logout delivery"}
      subtitle={delivery_pressure(delivery)}
    >
      <:meta>
        <span>Delivery <AdminComponents.long_value value={delivery.delivery_id} kind={:id} /></span>
        <span>Client <AdminComponents.long_value value={redacted_handle(:client, delivery.client_id)} kind={:id} /></span>
        <span>Channel <AdminComponents.long_value value={channel_label(delivery.channel)} kind={:text} /></span>
        <span>Endpoint <AdminComponents.long_value value={delivery.target_uri} kind={:url} /></span>
        <span>Attempts {delivery.attempt_count}</span>
        <span>Last activity <AdminComponents.long_value value={formatted_timestamp(delivery_timestamp(delivery))} kind={:timestamp} /></span>
        <span class="lockspire-admin-dense-resource-row__note">
          {delivery_support_note(delivery)}
        </span>
      </:meta>
      <:status>
        <AdminComponents.status_badge status={delivery.status} />
      </:status>
    </AdminComponents.dense_resource_row>
  <% end %>
</AdminComponents.resource_list>
```

**Interaction-specific starting point** (`interactions_live/index.ex` lines 70-84):

```elixir
<AdminComponents.dense_resource_row
  title="Authorization interaction"
  subtitle="Review interactions"
>
  <:meta>
    <span>Interaction <AdminComponents.long_value value={interaction.interaction_id} kind={:id} /></span>
    <span>Client <AdminComponents.long_value value={redacted_handle(:client, interaction.client_id)} kind={:id} /></span>
    <span>Subject <AdminComponents.long_value value={redacted_handle(:account, interaction.account_id)} kind={:id} /></span>
    <span>Prompt <AdminComponents.long_value value={prompt_label(interaction.prompt)} kind={:text} /></span>
    <span>Created <AdminComponents.long_value value={formatted_timestamp(interaction.inserted_at)} kind={:timestamp} /></span>
    <span>Expires <AdminComponents.long_value value={formatted_timestamp(interaction.expires_at)} kind={:timestamp} /></span>
  </:meta>
  <:status>
    <AdminComponents.status_badge status={interaction.status} />
  </:status>
```

**Helper pattern** (`interactions_live/index.ex` lines 94-109):

```elixir
defp count_status(interactions, status), do: Enum.count(interactions, &(&1.status == status))

defp redacted_handle(_type, nil), do: "Not recorded"
defp redacted_handle(type, value), do: Redaction.handle(type, value)

defp prompt_label(nil), do: "Not recorded"
defp prompt_label(value) when is_list(value), do: Enum.join(value, ", ")
defp prompt_label(value), do: to_string(value)

defp formatted_timestamp(nil), do: "Not recorded"
```

**Planner notes:** keep interaction shaping page-local unless all three queues need the same helper. Add pressure subtitles such as waiting/expired/completed/denied through private helpers rather than creating `operate_queue_row` by default.

---

### `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` (LiveView component, request-response/read-only)

**Analog:** `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex`, plus current `device_authorizations_live/index.ex`.

**Imports pattern** (`device_authorizations_live/index.ex` lines 4-9):

```elixir
use Phoenix.LiveView

alias Lockspire.Admin
alias Lockspire.Redaction
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive
```

**Read/error handling pattern** (`device_authorizations_live/index.ex` lines 93-98):

```elixir
defp load_device_authorizations do
  case Admin.list_device_authorizations() do
    {:ok, auths} -> auths
    {:error, _reason} -> []
  end
end
```

**Admin read boundary** (`lib/lockspire/admin/device_authorizations.ex` lines 9-13):

```elixir
@spec list_device_authorizations(keyword()) ::
        {:ok, [DeviceAuthorization.t()]} | {:error, term()}
def list_device_authorizations(opts \\ []) do
  Repository.list_device_authorizations(opts)
end
```

**Device row starting point** (`device_authorizations_live/index.ex` lines 71-83):

```elixir
<AdminComponents.dense_resource_row
  title="Device authorization"
  subtitle="Review device authorizations"
>
  <:meta>
    <span>Client <AdminComponents.long_value value={redacted_handle(:client, auth.client_id)} kind={:id} /></span>
    <span>Subject <AdminComponents.long_value value={redacted_handle(:account, auth.subject_id)} kind={:id} /></span>
    <span>Handle <AdminComponents.long_value value={redacted_handle(:device_authorization, auth.id || auth.verification_handle)} kind={:id} /></span>
    <span>Expires <AdminComponents.long_value value={formatted_timestamp(auth.expires_at)} kind={:timestamp} /></span>
  </:meta>
  <:status>
    <AdminComponents.status_badge status={auth.status} domain={:device_authorization} />
  </:status>
```

**Status-label analog** (`admin_components.ex` lines 665-670):

```elixir
defp status_metadata(:approved, :device_authorization),
  do: %{
    label: "Approved, waiting",
    tone: :waiting,
    title: "Approved device authorization awaiting completion"
  }
```

**Planner notes:** use available device fields only: `effective_poll_interval_seconds`, `next_poll_allowed_at`, `approved_at`, `denied_at`, `consumed_at`, `expired_at`, and `expires_at`. Do not reach for `auth.updated_at` unless a narrow internal read model is explicitly planned.

---

### `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` (LiveView component, request-response/read-only)

**Analog:** itself. It is the strongest Operate queue scan pattern.

**Imports and storage read** (`logout_deliveries_live/index.ex` lines 4-20):

```elixir
use Phoenix.LiveView

alias Lockspire.Redaction
alias Lockspire.Storage.Ecto.Repository
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive

@impl true
def mount(_params, _session, socket) do
  {:ok, deliveries} = Repository.list_all_logout_deliveries()

  {:ok,
   assign(socket,
     page_title: "Logout deliveries",
     current_section: :logouts,
     deliveries: deliveries,
     delivery_metrics: delivery_metrics(deliveries)
   )}
end
```

**Metrics pattern** (`logout_deliveries_live/index.ex` lines 86-94):

```elixir
defp delivery_metrics(deliveries) do
  %{
    waiting: Enum.count(deliveries, &(&1.status in [:pending, :enqueued])),
    retrying: Enum.count(deliveries, &(&1.status == :attempted)),
    failed: Enum.count(deliveries, &(&1.status == :retryable)),
    discarded: Enum.count(deliveries, &(&1.status in [:discarded, :skipped])),
    completed: Enum.count(deliveries, &(&1.status in [:succeeded, :rendered]))
  }
end
```

**Pressure/support-note pattern** (`logout_deliveries_live/index.ex` lines 117-147):

```elixir
defp delivery_pressure(%{status: status}) when status in [:pending, :enqueued],
  do: "Waiting for the protocol worker to attempt delivery."

defp delivery_pressure(%{status: :retryable}),
  do: "Retryable failure; verify the RP endpoint and preserve the delivery record."

defp delivery_pressure(%{status: status}) when status in [:discarded, :skipped],
  do: "Terminal queue outcome; use the record as support truth."

defp delivery_support_note(%{status: :retryable}),
  do:
    "Support note: confirm endpoint availability and client logout configuration before changing issuer policy."

defp delivery_support_note(_delivery),
  do:
    "Support note: use client, endpoint, attempts, and timestamp to triage without exposing secrets."
```

**Repository read pattern** (`lib/lockspire/storage/ecto/repository.ex` lines 763-772):

```elixir
@spec list_all_logout_deliveries() ::
        {:ok, [Lockspire.Domain.LogoutDelivery.t()]} | {:error, term()}
def list_all_logout_deliveries do
  LogoutDeliveryRecord
  |> order_by(desc: :inserted_at)
  |> repo().all()
  |> then(fn records -> {:ok, Enum.map(records, &LogoutDeliveryRecord.to_domain/1)} end)
rescue
  error -> {:error, error}
end
```

**Planner notes:** preserve this pattern. Add HTTP status or concise failure class only if it clarifies retryable/incident state and tests assert raw response bodies, endpoint secrets, Oban IDs, and worker internals remain absent.

---

### `lib/lockspire/web/components/admin_components.ex` (component, transform, conditional)

**Analog:** itself. Touch only if all three pages need a real shared primitive change.

**Function component conventions** (`admin_components.ex` lines 4-12):

```elixir
use Phoenix.Component

attr(:status, :atom, required: true)
attr(:domain, :atom, default: nil)
attr(:title, :string, default: nil)
attr(:class, :string, default: "")
attr(:rest, :global)

def status_badge(assigns) do
```

**Dense row slots** (`admin_components.ex` lines 438-459):

```elixir
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
```

**Long value pattern** (`admin_components.ex` lines 535-551):

```elixir
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
```

**Status metadata coverage** (`admin_components.ex` lines 672-710):

```elixir
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
```

**Planner notes:** do not create `operate_queue_row` or `operate_queue_page` by default. If shared component work happens, add/extend design-system contract and stress tests.

---

### `lib/lockspire/web/admin_css.ex` (style config, transform, conditional)

**Analog:** itself. Touch only if row wrapping/theme/focus/reduced-motion proof shows a shared gap.

**Token and focus pattern** (`admin_css.ex` lines 91-130 and 240-248):

```css
--ls-surface-page: var(--ls-color-gray-50);
--ls-surface-panel: #ffffff;
--ls-surface-muted: var(--ls-color-gray-100);
--ls-text-strong: var(--ls-color-gray-950);
--ls-text-body: var(--ls-color-gray-700);
--ls-text-muted: var(--ls-color-gray-500);
--ls-text-accent: var(--ls-color-brand-600);
--ls-focus-ring-color: var(--ls-color-brand-600);
--ls-focus-ring-width: 2px;
--ls-focus-ring-offset: 3px;
--ls-focus-ring-shadow: 0 0 0 3px var(--ls-color-brand-100);
```

```css
.lockspire-admin-nav-item:focus-visible,
.lockspire-admin-secondary-nav a:focus-visible,
.lockspire-admin-btn-primary:focus-visible,
.lockspire-admin-btn-secondary:focus-visible,
.lockspire-admin-btn-danger:focus-visible,
.lockspire-admin-resource-list a:focus-visible {
  outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);
  outline-offset: var(--ls-focus-ring-offset);
}
```

**Dense row wrapping/support note pattern** (`admin_css.ex` lines 562-587):

```css
.lockspire-admin-lifecycle-row__meta,
.lockspire-admin-dense-resource-row__meta {
  align-items: center;
  color: var(--ls-text-muted);
  display: flex;
  flex-wrap: wrap;
  gap: var(--ls-space-3);
  min-width: 0;
}

.lockspire-admin-dense-resource-row__note {
  background: var(--ls-surface-panel);
  border: 1px solid var(--ls-border-subtle);
  border-radius: var(--ls-radius-md);
  color: var(--ls-text-body);
  flex: 1 1 100%;
  padding: var(--ls-space-2) var(--ls-space-3);
}
```

**Long value wrapping** (`admin_css.ex` lines 1391-1402):

```css
.lockspire-admin-long-value {
  display: inline-block;
  max-width: 100%;
  min-width: 0;
  overflow-wrap: anywhere;
  word-break: break-word;
}

.lockspire-admin-long-value-mono {
  font-family: var(--ls-font-mono);
  font-variant-numeric: tabular-nums;
}
```

**Mobile/reduced-motion pattern** (`admin_css.ex` lines 1596-1723 and 1725-1740):

```css
@media (max-width: 720px) {
  .lockspire-admin-header,
  .lockspire-admin-body,
  .lockspire-admin-nav {
    padding-left: var(--ls-space-4);
    padding-right: var(--ls-space-4);
  }

  .lockspire-admin-pane__header,
  .lockspire-admin-entity-header,
  .lockspire-admin-lifecycle-row,
  .lockspire-admin-dense-resource-row,
  .lockspire-admin-task-card__header,
  .lockspire-admin-task-card__actions {
    align-items: stretch;
    flex-direction: column;
  }
}

@media (prefers-reduced-motion: reduce) {
  .lockspire-admin-shell *,
  .lockspire-admin-shell *::before,
  .lockspire-admin-shell *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto !important;
    transition-duration: 0.01ms !important;
  }
}
```

**Planner notes:** keep CSS BEM/token based. Do not introduce Tailwind, shadcn, arbitrary page-local class systems, or decorative animation.

---

### `test/lockspire/web/live/admin/interactions_live_test.exs` (test, rendered HTML/source fence)

**Analog:** itself, plus logout test for metric helper.

**Setup/imports pattern** (`interactions_live_test.exs` lines 1-10):

```elixir
defmodule Lockspire.Web.Live.Admin.InteractionsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Interaction
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.InteractionsLive.Index
  alias Phoenix.Router
```

**Fixture pattern** (`interactions_live_test.exs` lines 25-39):

```elixir
now = DateTime.utc_now()
expires_at = DateTime.add(now, 600, :second)

{:ok, interaction} =
  Repository.put_interaction(%Interaction{
    interaction_id: "test-interaction-123",
    client_id: "test-client",
    status: :pending_login,
    return_to: "http://example.com/return",
    expires_at: expires_at,
    inserted_at: now,
    updated_at: now
  })

%{interaction: interaction}
```

**Rendered proof pattern** (`interactions_live_test.exs` lines 48-96):

```elixir
assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/interactions", socket)

html = rendered_to_string(Index.render(socket.assigns))
page_html = page_markup(html)

HtmlAssertions.assert_no_duplicate_ids(page_html)
HtmlAssertions.assert_describedby_targets_exist(page_html)
HtmlAssertions.assert_no_generic_cta_text(page_html)

HtmlAssertions.assert_no_interactive_controls(page_html,
  text: unsupported_queue_control_text()
)

refute page_html =~ "<table"
refute page_html =~ "lockspire-admin-table-wrap"
refute page_html =~ "phx-click"
refute page_html =~ "phx-submit"
refute_unsupported_queue_controls(page_html)
```

**Unsupported-control helper** (`interactions_live_test.exs` lines 125-136):

```elixir
defp refute_unsupported_queue_controls(html) do
  refute Regex.match?(
           ~r/\b(Retry|Discard|Approve|Deny|Logout now|Worker control|Requeue)\b/i,
           html
         )
end

defp unsupported_queue_control_text do
  ["Retry", "Discard", "Approve", "Deny", "Logout now", "Worker control", "Requeue"]
end

defp page_markup(html), do: Regex.replace(~r/<style>.*?<\/style>/s, html, "")
```

**Planner notes:** extend with pending-login, pending-consent, denied, expired, completed, long identifiers, client/account redaction, prompt, age/created/expiry, no-table, and no-action proof.

---

### `test/lockspire/web/live/admin/device_authorizations_live_test.exs` (test, rendered HTML/source fence)

**Analog:** itself, plus interactions/logout tests.

**Endpoint/live setup pattern** (`device_authorizations_live_test.exs` lines 14-33):

```elixir
setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  Application.put_env(:lockspire, :mount_path, "")

  on_exit(fn ->
    Application.put_env(:lockspire, :mount_path, "/lockspire")
  end)

  Application.put_env(:lockspire, Lockspire.Web.Endpoint,
    secret_key_base: String.duplicate("a", 64),
    render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
    live_view: [signing_salt: "lockspire_salt"]
  )

  start_supervised!(Lockspire.TestRepo)
  start_supervised!(Lockspire.Web.Endpoint)
  Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

  :ok
end
```

**Sensitive fixture and denial pattern** (`device_authorizations_live_test.exs` lines 40-50 and 68-78):

```elixir
{:ok, _auth} =
  Repository.put_device_authorization(%DeviceAuthorization{
    device_code_hash: "hash1",
    user_code_hash: "hash2",
    verification_handle: "handle1",
    client_id: "test-client",
    status: :pending,
    effective_poll_interval_seconds: 5,
    next_poll_allowed_at: now,
    expires_at: DateTime.add(now, 3600, :second)
  })
```

```elixir
HtmlAssertions.assert_no_text(page_html, [
  "hash1",
  "hash2",
  "device_code",
  "user_code",
  "test-client"
])

HtmlAssertions.assert_no_interactive_controls(page_html,
  text: unsupported_queue_control_text()
)
```

**No-action/no-table proof** (`device_authorizations_live_test.exs` lines 88-102):

```elixir
assert page_html =~ "lockspire-admin-pane"
assert page_html =~ "lockspire-admin-resource-list"
assert page_html =~ "lockspire-admin-dense-resource-row"
assert page_html =~ "lockspire-admin-long-value"
assert page_html =~ "Device authorization"
refute page_html =~ "hash1"
refute page_html =~ "hash2"
refute page_html =~ "device_code"
refute page_html =~ "user_code"
refute page_html =~ "test-client"
refute page_html =~ "client_secret"
refute page_html =~ "phx-click"
refute page_html =~ "phx-submit"
```

**Planner notes:** extend with pending, approved, denied, expired, consumed, poll interval/next poll, no raw verification handle/code/hash, long-value wrapping, and no command labels.

---

### `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` (test, rendered HTML/source fence)

**Analog:** itself.

**SQL fixture pattern for logout deliveries** (`logout_deliveries_live_test.exs` lines 34-59):

```elixir
result =
  Ecto.Adapters.SQL.query!(
    Lockspire.TestRepo,
    "INSERT INTO lockspire_logout_events (event_id, sid, initiated_by, " <>
      "inserted_at, updated_at) VALUES ('test-logout-event-123', " <>
      "'test-sid', 'rp_initiated_logout', $1, $1) RETURNING id",
    [now]
  )

event_id = result.rows |> hd() |> hd()

for {delivery_id, client_id, status, attempt_count} <- [
      {"test-delivery-123", "test-client", "pending", 0},
      {"test-delivery-attempted", "test-client-attempted", "attempted", 1},
      {"test-delivery-retryable", "test-client-retryable", "retryable", 2}
    ] do
  Ecto.Adapters.SQL.query!(
    Lockspire.TestRepo,
    "INSERT INTO lockspire_logout_deliveries (delivery_id, " <>
      "logout_event_id, client_id, channel, target_uri, status, " <>
      "attempt_count, session_required, inserted_at, updated_at) " <>
      "VALUES ($1, $2, $3, 'backchannel', " <>
      "'http://example.com/logout', $4, $5, false, $6, $6)",
    [delivery_id, event_id, client_id, status, attempt_count, now]
  )
end
```

**Metric and row proof pattern** (`logout_deliveries_live_test.exs` lines 98-122):

```elixir
assert page_html =~ "Operate"
assert page_html =~ "Logout propagation queue"
assert page_html =~ "Review logout deliveries"
assert page_html =~ "Waiting"
assert page_html =~ "Retrying"
assert page_html =~ "Failed"
assert page_html =~ "Discarded"
assert page_html =~ "Completed"
assert summary_stat?(page_html, "Waiting", 1)
assert summary_stat?(page_html, "Retrying", 1)
assert summary_stat?(page_html, "Failed", 1)
assert page_html =~ "lockspire-admin-pane"
assert page_html =~ "lockspire-admin-resource-list"
assert page_html =~ "lockspire-admin-dense-resource-row"
assert page_html =~ "lockspire-admin-long-value"
assert page_html =~ "test-delivery-123"
assert page_html =~ "test-delivery-attempted"
assert page_html =~ "test-delivery-retryable"
refute page_html =~ "<table"
refute page_html =~ "lockspire-admin-table-wrap"
refute page_html =~ "phx-click"
refute page_html =~ "phx-submit"
```

**Metric helper and worker-control fence** (`logout_deliveries_live_test.exs` lines 153-171):

```elixir
defp summary_stat?(html, label, value) do
  Regex.match?(
    ~r/lockspire-admin-summary-value[^>]*>\s*#{value}\s*<.*?#{Regex.escape(label)}/s,
    html
  )
end

defp refute_unsupported_worker_controls(html) do
  refute Regex.match?(
           ~r/\b(Retry now|Discard|Logout now|Worker control|Requeue|Approve|Deny)\b/i,
           html
         )
end
```

**Planner notes:** extend fixture states to include retryable, discarded, skipped, rendered, succeeded/completed, long endpoint URL, and optional HTTP status/failure class if implemented.

---

### `test/lockspire/web/live/admin/design_system_contract_test.exs` (test, source contract, conditional)

**Analog:** itself. Touch only for source/API fences, shared primitive/CSS changes, or public-boundary assertions.

**Shared primitive contract pattern** (`design_system_contract_test.exs` lines 584-674):

```elixir
test "shared component primitives are exposed and backed by namespaced CSS" do
  components = File.read!(@admin_components_path)
  css = File.read!(@admin_css_path)

  for function_name <- [
        "page_hero",
        "metric_grid",
        "long_value",
        "empty_state",
        "status_badge",
        "pane",
        "status_cluster",
        "lifecycle_row",
        "dense_resource_row",
        "responsive_table"
      ] do
    assert components =~ "def #{function_name}"
  end

  for class <- [
        "lockspire-admin-hero",
        "lockspire-admin-page-hero",
        "lockspire-admin-metric-grid",
        "lockspire-admin-summary-stat",
        "lockspire-admin-long-value",
        "lockspire-admin-status-cluster",
        "lockspire-admin-pane",
        "lockspire-admin-dense-resource-row",
        "lockspire-admin-responsive-table"
      ] do
    assert css =~ "." <> class
  end
end
```

**Operate primitive contract** (`design_system_contract_test.exs` lines 1177-1183):

```elixir
for source <- @phase_119_operate_sources |> Enum.map(&File.read!/1) do
  assert source =~ "AdminComponents.pane"
  assert source =~ "AdminComponents.resource_list"
  assert source =~ "AdminComponents.dense_resource_row"
  assert source =~ "AdminComponents.status_badge"
  assert source =~ "AdminComponents.long_value"
end
```

**Copy/redaction/public-boundary fence** (`design_system_contract_test.exs` lines 1258-1290):

```elixir
test "phase 119 copy redaction and browser-boundary fences stay scoped" do
  sources = phase_119_source_blob()
  mix = File.read!(Path.expand("../../../../../mix.exs", __DIR__))

  for phrase <- [
        "DCR onboarding",
        "DCR policy",
        "post-logout redirect URIs",
        "logout propagation URIs",
        "Copy this value now. Lockspire stores only the hash after this response.",
        "redacted_handle",
        "plaintext",
        "copy_once_secret_panel"
      ] do
    assert sources =~ phrase
  end

  refute Regex.match?(
           ~r/(?:^|>|\n)\s*(Submit|Continue|Go|Manage)\s*(?:<|\n|$)/,
           sources
         )
```

**Internal lab/public route fence** (`design_system_contract_test.exs` lines 1723-1730):

```elixir
refute router =~ "component_lab"
refute router =~ "design_system_lab"

supported_surface = String.downcase(supported_surface)

for forbidden <- ["component lab", "design system lab", "design-system lab"] do
  refute supported_surface =~ forbidden
end
```

**Planner notes:** add a Phase 123 source/API fence here or in the route tests if needed: no new Operate mutation delegates in `Lockspire.Admin`, no new `/admin/operate` or detail routes, no `handle_event/3`, no `phx-click`/`phx-submit`, and no unsupported queue command labels.

---

### `test/lockspire/web/live/admin/design_system_component_stress_test.exs` (test, component stress, conditional)

**Analog:** itself. Touch only if shared components/CSS/AdminLab fixtures change.

**Fixture-key/state contract** (`design_system_component_stress_test.exs` lines 14-60):

```elixir
test "fixtures expose required lab keys and scenario states without forbidden values" do
  assert Fixtures.fixture_keys() == [
           :clients,
           :tokens,
           :consents,
           :keys,
           :dcr_iat,
           :operations,
           :structural_rows,
           :status_matrix,
           :theme_modes,
           :motion_modes
         ]

  for state <- [
        :normal,
        :empty,
        :error,
        :disabled,
        :destructive,
        :long_value,
        :dense_data,
        :light,
        :dark,
        :system,
        :reduced_motion,
        :warning,
        :incident,
        :expired,
        :revoked,
        :waiting,
        :completed
      ] do
    assert state in Fixtures.scenario_states()
  end

  fixture_blob = inspect(Fixtures.all())

  for forbidden <- Fixtures.forbidden_substrings() do
    refute fixture_blob =~ forbidden
  end
end
```

**Rendered stress proof** (`design_system_component_stress_test.exs` lines 62-77 and 127-160):

```elixir
html = render_component(&StressSurface.render/1, fixture_set: Fixtures.all())

HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_label_targets_exist(html)
HtmlAssertions.assert_no_text(html, Fixtures.forbidden_substrings())

for class <- [
      "lockspire-admin-page-hero",
      "lockspire-admin-badge-warning",
      "lockspire-admin-badge-danger",
      "lockspire-admin-pane",
      "lockspire-admin-dense-resource-row",
      "lockspire-admin-long-value",
      "lockspire-admin-empty"
    ] do
  assert html =~ class
end
```

**Planner notes:** if adding Operate lab fixtures, keep them redaction-safe and test-only. Do not add public routes or docs support claims for lab/browser evidence.

---

### `test/support/lockspire/web/admin_lab/fixtures.ex` (test fixture, batch transform, conditional)

**Analog:** itself. Touch only if shared primitive stress states are expanded.

**Scenario state pattern** (`fixtures.ex` lines 4-27):

```elixir
@scenario_states [
  :normal,
  :empty,
  :error,
  :disabled,
  :destructive,
  :long_value,
  :dense_data,
  :light,
  :dark,
  :system,
  :reduced_motion,
  :healthy,
  :warning,
  :incident,
  :self_registered,
  :expired,
  :revoked,
  :reuse_detected,
  :copy_once,
  :waiting,
  :completed,
  :provenance
]
```

**Forbidden substring/redaction pattern** (`fixtures.ex` lines 42-53):

```elixir
@forbidden_substrings [
  "real-client-secret",
  "production-secret",
  "prod-access-token",
  "prod-refresh-token",
  "customer.example.com",
  "tenant.example.com",
  "sk_live_",
  "pk_live_",
  "eyJhbGci",
  "BEGIN PRIVATE KEY"
]
```

**Operate-like structural rows** (`fixtures.ex` lines 135-153):

```elixir
structural_rows: [
  %{
    state: :pending,
    title: "Dense queue row with generated identifier",
    subtitle: "device_queue_01",
    identifier:
      "device_authorization_work_item_01JZ2Z6GZ8T3D8QPMTZZZZZZZZ_extremely_long_safe_identifier",
    actor: "redacted_actor_support_01",
    consequence: "Operator can inspect retry posture without token plaintext."
  },
  %{
    state: :reuse_detected,
    title: "Token family incident",
    subtitle: "family_reuse_detected",
    identifier: "redacted_handle_refresh_family_reuse_detected_01JZ2Z6GZ8T3D8QPMT",
    actor: "redacted_actor_security_02",
    consequence: "Reuse detection requires family-wide revocation proof."
  }
]
```

---

### `test/support/lockspire/web/admin_lab/stress_surface.ex` (component/test fixture, rendered transform, conditional)

**Analog:** itself. Touch only if `fixtures.ex` gains new Operate stress data.

**Component render setup** (`stress_surface.ex` lines 4-20):

```elixir
use Phoenix.Component

alias Lockspire.Web.AdminLab.Fixtures
alias Lockspire.Web.Components.AdminComponents

attr(:fixture_set, :map, required: true)

def render(assigns) do
  assigns =
    assigns
    |> assign_new(:states, fn -> Fixtures.scenario_states() end)
    |> assign_new(:clients, fn -> Map.get(assigns.fixture_set, :clients, []) end)
    |> assign_new(:tokens, fn -> Map.get(assigns.fixture_set, :tokens, []) end)
    |> assign_new(:operations, fn -> Map.get(assigns.fixture_set, :operations, []) end)
    |> assign_new(:structural_rows, fn -> Map.get(assigns.fixture_set, :structural_rows, []) end)
```

**Dense row stress pattern** (`stress_surface.ex` lines 155-170):

```elixir
<ul class="lockspire-admin-resource-list">
  <AdminComponents.dense_resource_row
    :for={row <- @structural_rows}
    title={row.title}
    subtitle={row.subtitle}
  >
    <:meta>
      <AdminComponents.long_value kind={:id} value={row.identifier} />
    </:meta>
    <:status>
      <AdminComponents.status_badge status={row.state} domain={:operate} />
    </:status>
    <:actions>
      <AdminComponents.admin_button>Inspect row</AdminComponents.admin_button>
    </:actions>
  </AdminComponents.dense_resource_row>
</ul>
```

**Planner notes:** for Phase 123, do not copy the `:actions` slot into Operate pages unless it is an existing safe route pivot and tests prove it is not a command control.

---

### `docs/operator-admin.md` (documentation, static docs, conditional)

**Analog:** itself. Update only if visible operator workflow truth changes.

**Journey boundary pattern** (`docs/operator-admin.md` lines 7-16):

```markdown
## Lockspire-owned operator journeys

Lockspire groups the admin surface by operator intent:

- **Orient**: use `/admin` or `/admin/overview` as the operator cockpit for client posture, security posture, key readiness, support incidents, and live protocol work.
- **Configure**: use `/admin/clients`, `/admin/policies`, `/admin/keys`, and `/admin/dcr` to manage client setup, issuer posture, key lifecycle, and partner intake.
- **Support**: use `/admin/consents` and `/admin/tokens` to investigate durable grant, token, refresh-family, account, client, and status questions.
- **Operate**: use `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts` to inspect live authorization work, device flow requests, and logout delivery pressure.

These routes live under the embedded Lockspire router and are meant for application operators.
```

**Host seam pattern** (`docs/operator-admin.md` lines 18-35):

````markdown
Mount the operator UI behind your host application's operator-auth pipeline. Lockspire does not authenticate your staff or decide who counts as an operator.

The generated router mounts `Lockspire.Web.AdminRouter` at `/lockspire/admin` before the general `Lockspire.Web.Router` forward:

```elixir
scope "/lockspire/admin" do
  pipe_through [:browser, :require_operator]
  forward "/", Lockspire.Web.AdminRouter
end
```
````

**Proof boundary pattern** (`docs/operator-admin.md` lines 50-68):

```markdown
The component lab and stress surface are internal maintainer proof only. They render real admin primitives and hostile redaction-safe fixture states for tests and local review, but they are not mounted through `Lockspire.Web.AdminRouter`, not a supported admin route, not a host extension point, and not part of `docs/supported-surface.md`.

Theme behavior is intentionally narrow:

- **System** is the default and follows `prefers-color-scheme`.
- **Light** and **Dark** are explicit admin-only choices exposed in the shell theme selector.
- Reduced-motion preferences must neutralize nonessential transitions and keep focus, form feedback, and queue state understandable without animation.
```

## Shared Patterns

### Route Boundary

**Source:** `lib/lockspire/web/admin_router.ex` lines 1-7 and 13-33
**Apply to:** all plans

```elixir
defmodule Lockspire.Web.AdminRouter do
  @moduledoc """
  Mountable Phoenix router exposing only Lockspire operator/admin LiveViews.

  Host applications should mount this router behind their own operator
  authentication pipeline before the general `Lockspire.Web.Router` forward.
  """

  scope "/" do
    live("/", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
    live("/overview", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
    live("/interactions", Lockspire.Web.Live.Admin.InteractionsLive.Index, :index)
    live("/logouts", Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index, :index)
    live(
      "/device_authorizations",
      Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index,
      :index
    )
  end
end
```

Do not add `/admin/operate`, detail routes, public lab routes, browser-proof routes, or support-surface routes.

### Read-Only Admin API Fence

**Source:** `lib/lockspire/admin.ex` lines 13-18, 142-175
**Apply to:** source/API fence tests and all Operate LiveViews

```elixir
@doc """
Lists device authorizations.
"""
@spec list_device_authorizations(keyword()) ::
        {:ok, [Lockspire.Domain.DeviceAuthorization.t()]} | {:error, term()}
defdelegate list_device_authorizations(opts \\ []), to: DeviceAuthorizations
```

Existing mutating delegates are for other domains (`revoke_consent`, `revoke_token`, `revoke_token_family`) and are not an Operate queue precedent. Phase 123 should not add `retry_*`, `discard_*`, `approve_*`, `deny_*`, `logout_now`, `requeue_*`, `pause_*`, `resume_*`, or worker-control delegates.

### Repository Read Shape

**Source:** `lib/lockspire/storage/ecto/repository.ex` lines 250-258, 329-336, 763-772
**Apply to:** any internal read-model or page-local loader

```elixir
def list_interactions(_opts \\ []) do
  InteractionRecord
  |> order_by(desc: :inserted_at)
  |> repo().all()
  |> then(fn records -> {:ok, Enum.map(records, &InteractionRecord.to_domain/1)} end)
rescue
  error -> {:error, error}
end
```

```elixir
def list_device_authorizations(opts \\ []) when is_list(opts) do
  DeviceAuthorizationRecord
  |> order_by([auth], desc: auth.inserted_at)
  |> repo().all()
  |> then(fn records -> {:ok, Enum.map(records, &DeviceAuthorizationRecord.to_domain/1)} end)
rescue
  error -> {:error, error}
end
```

### Redaction And Long Values

**Source:** `logout_deliveries_live/index.ex` lines 101-102 and `admin_components.ex` lines 540-551
**Apply to:** all three Operate queues and tests

```elixir
defp redacted_handle(_type, nil), do: "Not recorded"
defp redacted_handle(type, value), do: Redaction.handle(type, value)
```

```elixir
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
```

Never render raw OAuth/OIDC material, device/user codes, hashes, raw verification handles, logout token JTI, Oban job IDs, raw params, raw response bodies, cookies, or endpoint secrets.

### HTML Assertions

**Source:** `test/support/lockspire/web/admin_proof/html_assertions.ex` lines 16-63 and 153-184
**Apply to:** all Operate route tests and stress tests

```elixir
def assert_no_duplicate_ids(html) do
  ids =
    html
    |> document()
    |> LazyHTML.query("[id]")
    |> LazyHTML.attribute("id")
    |> Enum.reject(&(&1 == ""))

  duplicates =
    ids
    |> Enum.frequencies()
    |> Enum.filter(fn {_id, count} -> count > 1 end)

  assert duplicates == [],
         "expected rendered HTML to have unique IDs, found duplicates: #{inspect(duplicates)}"

  html
end
```

```elixir
def assert_no_interactive_controls(html, opts \\ []) do
  source = html_source(html)

  opts
  |> Keyword.get(:events, ["phx-click", "phx-submit"])
  |> Enum.each(fn event ->
    refute source =~ event, "expected rendered HTML to omit interactive event #{inspect(event)}"
  end)

  opts
  |> Keyword.get(:text, [])
  |> Enum.each(fn text ->
    refute Regex.match?(~r/\b#{Regex.escape(text)}\b/i, source),
           "expected rendered HTML to omit unsupported control text #{inspect(text)}"
  end)

  html
end
```

### Design-System Source Contracts

**Source:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 584-674 and 1177-1183
**Apply to:** shared component/CSS changes and final source fence

```elixir
for source <- @phase_119_operate_sources |> Enum.map(&File.read!/1) do
  assert source =~ "AdminComponents.pane"
  assert source =~ "AdminComponents.resource_list"
  assert source =~ "AdminComponents.dense_resource_row"
  assert source =~ "AdminComponents.status_badge"
  assert source =~ "AdminComponents.long_value"
end
```

### Internal Lab Boundary

**Source:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs` lines 230-244
**Apply to:** any AdminLab fixture/stress changes

```elixir
test "component lab stays internal, test-only, and outside package/public routes" do
  router = File.read!(@admin_router_path)
  mix = File.read!(@mix_path)
  supported_surface = File.read!(@supported_surface_path)

  assert Path.expand("../../../../support/lockspire/web/admin_lab/fixtures.ex", __DIR__) =~
           "/test/support/lockspire/web/admin_lab/fixtures.ex"

  refute mix =~ ~r/files:\s+~w\([^)]*test\/support/

  for forbidden <- ["component-lab", "component_lab", "design-system-lab", "design_system_lab"] do
    refute router =~ forbidden
    refute supported_surface =~ forbidden
  end
end
```

## No Analog Found

None. All planned and conditional files have exact or role-equivalent analogs in the current codebase.

## Metadata

**Analog search scope:** `lib/lockspire/web/live/admin`, `lib/lockspire/web/components`, `lib/lockspire/web`, `lib/lockspire/admin*`, `lib/lockspire/storage/ecto/repository.ex`, `test/lockspire/web/live/admin`, `test/support/lockspire/web`, `docs`
**Files scanned:** 129
**Pattern extraction date:** 2026-06-29
**Dirty worktree note:** source analogs were read from the current working tree. Unrelated user changes were not reverted or modified.
