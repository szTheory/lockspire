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
          The previous secret stops being the current credential after rotation. Plaintext is shown once.
          Lockspire does not store or re-show it.
        </p>
      </header>

      <AdminComponents.error_list errors={@errors} />

      <AdminComponents.copy_once_secret_panel
        :if={@revealed_secret}
        title="New client secret"
        body="Plaintext is shown once. Copy it now; Lockspire does not store or re-show it after this response."
        label="Client secret"
        value={@revealed_secret}
      />

      <form phx-submit="rotate_secret">
        <label class="lockspire-admin-checkbox-field">
          <input type="checkbox" name="rotate[confirm]" value="true" />
          <span>I understand the previous secret stops being the current credential after rotation.</span>
        </label>

        <AdminComponents.action_bar>
          <AdminComponents.admin_button type="submit" variant={:danger}>
            Rotate client secret
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>
      </form>
    </section>
    """
  end
end
