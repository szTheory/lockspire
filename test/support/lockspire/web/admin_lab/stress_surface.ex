defmodule Lockspire.Web.AdminLab.StressSurface do
  @moduledoc false

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
      |> assign_new(:status_matrix, fn -> Map.get(assigns.fixture_set, :status_matrix, []) end)
      |> assign_new(:proof_matrix, fn -> Map.get(assigns.fixture_set, :proof_matrix, []) end)
      |> assign_new(:copy_once, fn ->
        assigns.fixture_set |> Map.get(:dcr_iat, []) |> List.first()
      end)
      |> assign_new(:redirect_uri, fn ->
        assigns.fixture_set
        |> Map.get(:clients, [])
        |> List.first(%{})
        |> Map.get(:redirect_uri, "")
      end)

    ~H"""
    <section
      data-lab-surface="component-stress"
      data-theme-mode="light dark system"
      data-motion-mode="default reduced-motion"
      aria-label="Render stress surface"
    >
      <AdminComponents.page_hero
        eyebrow="Component lab"
        title="Render stress surface"
        body="Component lab proof drifted from the design-system contract when required states are missing."
      >
        <:summary>
          <AdminComponents.badge_group>
            <AdminComponents.status_badge status={:active} />
            <AdminComponents.status_badge status={:warning} />
            <AdminComponents.status_badge status={:reuse_detected} />
          </AdminComponents.badge_group>
        </:summary>
        <:actions>
          <AdminComponents.admin_button variant={:primary}>Create registration token</AdminComponents.admin_button>
          <AdminComponents.admin_button disabled href="/lockspire/admin/clients">
            Disabled link action
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <p>
        normal empty error disabled destructive long-value dense-data light dark system
        reduced-motion healthy warning incident self-registered expired revoked reuse-detected
        copy-once redacted
      </p>

      <AdminComponents.pane
        title="PROOF-01 shared fixture matrix"
        subtitle="D-04/D-05/D-06/D-16 internal test-support coverage."
        data-proof-surface="admin-capability-matrix"
      >
        <:status>
          <AdminComponents.status_badge status={:provenance} domain={:configure} />
        </:status>

        <AdminComponents.status_cluster>
          <span
            :for={class <- proof_matrix_classes(@proof_matrix)}
            class="lockspire-admin-badge lockspire-admin-badge-provenance"
            data-fixture-class={class}
          >
            {proof_matrix_label(class)}
          </span>
        </AdminComponents.status_cluster>

        <ul class="lockspire-admin-resource-list">
          <li
            :for={entry <- @proof_matrix}
            class="lockspire-admin-dense-resource-row"
            data-fixture-state={entry.state}
            data-fixture-class={entry.class}
          >
            <div class="lockspire-admin-dense-resource-row__main">
              <strong>{entry.label}</strong>
              <span>{proof_matrix_label(entry.class)}</span>
              <p :if={Map.get(entry, :consequence)}>{entry.consequence}</p>
            </div>
            <div class="lockspire-admin-dense-resource-row__meta">
              <span :if={!is_nil(Map.get(entry, :count))}>count {entry.count}</span>
              <span :if={Map.get(entry, :display_value)}>{entry.display_value}</span>
              <span :if={Map.get(entry, :journey)}>{entry.journey}</span>
              <span :if={Map.get(entry, :theme)}>{entry.theme}</span>
              <span :if={Map.get(entry, :motion)}>{entry.motion}</span>
              <span :if={Map.get(entry, :focus_path)}>{entry.focus_path}</span>
              <span :if={Map.get(entry, :viewport_width)}>{entry.viewport_width}px</span>
              <span :if={Map.get(entry, :route)}>{entry.route}</span>
              <span :if={Map.get(entry, :support_surface)}>{entry.support_surface}</span>
              <AdminComponents.long_value
                :if={Map.get(entry, :long_id)}
                kind={:id}
                value={entry.long_id}
              />
              <AdminComponents.long_value
                :if={Map.get(entry, :long_url)}
                kind={:url}
                value={entry.long_url}
              />
              <AdminComponents.long_value
                :if={Map.get(entry, :value)}
                kind={:token}
                value={entry.value}
                redacted
              />
            </div>
          </li>
        </ul>
      </AdminComponents.pane>

      <AdminComponents.entity_header
        eyebrow="Configure"
        title="Acme Ledger client"
        subtitle="Shared entity header proof with long identifiers, status, and actions."
        identifier="client_acme_ledger_public_01JZ2Z6GZ8T3D8QPMTZZZZZZZZ"
      >
        <:status>
          <AdminComponents.status_badge status={:active} domain={:configure} />
          <AdminComponents.status_badge status={:self_registered_client} domain={:configure} />
        </:status>
        <:actions>
          <AdminComponents.action_group>
            <:primary>
              <AdminComponents.admin_button variant={:primary}>Review client</AdminComponents.admin_button>
            </:primary>
            <:secondary>
              <AdminComponents.admin_button disabled href="/lockspire/admin/clients/client_acme">
                Disabled link action
              </AdminComponents.admin_button>
            </:secondary>
          </AdminComponents.action_group>
        </:actions>
      </AdminComponents.entity_header>

      <AdminComponents.metric_grid wide>
        <AdminComponents.summary_stat value={length(@clients)} label="Client scenarios" />
        <AdminComponents.summary_stat value={length(@tokens)} label="Token families" />
        <AdminComponents.summary_stat value={Enum.count(@operations, &(&1.state == :dense_data))} label="Dense rows" />
      </AdminComponents.metric_grid>

      <AdminComponents.decision_summary>
        <:item
          label="Registration gate"
          value="IAT-gated"
          tone={:success}
          detail="Partners need a valid intake token before self-registration metadata is accepted."
        >
        </:item>
        <:item
          label="Metadata allowlists"
          value="3 scopes, 2 grant types, 1 long redirect host"
          tone={:info}
          detail="Decision summaries must keep dense policy state readable without becoming a second form."
        >
        </:item>
        <:item
          label="Open-registration risk"
          value="Not enabled"
          tone={:warning}
          detail="Warning tone is available for policies that admit unauthenticated registration."
        >
        </:item>
      </AdminComponents.decision_summary>

      <AdminComponents.section_card
        title="Long operator data"
        subtitle="This group intentionally contains awkward real-world strings."
      >
        <AdminComponents.resource_list>
          <AdminComponents.resource_item
            :for={client <- @clients}
            title={client.name}
            subtitle={client.id}
            href={"/lockspire/admin/clients/#{client.id}"}
          >
            <:meta>
              <AdminComponents.long_value kind={:url} value={client.redirect_uri} />
              <AdminComponents.long_value kind={:token} value={client.secret_handle} redacted />
            </:meta>
            <:status>
              <AdminComponents.status_badge status={client.state} />
            </:status>
          </AdminComponents.resource_item>
        </AdminComponents.resource_list>
      </AdminComponents.section_card>

      <AdminComponents.pane title="DS-02 structural primitives" subtitle="Dense rows, lifecycle rows, and table/list alternatives.">
        <:status>
          <AdminComponents.status_badge status={:pending} domain={:support} />
        </:status>
        <:actions>
          <AdminComponents.admin_button>Secondary pane action</AdminComponents.admin_button>
        </:actions>

        <AdminComponents.status_cluster>
          <AdminComponents.status_badge
            :for={entry <- @status_matrix}
            status={entry.status}
            domain={entry.domain}
          />
        </AdminComponents.status_cluster>

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

        <AdminComponents.lifecycle_row
          title="Lifecycle consequence proof"
          state={:reuse_detected}
          domain={:support}
          actor="redacted_actor_security_02"
          timestamp={~U[2026-06-25 20:00:00Z]}
          consequence="Family-wide revocation is required when reuse is detected."
        >
          <:actions>
            <AdminComponents.action_group>
              <:destructive>
                <AdminComponents.admin_button variant={:danger}>Revoke affected family</AdminComponents.admin_button>
              </:destructive>
            </AdminComponents.action_group>
          </:actions>
        </AdminComponents.lifecycle_row>

        <AdminComponents.responsive_table caption="Responsive table and list alternative">
          <:thead>
            <tr><th>Queue item</th><th>Status</th></tr>
          </:thead>
          <:tbody>
            <tr><td>Device authorization attempts</td><td>Attempted</td></tr>
          </:tbody>
          <:list>
            <AdminComponents.dense_resource_row title="Empty table/list alternative" subtitle="List alternative">
              <:status><AdminComponents.status_badge status={:skipped} domain={:operate} /></:status>
            </AdminComponents.dense_resource_row>
          </:list>
          <:empty>
            <AdminComponents.empty_state title="No queue items" body="No table rows are available for this filter." />
          </:empty>
        </AdminComponents.responsive_table>
      </AdminComponents.pane>

      <AdminComponents.error_summary
        errors={[
          "Redirect URI must match a registered exact URI.",
          %{field: :client_name, reason: :too_long, detail: [count: 160]}
        ]}
      />

      <AdminComponents.section_card title="Accessible form primitives">
        <AdminComponents.workflow_shell
          title="Workflow shell validation proof"
          help="The page owns form submission while the shell owns calm validation chrome."
          errors={["Redirect URI must match a registered exact URI."]}
        >
          <p>Workflow body keeps mutation copy explicit.</p>
          <:actions>
            <AdminComponents.admin_button variant={:primary}>Run deterministic guardrails</AdminComponents.admin_button>
          </:actions>
        </AdminComponents.workflow_shell>

        <AdminComponents.form_field
          id="stress-redirect-uri"
          label="Redirect URI"
          help="Use an exact HTTPS URI owned by the relying party."
          errors={["Enter a registered redirect URI."]}
          required
        >
          <input
            id="stress-redirect-uri"
            name="redirect_uri"
            aria-invalid="true"
            aria-describedby="stress-redirect-uri-help stress-redirect-uri-error"
            value={@redirect_uri}
          />
        </AdminComponents.form_field>

        <AdminComponents.form_field
          id="stress-read-only-secret"
          label="Client secret hash"
          help="Stored hash is shown for correlation only."
        >
          <input id="stress-read-only-secret" readonly value="redacted_handle_secret_hash_v1" />
        </AdminComponents.form_field>
      </AdminComponents.section_card>

      <AdminComponents.copy_once_secret_panel
        title="Copy-once credential"
        body="Copy this value now. Lockspire stores only the hash after this response."
        value={@copy_once && @copy_once.value}
      />

      <AdminComponents.confirmation_panel
        title="Revoke token family"
        variant={:danger}
        errors={["Type the client ID before revoking this family."]}
      >
        <:body>
          Revoking this family invalidates all active refresh tokens for the selected client and account.
        </:body>
        <:actions>
          <AdminComponents.action_group>
            <:destructive>
              <AdminComponents.admin_button variant={:danger}>Revoke token family</AdminComponents.admin_button>
            </:destructive>
            <:secondary>
              <AdminComponents.admin_button>Keep token family active</AdminComponents.admin_button>
            </:secondary>
          </AdminComponents.action_group>
        </:actions>
      </AdminComponents.confirmation_panel>

      <AdminComponents.empty_state
        title="No lab scenarios rendered"
        body="This empty state protects the lab when fixture data is missing."
      />
    </section>
    """
  end

  defp proof_matrix_classes(entries) do
    entries
    |> Enum.map(&Map.fetch!(&1, :class))
    |> Enum.uniq()
  end

  defp proof_matrix_label(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
  end

  defp proof_matrix_label(value), do: to_string(value)
end
