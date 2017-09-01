defmodule Slack do

  def sendToHook(name, hook) do
    HTTPoison.start
    {len, message} = testMessage(name)
	if (len > 0) do
		{:ok, status} = HTTPoison.post(hook, Poison.encode!(message), [{"Content-Type", "application/json"}])
	end
  end

  def testMessage(project) do
   attachments = Enum.filter(difference(project), fn(x) -> x != nil end)
   { length(attachments),  %{"text" => "Update for " <> project, "attachments" => attachments}}
  end

  def getHooks do
   Fuseki.queryDB("SELECT ?name ?webhook WHERE { ?project rdf:type :project . ?project rdf:name ?name . ?project :webhook ?webhook .}")
   |> Fuseki.parseJSON
   |> Enum.map(fn(project) -> sendToHook(project["name"], project["webhook"]) end)
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
