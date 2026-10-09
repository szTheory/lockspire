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
        No lifecycle action is available for this key right now.
      </p>

      <AdminComponents.confirmation_panel
        :if={:publish in @key_detail.next_actions}
        title="Publish key"
      >
        <:body>
          <form class="lockspire-admin-form-stack" phx-submit="publish_key">
            <label class="lockspire-admin-checkbox-field">
              <input type="checkbox" name="publish[confirm]" value="true" />
              <span>
                Publish this public key so it is served in JWKS before activation.
                Key <AdminComponents.long_value value={@key_detail.key.handle} kind={:id} />
                becomes available to verifiers while the current signer remains active.
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
      >
        <:body>
          <form class="lockspire-admin-form-stack" phx-submit="activate_key">
            <label class="lockspire-admin-checkbox-field">
              <input type="checkbox" name="activate[confirm]" value="true" />
              <span>
                Activate this public key only when verifiers can accept the cutover signer.
                Key <AdminComponents.long_value value={@key_detail.key.handle} kind={:id} />
                becomes active; the previous signer moves to retiring overlap and remains in JWKS.
              </span>
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
        variant={:danger}
      >
        <:body>
          <form class="lockspire-admin-form-stack" phx-submit="retire_key">
            <label class="lockspire-admin-checkbox-field">
              <input type="checkbox" name="retire[confirm]" value="true" />
              <span>
                Retire this public key only after verifiers have moved off publication overlap.
                Key <AdminComponents.long_value value={@key_detail.key.handle} kind={:id} />
                leaves the served JWKS when retirement succeeds.
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
end
