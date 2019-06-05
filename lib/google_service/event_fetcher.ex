defmodule GoogleService.EventFetcher do
  use Task

  require Logger

  def start_link(_args) do
    Logger.debug("EventFetcher started")
    check_for_new_events()
    Task.start_link(&fetch/0)
  end

  def fetch do
    receive do
    after
      30 * 1000 ->
        check_for_new_events()
        fetch()
    end
  end

  def check_for_new_events(atoms \\ ReservationServer.Store.calender_atoms()) do
    atoms
    |> to_tupel_list
    |> Enum.map(&ReservationServer.Store.compare_and_put_next_events/1)
    |> Enum.each(&notify/1)
  end

  defp notify({atom, nil}), do: Logger.debug("#{atom}: Nothing changed")

  defp notify({atom, events}) do
    Logger.debug("Notify room #{Atom.to_string(atom)}")

    Enum.each(events, fn event ->
      name = Map.get(event, "summary")
      from = get_in(event, ["start", "dateTime"])
      to = get_in(event, ["end", "dateTime"])
      Logger.debug("#{name} from #{from} til #{to}")
    end)

    count = Enum.count(events)

    msg =
      events
      |> Enum.reduce("", &msg_reducer/2)
      |> String.slice(0..-2)

    occupied =
      events
      |> List.first()
      |> event_started()

    Tortoise.publish(
      :server,
      "#{Atom.to_string(atom)}/reservationUpdate",
      "#{count};#{occupied};#{msg}",
      qos: 0
    )
  end

  defp to_tupel_list(atoms) do
    Enum.reduce(atoms, [], fn atom, acc ->
      events =
        next_events(atom)
        |> Enum.take(2)

      [{atom, events} | acc]
    end)
  end

  defp next_events(atom) do
    {:ok, events} =
      GoogleService.Calender.events(
        ReservationServer.Store.access_token(),
        ReservationServer.Store.calender_id(atom),
        Timex.now("Europe/Berlin"),
        Timex.now("Europe/Berlin") |> Timex.shift(hours: 12)
      )

    events
  end

  def msg_reducer(event, acc) do
    name = Map.get(event, "summary")

    from =
      get_in(event, ["start", "dateTime"])
      |> Timex.parse!("{RFC3339}")
      |> Timex.format!("%H:%M", :strftime)

    to =
      get_in(event, ["end", "dateTime"])
      |> Timex.parse!("{RFC3339}")
      |> Timex.format!("%H:%M", :strftime)

    acc <> "#{name};#{from};#{to};"
  end

  defp event_started(nil), do: false

  defp event_started(event) do
    start =
      get_in(event, ["start", "dateTime"])
      |> Timex.parse!("{RFC3339}")

    now = Timex.now("Europe/Berlin")

    Timex.diff(start, now) < 0
  end
end
