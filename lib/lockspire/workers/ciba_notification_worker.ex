defmodule Lockspire.Workers.CibaNotificationWorker do
  @moduledoc """
  Delivers CIBA (Backchannel Authentication) notifications to Relying Parties.
  Supports both Ping and Push delivery modes.
  """

  use Oban.Worker,
    queue: :ciba_notification,
    max_attempts: 5,
    unique: [
      period: 300,
      fields: [:args],
      keys: [:ciba_authorization_id],
      states: [:available, :scheduled, :executing, :retryable]
    ]

  import Ecto.Query

  alias Lockspire.Config
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Storage.Ecto.CibaAuthorizationRecord
  alias Lockspire.Storage.Ecto.ClientRecord

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"ciba_authorization_id" => ciba_auth_id}}) do
    with {:ok, ciba_auth} <- fetch_authorization(ciba_auth_id),
         {:ok, client} <- fetch_client(ciba_auth.client_id) do
      case ciba_auth.status do
        :approved ->
          deliver_success(ciba_auth, client)

        :denied ->
          deliver_error(ciba_auth, client, "access_denied")

        :expired ->
          deliver_error(ciba_auth, client, "expired_token")

        _other ->
          {:discard, :invalid_status}
      end
    else
      {:error, :not_found} ->
        {:discard, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def perform(_job), do: {:discard, :invalid_args}

  defp deliver_success(ciba_auth, client) do
    case ciba_auth.delivery_mode do
      :ping ->
        deliver_ping(ciba_auth, client)

      :push ->
        deliver_push(ciba_auth, client)

      :poll ->
        {:discard, :poll_mode_no_notification}
    end
  end

  defp deliver_ping(ciba_auth, client) do
    payload = %{
      "auth_req_id" => ciba_auth.auth_req_id
    }

    send_notification(ciba_auth, client, payload)
  end

  defp deliver_push(ciba_auth, client) do
    # Generate tokens
    case TokenExchange.issue_ciba_tokens(client, ciba_auth, mock_issuance_context(client), %{}) do
      {:ok, %TokenExchange.Success{} = success} ->
        payload = %{
          "auth_req_id" => ciba_auth.auth_req_id,
          "access_token" => success.access_token,
          "token_type" => success.token_type,
          "expires_in" => success.expires_in,
          "refresh_token" => success.refresh_token,
          "id_token" => success.id_token
        }
        |> Map.reject(fn {_k, v} -> v == nil end)

        send_notification(ciba_auth, client, payload)

      {:error, reason} ->
        {:error, {:token_issuance_failed, reason}}
    end
  end

  defp deliver_error(ciba_auth, client, error) do
    payload = %{
      "auth_req_id" => ciba_auth.auth_req_id,
      "error" => error
    }

    send_notification(ciba_auth, client, payload)
  end

  defp send_notification(ciba_auth, client, payload) do
    url = ciba_auth.client_notification_endpoint || client.backchannel_client_notification_endpoint
    token = ciba_auth.client_notification_token_encrypted # Assuming it's the raw token for now as per previous discussion

    request_opts =
      Application.get_env(:lockspire, :backchannel_ciba_req, [])
      |> Keyword.put_new(:retry, false)
      |> Keyword.put(:url, url)
      |> Keyword.put(:json, payload)
      |> Keyword.put(:headers, [{"authorization", "Bearer #{token}"}])

    case Req.post(request_opts) do
      {:ok, %{status: status}} when status in 200..299 ->
        :ok

      {:ok, %{status: status}} when status in 400..499 ->
        {:discard, {:http_error, status}}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_authorization(id) do
    CibaAuthorizationRecord
    |> where([a], a.id == ^id)
    |> repo().one()
    |> case do
      nil -> {:error, :not_found}
      record -> 
        # auth_req_id is needed for payload and token generation
        auth_req_id = if record.auth_req_id_encrypted, do: to_string(record.auth_req_id_encrypted), else: nil
        {:ok, CibaAuthorizationRecord.to_domain(record, auth_req_id: auth_req_id)} 
    end
  end

  defp fetch_client(client_id) do
    ClientRecord
    |> where([c], c.client_id == ^client_id)
    |> repo().one()
    |> case do
      nil -> {:error, :not_found}
      record -> {:ok, ClientRecord.to_domain(record)}
    end
  end

  defp mock_issuance_context(client) do
    # For Push mode, we assume Bearer for now unless client/policy dictates otherwise.
    # But FAPI 2.0 would require DPoP. 
    # CIBA Push mode and DPoP is tricky because there's no proof for the push.
    # We'll default to bearer.
    %{
      mode: :bearer,
      proof: nil,
      jkt: nil,
      cnf: nil,
      token_type: "Bearer",
      security_profile: SecurityProfile.resolve_effective_profile(%Lockspire.Domain.ServerPolicy{}, client)
    }
  end

  defp repo, do: Config.repo!()
end
