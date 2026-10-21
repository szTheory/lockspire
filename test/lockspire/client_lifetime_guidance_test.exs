defmodule Lockspire.ClientLifetimeGuidanceTest do
  use ExUnit.Case, async: true

  @guide Path.expand("../../docs/upgrading/client-lifetimes.md", __DIR__)
  @upgrade_task Path.expand("../../lib/mix/tasks/lockspire.upgrade.ex", __DIR__)
  @runner Path.expand("../../scripts/acceptance/clean_room/client_lifetime_upgrade.py", __DIR__)

  test "the host guide states the additive, prefix-aware migration and rollback boundary" do
    guide = File.read!(@guide)

    for phrase <- [
          "prefix-aware",
          "mix lockspire.upgrade --dry-run",
          "--storage-prefix tenant_auth --oban-prefix tenant_auth",
          "web nodes, admin processes, Oban jobs, and CLI or",
          "After that first write, an old binary must not serve protocol traffic",
          "Fix forward",
          "does not promise immediate",
          "Phase 166"
        ] do
      assert guide =~ phrase
    end

    assert Regex.match?(~r/Do\s+not assume zero downtime/, guide)
    assert Regex.match?(~r/does not promise immediate\s+revocation/, guide)
  end

  test "documented installer and package receipt options exist in their real entry points" do
    task = File.read!(@upgrade_task)
    runner = File.read!(@runner)

    assert task =~ "dry_run: :boolean"
    assert task =~ "storage_prefix: :string"
    assert task =~ "oban_prefix: :string"
    assert runner =~ "parser.add_argument(\"--receipt\", type=Path)"
    assert runner =~ "parser.add_argument(\"--check-receipt\", type=Path)"
  end

  test "packaged upgrade proof documents both supported prefix scenarios" do
    guide = File.read!(@guide)
    runner = File.read!(@runner)

    assert guide =~ "`public` and `tenant_auth`"
    assert runner =~ ~s(SCENARIOS = {"public": "public", "tenant_auth": "tenant_auth"})
    assert guide =~ "client_lifetime_upgrade.py --check-receipt"
  end
end
