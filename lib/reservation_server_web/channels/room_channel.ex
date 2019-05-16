defmodule ReservationServerWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end

  def notify_new_reservation(room, msg) do
    payload = Jason.encode!(%{room: room, msg: msg})
    ReservationServerWeb.Endpoint.broadcast!(room, "new_reservation", %{body: payload})
  end
end
