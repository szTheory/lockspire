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
       policy: nil,
       policy_state: :loading,
       form: nil,
       form_errors: [],
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
             save_notice:
               "This change applies to future registrations only. Existing client records keep their stored configuration."
           )
           |> put_flash(:info, "Global DCR policy updated")}

        {:error, errors} when is_list(errors) ->
          {:noreply,
           assign(socket,
             form: form,
             form_errors: safe_service_errors(errors),
             save_notice: nil
           )}

        {:error, _reason} ->
          {:noreply,
           assign(socket,
             form: form,
             form_errors: [
               %{field: :base, message: "DCR policy was not saved. Your changes are still here."}
             ],
             save_notice: nil
           )}
      end
    else
      errors = format_changeset_errors(changeset)
      {:noreply, assign(socket, form: form, form_errors: errors, save_notice: nil)}
    end
  end

  def handle_event("save_policy", _params, socket) do
    {:noreply,
     assign(socket,
       form_errors: [
         %{field: :base, message: "DCR policy is unavailable. Reload it before saving changes."}
       ],
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
          save_notice: nil,
          private_key_jwt_truth: nil,
          client_secret_jwt_truth: nil
        )

      _result ->
        assign(socket,
          policy: nil,
          policy_state: :unavailable,
          form: nil,
          form_errors: [],
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
      [] -> [%{field: :base, message: "DCR policy was not saved. Your changes are still here."}]
      values -> values
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
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} ->
      %{field: field, message: "#{field_label(field)}: #{Enum.join(messages, ", ")}"}
    end)
  end

  def field_errors(errors, field) do
    Enum.filter(errors, &(Map.get(&1, :field) == field))
  end

  def field_error_attrs(field_id, errors) do
    if field_errors(errors, field_id_to_field(field_id)) == [] do
      nil
    else
      "#{field_id}-error"
    end
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

  defp field_label(:registration_policy), do: "Registration mode"
  defp field_label(:dcr_allowed_scopes), do: "Allowed scopes"
  defp field_label(:dcr_allowed_grant_types), do: "Allowed grant types"
  defp field_label(:dcr_allowed_response_types), do: "Allowed response types"
  defp field_label(:dcr_allowed_redirect_uri_schemes), do: "Allowed redirect URI schemes"
  defp field_label(:dcr_allowed_redirect_uri_hosts), do: "Allowed redirect URI hosts"

  defp field_label(:dcr_allowed_token_endpoint_auth_methods),
    do: "Allowed token endpoint auth methods"

  defp field_label(:dcr_default_client_lifetime_seconds), do: "Default client lifetime"

  defp field_label(:dcr_default_client_secret_lifetime_seconds),
    do: "Default client secret lifetime"

  defp field_label(:dcr_default_registration_access_token_lifetime_seconds),
    do: "Default Registration Access Token lifetime"

  defp field_label(_field), do: "DCR policy"

  defp comma_value(value) when is_list(value), do: Enum.join(value, ", ")
  defp comma_value(value) when is_binary(value), do: value
  defp comma_value(_value), do: ""

  defp registration_policy_label(:disabled), do: "Disabled"
  defp registration_policy_label(:initial_access_token), do: "Initial Access Token gated"
  defp registration_policy_label(:open), do: "Open registration"
  defp registration_policy_label(value), do: value |> to_string() |> String.replace("_", " ")

  defp registration_policy_tone(:disabled), do: :neutral
  defp registration_policy_tone(:initial_access_token), do: :success
  defp registration_policy_tone(:open), do: :warning
  defp registration_policy_tone(_value), do: :info

  defp registration_policy_detail(:disabled), do: "No new clients can self-register."

  defp registration_policy_detail(:initial_access_token),
    do: "Partners need a valid intake token before metadata is accepted."

  defp registration_policy_detail(:open),
    do: "Unauthenticated registration is allowed within issuer metadata allowlists and lifetimes."

  defp registration_policy_detail(_value), do: "Issuer registration posture."

  defp allowlist_summary(%ServerPolicy{} = policy) do
    counts = [
      {"scopes", policy.dcr_allowed_scopes},
      {"grant types", policy.dcr_allowed_grant_types},
      {"response types", policy.dcr_allowed_response_types},
      {"schemes", policy.dcr_allowed_redirect_uri_schemes},
      {"hosts", policy.dcr_allowed_redirect_uri_hosts}
    ]

    configured =
      counts
      |> Enum.filter(fn {_label, values} -> values not in [nil, []] end)
      |> Enum.map(fn {label, values} -> "#{length(values)} #{label}" end)

    case configured do
      [] -> "No metadata allowlists"
      values -> Enum.join(values, ", ")
    end
  end

  defp auth_methods_summary(%ServerPolicy{dcr_allowed_token_endpoint_auth_methods: methods})
       when methods in [nil, []],
       do: "No auth methods allowed"

  defp auth_methods_summary(%ServerPolicy{dcr_allowed_token_endpoint_auth_methods: methods}) do
    Enum.join(methods, ", ")
  end

  defp lifetime_summary(%ServerPolicy{} = policy) do
    values = [
      policy.dcr_default_client_lifetime_seconds,
      policy.dcr_default_client_secret_lifetime_seconds,
      policy.dcr_default_registration_access_token_lifetime_seconds
    ]

    if Enum.any?(values, &configured_lifetime?/1) do
      "Default lifetimes configured"
    else
      "No default expiry limits"
    end
  end

  defp configured_lifetime?(value) when is_integer(value), do: value > 0
  defp configured_lifetime?(_value), do: false
end
