defmodule Goth.Server do
  @moduledoc false

  use GenServer
  alias Goth.Token

  @max_retries 3
  @refresh_before 30

  defstruct [:name, :http_client, :credentials, :url, :scope, :cooldown, retries: @max_retries]

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def fetch(server) do
    {config, token} = get(server)

    if token do
      {:ok, token}
    else
      Token.fetch(config)
    end
  end

  @impl true
  def init(opts) do
    state =
      __MODULE__
      |> struct!(opts)
      |> Map.update!(:http_client, fn {module, opts} ->
        {module, module.init(opts)}
      end)

    # given calculating JWT for each request is expensive, we do it once
    # on system boot to hopefully fill in the cache.
    case Token.fetch(state) do
      {:ok, token} ->
        store_and_schedule_refresh(state, token)

      {:error, _} ->
        put(state, nil)
        send(self(), :refresh)
    end

    {:ok, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    case Token.fetch(state) do
      {:ok, token} ->
        store_and_schedule_refresh(state, token)
        {:noreply, %{state | retries: @max_retries}}

      {:error, exception} ->
        if state.retries > 1 do
          Process.send_after(self(), :refresh, state.cooldown)
          {:noreply, %{state | retries: state.retries - 1}}
        else
          raise "too many failed attempts to refresh, last error: #{inspect(exception)}"
        end
    end
  end

  defp store_and_schedule_refresh(state, token) do
    put(state, token)
    time = (token.expires_at - @refresh_before) * 1000
    Process.send_after(self(), :refresh, time)
  end

  defp get(name) do
    :persistent_term.get({__MODULE__, name})
  end

  defp put(state, token) do
    config = Map.take(state, [:http_client, :credentials, :scope, :url])
    :persistent_term.put({__MODULE__, state.name}, {config, token})
  end
end
