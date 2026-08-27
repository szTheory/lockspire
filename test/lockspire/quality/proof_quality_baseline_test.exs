defmodule Lockspire.Quality.ProofQualityBaselineTest do
  use ExUnit.Case, async: true

  alias Lockspire.TestSupport.QualityBaseline

  @dialyzer_files [
    "lib/lockspire/admin/tokens.ex",
    "lib/lockspire/client_lifecycle.ex",
    "lib/lockspire/generators/install.ex",
    "lib/lockspire/install/migrations.ex",
    "lib/lockspire/protocol/refresh_exchange.ex",
    "lib/lockspire/protocol/registration_management.ex",
    "lib/lockspire/protocol/token_exchange.ex",
    "lib/lockspire/protocol/token_exchange/authorization_code_grant.ex",
    "lib/lockspire/protocol/token_exchange/ciba_grant.ex",
    "lib/lockspire/protocol/token_exchange/device_code_grant.ex",
    "lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex",
    "lib/lockspire/protocol/token_exchange/internal/device_code_grant.ex",
    "lib/lockspire/protocol/token_exchange/internal/grant_support.ex",
    "lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex",
    "lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex",
    "lib/lockspire/protocol/token_exchange/internal/token_issuer.ex",
    "lib/lockspire/storage/ecto/repository.ex",
    "lib/lockspire/storage/ecto/repository/token_store.ex",
    "lib/lockspire/web/controllers/registration_controller.ex",
    "lib/lockspire/web/live/admin/clients_live/show.ex",
    "lib/lockspire/web/live/admin/iat_live/new.ex",
    "lib/lockspire/web/live/admin/tokens_live/show.ex",
    "lib/mix/tasks/lockspire.upgrade.ex"
  ]

  test "finds macro injection, archived planning reads, and count thresholds by construct" do
    source = """
    defmacro __using__(_), do: quote(do: :ok)
    artifact = File.read!(@phase_125_proof_path)
    assert assertion_count >= 588
    """

    assert QualityBaseline.proof_constructs("test/example_test.exs", source) == [
             %{file: "test/example_test.exs", line: 1, kind: :macro_injection},
             %{file: "test/example_test.exs", line: 2, kind: :phase_archaeology},
             %{file: "test/example_test.exs", line: 3, kind: :count_threshold}
           ]
  end

  test "pins active proof cleanup identities for Plan 11" do
    constructs = QualityBaseline.active_proof_constructs()

    assert QualityBaseline.proof_locations(constructs, :macro_injection) == [
             {"test/support/admin_contract_helpers.ex", 4},
             {"test/support/release_contract_helpers.ex", 4}
           ]

    assert QualityBaseline.proof_locations(constructs, :phase_archaeology) == [
             {"test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs", 157},
             {"test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs", 222},
             {"test/support/admin_contract_helpers.ex", 953}
           ]

    assert QualityBaseline.proof_locations(constructs, :count_threshold) == [
             {"test/lockspire/release_readiness_contract_test.exs", 85},
             {"test/lockspire/web/live/admin/design_system/inventory_contract_test.exs", 50},
             {"test/lockspire/web/live/admin/design_system/inventory_contract_test.exs", 51},
             {"test/lockspire/web/live/admin/design_system/inventory_contract_test.exs", 52},
             {"test/lockspire/web/live/admin/design_system/inventory_contract_test.exs", 53}
           ]
  end

  test "parses the zero-ignore Dialyzer baseline by exact owning source file" do
    output = """
    Total errors: 66, Skipped: 0, Unnecessary Skips: 0
    lib/lockspire/client_lifecycle.ex:40:invalid_contract
    detail
    lib/lockspire/protocol/token_exchange.ex:114:16:pattern_match
    """

    assert QualityBaseline.dialyzer_error_count(output) == 66

    assert QualityBaseline.dialyzer_warning_locations(output) == [
             %{file: "lib/lockspire/client_lifecycle.ex", line: 40, kind: "invalid_contract"},
             %{file: "lib/lockspire/protocol/token_exchange.ex", line: 114, kind: "pattern_match"}
           ]

    assert QualityBaseline.dialyzer_warning_files(@dialyzer_files) == @dialyzer_files
    refute File.exists?(".dialyzer_ignore.exs")
  end
end
