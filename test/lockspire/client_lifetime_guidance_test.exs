defmodule Lockspire.ClientLifetimeGuidanceTest do
  use ExUnit.Case, async: true

  @guide Path.expand("../../docs/upgrading/client-lifetimes.md", __DIR__)
  @dcr_guide Path.expand("../../docs/dynamic-registration.md", __DIR__)
  @operator_guide Path.expand("../../docs/operator-admin.md", __DIR__)
  @supported_surface Path.expand("../../docs/supported-surface.md", __DIR__)
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
          "App management-token expiry is an optional host policy",
          "final-candidate CI plus independent security review are still pending"
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

  test "management-token guidance describes finite policy, replacement, and host recovery" do
    dcr_guide = File.read!(@dcr_guide) |> String.replace(~r/\s+/, " ")
    upgrade_guide = File.read!(@guide) |> String.replace(~r/\s+/, " ")
    operator_guide = File.read!(@operator_guide) |> String.replace(~r/\s+/, " ")
    support = File.read!(@supported_surface) |> String.replace(~r/\s+/, " ")

    for phrase <- [
          "Lockspire.mount_path",
          "Include the unchanged `client_id` in every PUT body",
          "lockspire_client_expires_at",
          "lockspire_registration_access_token_expires_at",
          "may omit them or echo their current values",
          "the previous app management token stops working immediately",
          "A GET does not renew",
          "means no automatic expiry",
          "Lockspire does not require one universal registration-token timeout",
          "it cannot read, update, or delete the registration",
          "An expired but enabled app can still be read or deleted with an eligible management token",
          "replay of the previous token cannot recover it",
          "issued at time `100`",
          "160",
          "110",
          "120",
          "rotates the token at time `125`",
          "165",
          "shows the committed replacement token once",
          "does not enable a disabled app or extend the app's expiry or client-secret expiry",
          "Recovery does not restore PUT permission: an expired app's PUT remains blocked with `registration_expired`",
          "no automatic app, client-secret, or management-token expiry"
        ] do
      assert dcr_guide =~ phrase
    end

    assert upgrade_guide =~ "Custom storage adapters must preserve"
    assert operator_guide =~ "app management token"

    assert operator_guide =~
             "Rotating this token does not enable the app or extend app or client-secret expiry."

    assert support =~ "Optional finite expiry for self-registered app management tokens"
    assert support =~ "host-authorized operator workflow"
  end

  test "adopter storage guidance names only the executed public composition and example" do
    guide = File.read!(@guide)
    architecture = File.read!(Path.expand("../../docs/architecture.md", __DIR__))
    onboarding = File.read!(Path.expand("../../docs/install-and-onboard.md", __DIR__))

    for phrase <- [
          "`:client_store` and",
          "`:transaction_store` application configuration keys",
          "Lockspire.Storage.ClientStore",
          "Lockspire.Storage.TransactionStore",
          "not arbitrary external databases",
          "client_store: MyApp.LifetimeClientStore",
          "transaction_store: MyApp.LifetimeClientStore",
          "docs/examples/client-lifetime-adapter.md",
          "mix test test/client_lifetime_adapter_test.exs",
          "replace `CleanRoomProvider.Repo` with your host repo module",
          "not a shipped",
          "repository's private `scripts/` tree",
          "49 checks passed and none failed or skipped",
          "observed source",
          "8050a398",
          "5709092d",
          "broader canonical integration matrix had unrelated"
        ] do
      assert guide =~ phrase
    end

    assert architecture =~ "`:client_store` and `:transaction_store` selectors"
    assert architecture =~ "does not establish support for arbitrary datastore backends"
    assert onboarding =~ "lifetime storage upgrade guide"
    assert onboarding =~ "require a source checkout"
  end

  test "lifetime guidance keeps expiry, disablement, and host sessions distinct" do
    dcr = File.read!(@dcr_guide) |> String.replace(~r/\s+/, " ")
    operator = File.read!(@operator_guide) |> String.replace(~r/\s+/, " ")
    support = File.read!(@supported_surface) |> String.replace(~r/\s+/, " ")

    for phrase <- [
          "`nil` or `0` means no automatic expiry",
          "app deadline has no renewal event",
          "Operator secret rotation issues a new shared-secret deadline",
          "Successful PUT and authorized host recovery issue a new app management-token deadline",
          "GET, authentication, enabling an app, and metadata-only changes do not renew them",
          "Offline JWT verification cannot observe later app disablement or expiry"
        ] do
      assert dcr =~ phrase
    end

    assert operator =~
             "These provider-side changes do not clear the host application's staff or end-user browser sessions."

    assert operator =~ "An expired client secret cannot authenticate"

    assert operator =~
             "Disabling an app blocks its protocol use and registration-management operations."

    assert support =~ "App expiry has no renewal event"
    assert support =~ "offline JWT verification and caches may not see a"
  end
end
