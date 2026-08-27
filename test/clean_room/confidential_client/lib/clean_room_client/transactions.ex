defmodule CleanRoomClient.Transactions do
  @moduledoc false
  import Ecto.Query

  alias CleanRoomClient.{OAuthTransaction, Repo}

  @transaction_ttl_seconds 300

  def start(options) do
    verifier = random_urlsafe()
    now = DateTime.utc_now()

    attrs = %{
      state: random_urlsafe(),
      nonce: random_urlsafe(),
      verifier: verifier,
      challenge: s256(verifier),
      issuer: Map.fetch!(options, :issuer),
      client_id: Map.get(options, :client_id, "clean-room-bearer"),
      callback_uri: Map.get(options, :callback_uri, "http://127.0.0.1/oauth/callback"),
      profile: Map.fetch!(options, :profile),
      expires_at: DateTime.add(now, @transaction_ttl_seconds, :second),
      encrypted_dpop_key: Map.get(options, :encrypted_dpop_key),
      dpop_jkt: Map.get(options, :dpop_jkt)
    }

    %OAuthTransaction{}
    |> OAuthTransaction.changeset(attrs)
    |> Repo.insert!()
  end

  def consume(id, state) when is_integer(id) and is_binary(state) do
    now = DateTime.utc_now()

    {count, _} =
      from(transaction in OAuthTransaction,
        where:
          transaction.id == ^id and transaction.state == ^state and transaction.status == :pending and
            transaction.expires_at > ^now
      )
      |> Repo.update_all(set: [status: :consumed, updated_at: now])

    if count == 1, do: {:ok, Repo.get!(OAuthTransaction, id)}, else: {:error, :terminal}
  end

  def s256(verifier) when is_binary(verifier) do
    :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
  end

  defp random_urlsafe, do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
end
