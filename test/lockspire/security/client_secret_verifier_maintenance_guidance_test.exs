defmodule Lockspire.Security.ClientSecretVerifierMaintenanceGuidanceTest do
  use ExUnit.Case, async: true

  alias Lockspire.Clients
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  @configuration_doc File.read!("docs/client-secret-verifier-configuration.md")
                     |> String.replace(~r/\s+/, " ")
  @jwt_doc File.read!("docs/client-secret-jwt-host-guide.md") |> String.replace(~r/\s+/, " ")
  @supported_doc File.read!("docs/supported-surface.md") |> String.replace(~r/\s+/, " ")
  @install_doc File.read!("docs/install-and-onboard.md") |> String.replace(~r/\s+/, " ")
  @getting_started_doc File.read!("docs/getting-started.md") |> String.replace(~r/\s+/, " ")
  @maintainer_doc File.read!("docs/maintainer-release.md") |> String.replace(~r/\s+/, " ")

  test "documented task modes and progress options match the live task help" do
    help = Mix.Tasks.Lockspire.Clients.Verifier.Rewrap.help()

    runbook =
      section(
        @configuration_doc,
        "## Inspect, re-wrap, and check custody",
        "## Reader-first rollout, activation, and recovery"
      )

    for contract <- [
          "mix lockspire.clients.verifier.rewrap",
          "--dry-run",
          "--check",
          "--limit",
          "--after-client-id"
        ] do
      assert help =~ contract
      assert runbook =~ contract
    end

    assert help =~ "fresh read-only custody check"
    assert runbook =~ "progress only"
    assert runbook =~ "never establishes readiness"
    refute help =~ "--apply"
    assert runbook =~ "no mode flag it applies"
    assert runbook =~ "separate fresh `--check`"
  end

  test "runbook makes local check, fleet retirement, and logging boundaries explicit" do
    runbook =
      section(
        @configuration_doc,
        "## Inspect, re-wrap, and check custody",
        "## Diagnostic boundaries"
      )

    rollout =
      section(
        @configuration_doc,
        "## Reader-first rollout, activation, and recovery",
        "## Diagnostic boundaries"
      )

    support =
      section(
        @supported_doc,
        "### Verifier-key maintenance boundary",
        "### JWT Introspection Representation"
      )

    assert runbook =~ "starts at the beginning"
    assert runbook =~ "selected client store"
    assert rollout =~ "every serving node"
    assert rollout =~ "backup"
    assert rollout =~ "rollback"
    assert rollout =~ "live read key"
    assert rollout =~ "Destroying a backup is a separate retention decision"
    assert @configuration_doc =~ "host-installed telemetry handlers"
    assert @configuration_doc =~ "PostgreSQL server logging"
    assert support =~ "Phoenix 1.8.13 / LiveView 1.2.10"
    assert support =~ "does not extend support to arbitrary stores"
    assert support =~ "fails closed"
  end

  test "recovery wording matches key restoration and partner-secret replacement behavior" do
    secret = "guidance-client-secret-sentinel"
    client_id = "guidance-recovery-client"
    old_key = :crypto.hash(:sha256, "guidance-original-key")
    replacement_key = :crypto.hash(:sha256, "guidance-replacement-key")
    original_context = verifier_context([{"original", old_key}], "original")
    restored_context = verifier_context([{"original", old_key}], "original")
    lost_context = verifier_context([{"replacement", replacement_key}], "replacement")

    assert {:ok, ciphertext} = ClientSecretVerifier.seal(original_context, client_id, secret)
    assert {:ok, ^secret} = ClientSecretVerifier.open(restored_context, client_id, ciphertext, [])

    assert {:error, :client_secret_verifier_key_unknown} =
             ClientSecretVerifier.open(lost_context, client_id, ciphertext, [])

    original_hash = Policy.hash_client_secret(secret)
    assert Policy.verify_client_secret(original_hash, secret)
    {rotated_hash, rotated_secret} = Clients.rotate_secret_hash()
    refute rotated_secret == secret
    refute Policy.verify_client_secret(rotated_hash, secret)
    assert Policy.verify_client_secret(rotated_hash, rotated_secret)

    recovery =
      section(
        @configuration_doc,
        "## Reader-first rollout, activation, and recovery",
        "## Diagnostic boundaries"
      )

    assert recovery =~ "Restoring the original key restores access"
    assert recovery =~ "That action replaces the partner secret"
    assert recovery =~ "one-time handoff"
    assert @jwt_doc =~ "Restoring the original key preserves the existing partner secret"
    assert @jwt_doc =~ "replaces that secret"
    assert @configuration_doc =~ "original finite deadline"
    assert @configuration_doc =~ "remains ineligible to authenticate"
  end

  test "release RPC and bare Mix descriptions agree with task help" do
    help = Mix.Tasks.Lockspire.Clients.Verifier.Rewrap.help()

    runbook =
      section(
        @configuration_doc,
        "## Inspect, re-wrap, and check custody",
        "## Reader-first rollout, activation, and recovery"
      )

    assert help =~ "bin/app rpc"
    assert help =~ "immutable startup context"
    assert help =~ "does not start Lockspire supervision"
    assert runbook =~ "bin/app rpc"
    assert runbook =~ "immutable startup snapshot"
    assert runbook =~ "does not start Lockspire supervision"
    assert runbook =~ "mix run --no-start"
  end

  test "fresh install guidance assigns verifier keys to the host and preserves the shipped scope" do
    assert @configuration_doc =~ "does not generate or provision verifier keys"
    assert @configuration_doc =~ "write_mode: :legacy"
    assert @configuration_doc =~ "legacy_read: :allow"
    assert @configuration_doc =~ "write_mode: :dedicated"
    assert @install_doc =~ "generator does not provision verifier keys"

    assert @install_doc =~
             "your team keeps its accounts, sign-in pages, layouts, branding, and product policy"

    assert @install_doc =~
             "Account resolution, user login, consent policy, branding, and logout remain host responsibilities"

    assert @getting_started_doc =~ "separately from the files generated"

    for endpoint <- [
          "/token",
          "/revoke",
          "/introspect",
          "/device/code",
          "/backchannel/authentication"
        ] do
      assert @configuration_doc =~ endpoint
      assert @jwt_doc =~ endpoint
    end

    assert @jwt_doc =~ "POST /par"
    assert @jwt_doc =~ "HS384"
    assert @jwt_doc =~ "HS512"
    assert @jwt_doc =~ "Existing `client_secret_basic`"
    assert @jwt_doc =~ "one-time handoff with the partner"
  end

  test "maintainer handoff keeps candidate, accepted main, and publication authority separate" do
    assert @maintainer_doc =~ "one reviewed PR to `main`"
    assert @maintainer_doc =~ "pre-merge audit does not mean the milestone is accepted"
    assert @maintainer_doc =~ "--accept-sha <full-merged-main-sha>"
    assert @maintainer_doc =~ "does not authorize a merge, tag, dispatch, or publication"
    assert @maintainer_doc =~ "Release Please"
    assert @supported_doc =~ "canonical public support contract"
  end

  defp verifier_context(keys, current) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: Enum.map(keys, fn {id, key} -> {id, Base.url_encode64(key, padding: false)} end),
           current: current,
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    context
  end

  defp section(document, start_marker, next_marker) do
    document
    |> String.split(start_marker, parts: 2)
    |> case do
      [_before, after_start] -> String.split(after_start, next_marker, parts: 2) |> hd()
      _ -> flunk("missing documented section: #{start_marker}")
    end
  end
end
