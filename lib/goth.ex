defmodule Goth do
  @moduledoc """
  Our re-implementation of [Goth](https://hex.pm/packages/goth).

  Notable differences:

    * Use finch instead of httpoison.

    * Use jose (hi!) directly instead of going through joken.

    * Use persistent_term to avoid single-process bottleneck.

    * Configure different servers for different tokens instead of global config.
    
    * You add it to your own supervision tree.

    * Simple built-in backoff.

  On the flip side, we don't support everything Goth has, notably we:

    * support only JSON credentials (and not the metadata service)

    * support one scope per credentials

    * haven't been around for more than 4 years!

  ## Usage

  Add Goth to your supervision tree:

      credentials = "GOOGLE_APPLICATION_CREDENTIALS_JSON" |> System.fetch_env!() |> Jason.decode!()

      children = [
        {Goth, name: MyApp.Goth, finch: MyApp.Finch, credentials: credentials},
        ...
      ]

      Supervisor.start_link(children, ...)

  And use it:

      Goth.fetch(MyApp.Goth)
      #=> {:ok, %Goth.Token{}}

  """

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

    * `:finch` - the name of the `Finch` pool to use.

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
