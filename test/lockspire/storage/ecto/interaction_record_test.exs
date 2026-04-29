defmodule Lockspire.Storage.Ecto.InteractionRecordTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Interaction
  alias Lockspire.Storage.Ecto.InteractionRecord

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  test "InteractionRecord round-trips auth_time, max_age, and auth_time_requested through changeset and domain mapping" do
    repo = Lockspire.TestRepo
    now = ~U[2026-04-28 22:00:00Z]
    auth_time = DateTime.add(now, -120, :second)

    interaction = %Interaction{
      interaction_id: "interaction-record-round-trip",
      client_id: "client_123",
      account_id: "subject_123",
      scopes_requested: ["openid", "email"],
      prompt: ["consent"],
      nonce: "nonce-123",
      redirect_uri: "https://client.example.com/callback",
      return_to: "/lockspire/interactions/interaction-record-round-trip",
      state: "state-123",
      code_challenge: "challenge-123",
      code_challenge_method: :S256,
      status: :pending_consent,
      auth_time: auth_time,
      max_age: 600,
      auth_time_requested: true,
      consent_requested_at: now,
      expires_at: DateTime.add(now, 300, :second)
    }

    {:ok, inserted} =
      %InteractionRecord{}
      |> InteractionRecord.changeset(interaction)
      |> repo.insert()

    out = InteractionRecord.to_domain(repo.get!(InteractionRecord, inserted.id))

    assert DateTime.compare(out.auth_time, auth_time) == :eq
    assert out.max_age == 600
    assert out.auth_time_requested == true
  end
end
