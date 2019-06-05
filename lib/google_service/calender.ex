defmodule GoogleService.Calender do
  # --- Google API ---
  # Get all calenders from user
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

  # Get calender data for one specific calender
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

  # Get all events for a specific period
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

  def create_event(token, id, from, to, name) do
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
        summary: name
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, Poison.decode!(body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Delete an event in a calender
  def delete_event(token, calender_id, event_id) do
    url = "https://www.googleapis.com/calendar/v3/calendars/#{calender_id}/events/#{event_id}"

    headers = [
      authorization: "Bearer " <> token,
      accept: "application/json"
    ]

    case HTTPoison.delete(url, headers) do
      {:ok, _} ->
        {:ok}

      error ->
        error
    end
  end

  # --- Helper Methods ---

  # Create block event at current time with a duration
  def insert_block(token, id, duration) do
    from = Timex.now("Europe/Berlin")
    to = Timex.now("Europe/Berlin") |> Timex.shift(minutes: duration)

    case timeslot_blocked(token, id, from, to) do
      {:ok, _} ->
        create_event(token, id, from, to, "Block")

      blocked ->
        blocked
    end
  end

  # Search for a block event in current period and delete it
  def delete_current_block(token, id) do
    from = Timex.now("Europe/Berlin")
    to = from |> Timex.shift(minutes: 1)
    {:ok, events} = events(token, id, from, to)

    case current_block(events) do
      {:ok, event_id} ->
        delete_event(token, id, event_id)

      error ->
        error
    end
  end

  # --- Private Methods ---

  # Check if events exists in given time period
  defp timeslot_blocked(token, id, from, to) do
    {:ok, items} = events(token, id, from, to)

    if Enum.count(items) > 0 do
      next_event_start =
        items
        |> Enum.at(0)
        |> Map.get("start")
        |> Map.get("dateTime")
        |> Timex.parse!("{ISO:Extended}")

      # {:blocked, Timex.diff(next_event_start, from, :minutes)}
      {:blocked, Timex.format!(next_event_start, "%H:%M", :strftime)}
    else
      {:ok, 0}
    end
  end

  defp current_block([event]) do
    case String.equivalent?(Map.get(event, "summary"), "Block") do
      true ->
        {:ok, Map.get(event, "id")}

      false ->
        {:error, "No block found"}
    end
  end

  defp current_block(_), do: {:error}
end
