%{
  configs: [
    %{
      name: "default",
      strict: true,
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
