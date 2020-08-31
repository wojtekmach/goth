defmodule Goth.HTTPClient do
  @moduledoc """
  Specification for a Goth HTTP client.

  The client is configured as a `{module, opts}` tuple where the module
  implements this behaviour and `opts` is a keyword list given to the
  `c:init/1` callback.

  For example, to use the built-in Finch-based client (via `Goth.HTTPClient.Finch`), do:

      http_client: {Goth.HTTPClient.Finch, name: MyApp.Finch}
  """

  @type method() :: atom()

  @type url() :: binary()

  @type status() :: non_neg_integer()

  @type header() :: {binary(), binary()}

  @type body() :: binary()

  @type initial_state() :: term()

  @type http_client() :: {module(), initial_state()}

  @doc """
  Callback to initialize the given HTTP client.

  The returned `initial_state` will be given to `c:request/6`.
  """
  @callback init(opts :: keyword()) :: initial_state()

  @doc """
  Callback to make an HTTP request.
  """
  @callback request(method(), url(), [header()], body(), opts :: keyword(), initial_state()) ::
              {:ok, %{status: status, headers: [header()], body: body()}}
              | {:error, Exception.t()}

  @spec request(http_client(), method(), url(), [header()], body(), opts :: keyword()) ::
          {:ok, %{status: status, headers: [header()], body: body()}}
          | {:error, Exception.t()}
  def request(http_client, method, url, headers, body, opts) do
    {module, initial_state} = http_client
    module.request(method, url, headers, body, opts, initial_state)
  end
end
