defmodule ReservationServer.Store do
  use Agent

  require Logger

  def start_link(_) do
    Logger.debug("Store started")

    Agent.start_link(
      fn ->
        %{
          calender_atoms: [:meeting],
          refresh_token: Application.get_env(:reservation_server, :refresh_token),
          calenders: %{
            meeting: %{
              id: "gjh9urs7c9474kqdt7r326d7d0@group.calendar.google.com",
              next_events: []
            }
          }
        }
      end,
      name: __MODULE__
    )
  end

  def calender_atoms do
    Agent.get(__MODULE__, fn map ->
      Map.get(map, :calender_atoms)
    end)
  end

  def put_access_token(token) do
    Agent.update(__MODULE__, fn map ->
      Map.put(map, :access_token, token)
    end)
  end

  def access_token do
    Agent.get(__MODULE__, fn map ->
      Map.get(map, :access_token)
    end)
  end

  def put_refresh_token(token) do
    Agent.update(__MODULE__, fn map ->
      Map.put(map, :refresh_token, token)
    end)
  end

  def refresh_token do
    Agent.get(__MODULE__, fn map ->
      Map.get(map, :refresh_token)
    end)
  end

  def calender_id(calender) do
    Agent.get(__MODULE__, &Map.get(&1, :calenders))
    |> Map.get(calender)
    |> Map.get(:id)
  end

  def next_events(calender) do
    Agent.get(__MODULE__, &Map.get(&1, :calenders))
    |> Map.get(calender)
    |> Map.get(:next_events)
  end

  def put_next_events(calender, events) do
    Agent.update(__MODULE__, fn map ->
      update_in(map, [:calenders, calender, :next_events], fn _list -> events end)
    end)
  end
end
