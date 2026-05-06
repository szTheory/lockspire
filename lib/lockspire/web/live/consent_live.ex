defmodule Lockspire.Web.ConsentLive do
  @moduledoc """
  Reference consent surface rendered from durable interaction state.
  """

  use Phoenix.LiveView

  alias Lockspire.Host.Claims
  alias Lockspire.Protocol.AuthorizationFlow
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Storage.Ecto.Repository

  @impl true
  def mount(%{"interaction_id" => interaction_id}, _session, socket) do
    case load_consent_context(socket, interaction_id) do
      {:ok, assigns} ->
        {:ok, assign(socket, assigns)}

      {:redirect, redirect_uri} ->
        {:ok, redirect(socket, external: redirect_uri)}

      {:error, %Error{} = error} ->
        {:ok,
         assign(socket,
           page_title: "Authorization Error",
           error: error,
           interaction_id: interaction_id
         )}
    end
  end

  @impl true
  def render(%{error: %Error{} = error} = assigns) do
    assigns = assign(assigns, :error_message, error.error_description)

    ~H"""
    <section class="lockspire-consent-error">
      <h1>Authorization request rejected</h1>
      <p>{@error_message}</p>
      <p>Reason: <code>{@error.reason_code}</code></p>
    </section>
    """
  end

  def render(assigns) do
    ~H"""
    <section class="lockspire-consent-shell">
      <header>
        <p class="eyebrow">Host-owned consent review</p>
        <h1>{@page_title}</h1>
        <p>
          <strong>{@client_name}</strong>
          wants access to these scopes for account
          <code>{@subject_id}</code>.
        </p>
      </header>

      <ul>
        <%= for scope <- @requested_scopes do %>
          <li>{scope}</li>
        <% end %>
      </ul>

      <%= if @authorization_details != [] do %>
        <section class="lockspire-consent-rar">
          <h2>authorization_details</h2>
          <ul>
            <%= for type <- @authorization_detail_types do %>
              <li>{type}</li>
            <% end %>
          </ul>
          <pre>{Jason.encode_to_iodata!(@authorization_details, pretty: true)}</pre>
        </section>
      <% end %>

      <p>
        Brand, copy, and product framing stay in the host app. Lockspire remains the authority
        for interaction validity and the final redirect.
      </p>

      <form action={@finalize_path} method="post">
        <input type="hidden" name="decision" value="approve" />
        <label>
          <input type="checkbox" name="remember" value="true" checked />
          Remember this consent for future matching requests
        </label>
        <button type="submit" class="approve-submit">Approve access</button>
      </form>

      <form action={@finalize_path} method="post">
        <input type="hidden" name="decision" value="deny" />
        <button type="submit" class="deny-submit">Deny access</button>
      </form>
    </section>
    """
  end

  defp load_consent_context(socket, interaction_id) do
    with {:ok, interaction} <- fetch_interaction(interaction_id),
         {:ok, subject_context} <- resolve_subject_context(socket, interaction),
         {:ok, interaction} <- ensure_ready_for_consent(interaction, subject_context),
         {:ok, client} <- fetch_client(interaction.client_id) do
      {:ok,
       %{
         page_title: "Authorize Access",
         interaction_id: interaction.interaction_id,
         client_name: client.name || interaction.client_id,
         client_id: interaction.client_id,
         requested_scopes: interaction.scopes_requested,
         authorization_details: interaction.authorization_details,
         authorization_detail_types: authorization_detail_types(interaction.authorization_details),
         subject_id: subject_context.subject_id,
         finalize_path: finalize_path(interaction.interaction_id),
         error: nil
       }}
    else
      {:redirect, redirect_uri} ->
        {:redirect, redirect_uri}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp fetch_interaction(interaction_id) do
    case Repository.fetch_interaction(interaction_id) do
      {:ok, nil} ->
        {:error,
         consent_error(:interaction_not_found, "Authorization interaction could not be found")}

      {:ok, interaction} ->
        {:ok, interaction}

      {:error, _reason} ->
        {:error,
         consent_error(:interaction_lookup_failed, "Unable to load the authorization interaction")}
    end
  end

  defp fetch_client(client_id) do
    case Repository.fetch_client_by_id(client_id) do
      {:ok, nil} ->
        {:error, consent_error(:client_not_found, "OAuth client details could not be loaded")}

      {:ok, client} ->
        {:ok, client}

      {:error, _reason} ->
        {:error, consent_error(:client_lookup_failed, "Unable to load OAuth client details")}
    end
  end

  defp resolve_subject_context(socket, interaction) do
    resolver = Lockspire.account_resolver!()

    context = %Lockspire.Host.Context{
      interaction_id: interaction.interaction_id,
      return_to: consent_path(interaction.interaction_id),
      client_id: interaction.client_id,
      scopes: interaction.scopes_requested,
      resources: interaction.resources_requested
    }

    case resolver.resolve_current_account(socket, context) do
      {:ok, account} ->
        case resolver.build_claims(account, context) do
          {:ok, %Claims{} = claims} ->
            {:ok, %{subject_id: claims.subject}}

          {:error, _reason} ->
            {:error,
             consent_error(
               :account_claims_failed,
               "Unable to build account claims for this authorization interaction"
             )}
        end

      {:redirect, _result} ->
        {:error,
         consent_error(
           :authentication_required,
           "Sign in is required before reviewing this authorization request"
         )}

      {:error, _reason} ->
        {:error,
         consent_error(
           :account_resolution_failed,
           "Unable to resolve the current account for this authorization request"
         )}
    end
  end

  defp ensure_ready_for_consent(interaction, subject_context) do
    case interaction.status do
      :pending_login ->
        case AuthorizationFlow.resume_interaction(
               interaction.interaction_id,
               subject_context,
               protocol_store_opts()
             ) do
          {:consent_required, resumed_interaction} -> {:ok, resumed_interaction}
          {:consent_reused, redirect_uri} -> {:redirect, redirect_uri}
          {:error, reason} -> {:error, consent_error(reason)}
        end

      :pending_consent ->
        if interaction.account_id == subject_context.subject_id do
          {:ok, interaction}
        else
          {:error,
           consent_error(
             :subject_mismatch,
             "Authorization interaction does not belong to this account"
           )}
        end

      :expired ->
        {:error, consent_error(:interaction_expired, "Authorization interaction has expired")}

      _other ->
        {:error,
         consent_error(:interaction_not_active, "Authorization interaction is no longer active")}
    end
  end

  defp consent_path(interaction_id) do
    Lockspire.mount_path() <> "/consent/" <> interaction_id
  end

  defp finalize_path(interaction_id) do
    Lockspire.mount_path() <> "/interactions/" <> interaction_id <> "/complete"
  end

  defp consent_error(
         reason_code,
         description \\ "Unable to continue this authorization interaction"
       ) do
    %Error{
      error: "server_error",
      error_description: description,
      reason_code: reason_code
    }
  end

  defp protocol_store_opts do
    [
      interaction_store: Repository,
      consent_store: Repository,
      token_store: Repository
    ]
  end

  defp authorization_detail_types(authorization_details) do
    authorization_details
    |> Enum.map(&Map.get(&1, "type"))
    |> Enum.reject(&is_nil/1)
  end
end
