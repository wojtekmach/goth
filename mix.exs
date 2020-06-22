defmodule Goth.MixProject do
  use Mix.Project

  def project do
    [
      app: :goth,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:finch, "~> 0.2.0 or ~> 0.3.0"},
      {:jason, "~> 1.0"},
      {:jose, "~> 1.0"},
      # TODO: Master version does not emit simple_one_for_one warnings
      {:bypass, "~> 1.0", github: "PSPDFKit-labs/bypass", only: :test}
    ]
  end
end
