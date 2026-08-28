defmodule Lockspire.ReleasePleaseRuntimeContractTest do
  use ExUnit.Case, async: true

  @runtime_package Path.expand(
                     "../../.github/actions/release-please/runtime/package.json",
                     __DIR__
                   )
  @runtime_lock Path.expand(
                  "../../.github/actions/release-please/runtime/package-lock.json",
                  __DIR__
                )
  @runtime_entry Path.expand(
                   "../../.github/actions/release-please/runtime/index.js",
                   __DIR__
                 )
  @action Path.expand("../../.github/actions/release-please/action.yml", __DIR__)
  @dependabot Path.expand("../../.github/dependabot.yml", __DIR__)

  test "privileged local runtime is pinned, locked, and retains its composite action API" do
    package = File.read!(@runtime_package)
    lock = File.read!(@runtime_lock)
    action = File.read!(@action)

    assert package =~ "\"@actions/core\": \"3.0.1\""
    assert package =~ "\"release-please\": \"17.11.2\""
    assert package =~ "\"type\": \"module\""
    assert lock =~ "\"@actions/core\": \"3.0.1\""
    assert lock =~ "\"release-please\": \"17.11.2\""
    assert action =~ "npm ci"
    assert action =~ "--ignore-scripts"

    for output <- ["release_created", "tag_name", "sha", "version", "body"] do
      assert action =~ "#{output}:"
    end

    refute action =~ "googleapis/release-please-action@"
    refute action =~ "npm install"
  end

  test "runtime entry imports its pinned ESM dependencies under the action Node version" do
    entry = File.read!(@runtime_entry)

    assert entry =~ ~s(import * as core from "@actions/core")
    assert entry =~ ~s(import {GitHub, Manifest, VERSION} from "release-please")
    assert entry =~ "import.meta.url === pathToFileURL(invokedPath).href"
    refute entry =~ "require("
  end

  test "dependabot watches the checked-in nested npm runtime" do
    dependabot = File.read!(@dependabot)

    assert dependabot =~ "package-ecosystem: \"github-actions\""
    assert dependabot =~ "package-ecosystem: \"mix\""
    assert dependabot =~ "package-ecosystem: \"npm\""
    assert dependabot =~ "directory: \"/.github/actions/release-please/runtime\""
    assert dependabot =~ "interval: \"weekly\""
    assert dependabot =~ "open-pull-requests-limit: 5"
    refute dependabot =~ "package-ecosystem: \"npm\"\n    directory: \"/\""
  end
end
