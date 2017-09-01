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
    series = Project.getTimeseries(name)
    Enum.map(Map.keys(series), fn(metricName) ->
      {metricName , Enum.take(series[metricName], -2)}
    end)
    |> Enum.reduce(%{}, fn({k, v}, all) ->
      {date, first} = Enum.at(v, 0)
      {date, second} = Enum.at(v, 1)
      sum = second - first
      Map.put(all, k, sum)
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
