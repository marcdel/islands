%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ~w{config lib src test web apps},
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      strict: true,
      color: true,
      checks: [
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 98},
        {Credo.Check.Readability.Specs, priority: :low}
      ]
    }
  ]
}