defmodule Lockspire.Web.Live.Admin.ClientsLive.RotateSecretComponent do
  @moduledoc false

  use Phoenix.Component

  alias Lockspire.Web.Components.AdminComponents

  attr(:errors, :list, default: [])
  attr(:revealed_secret, :string, default: nil)
  attr(:show_heading, :boolean, default: true)

  def rotation_panel(assigns) do
    ~H"""
    <section class="lockspire-admin-form-shell">
      <header :if={@show_heading}>
        <h2>Rotate client secret</h2>
        <p>
          After rotation, the app must use the new secret to get tokens. The new secret is
          shown once. Lockspire stores only a hash and can't show it again.
        </p>
      </header>

      <AdminComponents.error_list errors={@errors} />

      <AdminComponents.copy_once_secret_panel
        :if={@revealed_secret}
        title="New client secret"
        body="Copy this secret now. It is shown once, and Lockspire stores only a hash."
        label="Client secret"
        value={@revealed_secret}
      />
      <AdminComponents.action_bar :if={@revealed_secret}>
        <AdminComponents.admin_button phx-click="acknowledge_secret">
          I have copied the client secret
        </AdminComponents.admin_button>
      </AdminComponents.action_bar>

      <form :if={is_nil(@revealed_secret)} phx-submit="rotate_secret">
        <label class="lockspire-admin-checkbox-field">
          <input type="checkbox" name="rotate[confirm]" value="true" />
          <span>I understand the previous secret stops being the current credential after rotation.</span>
        </label>

        <AdminComponents.action_bar>
          <AdminComponents.admin_button
            type="submit"
            variant={:danger}
            phx-disable-with="Rotating client secret…"
          >
            Rotate client secret
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>
      </form>
    </section>
    """
  end
end
