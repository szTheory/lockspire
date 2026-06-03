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
        <p>Lockspire reveals the new secret once. It is redacted immediately after this state.</p>
      </header>

      <AdminComponents.error_list errors={@errors} />

      <div :if={@revealed_secret} class="lockspire-admin-secret-reveal">
        <h3>New client secret</h3>
        <code>{@revealed_secret}</code>
        <p>Copy it now. Lockspire does not store or re-show plaintext secrets.</p>
      </div>

      <form phx-submit="rotate_secret">
        <label class="lockspire-admin-checkbox-field">
          <input type="checkbox" name="rotate[confirm]" value="true" />
          <span>I understand the previous secret stops being the current credential after rotation.</span>
        </label>

        <AdminComponents.action_bar>
          <AdminComponents.admin_button type="submit" variant={:danger}>
            Rotate secret
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>
      </form>
    </section>
    """
  end
end
