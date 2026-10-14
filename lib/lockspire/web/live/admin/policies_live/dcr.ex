defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dcr do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Admin.ServerPolicy, as: AdminServerPolicy
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr.LifetimeHint
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr.PolicyForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "App registration settings",
       current_section: :policies,
       policy: nil,
       policy_state: :loading,
       form: nil,
       form_errors: [],
       show_error_summary: false,
       save_notice: nil
     )
     |> load_policy()}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("reload_policy", _params, socket) do
    {:noreply, load_policy(socket)}
  end

  def handle_event(
        "preview_policy",
        %{"policy" => policy_params},
        %{assigns: %{policy_state: :loaded}} = socket
      ) do
    params = Map.merge(socket.assigns.form.params, policy_params)
    errors = params |> PolicyForm.changeset() |> format_changeset_errors()

    {:noreply,
     assign(socket,
       form: to_form(params, as: :policy),
       form_errors: errors,
       show_error_summary: false,
       save_notice: nil
     )}
  end

  def handle_event("preview_policy", _params, socket), do: {:noreply, socket}

  def handle_event(
        "save_policy",
        %{"policy" => policy_params},
        %{assigns: %{policy_state: :loaded}} = socket
      ) do
    changeset = PolicyForm.changeset(policy_params)
    form = to_form(policy_params, as: :policy)

    if changeset.valid? do
      policy_attrs = Ecto.Changeset.apply_changes(changeset)
      attrs = Map.from_struct(policy_attrs)

      case Admin.put_dcr_policy(attrs) do
        {:ok, %ServerPolicy{} = policy} ->
          {:noreply,
           socket
           |> assign(
             policy: policy,
             policy_state: :loaded,
             form: policy_form(policy),
             private_key_jwt_truth: dcr_private_key_jwt_truth(policy),
             client_secret_jwt_truth: dcr_client_secret_jwt_truth(policy),
             form_errors: [],
             show_error_summary: false,
             save_notice: "App registration settings saved. Existing apps are unchanged."
           )
           |> put_flash(:info, "App registration settings saved")}

        {:error, errors} when is_list(errors) ->
          {:noreply,
           assign(socket,
             form: form,
             form_errors: safe_service_errors(errors),
             show_error_summary: true,
             save_notice: nil
           )}

        {:error, _reason} ->
          {:noreply,
           assign(socket,
             form: form,
             form_errors: [
               %{
                 field: :base,
                 message: "App registration settings were not saved. Your changes are still here."
               }
             ],
             show_error_summary: true,
             save_notice: nil
           )}
      end
    else
      errors = format_changeset_errors(changeset)

      {:noreply,
       assign(socket, form: form, form_errors: errors, show_error_summary: true, save_notice: nil)}
    end
  end

  def handle_event("save_policy", _params, socket) do
    {:noreply,
     assign(socket,
       form_errors: [
         %{
           field: :base,
           message: "App registration settings are unavailable. Reload before saving changes."
         }
       ],
       show_error_summary: true,
       save_notice: nil
     )}
  end

  defp load_policy(socket) do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} ->
        assign(socket,
          policy: policy,
          policy_state: :loaded,
          form: policy_form(policy),
          form_errors: [],
          show_error_summary: false,
          save_notice: nil,
          private_key_jwt_truth: dcr_private_key_jwt_truth(policy),
          client_secret_jwt_truth: dcr_client_secret_jwt_truth(policy)
        )

      {:error, _reason} ->
        assign(socket,
          policy: nil,
          policy_state: :unavailable,
          form: nil,
          form_errors: [],
          show_error_summary: false,
          save_notice: nil,
          private_key_jwt_truth: nil,
          client_secret_jwt_truth: nil
        )
    end
  end

  defp policy_form(%ServerPolicy{} = policy) do
    policy
    |> Map.from_struct()
    |> Enum.map(fn {field, value} -> {Atom.to_string(field), value} end)
    |> Map.new()
    |> then(&to_form(&1, as: :policy))
  end

  defp safe_service_errors(errors) do
    safe_errors =
      Enum.map(errors, fn error ->
        field = Map.get(error, :field, :base)

        %{field: field, message: "#{field_label(field)} could not be saved."}
      end)

    case safe_errors do
      [] ->
        [
          %{
            field: :base,
            message: "App registration settings were not saved. Your changes are still here."
          }
        ]

      values ->
        values
    end
  end

  defp dcr_private_key_jwt_truth(%ServerPolicy{} = policy) do
    AdminServerPolicy.private_key_jwt_registration_truth(policy)
  end

  defp dcr_client_secret_jwt_truth(%ServerPolicy{} = policy) do
    AdminServerPolicy.client_secret_jwt_registration_truth(policy)
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      cond do
        opts[:type] == :integer and opts[:validation] == :cast ->
          "Enter a whole number of seconds, such as 60."

        opts[:validation] == :number and opts[:kind] == :greater_than_or_equal_to ->
          "Enter zero or a positive number of seconds."

        opts[:validation] == :number and opts[:kind] == :less_than_or_equal_to ->
          "Enter 2,147,483,647 seconds or less."

        true ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
      end
    end)
    |> Enum.map(fn {field, messages} ->
      inline_message =
        if field == :registration_policy,
          do: "Choose who can register apps.",
          else: Enum.join(messages, " ")

      %{
        field: field,
        message: "#{field_label(field)}: #{inline_message}",
        inline_message: inline_message
      }
    end)
  end

  def field_errors(errors, field) do
    Enum.filter(errors, &(Map.get(&1, :field) == field))
  end

  def field_error_attrs(field_id, errors) do
    if field_errors(errors, field_id_to_field(field_id)) == [] do
      "#{field_id}-help"
    else
      "#{field_id}-help #{field_id}-error"
    end
  end

  def lifetime_described_by(field_id, errors) do
    [
      "#{field_id}-help",
      "#{field_id}-info",
      "#{field_id}-duration",
      field_errors(errors, field_id_to_field(field_id)) != [] && "#{field_id}-error"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  defp field_id_to_field("registration_policy"), do: :registration_policy
  defp field_id_to_field("dcr_allowed_scopes"), do: :dcr_allowed_scopes
  defp field_id_to_field("dcr_allowed_grant_types"), do: :dcr_allowed_grant_types
  defp field_id_to_field("dcr_allowed_response_types"), do: :dcr_allowed_response_types

  defp field_id_to_field("dcr_allowed_redirect_uri_schemes"),
    do: :dcr_allowed_redirect_uri_schemes

  defp field_id_to_field("dcr_allowed_redirect_uri_hosts"), do: :dcr_allowed_redirect_uri_hosts

  defp field_id_to_field("dcr_allowed_token_endpoint_auth_methods"),
    do: :dcr_allowed_token_endpoint_auth_methods

  defp field_id_to_field("dcr_default_client_lifetime_seconds"),
    do: :dcr_default_client_lifetime_seconds

  defp field_id_to_field("dcr_default_client_secret_lifetime_seconds"),
    do: :dcr_default_client_secret_lifetime_seconds

  defp field_id_to_field("dcr_default_registration_access_token_lifetime_seconds"),
    do: :dcr_default_registration_access_token_lifetime_seconds

  defp field_id_to_field(_field_id), do: :base

  defp field_label(:registration_policy), do: "Registration access"
  defp field_label(:dcr_allowed_scopes), do: "Allowed scopes"
  defp field_label(:dcr_allowed_grant_types), do: "Allowed grant types"
  defp field_label(:dcr_allowed_response_types), do: "Allowed response types"
  defp field_label(:dcr_allowed_redirect_uri_schemes), do: "Allowed sign-in return URL schemes"
  defp field_label(:dcr_allowed_redirect_uri_hosts), do: "Allowed sign-in return URL hosts"

  defp field_label(:dcr_allowed_token_endpoint_auth_methods),
    do: "Allowed methods"

  defp field_label(:dcr_default_client_lifetime_seconds), do: "App lifetime"

  defp field_label(:dcr_default_client_secret_lifetime_seconds),
    do: "Client secret lifetime"

  defp field_label(:dcr_default_registration_access_token_lifetime_seconds),
    do: "App management token lifetime"

  defp field_label(_field), do: "App registration settings"
end
