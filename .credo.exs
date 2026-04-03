%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/test\/support/"]
      },
      checks: %{
        enabled: [
          {Credo.Check.Consistency.TabsOrSpaces, []},
          {Credo.Check.Design.AliasUsage,
           if_nested_deeper_than: 2, excluded_namespaces: ["Phoenix"]},
          {Credo.Check.Readability.MaxLineLength, max_length: 120},
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Readability.Specs, []},
          {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 10}
        ]
      }
    }
  ]
}
