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
        extra: [
          # These tags correlate in-memory verification events and are intentionally
          # omitted from formatted application logs.
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig,
           metadata_keys: [
             :event,
             :category,
             :authorization_scheme,
             :reason_code,
             :required_audiences_count,
             :lockspire_disclosure_capture_ref,
             :lockspire_disclosure_capture_phase
           ]}
        ],
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
