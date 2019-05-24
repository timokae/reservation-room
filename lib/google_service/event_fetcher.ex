defmodule GoogleService.EventFetcher do
  use Task

  require Logger

  def start_link(_args) do
    Logger.debug("EventFetcher started")
    Task.start_link(&fetch/0)
  end

  def fetch do
    receive do
    after
      60 * 1000 ->
        atoms = ReservationServer.Store.calender_atoms()

        list =
          atoms
          |> Enum.reduce([], fn atom, acc ->
            events = next_events(atom, 2)
            [{atom, events} | acc]
          end)

        Enum.each(list, &notify/1)

        fetch()
    end
  end

  def next_events(atom, amount) do
    {:ok, events} =
      GoogleService.Calender.events(
        ReservationServer.Store.access_token(),
        ReservationServer.Store.calender_id(atom),
        Timex.now("Europe/Berlin"),
        Timex.now("Europe/Berlin") |> Timex.shift(hours: 12)
      )

    Enum.take(events, amount)
  end

  def notify({atom, events}) do
    Logger.debug("Notify room #{Atom.to_string(atom)}")

    Enum.each(events, fn event ->
      name = Map.get(event, "summary")
      from = get_in(event, ["start", "dateTime"])
      to = get_in(event, ["end", "dateTime"])
      Logger.debug("#{name} from #{from} til #{to}")
    end)
  end
end
