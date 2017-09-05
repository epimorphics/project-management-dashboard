defmodule Slack.API do
  @fuseki_api Application.get_env(:hello_phoenix, :fuseki_api)

  def getHooks do
   @fuseki_api.queryDB("SELECT ?name ?webhook WHERE { ?project rdf:type :project . ?project rdf:name ?name . ?project :webhook ?webhook .}")
  end

  def sendToHook(message, hook) do
    HTTPoison.start
    HTTPoison.post(hook, Poison.encode!(message), [{"Content-Type", "application/json"}])
  end

  def getTimeseries(name) do
    Project.getTimeseries(name)
  end
end


defmodule Slack do
  @slack_api Application.get_env(:hello_phoenix, :slack_api)

  def sendToAPI(name, hook) do
    {len, message} = projectMessage(name)
  if (len > 0) do
    @slack_api.sendToHook(message, hook)
  end
  end

  def update do
   @slack_api.getHooks
   |> Enum.map(fn(project) -> sendToAPI(project["name"], project["webhook"]) end)
  end

  def projectMessage(project) do
   attachments = Enum.filter(difference(project), fn(x) -> x != nil end)
   { length(attachments),  %{"text" => "Update for " <> project, "attachments" => attachments}}
  end

  def upOrDown(val) do
    case val < 0 do
      true -> "down"
      false -> "up"
    end
  end

  def difference(name) do
    series = @slack_api.getTimeseries(name)
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
