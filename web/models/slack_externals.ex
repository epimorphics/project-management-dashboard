defmodule Slack.Externals do
  def getHooks do
   Fuseki.queryDB("SELECT ?name ?webhook WHERE { ?project rdf:type :project . ?project rdf:name ?name . ?project :webhook ?webhook .}")
   |> Fuseki.parseJSON
  end

  def sendToHook(message, hook) do
    HTTPoison.start
    HTTPoison.post(hook, Poison.encode!(message), [{"Content-Type", "application/json"}])
  end

  def getTimeseries(name) do
    Project.getTimeseries(name)
  end
end


defmodule Slack.Test do
  def getHooks do
    [%{"name" => "Max Projects",
         "webhook" => "https://hooks.slack.com/services/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"},
      %{"name" => "New Project",
           "webhook" => "https://hooks.slack.com/services/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"}]
  end

  def sendToHook(message, hook) do
    {message, hook}
  end

  def getTimeseries(name) do
    case name do
      "up" -> %{"To Do" => %{"2017-8-29T09:24:00+00:00" => 2,
        "2017-8-31T07:27:00+00:00" => 8,
        "2017-8-31T07:30:00+00:00" => 8,
        "2017-9-1T09:23:00+00:00" => 9}}
      "down" -> %{"Bugs" => %{"2017-8-29T09:24:00+00:00" => 3,
        "2017-8-31T07:29:00+00:00" => 3,
        "2017-8-31T07:30:00+00:00" => 2,
        "2017-9-1T09:23:00+00:00" => 1}}
      "nil" -> %{"Bugs" => %{"2017-8-29T09:24:00+00:00" => 0,
        "2017-8-31T07:30:00+00:00" => 0,
        "2017-9-1T09:23:00+00:00" => 0}}
    end
  end
end
