defmodule GoogleService.Refresher do
  use Task

  require Logger

  def start_link(_arg) do
    :timer.sleep(2000)
    Logger.debug("Refresher started")

    startResult = Task.start_link(&refresh/0)
    %{"access_token" => at} = GoogleService.Auth.refresh_token()
    ReservationServer.Store.put_access_token(at)

    startResult
  end

  def refresh do
    receive do
    after
      3000 * 1000 ->
        %{"access_token" => at} = GoogleService.Auth.refresh_token()
        ReservationServer.Store.put_access_token(at)
        refresh()
    end
  end
end
