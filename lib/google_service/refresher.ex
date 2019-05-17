defmodule GoogleService.Refresher do
  use Task

  def start_link(_arg) do
    Task.start_link(&refresh/0)
    %{"access_token" => at} = GoogleService.Auth.refresh_token()
    ReservationServer.Store.put_access_token(at)
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
