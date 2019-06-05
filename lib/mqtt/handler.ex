defmodule Mqtt.Handler do
  @moduledoc false

  require Logger

  defstruct([:name])
  alias __MODULE__, as: State

  def init(opts) do
    name = Keyword.get(opts, :name)
    {:ok, %State{name: name}}
  end

  def connection(:up, state) do
    Logger.info("Connection has been established")
    {:ok, state}
  end

  def connection(:down, state) do
    Logger.warn("Connection has been dropped")
    {:ok, state}
  end

  def subscription(:up, topic, state) do
    Logger.info("Subscribed to #{topic}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    Logger.warn("Subscribed to #{topic}; requested #{req} but got accepted with QoS #{qos}")
    {:ok, state}
  end

  def subscription({:error, reason}, topic, state) do
    Logger.error("Error subscribing to #{topic}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(:down, topic, state) do
    Logger.info("Unsubscribed from #{topic}")
    {:ok, state}
  end

  def handle_message([room, "reserveRequest"], publish, state) do
    Logger.info("#{state.name}: #{room}/reserveRequest #{inspect(publish)}")

    {duration, _} = Integer.parse(publish)
    atom = String.to_atom(room)

    response =
      GoogleService.Calender.insert_block(
        ReservationServer.Store.access_token(),
        ReservationServer.Store.calender_id(atom),
        duration
      )

    case response do
      {:ok, _} ->
        Tortoise.publish(:server, "#{room}/reserveResponse", "true;0")
        GoogleService.EventFetcher.check_for_new_events([atom])

      {:blocked, time} ->
        Tortoise.publish(:server, "#{room}/reserveResponse", "false;#{time}")
    end

    # ReservationServerWeb.RoomChannel.notify_new_reservation(
    #   Enum.join(topic, ":"),
    #   publish
    # )

    {:ok, state}
  end

  def handle_message([room, "releaseRequest"], _, state) do
    Logger.info("#{state.name}: #{room}/releaseRequest")

    atom = String.to_atom(room)

    GoogleService.Calender.delete_current_block(
      ReservationServer.Store.access_token(),
      ReservationServer.Store.calender_id(atom)
    )

    {:ok, state}
  end

  def handle_message([_, "reservationUpdate"], _, state), do: {:ok, state}
  def handle_message([_, "reserveResponse"], _, state), do: {:ok, state}

  def handle_message(room, publish, state) do
    IO.inspect(room)
    IO.puts(publish)
    Logger.warn("Unhandled Message!")

    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.warn("Client has been terminated with reason: #{inspect(reason)}")
    :ok
  end
end
