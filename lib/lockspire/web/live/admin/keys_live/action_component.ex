defmodule Lockspire.Web.Live.Admin.KeysLive.ActionComponent do
  @moduledoc false

  use Phoenix.Component

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

      <form :if={:publish in @key_detail.next_actions} phx-submit="publish_key">
        <label>
          <input type="checkbox" name="publish[confirm]" value="true" />
          Publish this upcoming key so verifiers can see it before cutover.
        </label>
        <button type="submit">Publish key</button>
      </form>

      <form :if={:activate in @key_detail.next_actions} phx-submit="activate_key">
        <label>
          <input type="checkbox" name="activate[confirm]" value="true" />
          Activate this published key and move the current signer into retiring overlap.
        </label>
        <button type="submit">Activate key</button>
      </form>

      <form :if={:retire in @key_detail.next_actions} phx-submit="retire_key">
        <label>
          <input type="checkbox" name="retire[confirm]" value="true" />
          Retire this overlap key after verifiers have moved off it.
        </label>
        <button type="submit">Retire key</button>
      </form>
    </div>
    """
  end
end
