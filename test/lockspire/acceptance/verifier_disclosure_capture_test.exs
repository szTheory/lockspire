Code.require_file(
  Path.expand(
    "../../clean_room/provider_host/lib/clean_room_provider/verifier_disclosure.ex",
    __DIR__
  )
)

defmodule Lockspire.Acceptance.VerifierDisclosureCaptureTest do
  use ExUnit.Case, async: true

  alias CleanRoomProvider.VerifierDisclosure.LoggerHandler
  alias CleanRoomProvider.VerifierDisclosure.QueryHandler

  setup do
    table = :ets.new(:verifier_disclosure_capture_contract, [:set, :public])

    for key <- [
          :logger_count,
          :logger_control_count,
          :logger_operation_count,
          :query_count,
          :query_control_count,
          :query_operation_count,
          :logger_leaks,
          :query_leaks
        ] do
      :ets.insert(table, {key, 0})
    end

    capture_ref = make_ref()

    config = %{
      table: table,
      sentinels: ["secret-sentinel"],
      capture_ref: capture_ref,
      capture_pid: self(),
      ack: {self(), make_ref()}
    }

    # The table is owned by this test process and is removed when it exits.
    {:ok, config: config}
  end

  test "handler counts are process, ref, and phase attributed while leaks remain global", %{
    config: config
  } do
    ref = config.capture_ref
    owner = config.capture_pid

    LoggerHandler.log(event(owner, ref, :control, "safe control"), config)
    LoggerHandler.log(event(owner, ref, :operation, "safe operation"), config)
    LoggerHandler.log(event(self(), make_ref(), :operation, "wrong reference"), config)
    LoggerHandler.log(event(make_ref(), ref, :operation, "wrong process"), config)
    LoggerHandler.log(event(make_ref(), ref, :control, "secret-sentinel background"), config)

    query(:control, ref, config)
    with_metadata(ref, :operation, fn -> query(nil, nil, config) end)
    with_metadata(make_ref(), :operation, fn -> query(nil, nil, config) end)
    with_metadata(ref, :control, fn -> query(nil, nil, config) end)

    task =
      Task.async(fn ->
        with_metadata(ref, :operation, fn ->
          query(nil, nil, config, "SELECT 'secret-sentinel'")
        end)
      end)

    Task.await(task)

    assert count(config, :logger_count) == 5
    assert count(config, :logger_control_count) == 1
    assert count(config, :logger_operation_count) == 1
    assert count(config, :logger_leaks) == 1
    assert count(config, :query_count) == 5
    assert count(config, :query_control_count) == 1
    assert count(config, :query_operation_count) == 1
    assert count(config, :query_leaks) == 1
  end

  defp event(pid, ref, phase, message) do
    %{
      level: :info,
      msg: {:string, message},
      meta: %{
        pid: pid,
        lockspire_disclosure_capture_ref: ref,
        lockspire_disclosure_capture_phase: phase
      }
    }
  end

  defp query(control, control_ref, config, query_text \\ "SELECT 1") do
    options = if control, do: [lockspire_disclosure_capture: {control_ref, control}], else: []

    QueryHandler.handle_event(
      [:clean_room_provider, :repo, :query],
      %{},
      %{options: options, query: query_text},
      config
    )
  end

  defp with_metadata(ref, phase, fun) do
    previous = Logger.metadata()

    Logger.metadata(
      lockspire_disclosure_capture_ref: ref,
      lockspire_disclosure_capture_phase: phase
    )

    try do
      fun.()
    after
      Logger.reset_metadata(previous)
    end
  end

  defp count(config, key), do: :ets.lookup_element(config.table, key, 2)
end
