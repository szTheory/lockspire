defmodule CleanRoomClient.Transactions do
  @moduledoc false
  import Ecto.Query

  alias CleanRoomClient.{DPoPSession, OAuthTransaction, Repo}

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

  def replace_nonce(id) when is_integer(id) do
    {count, _} =
      from(transaction in OAuthTransaction,
        where: transaction.id == ^id and transaction.status == :pending
      )
      |> Repo.update_all(set: [nonce: random_urlsafe(), updated_at: DateTime.utc_now()])

    if count == 1, do: :ok, else: {:error, :terminal}
  end

  def s256(verifier) when is_binary(verifier) do
    :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
  end

  def attach_dpop_key(transaction, encrypted_key, jkt) do
    {1, _} =
      from(item in OAuthTransaction,
        where: item.id == ^transaction.id and item.status == :pending
      )
      |> Repo.update_all(set: [encrypted_dpop_key: encrypted_key, dpop_jkt: jkt])

    Repo.get!(OAuthTransaction, transaction.id)
  end

  def handoff_dpop_session(transaction, encrypted_access_token, subject) do
    Repo.transaction(fn ->
      handle = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

      session =
        %DPoPSession{}
        |> DPoPSession.changeset(%{
          handle: handle,
          encrypted_key: transaction.encrypted_dpop_key,
          encrypted_access_token: encrypted_access_token,
          subject: subject,
          jkt: transaction.dpop_jkt,
          expires_at: DateTime.add(DateTime.utc_now(), @transaction_ttl_seconds, :second)
        })
        |> Repo.insert!()

      from(item in OAuthTransaction, where: item.id == ^transaction.id)
      |> Repo.update_all(set: [encrypted_dpop_key: nil, dpop_jkt: nil])

      session
    end)
  end

  def close_dpop_session(handle) do
    from(session in DPoPSession, where: session.handle == ^handle and is_nil(session.closed_at))
    |> Repo.update_all(
      set: [
        closed_at: DateTime.utc_now(),
        encrypted_key: nil,
        encrypted_access_token: nil,
        encrypted_resource_nonce: nil,
        encrypted_accepted_resource_proof: nil
      ]
    )
  end

  def active_dpop_session(handle) when is_binary(handle) do
    now = DateTime.utc_now()

    Repo.one(
      from(session in DPoPSession,
        where:
          session.handle == ^handle and is_nil(session.closed_at) and session.expires_at > ^now
      )
    )
    |> case do
      %DPoPSession{} = session -> {:ok, session}
      nil -> {:error, :terminal}
    end
  end

  def store_resource_nonce(handle, encrypted_nonce)
      when is_binary(handle) and is_binary(encrypted_nonce) do
    update_active_session(handle, encrypted_resource_nonce: encrypted_nonce)
  end

  def store_accepted_resource_proof(handle, encrypted_proof)
      when is_binary(handle) and is_binary(encrypted_proof) do
    update_active_session(handle, encrypted_accepted_resource_proof: encrypted_proof)
  end

  defp update_active_session(handle, updates) do
    now = DateTime.utc_now()

    {count, _} =
      from(session in DPoPSession,
        where:
          session.handle == ^handle and is_nil(session.closed_at) and session.expires_at > ^now
      )
      |> Repo.update_all(set: [updated_at: now] ++ updates)

    if count == 1, do: :ok, else: {:error, :terminal}
  end

  defp random_urlsafe, do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
end
