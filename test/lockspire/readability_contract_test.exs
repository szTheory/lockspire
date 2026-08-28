defmodule Lockspire.ReadabilityContractTest do
  use ExUnit.Case, async: true

  @facade Path.expand("../../lib/lockspire/protocol/token_exchange.ex", __DIR__)
  @grant_support Path.expand(
                   "../../lib/lockspire/protocol/token_exchange/grant_support.ex",
                   __DIR__
                 )
  @lib_root Path.expand("../../lib", __DIR__)
  @planning_marker ~r/\b(?:Phase|Plan)\s+\d+|acceptance marker|\b(?:D|WR|VERIFIER|TELEMETRY|FORMAT|DISCOVERY|DCR|SIGNER|AUD|FAPI)-\d+\b|\bT-\d+(?:-\d+)?\b/i

  test "token endpoint module names match their source paths" do
    assert File.read!(@facade) =~ "defmodule Lockspire.Protocol.TokenExchange do"

    assert File.read!(@grant_support) =~
             "defmodule Lockspire.Protocol.TokenExchange.GrantSupport do"

    refute File.exists?(
             Path.expand("../../lib/lockspire/protocol/token_exchange_facade.ex", __DIR__)
           )
  end

  test "token endpoint source carries durable engineering rationale instead of roadmap labels" do
    for path <- [@facade, @grant_support] do
      refute Regex.match?(~r/\b(?:Phase|Plan)\s+\d+/i, File.read!(path)),
             "planning marker remains in #{Path.relative_to_cwd(path)}"
    end
  end

  test "runtime source contains durable rationale instead of planning vocabulary" do
    @lib_root
    |> Path.join("**/*.{ex,exs}")
    |> Path.wildcard()
    |> Enum.each(fn path ->
      refute Regex.match?(@planning_marker, File.read!(path)),
             "planning marker remains in #{Path.relative_to_cwd(path)}"
    end)
  end
end
