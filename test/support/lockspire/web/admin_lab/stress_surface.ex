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

      <AdminComponents.metric_grid wide>
        <AdminComponents.summary_stat value={length(@clients)} label="Client scenarios" />
        <AdminComponents.summary_stat value={length(@tokens)} label="Token families" />
        <AdminComponents.summary_stat value={Enum.count(@operations, &(&1.state == :dense_data))} label="Dense rows" />
      </AdminComponents.metric_grid>

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

      <AdminComponents.error_summary
        errors={[
          "Redirect URI must match a registered exact URI.",
          %{field: :client_name, reason: :too_long, detail: [count: 160]}
        ]}
      />

      <AdminComponents.section_card title="Accessible form primitives">
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
end
