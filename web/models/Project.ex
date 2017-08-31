defmodule Project do

  def minuteGranularity(date) do
    Timex.parse!(date)
    |> 
  end

  def getTimeseries(name) do
    Fuseki.queryDB("
      SELECT ?name (SUM(?val) as ?value) ?date
      WHERE {
        ?project rdf:type :project .
        ?project rdf:name \"" <> name <> "\" .
        ?project ?type ?source .
        ?source :metric ?metric .
        ?metric rdf:name ?name .
        ?metric :data  ?data .
        ?data xsd:integer ?val .
        ?data xsd:dateTime ?date .
        FILTER (?type IN (:cb, :git, :trello))
      } GROUP BY ?name ?metricName ?date
        ORDER BY ?date
    ")
    |> Fuseki.parseJSON
    |> Enum.reduce(%{}, fn(row, series) ->
        updateMetric = Map.get(series, row["name"], %{})
        |> Map.put(row["date"], String.to_integer(row["value"]))
        Map.put(series, row["name"], updateMetric)
      end)
  end

  def getTransform(name) do
    Fuseki.queryDB("
      SELECT ?transform
      WHERE {
        ?project rdf:type :project .
        ?project rdf:name \"" <> name <> "\" .
        ?project :transform ?transform .
      }")
      |> Fuseki.parseJSON
      |> List.first
      |> Map.get("transform")
      |> Base.decode64!
      |> Poison.decode!
  end

  def hide(timeseries, transform) do
    Enum.reduce(Map.keys(timeseries), %{}, fn(key, all) ->
      case Enum.member?(transform, key) do
        true -> all
        false -> Map.put(all, key, timeseries[key])
      end
    end)
  end

  def newmapmerge(a, b, fun) do
    Enum.reduce(Map.keys(a), b, fn(key, newb) ->
      Map.put(newb, key, fun.(Map.get(a, key, 0), Map.get(newb, key, 0)))
    end)
  end

  def similarDates(map) do
    Map.keys(map)
    |> Enum.reduce(%{}
  end

  # Timeseries, [Merge] -> Timeseries
  def merge(timeseries, transform) do
    needed= Enum.map(transform["fields"], fn(x) -> timeseries[x] end)
            |> Enum.reduce(%{}, &newmapmerge(&1, &2, fn(a,b) -> a + b end))
    %{transform["name"] => needed}
  end

  def multimerge(timeseries, merges) do
    Enum.map(merges, fn(transform) -> merge(timeseries, transform) end)
  end

  def transformTimeseries(timeseries, transform) do
    timeseries
    |> multimerge Map.get(transform, "merge", [])
    #|> hide Map.get(transform, "hide", [])
  end

end
