defmodule Lockspire.Protocol.InitialAccessTokenTest do
  use ExUnit.Case, async: false

  alias Lockspire.Protocol.InitialAccessToken
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    handler_id = "iat-test-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      handler_id,
      [
        [:lockspire, :iat_redeemed],
        [:lockspire, :iat_redemption_failed],
        [:lockspire, :audit, :iat_redeemed],
        [:lockspire, :audit, :iat_redemption_failed]
      ],
      &__MODULE__.handle_event/4,
      self()
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  def handle_event(event, measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, measurements, metadata})
  end

  describe "redeem/1" do
    test "returns {:ok, %Domain{}} for a fresh, unused, unexpired, unrevoked IAT and emits :iat_redeemed" do
      plaintext = "iat_valid_test"
      {:ok, _row} = InitialAccessTokenFixtures.persist(%{plaintext: plaintext})

      assert {:ok, iat} = InitialAccessToken.redeem(plaintext)
      assert iat.used_at != nil

      # Fetch it again to ensure it's persisted
      assert Lockspire.TestRepo.get(Lockspire.Storage.Ecto.InitialAccessTokenRecord, iat.id).used_at !=
               nil

      assert_receive {:telemetry_event, [:lockspire, :iat_redeemed], _measurements, metadata}
      refute Map.has_key?(metadata, :plaintext)
      refute Map.has_key?(metadata, :token)
      refute Map.has_key?(metadata, :initial_access_token)
    end

    test "returns {:error, :invalid_token} when the token doesn't exist (no row matches the hash) and emits failure" do
      plaintext = "iat_unknown_test"
      assert {:error, :invalid_token} = InitialAccessToken.redeem(plaintext)

      assert_receive {:telemetry_event, [:lockspire, :iat_redemption_failed], measurements,
                      metadata}

      assert measurements.failure_reason == :not_found
      refute Map.has_key?(metadata, :plaintext)
    end

    test "returns {:error, :invalid_token} when the row has revoked_at set" do
      plaintext = "iat_revoked_test"
      revoked_at = DateTime.utc_now()

      {:ok, _row} =
        InitialAccessTokenFixtures.persist(%{plaintext: plaintext, revoked_at: revoked_at})

      assert {:error, :invalid_token} = InitialAccessToken.redeem(plaintext)

      assert_receive {:telemetry_event, [:lockspire, :iat_redemption_failed], measurements,
                      metadata}

      assert measurements.failure_reason == :revoked
      refute Map.has_key?(metadata, :plaintext)
    end

    test "returns {:error, :invalid_token} when the row's expires_at is in the past" do
      plaintext = "iat_expired_test"
      past = DateTime.add(DateTime.utc_now(), -3600, :second)
      {:ok, _row} = InitialAccessTokenFixtures.persist(%{plaintext: plaintext, expires_at: past})

      assert {:error, :invalid_token} = InitialAccessToken.redeem(plaintext)

      assert_receive {:telemetry_event, [:lockspire, :iat_redemption_failed], measurements,
                      metadata}

      assert measurements.failure_reason == :expired
      refute Map.has_key?(metadata, :plaintext)
    end

    test "returns {:error, :invalid_token} when the row is single_use: true and used_at is already set" do
      plaintext = "iat_used_test"
      used_at = DateTime.utc_now()
      {:ok, _row} = InitialAccessTokenFixtures.persist(%{plaintext: plaintext, used_at: used_at})

      assert {:error, :invalid_token} = InitialAccessToken.redeem(plaintext)

      assert_receive {:telemetry_event, [:lockspire, :iat_redemption_failed], measurements,
                      metadata}

      assert measurements.failure_reason == :already_used
      refute Map.has_key?(metadata, :plaintext)
    end
  end

  describe "redeem/1 concurrency" do
    test "exactly one task wins under concurrent redemption" do
      {plaintext, _iat} = InitialAccessTokenFixtures.persist_with_plaintext(%{})
      parent = self()

      results =
        1..10
        |> Enum.map(fn _ ->
          Task.async(fn ->
            :ok = Ecto.Adapters.SQL.Sandbox.allow(Lockspire.TestRepo, parent, self())
            InitialAccessToken.redeem(plaintext)
          end)
        end)
        |> Task.await_many(5_000)

      successes = Enum.count(results, &match?({:ok, _}, &1))
      failures = Enum.count(results, &match?({:error, :invalid_token}, &1))

      assert successes == 1, "expected exactly 1 success, got: #{inspect(results)}"
      assert failures == 9, "expected exactly 9 failures, got: #{inspect(results)}"
    end
  end
end
