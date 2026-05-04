defmodule Lockspire.Workers.PrunerTest do
  use ExUnit.Case, async: false

  alias Lockspire.Workers.Pruner

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  test "pruner sweeps expired records and emits telemetry" do
    now = DateTime.utc_now()
    past = DateTime.add(now, -100, :second)

    # Insert a dummy expired token to ensure count is at least 1
    Lockspire.TestRepo.insert_all(Lockspire.Storage.Ecto.TokenRecord, [
      %{
        token_hash: "sweep_token",
        token_type: :access_token,
        client_id: "c1",
        expires_at: past,
        inserted_at: past,
        updated_at: past
      }
    ])

    Lockspire.TestRepo.insert_all(Lockspire.Storage.Ecto.UsedJtiRecord, [
      %{
        client_id: "c1",
        jti: "expired_jti",
        expires_at: past,
        inserted_at: past,
        updated_at: past
      }
    ])

    test_pid = self()

    telemetry_handler = fn [:lockspire, :pruner, :completed], measurements, metadata, _config ->
      send(test_pid, {:telemetry, metadata.model, measurements.count})
    end

    :telemetry.attach("pruner-test", [:lockspire, :pruner, :completed], telemetry_handler, nil)

    assert :ok = Pruner.perform(%Oban.Job{})

    models = [
      "TokenRecord",
      "DpopReplayRecord",
      "PushedAuthorizationRequestRecord",
      "InteractionRecord",
      "DeviceAuthorizationRecord",
      "InitialAccessTokenRecord",
      "UsedJtiRecord"
    ]

    for model <- models do
      assert_receive {:telemetry, ^model, count}, 500
      if model in ["TokenRecord", "UsedJtiRecord"] do
        assert count >= 1
      else
        assert is_integer(count)
      end
    end

    :telemetry.detach("pruner-test")
  end
end
