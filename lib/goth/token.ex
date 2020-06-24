defmodule Goth.Token do
  defstruct [:expires_at, :token, :type, :scope]

  @type t() :: %__MODULE__{
    expires_at: non_neg_integer(),
    scope: String.t(),
    token: String.t(),
    type: String.t(),
  }

  @doc false
  def fetch(finch, url, credentials, scope) do
    jwt = jwt(scope, credentials)

    case request(finch, url, jwt) do
      {:ok, %{status: 200} = response} ->
        map = Jason.decode!(response.body)
        %{"access_token" => token, "expires_in" => expires_in, "token_type" => type} = map
        expires_at = System.system_time(:second) + expires_in

        token = %__MODULE__{
          expires_at: expires_at,
          scope: scope,
          token: token,
          type: type
        }

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

  defp request(finch, url, jwt) do
    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    body = "grant_type=#{grant_type}&assertion=#{jwt}"

    Finch.build(:post, url, headers, body)
    |> Finch.request(finch)
  end
end
