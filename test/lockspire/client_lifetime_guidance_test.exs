defmodule Lockspire.ClientLifetimeGuidanceTest do
  use ExUnit.Case, async: true

  @guide Path.expand("../../docs/upgrading/client-lifetimes.md", __DIR__)
  @dcr_guide Path.expand("../../docs/dynamic-registration.md", __DIR__)
  @jwt_guide Path.expand("../../docs/client-secret-jwt-host-guide.md", __DIR__)
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

  test "dynamic registration guidance separates management PUT rotation from secret rotation" do
    guide = File.read!(@dcr_guide) |> String.replace(~r/\s+/, " ")

    for phrase <- [
          "A value of `0` means that the secret has no automatic expiry",
          "is recorded for newly registered self-managed apps that use a shared secret",
          "Changing the setting does not change the expiry already stored",
          "At the exact expiry time and afterward",
          "does not revoke access or refresh tokens that were already issued",
          "A successful PUT rotates the app management token",
          "It preserves the existing client secret",
          "the new secret is shown once"
        ] do
      assert guide =~ phrase
    end

    refute guide =~
             "This will rotate both the `client_secret` and the `registration_access_token`"

    refute guide =~ ~s("client_secret": "sec_rotated789")
  end

  test "upgrade and secret JWT guidance describe legacy replacement and separate assertion timing" do
    upgrade_guide = File.read!(@guide) |> String.replace(~r/\s+/, " ")
    jwt_guide = File.read!(@jwt_guide) |> String.replace(~r/\s+/, " ")

    for phrase <- [
          "A legacy secret continues to work until it is explicitly replaced",
          "uses the current DCR secret-lifetime policy",
          "zero-argument clock function",
          "after the adapter has locked and reloaded the current row",
          "Management-token expiry and recovery remain owned by Phase 165",
          "Phase 166 owns"
        ] do
      assert upgrade_guide =~ phrase
    end

    for phrase <- [
          "A blank or zero setting means no automatic expiry",
          "legacy secret dates remain advisory until an operator replaces",
          "It does not replace assertion `exp`, `iat`, audience, algorithm, or replay checks",
          "does not revoke tokens issued earlier",
          "partner coordination around credential rollout"
        ] do
      assert jwt_guide =~ phrase
    end

    refute upgrade_guide =~ "does not complete later shared-secret"
    refute upgrade_guide =~ "Management-token expiry and recovery are implemented"
  end
end
