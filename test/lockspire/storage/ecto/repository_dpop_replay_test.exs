defmodule Lockspire.Storage.Ecto.RepositoryDpopReplayTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Storage.DpopReplayStore
  alias Lockspire.Storage.Ecto.DpopReplayRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  defp replay_fixture(attrs \\ %{}) do
    now = Map.get(attrs, :seen_at, DateTime.utc_now())

    %DpopReplay{
      replay_key: Map.get(attrs, :replay_key, "replay:proof:123"),
      jti: Map.get(attrs, :jti, "proof-jti"),
      htm: Map.get(attrs, :htm, "POST"),
      htu: Map.get(attrs, :htu, "https://server.example.com/lockspire/token"),
      jkt: Map.get(attrs, :jkt, "thumbprint"),
      seen_at: now,
      expires_at: Map.get(attrs, :expires_at, DateTime.add(now, 300, :second))
    }
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

    assert %Ecto.Changeset{valid?: true} =
             changeset = DpopReplayRecord.changeset(%DpopReplayRecord{}, replay)

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

  describe "record_dpop_proof/1" do
    test "accepts the first proof presentation and rejects an immediate replay" do
      replay = replay_fixture()

      assert {:ok, :accepted} = Repository.record_dpop_proof(replay)
      assert {:ok, :replay} = Repository.record_dpop_proof(replay)
    end

    test "classifies a replay durably across fresh repository calls" do
      replay = replay_fixture(%{replay_key: "replay:proof:persisted", jti: "persisted-jti"})

      assert {:ok, :accepted} = Repository.record_dpop_proof(replay)

      assert {:ok, :replay} =
               replay
               |> Map.put(:seen_at, DateTime.add(replay.seen_at, 5, :second))
               |> Repository.record_dpop_proof()
    end

    test "allows a new proof once prior replay state has expired" do
      initial_seen_at = DateTime.utc_now()

      assert {:ok, :accepted} =
               replay_fixture(%{
                 replay_key: "replay:proof:expired-window",
                 jti: "expired-window-jti",
                 seen_at: initial_seen_at,
                 expires_at: DateTime.add(initial_seen_at, 1, :second)
               })
               |> Repository.record_dpop_proof()

      assert {:ok, :accepted} =
               replay_fixture(%{
                 replay_key: "replay:proof:expired-window",
                 jti: "expired-window-jti",
                 seen_at: DateTime.add(initial_seen_at, 2, :second),
                 expires_at: DateTime.add(initial_seen_at, 302, :second)
               })
               |> Repository.record_dpop_proof()
    end
  end
end
