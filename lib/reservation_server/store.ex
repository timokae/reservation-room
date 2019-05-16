defmodule ReservationServer.Store do
  use Agent

  def start_link(_) do
    Agent.start_link(
      fn ->
        %{
          refresh_token: Application.get_env(:reservation_server, :refresh_token)
        }
      end,
      name: __MODULE__
    )
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
end
