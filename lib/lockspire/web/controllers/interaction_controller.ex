defmodule Lockspire.Web.InteractionController do
  @moduledoc """
  Delivery adapter for host login handoff and consent finalization.
  """

  use Phoenix.Controller, formats: [:html]

  alias Lockspire.Host.Claims
  alias Lockspire.Protocol.AuthorizationFlow
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AuthorizeHTML

  def show(conn, %{"interaction_id" => interaction_id}) do
    with {:ok, interaction} <- fetch_interaction(interaction_id),
         {:ok, subject_context} <- resolve_subject_context(conn, interaction),
         outcome <-
           AuthorizationFlow.resume_interaction(
             interaction_id,
             subject_context,
             protocol_store_opts()
           ) do
      case outcome do
        {:consent_required, interaction} ->
          redirect(conn, to: consent_path(interaction.interaction_id))

        {:consent_reused, redirect_uri} ->
          redirect(conn, external: redirect_uri)

        {:error, reason} ->
          render_browser_error(conn, interaction_error(reason), :bad_request)
      end
    else
      {:error, %Error{} = error} ->
        render_browser_error(conn, error, :bad_request)
    end
  end

  def complete(conn, %{"interaction_id" => interaction_id, "decision" => decision} = params) do
    with {:ok, interaction} <- fetch_interaction(interaction_id),
         {:ok, subject_context} <- resolve_subject_context(conn, interaction),
         outcome <- finalize_interaction(interaction_id, decision, subject_context, params) do
      case outcome do
        {:approved, redirect_uri} ->
          redirect(conn, external: redirect_uri)

        {:denied, redirect_uri} ->
          redirect(conn, external: redirect_uri)

        {:error, reason} ->
          render_browser_error(conn, interaction_error(reason), :bad_request)
      end
    else
      {:error, %Error{} = error} ->
        render_browser_error(conn, error, :bad_request)
    end
  end

  def complete(conn, _params) do
    render_browser_error(
      conn,
      interaction_error(:invalid_decision, "Consent decision must be approve or deny"),
      :bad_request
    )
  end

  defp finalize_interaction(interaction_id, "approve", subject_context, params) do
    AuthorizationFlow.approve_interaction(
      interaction_id,
      subject_context,
      Keyword.merge(protocol_store_opts(), remember: truthy_param?(params["remember"]))
    )
  end

  defp finalize_interaction(interaction_id, "deny", subject_context, _params) do
    AuthorizationFlow.deny_interaction(interaction_id, subject_context, protocol_store_opts())
  end

  defp finalize_interaction(_interaction_id, _decision, _subject_context, _params) do
    {:error, :invalid_decision}
  end

  defp fetch_interaction(interaction_id) do
    case Repository.fetch_interaction(interaction_id) do
      {:ok, nil} ->
        {:error,
         interaction_error(:interaction_not_found, "Authorization interaction could not be found")}

      {:ok, interaction} ->
        {:ok, interaction}

      {:error, _reason} ->
        {:error,
         interaction_error(
           :interaction_lookup_failed,
           "Unable to load the authorization interaction"
         )}
    end
  end

  defp resolve_subject_context(conn, interaction) do
    resolver = Lockspire.account_resolver!()

    context = %Lockspire.Host.Context{
      interaction_id: interaction.interaction_id,
      return_to: consent_path(interaction.interaction_id),
      client_id: interaction.client_id,
      scopes: interaction.scopes_requested,
      resources: interaction.resources_requested
    }

    case resolver.resolve_current_account(conn, context) do
      {:ok, account} ->
        case resolver.build_claims(account, context) do
          {:ok, %Claims{} = claims} ->
            {:ok, %{subject_id: claims.subject}}

          {:error, _reason} ->
            {:error,
             interaction_error(
               :account_claims_failed,
               "Unable to build account claims for this authorization interaction"
             )}
        end

      {:redirect, _result} ->
        {:error,
         interaction_error(
           :authentication_required,
           "Sign in is required before continuing this authorization interaction"
         )}

      {:error, _reason} ->
        {:error,
         interaction_error(
           :account_resolution_failed,
           "Unable to resolve the current account for this authorization interaction"
         )}
    end
  end

  defp consent_path(interaction_id) do
    Lockspire.mount_path() <> "/consent/" <> interaction_id
  end

  defp render_browser_error(conn, %Error{} = error, status) do
    conn
    |> put_status(status)
    |> put_resp_content_type("text/html")
    |> send_resp(status, AuthorizeHTML.error_page(error))
  end

  defp interaction_error(:interaction_expired),
    do: interaction_error(:interaction_expired, "Authorization interaction has expired")

  defp interaction_error(:subject_mismatch),
    do:
      interaction_error(
        :subject_mismatch,
        "Authorization interaction does not belong to this account"
      )

  defp interaction_error(reason_code),
    do: interaction_error(reason_code, "Unable to continue this authorization interaction")

  defp interaction_error(:interaction_expired, description),
    do: %Error{
      error: "server_error",
      error_description: description,
      reason_code: :interaction_expired
    }

  defp interaction_error(:subject_mismatch, description),
    do: %Error{
      error: "server_error",
      error_description: description,
      reason_code: :subject_mismatch
    }

  defp interaction_error(reason_code, description) do
    %Error{
      error: "server_error",
      error_description: description,
      reason_code: reason_code
    }
  end

  defp truthy_param?(value), do: value in ["true", "1", 1, true, "on"]

  defp protocol_store_opts do
    [
      interaction_store: Repository,
      consent_store: Repository,
      token_store: Repository
    ]
  end
end
