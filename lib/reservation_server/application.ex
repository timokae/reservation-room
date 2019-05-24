defmodule ReservationServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      ReservationServer.Repo,
      # Start the endpoint when the application starts
      ReservationServerWeb.Endpoint,
      # Starts a worker by calling: ReservationServer.Worker.start_link(arg)
      # {ReservationServer.Worker, arg},
      ReservationServer.Store,
      GoogleService.Refresher,
      GoogleService.EventFetcher
    ]

    {:ok, _} =
      Tortoise.Supervisor.start_child(
        client_id: :a,
        handler: {Mqtt.Handler, [name: :server]},
        server: {Tortoise.Transport.Tcp, host: 'localhost', port: 1883},
        subscriptions: [{"+/+", 0}]
      )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReservationServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ReservationServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
