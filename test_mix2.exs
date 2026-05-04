defmodule TestMix2 do
  use Mix.Project
  def project do
    [
      app: :test, version: "0.1.0",
      aliases: ["deps.audit": ["hex.audit", "deps.audit"]]
    ]
  end
end
