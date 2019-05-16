defmodule ReservationServerWeb.PageController do
  use ReservationServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
