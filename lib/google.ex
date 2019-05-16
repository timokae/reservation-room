defmodule Google do
  use OAuth2.Strategy

  # Public API
  def auth_client do
    ReservationServer.Store.auth_client()
    |> OAuth2.Client.put_serializer("application/json", Jason)
    |> OAuth2.Client.put_header("content-type", "*/*")
    |> OAuth2.Client.put_header("accept", "*/*")
  end

  def refresh_client do
    ReservationServer.Store.refresh_client()
    |> OAuth2.Client.put_serializer("application/json", Jason)
    |> OAuth2.Client.put_header("content-type", "*/*")
    |> OAuth2.Client.put_header("accept", "*/*")
  end

  def request_client do
    ReservationServer.Store.request_client()
    |> OAuth2.Client.put_serializer("application/json", Jason)
    |> OAuth2.Client.put_header("content-type", "*/*")
    |> OAuth2.Client.put_header("accept", "*/*")
  end

  def authorize_url! do
    OAuth2.Client.authorize_url!(auth_client(),
      scope:
        "https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/calendar.events",
      access_type: "offline",
      prompt: "consent"
    )
  end

  def refresh_token! do
    OAuth2.Client.refresh_token!(Google.refresh_client())
  end

  def get_token!(code) do
    OAuth2.Client.get_token!(Google.auth_client(),
      code: code,
      client_secret: "2evZv5IDk55OtHkm21eAEKRa",
      access_type: "offline",
      prompt: "consent"
    )
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
