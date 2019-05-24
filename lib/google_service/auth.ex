defmodule GoogleService.Auth do
  def authorize_url do
    url = "https://accounts.google.com/o/oauth2/v2/auth"

    options = [
      client_id: Application.get_env(:reservation_server, :client_id),
      # client_secret: Application.get_env(:reservation_server, :client_secret),
      redirect_uri: Application.get_env(:reservation_server, :redirect_uri),
      scope:
        "https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/calendar.events",
      access_type: "offline",
      prompt: "consent",
      response_type: "code"
    ]

    url <> "?" <> URI.encode_query(options)
  end

  def get_token(code) do
    url = "https://accounts.google.com/o/oauth2/token"

    headers = [
      accept: "application/json"
    ]

    body =
      Poison.encode!(%{
        code: code,
        client_id: Application.get_env(:reservation_server, :client_id),
        client_secret: Application.get_env(:reservation_server, :client_secret),
        grant_type: "authorization_code",
        redirect_uri: Application.get_env(:reservation_server, :redirect_uri)
      })

    {:ok, response} = HTTPoison.post(url, body, headers)
    IO.inspect(Poison.decode!(response.body))
    Poison.decode!(response.body)
  end

  def refresh_token do
    url = "https://accounts.google.com/o/oauth2/token"

    headers = [
      accept: "application/json"
    ]

    body =
      Poison.encode!(%{
        refresh_token: ReservationServer.Store.refresh_token(),
        client_id: Application.get_env(:reservation_server, :client_id),
        client_secret: Application.get_env(:reservation_server, :client_secret),
        grant_type: "refresh_token",
        redirect_uri: Application.get_env(:reservation_server, :redirect_uri)
      })

    {:ok, response} = HTTPoison.post(url, body, headers)
    IO.inspect(Poison.decode!(response.body))
    Poison.decode!(response.body)
  end
end
