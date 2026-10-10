defmodule Lockspire.Web.Live.Admin.ClientsLive.RotateSecretComponent do
  @moduledoc false

  use Phoenix.Component

  alias Lockspire.Web.Components.AdminComponents

  attr(:errors, :list, default: [])
  attr(:revealed_secret, :string, default: nil)

  def rotation_panel(assigns) do
    ~H"""
    <section class="lockspire-admin-form-shell">
      <header>
        <h2>Rotate client secret</h2>
        <p>
          If rotation succeeds, the previous secret stops being the current credential. Use the
          new client secret to authenticate this confidential client at the token endpoint.
          Plaintext is shown once and is not stored or re-shown by Lockspire.
        </p>
      </header>

      <AdminComponents.error_list errors={@errors} />

      <AdminComponents.copy_once_secret_panel
        :if={@revealed_secret}
        title="New client secret"
        body="Plaintext is shown once. Copy the client secret now; it is not stored or re-shown by Lockspire."
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
