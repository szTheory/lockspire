defmodule Lockspire.Web.ConsentContext do
  @moduledoc """
  Prepares the small, redaction-safe render context for a host-owned consent page.

  Host LiveViews call `load/2` with their current connection or socket and the
  interaction identifier from the route. Lockspire performs the authoritative
  interaction lookup, account resolution, subject binding, expiration checks,
  and remembered-consent transition before returning decision-capable facts.

  The returned context deliberately excludes repository records, account and
  interaction identifiers, redirect URIs, raw authorization details, tokens,
  and protocol errors. A redirect result is terminal and must be performed
  without rendering its destination.
  """

  alias Lockspire.Host.Claims
  alias Lockspire.Protocol.AuthorizationFlow
  alias Lockspire.Storage.Ecto.Repository

  @type render_context :: %{
          required(:page_title) => String.t(),
          required(:client_name) => String.t() | nil,
          required(:requested_scopes) => [String.t()],
          required(:authorization_detail_types) => [String.t()],
          required(:remember?) => boolean(),
          required(:finalize_path) => String.t()
        }

  @type error_reason :: :not_found | :expired | :subject_mismatch | :unavailable

  @spec load(Plug.Conn.t() | Phoenix.LiveView.Socket.t() | term(), String.t()) ::
          {:ok, render_context()} | {:redirect, String.t()} | {:error, error_reason()}
  def load(conn_or_socket, interaction_id) when is_binary(interaction_id) do
    with {:ok, interaction} <- fetch_interaction(interaction_id),
         {:ok, subject_context} <- resolve_subject_context(conn_or_socket, interaction),
         {:ok, interaction} <- ensure_ready_for_consent(interaction, subject_context),
         {:ok, client} <- fetch_client(interaction.client_id) do
      {:ok,
       %{
         page_title: "Authorize Access",
         client_name: client.name,
         requested_scopes: interaction.scopes_requested,
         authorization_detail_types:
           authorization_detail_types(interaction.authorization_details),
         remember?: true,
         finalize_path: finalize_path(interaction.interaction_id)
       }}
    else
      {:redirect, redirect_uri} -> {:redirect, redirect_uri}
      {:error, reason} -> {:error, error_reason(reason)}
    end
  end

  def load(_conn_or_socket, _interaction_id), do: {:error, :not_found}

  defp fetch_interaction(interaction_id) do
    case Repository.fetch_interaction(interaction_id) do
      {:ok, nil} -> {:error, :interaction_not_found}
      {:ok, interaction} -> {:ok, interaction}
      {:error, _reason} -> {:error, :interaction_lookup_failed}
    end
  end

  defp fetch_client(client_id) do
    case Repository.fetch_client_by_id(client_id) do
      {:ok, nil} -> {:error, :client_not_found}
      {:ok, client} -> {:ok, client}
      {:error, _reason} -> {:error, :client_lookup_failed}
    end
  end

  defp resolve_subject_context(conn_or_socket, interaction) do
    resolver = Lockspire.account_resolver!()

    context = %Lockspire.Host.Context{
      interaction_type: :consent,
      interaction_id: interaction.interaction_id,
      return_to: consent_path(interaction.interaction_id),
      client_id: interaction.client_id,
      scopes: interaction.scopes_requested,
      resources: interaction.resources_requested
    }

    with {:ok, account} <- resolver.resolve_current_account(conn_or_socket, context),
         {:ok, %Claims{} = claims} <- resolver.build_claims(account, context) do
      {:ok, %{subject_id: claims.subject}}
    else
      {:redirect, _result} -> {:error, :authentication_required}
      {:error, _reason} -> {:error, :account_resolution_failed}
      _other -> {:error, :account_claims_failed}
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
          {:error, reason} -> {:error, reason}
        end

      :pending_consent when interaction.account_id == subject_context.subject_id ->
        {:ok, interaction}

      :pending_consent ->
        {:error, :subject_mismatch}

      :expired ->
        {:error, :interaction_expired}

      _other ->
        {:error, :interaction_not_active}
    end
  end

  defp error_reason(:interaction_not_found), do: :not_found
  defp error_reason(:interaction_expired), do: :expired
  defp error_reason(:subject_mismatch), do: :subject_mismatch
  defp error_reason(_reason), do: :unavailable

  defp consent_path(interaction_id), do: Lockspire.mount_path() <> "/consent/" <> interaction_id

  defp finalize_path(interaction_id),
    do: Lockspire.mount_path() <> "/interactions/" <> interaction_id <> "/complete"

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
