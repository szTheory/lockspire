defmodule Lockspire.Web.Live.Admin.ClientsLive.RotateSecretComponent do
  @moduledoc false

  use Phoenix.Component

  attr(:errors, :list, default: [])
  attr(:revealed_secret, :string, default: nil)

  def rotation_panel(assigns) do
    ~H"""
    <section class="lockspire-admin-form-shell">
      <header>
        <h2>Rotate client secret</h2>
        <p>Lockspire reveals the new secret once. It is redacted immediately after this state.</p>
      </header>

      <ul :if={@errors != []} class="lockspire-admin-errors">
        <%= for error <- @errors do %>
          <li>{error_message(error)}</li>
        <% end %>
      </ul>

      <div :if={@revealed_secret} class="lockspire-admin-secret-reveal">
        <h3>New client secret</h3>
        <code>{@revealed_secret}</code>
        <p>Copy it now. Lockspire does not store or re-show plaintext secrets.</p>
      </div>

      <form phx-submit="rotate_secret">
        <label>
          <input type="checkbox" name="rotate[confirm]" value="true" />
          I understand the previous secret stops being the current credential after rotation.
        </label>

        <button type="submit">Rotate secret</button>
      </form>
    </section>
    """
  end

  defp error_message(%{field: field, reason: reason, detail: detail}) do
    "#{field} #{reason} #{inspect(detail)}"
  end

  defp error_message(other), do: inspect(other)
end
