defmodule ReservationServer.Repo do
  use Ecto.Repo,
    otp_app: :reservation_server,
    adapter: Ecto.Adapters.Postgres
end
