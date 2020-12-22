defmodule Goth.Config do
  @doc """
  Fetches the `key` from the config.

  WARNING: This function serves as compatibility layer for https://hex.pm/packages/goth
  and you should use `Goth.get_config/1` instead.

  In order to use it, you need to set this global configuration:

      config :goth,
        default_server: server

  Where `server` is the name of the server that was started with
  `Goth.start_link/1`.

  Currently, it only fetches the keys from the credentials config.

  ## Examples

      iex> Goth.Config.get(:client_email)
      {:ok, "alice@example.com"}

  """
  @doc deprecated: "Use Goth.config/1 instead"
  def get(key) when is_binary(key) do
    server = Application.fetch_env!(:goth, :default_server)
    config = Goth.config(server)
    Map.fetch(config.credentials, key)
  end

  def get(key) when is_atom(key) do
    get(Atom.to_string(key))
  end
end
