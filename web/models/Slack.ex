defmodule Slack do
  @webhook "https://hooks.slack.com/services/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"

  def sendToHook(name) do
    HTTPoison.start
    {:ok, status} = HTTPoison.post(@webhook, Poison.encode!(testMessage(name)), [{"Content-Type", "application/json"}])
  end

  def testMessage(project) do
    %{ "text" => "",
      "attachments" => Enum.filter(difference(project), fn(x) -> x != nil end)}
  end

  def send(message) do
    {:ok, status} = HTTPoison.post(@webhook, message, [{"Content-Type", "application/json"}])
  end

  def upOrDown(val) do
    case val < 0 do
      true -> "down"
      false -> "up"
    end
  end

  def difference(name) do
    series = Fuseki.getTimeseries(name)
    Enum.map(Map.keys(series), fn(key) ->
      map = Enum.reduce(series[key], %{}, fn(x, all) ->
        key = List.first Map.keys(x)
        Map.put(all, key, x[key])
      end)
      diff = Map.values(map)
      |> Enum.take(-2)
      |> Enum.map(fn(x) -> String.to_integer(x) end)
      |> Enum.reduce(fn(x, all) -> x - all end)
      {key, diff}
    end)
    |> Enum.map(fn({k, v}) ->
      case v do
        0 -> nil
        _ -> %{"title" => k <> " is " <> upOrDown(v) <> " by " <> to_string(v),
        "color" => "good"}
      end
      end)
  end
end
