defmodule GoogleService.Calender do
  def calenders(token) do
    url = "https://www.googleapis.com/calendar/v3/users/me/calendarList"

    headers = [
      authorization: "Bearer " <> token,
      accept: "application/json"
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, Poison.decode!(body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def calender(token, id) do
    url = "https://www.googleapis.com/calendar/v3/calendars/#{id}"

    headers = [
      authorization: "Bearer " <> token,
      accept: "application/json"
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, Poison.decode!(body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def events(token, id, from, to) do
    url = "https://www.googleapis.com/calendar/v3/calendars/#{id}/events?"

    parameters =
      URI.encode_query(
        timeMin: from |> DateTime.to_iso8601(),
        timeMax: to |> DateTime.to_iso8601(),
        orderBy: "startTime",
        singleEvents: true
      )

    headers = [
      authorization: "Bearer " <> token,
      accept: "application/json"
    ]

    case HTTPoison.get(url <> parameters, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        decoded_body = Poison.decode!(body)
        {:ok, Map.get(decoded_body, "items")}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def insert_block(token, id, duration) do
    from = Timex.now("Europe/Berlin")
    to = Timex.now("Europe/Berlin") |> Timex.shift(minutes: duration)

    case timeslot_blocked(token, id, from, to) do
      {:ok, _} ->
        IO.puts("lol")
        reserve_timeslot(token, id, from, to)

      blocked ->
        IO.inspect(blocked)
        blocked
    end
  end

  defp timeslot_blocked(token, id, from, to) do
    {:ok, items} = events(token, id, from, to)

    if Enum.count(items) > 0 do
      next_event_start =
        items
        |> Enum.at(0)
        |> Map.get("start")
        |> Map.get("dateTime")
        |> Timex.parse!("{ISO:Extended}")

      {:blocked, Timex.diff(from, next_event_start, :minutes)}
    else
      {:ok, 0}
    end
  end

  defp reserve_timeslot(token, id, from, to) do
    url = "https://www.googleapis.com/calendar/v3/calendars/#{id}/events"

    headers = [
      {"authorization", "Bearer " <> token},
      {"accept", "application/json"},
      {"Content-type", "application/json"}
    ]

    body =
      Poison.encode!(%{
        start: %{
          dateTime: from,
          timeZone: "Europe/Berlin"
        },
        end: %{
          dateTime: to,
          timeZone: "Europe/Berlin"
        },
        description: "In place block",
        summary: "Block"
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, Poison.decode!(body)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
