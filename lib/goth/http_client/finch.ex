defmodule Goth.HTTPClient.Finch do
  @moduledoc """
  Finch-based HTTP client for Goth.

  ## Options

    * `:name` - the name of the `Finch` pool to use.

    * `:default_opts` - default options that will be used on each request,
      defaults to `[]`. See `Finch.request/3` for a list of supported options.
  """

  @behaviour Goth.HTTPClient

  defstruct [:name, default_opts: []]

  require Logger

  @impl true
  def init(opts) do
    unless Code.ensure_loaded?(Finch) do
      Logger.error("""
      Could not find finch dependency.

      Please add it to your dependencies:

          {:finch, "~> 0.3.0"}
      """)

      raise "missing finch dependency"
    end

    _ = Application.ensure_all_started(:finch)
    struct!(__MODULE__, opts)
  end

  @impl true
  def request(method, url, headers, body, opts, initial_state) do
    Finch.build(method, url, headers, body)
    |> Finch.request(initial_state.name, Keyword.merge(initial_state.default_opts, opts))
  end
end
