defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dcr do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr.PolicyForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "DCR policy",
       current_section: :policies
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

      # Convert the struct map to a map that can be passed to the domain logic.
      # Wait, put_dcr_policy might take a map of attrs. Let's check Admin module.
      attrs = Map.from_struct(policy_attrs)

      case Admin.put_dcr_policy(attrs) do
        {:ok, %ServerPolicy{} = policy} ->
          {:noreply,
           socket
           |> assign(policy: policy)
           |> assign_form(policy)
           |> put_flash(:info, "Global DCR policy updated")}

        {:error, errors} when is_list(errors) ->
          # Generic form errors from backend, if any
          {:noreply,
           assign(socket,
             form:
               Ecto.Changeset.add_error(changeset, :registration_policy, "Request failed",
                 detail: errors
               )
           )}

        {:error, _reason} ->
          {:noreply,
           assign(socket,
             form: Ecto.Changeset.add_error(changeset, :registration_policy, "Request failed")
           )}
      end
    else
      {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp load_policy(socket) do
    policy =
      case Admin.get_server_policy() do
        {:ok, %ServerPolicy{} = p} -> p
        {:error, _reason} -> %ServerPolicy{registration_policy: :disabled}
      end

    socket
    |> assign(policy: policy)
    |> assign_form(policy)
  end

  defp assign_form(socket, %ServerPolicy{} = policy) do
    attrs = %{
      registration_policy: policy.registration_policy,
      dcr_allowed_scopes: policy.dcr_allowed_scopes,
      dcr_allowed_grant_types: policy.dcr_allowed_grant_types,
      dcr_allowed_response_types: policy.dcr_allowed_response_types,
      dcr_allowed_redirect_uri_schemes: policy.dcr_allowed_redirect_uri_schemes,
      dcr_allowed_redirect_uri_hosts: policy.dcr_allowed_redirect_uri_hosts,
      dcr_allowed_token_endpoint_auth_methods: policy.dcr_allowed_token_endpoint_auth_methods,
      dcr_default_client_lifetime_seconds: policy.dcr_default_client_lifetime_seconds,
      dcr_default_client_secret_lifetime_seconds:
        policy.dcr_default_client_secret_lifetime_seconds,
      dcr_default_registration_access_token_lifetime_seconds:
        policy.dcr_default_registration_access_token_lifetime_seconds
    }

    changeset = PolicyForm.changeset(%PolicyForm{}, attrs)
    assign(socket, form: to_form(changeset))
  end
end
