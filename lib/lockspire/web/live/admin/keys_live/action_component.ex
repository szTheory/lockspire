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
      <p :if={@action_error}>{@action_error}</p>
      <p :if={@action_notice}>{@action_notice}</p>

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
              <span>Publish this upcoming key so verifiers can see it before cutover.</span>
            </label>
            <AdminComponents.action_bar>
              <AdminComponents.admin_button type="submit" variant={:primary}>
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
              <span>Activate this published key and move the current signer into retiring overlap.</span>
            </label>
            <AdminComponents.action_bar>
              <AdminComponents.admin_button type="submit" variant={:primary}>
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
              <span>Retire this overlap key after verifiers have moved off it.</span>
            </label>
            <AdminComponents.action_bar>
              <AdminComponents.admin_button type="submit" variant={:danger}>
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
