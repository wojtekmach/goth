defmodule GothTest do
  use ExUnit.Case, async: true

  setup_all do
    start_supervised!({Finch, name: Finch})
    :ok
  end

  test "fetch/1", %{test: test} do
    now = System.system_time(:second)
    bypass = Bypass.open()

    Bypass.expect(bypass, fn conn ->
      body = ~s|{"access_token":"dummy","expires_in":3599,"token_type":"Bearer"}|
      Plug.Conn.resp(conn, 200, body)
    end)

    start_supervised!(
      {Goth,
       name: test,
       http_client: {Goth.HTTPClient.Finch, name: Finch},
       credentials: random_credentials(),
       url: "http://localhost:#{bypass.port}"}
    )

    {:ok, token} = Goth.fetch(test)
    assert token.token == "dummy"
    assert token.type == "Bearer"
    assert_in_delta token.expires_at, now + 3599, 1

    Bypass.down(bypass)
    {:ok, ^token} = Goth.fetch(test)
  end

  @tag :capture_log
  test "retries", %{test: test} do
    Process.flag(:trap_exit, true)
    pid = self()
    bypass = Bypass.open()

    Bypass.expect(bypass, fn conn ->
      send(pid, :pong)
      Plug.Conn.resp(conn, 500, "oops")
    end)

    Goth.Server.start_link(
      name: test,
      http_client: {Goth.HTTPClient.Finch, name: Finch},
      credentials: random_credentials(),
      url: "http://localhost:#{bypass.port}",
      cooldown: 10
    )

    # higher timeouts since calculating JWT is expensive
    assert_receive :pong, 1000
    assert_receive :pong, 1000
    assert_receive :pong, 1000

    assert_receive {:EXIT, _,
                    {%RuntimeError{message: "too many failed attempts to refresh" <> _}, _}},
                   1000
  end

  test "refresh", %{test: test} do
    pid = self()
    bypass = Bypass.open()

    Bypass.expect(bypass, fn conn ->
      send(pid, :pong)
      body = ~s|{"access_token":#{System.unique_integer()},"expires_in":1,"token_type":"Bearer"}|
      Plug.Conn.resp(conn, 200, body)
    end)

    start_supervised!(
      {Goth,
       name: test,
       http_client: {Goth.HTTPClient.Finch, name: Finch},
       credentials: random_credentials(),
       url: "http://localhost:#{bypass.port}",
       retries: 0}
    )

    # higher timeouts since calculating JWT is expensive
    assert_receive :pong, 1000
    assert_receive :pong, 1000
    assert_receive :pong, 1000
  end

  test "config/1", %{test: test} do
    assert_raise RuntimeError, fn ->
      Goth.config(test)
    end

    credentials = random_credentials()

    bypass = Bypass.open()

    Bypass.expect(bypass, fn conn ->
      body = ~s|{"access_token":"dummy","expires_in":3599,"token_type":"Bearer"}|
      Plug.Conn.resp(conn, 200, body)
    end)

    start_supervised!(
      {Goth,
       name: test,
       http_client: {Goth.HTTPClient.Finch, name: Finch},
       credentials: credentials,
       url: "http://localhost:#{bypass.port}"}
    )

    assert Goth.config(test).credentials == credentials
  end

  test "compatibility", %{test: test} do
    bypass = Bypass.open()

    Bypass.expect(bypass, fn conn ->
      body = ~s|{"access_token":"dummy","expires_in":3599,"token_type":"Bearer"}|
      Plug.Conn.resp(conn, 200, body)
    end)

    start_supervised!(
      {Goth,
       name: test,
       http_client: {Goth.HTTPClient.Finch, name: Finch},
       credentials: random_credentials(),
       url: "http://localhost:#{bypass.port}"}
    )

    assert_raise ArgumentError, ~r"could not fetch application environment :default_server", fn ->
      Goth.Token.for_scope("does-not-matter")
    end

    assert_raise ArgumentError, ~r"could not fetch application environment :default_server", fn ->
      Goth.Config.get(:client_email)
    end

    Application.put_env(:goth, :default_server, test)

    assert {:ok, %Goth.Token{}} = Goth.Token.for_scope("does-not-matter")
    assert {:ok, "alice@example.com"} = Goth.Config.get(:client_email)
    assert {:ok, "alice@example.com"} = Goth.Config.get("client_email")
  end

  defp random_credentials() do
    %{
      "private_key" => random_private_key(),
      "client_email" => "alice@example.com",
      "token_uri" => "/"
    }
  end

  defp random_private_key() do
    private_key = :public_key.generate_key({:rsa, 2048, 65537})
    {:ok, private_key}
    :public_key.pem_encode([:public_key.pem_entry_encode(:RSAPrivateKey, private_key)])
  end
end
