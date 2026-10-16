defmodule Lockspire.Security.KeyMaterialLeakTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Lockspire.Admin.Keys
  alias Lockspire.KeyEncryptionHelpers, as: Helpers
  alias Lockspire.Protocol.PrivateJwk
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.TestSupport.TelemetryCapture

  @sentinel_d "SENTINEL-PRIVATE-D-0001"
  @kek_one_bytes "lockspire-leak-sentinel-kek-0001"
  @kek_two_bytes "lockspire-leak-sentinel-kek-0002"
  @kek_one Base.encode64(@kek_one_bytes)
  @kek_two Base.encode64(@kek_two_bytes)

  @key_events ~w(legacy_read decode_failed encrypted rewrapped reencrypt_failed
                 reencrypt_completed)a

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    # Repo query logging is switched on for this module only, so the log check is not vacuous.
    start_supervised!({Lockspire.TestRepo, log: :debug})
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

    previous_level = Logger.level()
    Logger.configure(level: :debug)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    Helpers.reset_decode_warnings()
    on_exit(&Helpers.reset_decode_warnings/0)

    :ok
  end

  defp configure(current, mode) do
    Helpers.put_key_encryption(
      keys: [{"leak-1", @kek_one}, {"leak-2", @kek_two}],
      current: current,
      legacy_plaintext: mode
    )
  end

  defp sentinel_keyset(current) do
    {:ok, keyset} =
      KeySet.new(keys: [{"leak-1", @kek_one}, {"leak-2", @kek_two}], current: current)

    keyset
  end

  defp sentinel_row(kid, opts \\ []) do
    row = Helpers.legacy_json_row(kid, opts)
    jwk = row.private_jwk_encrypted |> Jason.decode!() |> Map.put("d", @sentinel_d)
    %{row | private_jwk_encrypted: Jason.encode!(jwk)}
  end

  defp sealed_sentinel_row(kid, kek_id, opts \\ []) do
    row = sentinel_row(kid, opts)
    {:ok, envelope} = KeyEncryption.seal(sentinel_keyset(kek_id), kid, row.private_jwk_encrypted)
    %{row | private_jwk_encrypted: envelope}
  end

  defp flip_last_byte(bin) do
    size = byte_size(bin) - 1
    <<head::binary-size(size), last>> = bin
    <<head::binary, Bitwise.bxor(last, 1)>>
  end

  defp drain(acc \\ []) do
    receive do
      {:telemetry_event, event, measurements, metadata} ->
        drain([{event, measurements, metadata} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  test "no sentinel key material or KEK reaches telemetry, repo events, audit rows, logs or the report" do
    configure("leak-1", :allow)

    # Seed before any handler is attached or log is captured: fixture inserts legitimately
    # bind the plaintext column.
    seeded =
      capture_log([level: :debug], fn ->
        [
          Helpers.insert_signing_key_row!(sentinel_row("leak-legacy-db", status: :active)),
          Helpers.insert_signing_key_row!(sealed_sentinel_row("leak-rewrap-db", "leak-2")),
          Helpers.insert_signing_key_row!(Helpers.sealed_row("leak-gone-db", "gone-1"))
        ]
        |> then(&Process.put(:seeded, &1))
      end)
      |> then(fn _log -> Process.get(:seeded) end)

    assert length(seeded) == 3

    repo_query = (Lockspire.TestRepo.config()[:telemetry_prefix] || []) ++ [:query]

    key_events =
      for e <- @key_events, prefix <- [[:lockspire, :key], [:lockspire, :audit, :key]] do
        prefix ++ [e]
      end

    TelemetryCapture.attach_many([repo_query | key_events])

    legacy = sentinel_row("leak-legacy-mem")
    unknown_kek = Helpers.sealed_row("leak-unknown", "gone-1")
    tampered = %{sealed_sentinel_row("leak-tampered", "leak-1") | kid: "leak-tampered"}
    malformed = %{legacy | kid: "leak-malformed", private_jwk_encrypted: "LSK" <> <<1, 2, 3>>}
    mismatched = sealed_sentinel_row("leak-mismatch", "leak-1")

    mismatched = %{
      mismatched
      | private_jwk_encrypted:
          elem(
            KeyEncryption.seal(
              sentinel_keyset("leak-1"),
              "some-other-kid",
              legacy.private_jwk_encrypted
            ),
            1
          )
    }

    reports = :ets.new(:leak_reports, [:public])

    log =
      capture_log([level: :debug], fn ->
        # legacy read under :allow
        assert {:ok, _jwk} = PrivateJwk.decode(legacy)

        # refusal under :reject
        configure("leak-1", :reject)
        assert {:error, :invalid_signing_key} = PrivateJwk.decode(legacy)

        # every decode failure reason
        configure("leak-1", :allow)

        for row <- [
              unknown_kek,
              %{tampered | private_jwk_encrypted: flip_last_byte(tampered.private_jwk_encrypted)},
              malformed,
              mismatched
            ] do
          assert {:error, :invalid_signing_key} = PrivateJwk.decode(row)
        end

        # the read-only paths select every stored key row, so they must be silent too
        assert {:ok, _preview} = Keys.reencrypt(dry_run: true)
        assert {:ok, _status} = Keys.encryption_status()

        # encrypt and re-wrap, then re-wrap again after switching the current key
        assert {:ok, first} = Keys.reencrypt()
        configure("leak-2", :allow)
        assert {:ok, second} = Keys.reencrypt()
        :ets.insert(reports, {:reports, [first, second]})
      end)

    [{:reports, report_list}] = :ets.lookup(reports, :reports)
    assert Enum.sum(Enum.map(report_list, & &1.encrypted)) >= 1
    assert Enum.sum(Enum.map(report_list, & &1.rewrapped)) >= 1

    events = drain()

    {repo_events, key_events_received} =
      Enum.split_with(events, fn {event, _m, _md} -> event == repo_query end)

    assert repo_events != [], "repo query telemetry handler received nothing"

    for name <- [:legacy_read, :decode_failed, :encrypted, :rewrapped, :reencrypt_completed] do
      assert Enum.any?(key_events_received, fn {event, _m, _md} ->
               event == [:lockspire, :key, name]
             end),
             "expected a #{name} event"
    end

    audit_rows = inspect(Lockspire.TestRepo.all(AuditEventRecord, log: false), limit: :infinity)

    forbidden = [
      {"private d value", @sentinel_d},
      {"KEK one (base64)", @kek_one},
      {"KEK two (base64)", @kek_two},
      {"KEK one (raw)", @kek_one_bytes},
      {"KEK two (raw)", @kek_two_bytes}
    ]

    key_event_text =
      key_events_received
      |> Enum.map_join("\n", fn {_e, m, md} -> inspect({m, md}, limit: :infinity) end)

    repo_param_text =
      repo_events
      |> Enum.map_join("\n", fn {_e, _m, md} ->
        inspect({md[:params], md[:cast_params], md[:result]}, limit: :infinity)
      end)

    refute key_event_text =~ "LSK"
    refute repo_param_text =~ "LSK"

    # The query log lines must exist before their absence of key material means anything.
    assert log =~ ~r/QUERY (OK|ERROR)/,
           "repo query logging is not active, so the leak check would be vacuous"

    # Any query that touches the stored key column is sensitive, so none may reach either channel.
    refute log =~ "private_jwk_encrypted", "key column queries reached the query log"

    refute Enum.any?(repo_events, fn {_e, _m, md} ->
             String.contains?(to_string(md[:query]), "private_jwk_encrypted")
           end),
           "key column queries reached the repo query telemetry event"

    surfaces = [
      {"key telemetry", key_event_text},
      {"repo query params", repo_param_text},
      {"audit rows", audit_rows},
      {"captured log", log},
      {"re-encryption report", inspect(report_list, limit: :infinity)}
    ]

    for {surface, text} <- surfaces, {label, secret} <- forbidden do
      refute String.contains?(text, secret), "#{label} leaked into #{surface}"
    end

    for {surface, text} <- [{"captured log", log}, {"audit rows", audit_rows}] do
      refute String.contains?(text, "LSK"), "envelope bytes leaked into #{surface}"
    end
  end
end
