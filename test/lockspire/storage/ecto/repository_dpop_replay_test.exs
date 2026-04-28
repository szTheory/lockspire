defmodule Lockspire.Storage.Ecto.RepositoryDpopReplayTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Storage.DpopReplayStore
  alias Lockspire.Storage.Ecto.DpopReplayRecord

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  test "exposes a first-class durable replay domain shape" do
    now = DateTime.utc_now()
    expires_at = DateTime.add(now, 300, :second)

    replay = %DpopReplay{
      replay_key: "proof-key",
      jti: "proof-jti",
      htm: "POST",
      htu: "https://server.example.com/lockspire/token",
      jkt: "thumbprint",
      seen_at: now,
      expires_at: expires_at
    }

    assert replay.replay_key == "proof-key"
    assert replay.jti == "proof-jti"
    assert replay.htu == "https://server.example.com/lockspire/token"
    assert replay.expires_at == expires_at
  end

  test "publishes a typed store contract for replay recording" do
    callbacks = DpopReplayStore.behaviour_info(:callbacks)

    assert {:record_dpop_proof, 1} in callbacks
  end

  test "maps the replay schema to and from the domain struct" do
    now = DateTime.utc_now()
    expires_at = DateTime.add(now, 300, :second)

    replay = %DpopReplay{
      replay_key: "proof-key",
      jti: "proof-jti",
      htm: "POST",
      htu: "https://server.example.com/lockspire/token",
      jkt: "thumbprint",
      seen_at: now,
      expires_at: expires_at
    }

    assert %Ecto.Changeset{valid?: true} = changeset = DpopReplayRecord.changeset(%DpopReplayRecord{}, replay)
    record = Ecto.Changeset.apply_changes(changeset)

    assert record.replay_key == replay.replay_key
    assert record.jti == replay.jti
    assert record.htu == replay.htu
    assert DpopReplayRecord.to_domain(record).expires_at == expires_at
  end

  test "has a durable replay table and unique replay key index" do
    assert %{rows: [[1]]} =
             Ecto.Adapters.SQL.query!(
               Lockspire.TestRepo,
               "select count(*) from information_schema.tables where table_name = 'lockspire_dpop_replay'",
               []
             )

    assert %{rows: rows} =
             Ecto.Adapters.SQL.query!(
               Lockspire.TestRepo,
               """
               select indexname
               from pg_indexes
               where tablename = 'lockspire_dpop_replay'
               """,
               []
             )

    index_names = Enum.map(rows, &List.first/1)

    assert "lockspire_dpop_replay_replay_key_index" in index_names
  end
end
