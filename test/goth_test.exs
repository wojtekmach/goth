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

    credentials = %{
      "private_key" => random_private_key(),
      "client_email" => "alice@example.com",
      "token_uri" => "/"
    }

    url = "http://localhost:#{bypass.port}"

    start_supervised!({Goth, name: test, finch: Finch, credentials: credentials, url: url})

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

    credentials = %{
      "private_key" => random_private_key(),
      "client_email" => "alice@example.com",
      "token_uri" => "/"
    }

    url = "http://localhost:#{bypass.port}"

    Goth.Server.start_link(
      name: test,
      finch: Finch,
      credentials: credentials,
      url: url,
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

  defp random_private_key() do
    private_key = :public_key.generate_key({:rsa, 2048, 65537})
    {:ok, private_key}
    :public_key.pem_encode([:public_key.pem_entry_encode(:RSAPrivateKey, private_key)])
  end
end
