%{
  configs: [
    %{
      name: "default",
      strict: true,
      # Security-sensitive protocol modules must never disappear from analysis
      # merely because a slower runner exceeds Credo's default 5s parse budget.
      parse_timeout: 30_000,
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      checks: %{
        disabled: [
          {Credo.Check.Design.AliasUsage, files: %{included: ["test/**/*.exs"]}},
          {Credo.Check.Readability.AliasOrder, files: %{included: ["test/**/*.exs"]}},
          {Credo.Check.Refactor.Nesting,
           files: %{included: ["test/lockspire/protocol/authorization_flow_test.exs"]}}
        ]
      }
    }
  ]
}
