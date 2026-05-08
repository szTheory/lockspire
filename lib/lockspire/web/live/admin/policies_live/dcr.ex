defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dcr do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Admin.ServerPolicy, as: AdminServerPolicy
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr.PolicyForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "DCR policy",
       current_section: :policies,
       form_errors: []
     )
     |> load_policy()}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_policy", %{"policy" => policy_params}, socket) do
    changeset = PolicyForm.changeset(policy_params)

    if changeset.valid? do
      policy_attrs = Ecto.Changeset.apply_changes(changeset)
      attrs = Map.from_struct(policy_attrs)

      case Admin.put_dcr_policy(attrs) do
        {:ok, %ServerPolicy{} = policy} ->
          {:noreply,
           socket
           |> assign(
             policy: policy,
             private_key_jwt_truth: dcr_private_key_jwt_truth(policy),
             form_errors: []
           )
           |> put_flash(:info, "Global DCR policy updated")}

        {:error, errors} when is_list(errors) ->
          {:noreply, assign(socket, form_errors: errors)}

        {:error, _reason} ->
          {:noreply,
           assign(socket,
             form_errors: [%{field: :registration_policy, reason: :request_failed, detail: nil}]
           )}
      end
    else
      errors = format_changeset_errors(changeset)
      {:noreply, assign(socket, form_errors: errors)}
    end
  end

  defp load_policy(socket) do
    policy =
      case Admin.get_server_policy() do
        {:ok, %ServerPolicy{} = p} -> p
        {:error, _reason} -> %ServerPolicy{registration_policy: :disabled}
      end

    assign(socket, policy: policy, private_key_jwt_truth: dcr_private_key_jwt_truth(policy))
  end

  defp dcr_private_key_jwt_truth(%ServerPolicy{} = policy) do
    AdminServerPolicy.private_key_jwt_registration_truth(policy)
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} ->
      %{field: field, reason: Enum.join(messages, ", "), detail: nil}
    end)
  end
end
