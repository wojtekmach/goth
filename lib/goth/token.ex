defmodule Goth.Token do
  defstruct [:token, :type, :expires_at]

  @doc false
  def fetch(finch, credentials, scope, opts \\ []) do
    jwt = jwt(scope, credentials)

    case request(finch, jwt, opts) do
      {:ok, %{status: 200} = response} ->
        map = Jason.decode!(response.body)
        %{"access_token" => token, "expires_in" => expires_in, "token_type" => type} = map
        expires_at = System.system_time(:second) + expires_in
        token = %__MODULE__{token: token, type: type, expires_at: expires_at}
        {:ok, token}

      {:ok, response} ->
        message = """
        unexpected status #{response.status} from Google

        #{response.body}
        """

        {:error, RuntimeError.exception(message)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  defp jwt(scope, %{
         "private_key" => private_key,
         "client_email" => client_email,
         "token_uri" => token_uri
       }) do
    jwk = JOSE.JWK.from_pem(private_key)
    header = %{"alg" => "RS256", "typ" => "JWT"}
    unix_time = System.system_time(:second)

    claim_set = %{
      "iss" => client_email,
      "scope" => scope,
      "aud" => token_uri,
      "exp" => unix_time + 3600,
      "iat" => unix_time
    }

    JOSE.JWT.sign(jwk, header, claim_set) |> JOSE.JWS.compact() |> elem(1)
  end

  defp request(finch, jwt, opts) do
    url = opts[:url] || "https://www.googleapis.com/oauth2/v4/token"
    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    body = "grant_type=#{grant_type}&assertion=#{jwt}"
    request(finch, :post, url, headers, body)
  end

  # TODO: remove on Finch v0.3.0
  if Code.ensure_loaded?(Finch) and function_exported?(Finch, :build, 4) do
    defp request(finch, method, url, headers, body) do
      Finch.build(method, url, headers, body)
      |> Finch.request(finch)
    end
  else
    defp request(finch, method, url, headers, body) do
      Finch.request(finch, method, url, headers, body)
    end
  end
end
