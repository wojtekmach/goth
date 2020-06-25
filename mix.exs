defmodule Goth.MixProject do
  use Mix.Project

  def project do
    [
      app: :goth,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [
        exclude: [Finch]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:jose, "~> 1.0"},
      {:finch, "~> 0.3.0", optional: true},
      # TODO: Master version does not emit simple_one_for_one warnings
      {:bypass, "~> 1.0", github: "PSPDFKit-labs/bypass", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
