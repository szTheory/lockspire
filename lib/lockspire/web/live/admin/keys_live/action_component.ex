defmodule Lockspire.Web.Live.Admin.KeysLive.ActionComponent do
  @moduledoc false

  use Phoenix.Component

  alias Lockspire.Web.Components.AdminComponents

  attr(:key_detail, :map, required: true)
  attr(:action_error, :string, default: nil)
  attr(:action_notice, :string, default: nil)

  def lifecycle_actions(assigns) do
    ~H"""
    <div>
      <ul :if={@action_error} class="lockspire-admin-errors" role="alert">
        <li>{@action_error}</li>
      </ul>
      <p :if={@action_notice} role="status" class="lockspire-admin-help lockspire-admin-help-block">
        {@action_notice}
      </p>

      <p :if={@key_detail.next_actions == []}>
        No further action is available for this key.
      </p>

      <AdminComponents.confirmation_panel
        :if={:publish in @key_detail.next_actions}
        title="Publish key"
        embedded={true}
      >
        <:body>
          <form class="lockspire-admin-form-stack" phx-submit="publish_key">
            <label class="lockspire-admin-checkbox-field">
              <input type="checkbox" name="publish[confirm]" value="true" />
              <span>
                {publish_consequence(@key_detail.key.use)}
              </span>
            </label>
            <AdminComponents.action_bar>
              <AdminComponents.admin_button
                type="submit"
                variant={:primary}
                phx-disable-with="Publishing key…"
              >
                Publish key
              </AdminComponents.admin_button>
            </AdminComponents.action_bar>
          </form>
        </:body>
      </AdminComponents.confirmation_panel>

      <AdminComponents.confirmation_panel
        :if={:activate in @key_detail.next_actions}
        title="Activate key"
        embedded={true}
      >
        <:body>
          <form class="lockspire-admin-form-stack" phx-submit="activate_key">
            <label class="lockspire-admin-checkbox-field">
              <input type="checkbox" name="activate[confirm]" value="true" />
              <span>{activation_consequence(@key_detail.key.use)}</span>
            </label>
            <AdminComponents.action_bar>
              <AdminComponents.admin_button
                type="submit"
                variant={:primary}
                phx-disable-with="Activating key…"
              >
                Activate key
              </AdminComponents.admin_button>
            </AdminComponents.action_bar>
          </form>
        </:body>
      </AdminComponents.confirmation_panel>

      <AdminComponents.confirmation_panel
        :if={:retire in @key_detail.next_actions}
        title="Retire key"
        embedded={true}
        variant={:danger}
      >
        <:body>
          <form class="lockspire-admin-form-stack" phx-submit="retire_key">
            <label class="lockspire-admin-checkbox-field">
              <input type="checkbox" name="retire[confirm]" value="true" />
              <span>
                Remove this key from the public list only after connected apps have switched to its replacement.
              </span>
            </label>
            <AdminComponents.action_bar>
              <AdminComponents.admin_button
                type="submit"
                variant={:danger}
                phx-disable-with="Retiring key…"
              >
                Retire key
              </AdminComponents.admin_button>
            </AdminComponents.action_bar>
          </form>
        </:body>
      </AdminComponents.confirmation_panel>
    </div>
    """
  end

  defp publish_consequence(:sig),
    do:
      "Publish this key so connected apps can recognize it before the signing key changes. The current key remains active."

  defp publish_consequence(:enc),
    do:
      "Publish this encryption key so connected apps can prepare to encrypt authorization requests with it. The current encryption key remains active."

  defp publish_consequence(_use),
    do:
      "Publish this key so connected apps can recognize it before activation. The current key remains active."

  defp activation_consequence(:sig),
    do:
      "New tokens will use this key. The previous key stays available to apps while they switch."

  defp activation_consequence(:enc),
    do:
      "New encrypted data will use this key. The previous key stays available to decrypt existing data."

  defp activation_consequence(_use),
    do:
      "Make this the active key for its purpose. The previous key stays available while apps switch."
end
