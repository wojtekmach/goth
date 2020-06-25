defmodule Goth do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc """
  Fetches the token.

  If the token is not in the cache, we immediately request it.
  """
  defdelegate fetch(server), to: Goth.Server

  @scope "https://www.googleapis.com/auth/cloud-platform"
  @url "https://www.googleapis.com/oauth2/v4/token"
  @cooldown 1000

  @doc """
  Starts the server.

  When the server is started, we attempt to fetch the token and store it in
  internal cache. If we fail, we'll try up to 3 times with #{@cooldown}ms
  cooldown between requests and if we couldn't retrieve it, we crash.

  ## Options

    * `:name` - the name to register the server under.

    * `:http_client` - a `{module, opts}` tuple describing a HTTP client,
      see `Goth.HTTPClient` for more information.

    * `:credentials` - a map of credentials.

    * `:cooldown` - Time in milliseconds between retrying requests, defaults
      to `#{@cooldown}`.

    * `:scope` - Token scope, defaults to `#{inspect(@scope)}`.

    * `:url` - URL to fetch the token from, defaults to `#{inspect(@url)}`.

  """
  def start_link(opts) do
    opts |> with_default_opts() |> Goth.Server.start_link()
  end

  @doc false
  def child_spec(opts) do
    opts |> with_default_opts() |> Goth.Server.child_spec()
  end

  defp with_default_opts(opts) do
    opts
    |> Keyword.put_new(:scope, @scope)
    |> Keyword.put_new(:url, @url)
    |> Keyword.put_new(:cooldown, @cooldown)
  end
end
