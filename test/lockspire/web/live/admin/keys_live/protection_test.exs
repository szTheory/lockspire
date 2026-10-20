defmodule Lockspire.Web.Live.Admin.KeysLive.ProtectionTest do
  use ExUnit.Case, async: true

  alias Lockspire.Web.Live.Admin.KeysLive.Protection

  defp status(overrides) do
    Map.merge(
      %{
        configured: true,
        current_kek_id: "test-1",
        configured_kek_ids: ["test-1", "test-2"],
        total: 0,
        legacy: 0,
        by_kek_id: %{},
        unknown_kek: %{},
        undecryptable: 0,
        stranded_retired: %{count: 0}
      },
      Map.new(overrides)
    )
  end

  defp summarize_status(overrides), do: Protection.summarize({:ok, status(overrides)})

  defp all_text(summary),
    do: summary.value <> " " <> summary.detail <> " " <> (summary.command || "")

  test "each state has its tone and value" do
    cases = [
      {summarize_status(%{by_kek_id: %{"test-1" => 2}}), :encrypted, :success, "Encrypted"},
      {summarize_status(%{by_kek_id: %{"test-1" => 1, "test-2" => 1}}), :older_key, :info,
       "Encrypted, some with an older key-encryption key"},
      {summarize_status(%{legacy: 1}), :unencrypted, :warning,
       "Some keys are stored unencrypted"},
      {summarize_status(%{undecryptable: 1}), :unreadable, :danger, "Some keys cannot be read"},
      {Protection.summarize({:ok, status(%{configured: false})}), :not_set_up, :warning,
       "Not set up"},
      {Protection.summarize({:error, {:invalid_config, "x"}}), :invalid_config, :warning,
       "Setup needs attention"},
      {Protection.summarize({:error, :storage_unavailable}), :could_not_check, :neutral,
       "Unknown"}
    ]

    for {summary, state, tone, value} <- cases do
      assert summary.state == state
      assert summary.tone == tone
      assert summary.value == value
    end
  end

  test "commands are present for exactly five states" do
    assert summarize_status(%{by_kek_id: %{"test-1" => 1}}).command == nil

    assert summarize_status(%{by_kek_id: %{"test-2" => 1}}).command ==
             "mix lockspire.keys.reencrypt"

    assert summarize_status(%{legacy: 1}).command == "mix lockspire.keys.reencrypt"
    assert summarize_status(%{undecryptable: 1}).command == "mix lockspire.doctor.key_encryption"

    assert Protection.summarize({:ok, status(%{configured: false})}).command ==
             "mix lockspire.gen.kek"

    assert Protection.summarize({:error, {:invalid_config, "x"}}).command ==
             "mix lockspire.doctor.key_encryption"

    assert Protection.summarize(:error).command == nil
  end

  test "anything unrecognised reads as could not check, never healthy" do
    for input <- [
          {:error, :repo_not_started},
          {:error, :storage_unavailable},
          :error,
          {:unexpected, :term},
          nil,
          {:ok, %{}}
        ] do
      summary = Protection.summarize(input)
      assert summary.state == :could_not_check
      assert summary.tone == :neutral
      assert summary.value == "Unknown"
    end
  end

  test "invalid config message never reaches the output" do
    summary = Protection.summarize({:error, {:invalid_config, "SENTINEL_ENV_VAR_NAME"}})
    refute inspect(summary) =~ "SENTINEL_ENV_VAR_NAME"
  end

  test "precedence is first match" do
    not_set_up =
      Protection.summarize(
        {:ok, status(%{configured: false, unknown_kek: %{"gone-1" => 1}, legacy: 2})}
      )

    assert not_set_up.state == :not_set_up

    assert summarize_status(%{
             unknown_kek: %{"gone-1" => 1},
             legacy: 1,
             by_kek_id: %{"test-2" => 1}
           }).state == :unreadable

    assert summarize_status(%{legacy: 1, by_kek_id: %{"test-2" => 1}}).state == :unencrypted
    assert summarize_status(%{by_kek_id: %{"test-2" => 1}}).state == :older_key
    assert summarize_status(%{by_kek_id: %{"test-1" => 4}}).state == :encrypted
  end

  test "legacy rows the engine cannot seal read unreadable, ahead of unencrypted" do
    summary =
      summarize_status(%{
        legacy: 2,
        pending: [%{kid: "a", state: :legacy}, %{kid: "b", state: :unsealable_legacy}]
      })

    assert summary.state == :unreadable
    assert summary.command == "mix lockspire.doctor.key_encryption"

    assert summarize_status(%{legacy: 1, pending: [%{kid: "a", state: :legacy}]}).state ==
             :unencrypted
  end

  test "empty configured key set reads encrypted" do
    assert summarize_status(%{total: 0, by_kek_id: %{}, unknown_kek: %{}}).state == :encrypted
  end

  test "several non-current ids in any order read older key" do
    for ids <- [["a", "b", "test-1"], ["test-1", "b", "a"], ["b", "a"]] do
      by = Map.new(ids, &{&1, 1})
      assert summarize_status(%{by_kek_id: by}).state == :older_key
    end
  end

  test "stranded retired rows do not change the state" do
    assert summarize_status(%{stranded_retired: %{count: 3}}).state == :encrypted
  end

  test "legacy rows are unreadable under reject mode and unencrypted otherwise" do
    assert summarize_status(%{legacy_plaintext: :reject, legacy: 1}).state == :unreadable
    assert summarize_status(%{legacy_plaintext: :allow, legacy: 1}).state == :unencrypted
    assert summarize_status(%{legacy_plaintext: :reject, legacy: 0}).state == :encrypted
  end

  test "only the current id appears, and only when encrypted or older key" do
    encrypted = summarize_status(%{by_kek_id: %{"test-1" => 1}})
    older = summarize_status(%{by_kek_id: %{"test-1" => 1, "test-2" => 1}})

    others = [
      summarize_status(%{legacy: 1, by_kek_id: %{"test-2" => 1}}),
      summarize_status(%{undecryptable: 1, unknown_kek: %{"gone-1" => 1}}),
      Protection.summarize({:ok, status(%{configured: false})}),
      Protection.summarize({:error, {:invalid_config, "x"}}),
      Protection.summarize(:error)
    ]

    assert all_text(encrypted) =~ "test-1"
    assert all_text(older) =~ "test-1"
    refute all_text(older) =~ "test-2"

    for summary <- others do
      refute all_text(summary) =~ "test-1"
    end

    for summary <- [encrypted, older | others] do
      refute all_text(summary) =~ "test-2"
      refute all_text(summary) =~ "gone-1"
    end
  end
end
