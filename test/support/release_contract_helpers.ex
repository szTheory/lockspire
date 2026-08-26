defmodule Lockspire.TestSupport.ReleaseContractHelpers do
  @moduledoc false

  defmacro __using__(_opts) do
    repo_root = Path.expand("../..", __DIR__)

    quote bind_quoted: [repo_root: repo_root] do
      import Lockspire.TestSupport.AdvancedSetupSupportTruth,
        only: [
          assert_advanced_setup_support_contract!: 1,
          assert_install_and_onboard_guide!: 1,
          assert_private_key_jwt_host_guide!: 1,
          assert_mtls_host_guide!: 1,
          assert_protected_routes_guide!: 1,
          assert_operator_admin_guide!: 1,
          assert_dynamic_registration_guide!: 1,
          assert_maintainer_release_deference!: 1,
          assert_security_policy_deference!: 1,
          refute_broadened_security_non_claims!: 1
        ]

      import Lockspire.TestSupport.ClientSecretJwtSupportTruth
      import Lockspire.TestSupport.ReleaseContractHelpers

      @maintainer_guide_path Path.join(repo_root, "docs/maintainer-release.md")
      @release_workflow_path Path.join(repo_root, ".github/workflows/release.yml")
      @release_please_automerge_workflow_path Path.join(
                                                repo_root,
                                                ".github/workflows/release-please-automerge.yml"
                                              )
      @release_please_action_path Path.join(
                                    repo_root,
                                    ".github/actions/release-please/action.yml"
                                  )
      @release_please_runtime_package_path Path.join(
                                             repo_root,
                                             ".github/actions/release-please/runtime/package.json"
                                           )
      @release_please_runtime_lock_path Path.join(
                                          repo_root,
                                          ".github/actions/release-please/runtime/package-lock.json"
                                        )
      @release_please_runtime_index_path Path.join(
                                           repo_root,
                                           ".github/actions/release-please/runtime/index.js"
                                         )
      @ci_workflow_path Path.join(repo_root, ".github/workflows/ci.yml")
      @oidf_conformance_workflow_path Path.join(
                                        repo_root,
                                        ".github/workflows/oidf-conformance.yml"
                                      )
      @release_please_config_path Path.join(repo_root, "release-please-config.json")
      @release_please_manifest_path Path.join(repo_root, ".release-please-manifest.json")
      @readme_path Path.join(repo_root, "README.md")
      @supported_surface_path Path.join(repo_root, "docs/supported-surface.md")
      @maintainer_conformance_path Path.join(repo_root, "docs/maintainer-conformance.md")
      @phase37_conformance_script_path Path.join(
                                         repo_root,
                                         "scripts/conformance/run_phase37_suite.sh"
                                       )
      @phase37_conformance_plan_path Path.join(
                                       repo_root,
                                       "scripts/conformance/phase37-plan.json"
                                     )
      @security_policy_path Path.join(repo_root, "SECURITY.md")
      @install_and_onboard_path Path.join(repo_root, "docs/install-and-onboard.md")
      @private_key_jwt_host_guide_path Path.join(
                                         repo_root,
                                         "docs/private-key-jwt-host-guide.md"
                                       )
      @client_secret_jwt_host_guide_path Path.join(
                                           repo_root,
                                           "docs/client-secret-jwt-host-guide.md"
                                         )
      @mtls_host_guide_path Path.join(repo_root, "docs/mtls-host-guide.md")
      @protect_phoenix_api_routes_path Path.join(
                                         repo_root,
                                         "docs/protect-phoenix-api-routes.md"
                                       )
      @saas_adoption_recipe_path Path.join(repo_root, "docs/saas-adoption-recipe.md")
      @operator_admin_guide_path Path.join(repo_root, "docs/operator-admin.md")
      @dynamic_registration_guide_path Path.join(repo_root, "docs/dynamic-registration.md")
      @device_flow_host_guide_path Path.join(repo_root, "docs/device-flow-host-guide.md")
      @rar_consent_host_guide_path Path.join(repo_root, "docs/rar-consent-host-guide.md")
      @upgrading_v1_27_path Path.join(repo_root, "docs/upgrading/v1.27.md")
      @project_path Path.join(repo_root, ".planning/PROJECT.md")
      @repo_hygiene_script_path Path.join(
                                  repo_root,
                                  "scripts/maintainer/repo_hygiene_check.sh"
                                )
      @adoption_demo_docs_path Path.join(repo_root, "docs/adoption-demo.md")
      @docker_reset_path Path.join(repo_root, "examples/adoption_demo/bin/docker-reset")
      @docker_stop_path Path.join(repo_root, "examples/adoption_demo/bin/docker-stop")
      @docker_cleanup_path Path.join(repo_root, "examples/adoption_demo/bin/docker-cleanup")
      @fapi2_conformance_plan_path Path.join(repo_root, "scripts/conformance/fapi2-plan.json")
      @templates_registry_path Path.join(repo_root, "lib/lockspire/generators/templates.ex")
      @adoption_demo_router_path Path.join(
                                   repo_root,
                                   "examples/adoption_demo/lib/adoption_demo_web/router.ex"
                                 )
      @install_template_router_path Path.join(
                                      repo_root,
                                      "priv/templates/lockspire.install/router.ex"
                                    )
      @install_task_path Path.join(repo_root, "lib/mix/tasks/lockspire.install.ex")
      @install_generator_path Path.join(repo_root, "lib/lockspire/generators/install.ex")
      @adoption_smoke_script_path Path.join(repo_root, "scripts/demo/adoption_smoke.py")
      @adoption_smoke_wrapper_path Path.join(repo_root, "scripts/demo/adoption_smoke.sh")
    end
  end

  def mix_version do
    repo_file("mix.exs")
    |> File.read!()
    |> then(&Regex.run(~r/version:\s+"([0-9]+\.[0-9]+\.[0-9]+)"/, &1, capture: :all_but_first))
    |> List.first()
  end

  def manifest_version do
    repo_file(".release-please-manifest.json")
    |> File.read!()
    |> then(&Regex.run(~r/"\."\s*:\s*"([0-9]+\.[0-9]+\.[0-9]+)"/, &1, capture: :all_but_first))
    |> List.first()
  end

  def newest_changelog_version, do: List.first(changelog_versions())

  def changelog_versions do
    repo_file("CHANGELOG.md")
    |> File.read!()
    |> then(&Regex.scan(~r/^## \[([0-9]+\.[0-9]+\.[0-9]+)\]/m, &1, capture: :all_but_first))
    |> Enum.map(&List.first/1)
  end

  def release_workflow_job(name, next_name) do
    repo_file(".github/workflows/release.yml")
    |> File.read!()
    |> then(
      &Regex.run(
        ~r/^  #{Regex.escape(name)}:\n(.*?)^  #{Regex.escape(next_name)}:/ms,
        &1,
        capture: :all_but_first
      )
    )
    |> List.first()
  end

  def publish_job_section do
    repo_file(".github/workflows/release.yml")
    |> File.read!()
    |> then(&Regex.run(~r/^  publish:\n(.*)\z/ms, &1, capture: :all_but_first))
    |> List.first()
  end

  def extract_canonical_pipeline!(path, kind) do
    bytes =
      path
      |> File.read!()
      |> then(
        &Regex.run(
          ~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n[ \t]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms,
          &1,
          capture: :all_but_first
        )
      )
      |> case do
        [captured] when is_binary(captured) and captured != "" -> captured
        _ -> raise "missing BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers in #{path}"
      end

    normalize(bytes, kind)
  end

  def canonical_hash!(path, kind) do
    bytes = extract_canonical_pipeline!(path, kind)

    unless bytes =~ "Lockspire.Plug.VerifyToken" do
      raise "canonical region in #{path} missing Lockspire.Plug.VerifyToken — markers renamed or extraction broken"
    end

    if String.ends_with?(path, ".ex") and bytes =~ ~r/<%/ do
      raise "canonical region in #{path} contains EEx tag — heredoc interpolation would chew the canonical bytes"
    end

    :crypto.hash(:sha256, bytes)
  end

  def byte_offset(bytes, needle) do
    case :binary.match(bytes, needle) do
      {start, _len} ->
        start

      :nomatch ->
        raise ExUnit.AssertionError,
          message: "expected #{inspect(needle)} in canonical pipeline block"
    end
  end

  defp normalize(bytes, kind) when kind in [:python_commented, :elixir_in_commented_heredoc] do
    bytes
    |> String.replace("\r\n", "\n")
    |> strip_uniform_indent()
    |> String.split("\n")
    |> Enum.map_join("\n", &String.replace_prefix(&1, "# ", ""))
    |> strip_uniform_indent()
    |> String.replace(~r/[ \t]+$/m, "")
  end

  defp normalize(bytes, _kind) do
    bytes
    |> String.replace("\r\n", "\n")
    |> strip_uniform_indent()
    |> String.replace(~r/[ \t]+$/m, "")
  end

  defp strip_uniform_indent(bytes) do
    lines = String.split(bytes, "\n")

    non_blank_indents =
      lines
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.map(fn line ->
        case Regex.run(~r/^[ \t]*/, line) do
          [leading] -> String.length(leading)
          _ -> 0
        end
      end)

    case non_blank_indents do
      [] ->
        bytes

      indents ->
        n = Enum.min(indents)

        Enum.map_join(lines, "\n", fn line ->
          if String.length(line) >= n, do: String.slice(line, n..-1//1), else: line
        end)
    end
  end

  defp repo_file(relative_path), do: Path.expand("../../#{relative_path}", __DIR__)
end
