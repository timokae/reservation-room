defmodule ReservationServerWeb.AuthController do
  use ReservationServerWeb, :controller

  def index(conn, _) do
    redirect(conn, external: GoogleService.Auth.authorize_url())
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  def callback(conn, %{"provider" => _provider, "code" => code}) do
    response = GoogleService.Auth.get_token(code)

    ReservationServer.Store.put_access_token(Map.get(response, "access_token"))
    ReservationServer.Store.put_refresh_token(Map.get(response, "refresh_token"))

    GoogleService.Refresher.start_link([])

    conn
    |> redirect(to: "/")
  end
end
