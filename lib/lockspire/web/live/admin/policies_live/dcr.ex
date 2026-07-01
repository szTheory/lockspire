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
             client_secret_jwt_truth: dcr_client_secret_jwt_truth(policy),
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

    assign(socket,
      policy: policy,
      private_key_jwt_truth: dcr_private_key_jwt_truth(policy),
      client_secret_jwt_truth: dcr_client_secret_jwt_truth(policy)
    )
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
      %{field: field, reason: Enum.join(messages, ", "), detail: nil}
    end)
  end

  defp registration_policy_label(:disabled), do: "Disabled"
  defp registration_policy_label(:initial_access_token), do: "IAT-gated"
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
    do: "Unauthenticated registration is allowed; keep allowlists and lifetimes narrow."

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
