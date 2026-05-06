defmodule Lockspire.Ciba do
  @moduledoc """
  Public API for host applications to manage CIBA (Backchannel Authentication) flows.
  """

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Workers.CibaNotificationWorker

  @doc """
  Approves a pending CIBA authorization request.

  Transitions the authorization status to `:approved` and records the `subject_id` 
  and final `scopes`.

  Returns `{:ok, CibaAuthorization.t()}` on success, or `{:error, reason}` if the 
  authorization is not found or is in an invalid state (e.g., already expired or denied).
  """
  @spec approve_authorization(
          auth_req_id_hash :: String.t(),
          subject_id :: String.t(),
          scopes :: [String.t()]
        ) ::
          {:ok, CibaAuthorization.t()} | {:error, :not_found | :invalid_state | term()}
  def approve_authorization(auth_req_id_hash, subject_id, scopes) do
    attrs = %{
      status: :approved,
      subject_id: subject_id,
      scopes: scopes,
      approved_at: DateTime.utc_now()
    }

    case ciba_authorization_store().transition_ciba_authorization(
           auth_req_id_hash,
           [:pending],
           attrs
         ) do
      {:ok, %CibaAuthorization{} = ciba_auth} = result ->
        maybe_enqueue_notification(ciba_auth)
        result

      other ->
        other
    end
  end

  @doc """
  Denies a pending CIBA authorization request.

  Transitions the authorization status to `:denied`.

  Returns `{:ok, CibaAuthorization.t()}` on success.
  """
  @spec deny_authorization(auth_req_id_hash :: String.t(), reason :: String.t() | nil) ::
          {:ok, CibaAuthorization.t()} | {:error, :not_found | :invalid_state | term()}
  def deny_authorization(auth_req_id_hash, _reason \\ nil) do
    attrs = %{
      status: :denied,
      denied_at: DateTime.utc_now()
    }

    case ciba_authorization_store().transition_ciba_authorization(
           auth_req_id_hash,
           [:pending],
           attrs
         ) do
      {:ok, %CibaAuthorization{} = ciba_auth} = result ->
        maybe_enqueue_notification(ciba_auth)
        result

      other ->
        other
    end
  end

  defp maybe_enqueue_notification(%CibaAuthorization{delivery_mode: mode} = ciba_auth)
       when mode in [:ping, :push] do
    %{ciba_authorization_id: ciba_auth.id}
    |> CibaNotificationWorker.new()
    |> then(&Oban.insert(Lockspire.Oban, &1))
  end

  defp maybe_enqueue_notification(_ciba_auth), do: :ok

  defp ciba_authorization_store do
    Repository
  end
end
