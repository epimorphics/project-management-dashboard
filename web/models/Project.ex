defmodule Project do

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
        FILTER (?type IN (:repo, :trello))
      } GROUP BY ?name ?metricName ?date
        ORDER BY ?date
    ")
    |> Fuseki.parseJSON
    |> Enum.reduce(%{}, fn(row, series) ->
        updateMetric = Map.get(series, row["name"], %{})
        |> Map.put(row["date"], String.to_integer(row["value"]))
        Map.put(series, row["name"], updateMetric)
      end)
    |> congregateDates
  end

  def getTransformedSeries(name) do
    transform = getTransform(name)
    timeseries = getTimeseries(name)
    transformTimeseries(timeseries, transform)
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
      case Enum.member?(transform["hide"], key) do
        true -> all
        false -> Map.put(all, key, timeseries[key])
      end
    end)
  end

  def show(timeseries, transform) do
    case Map.get(transform, "show", []) do
     [] -> timeseries
     _ ->  Enum.reduce(Map.keys(timeseries), %{}, fn(key, all) ->
      case Enum.member?(Map.get(transform, "show", []), key) do
        false -> all
        true -> Map.put(all, key, timeseries[key])
      end
    end)
	end
  end

  def newmapmerge(a, b, fun) do
    Enum.reduce(Map.keys(a), b, fn(key, newb) ->
      newkey = Timex.parse!(key, "{ISO:Extended}")
      |> Timex.format!("{YYYY}-{M}-{D}T{h24}:{m}:00+00:00")
      Map.put(newb, newkey, fun.(Map.get(a, key, 0), Map.get(newb, newkey, 0)))
    end)
  end

  def congregateDates(timeseries) do
    Enum.reduce(Map.keys(timeseries), %{}, fn(key, all) -> Map.put(all, key, newmapmerge(timeseries[key], %{}, fn(a, b) -> a end)) end)
  end

  # Timeseries, [Merge] -> Timeseries
  def merge(timeseries, transform) do
    needed= Enum.map(transform["fields"], fn(x) -> timeseries[x] end)
            |> Enum.reduce(%{}, &newmapmerge(&1, &2, fn(a,b) -> a + b end))
  end

  def multimerge(timeseries, transform) do
    transforms = Enum.map(Map.get(transform, "merge", []), fn(merges) -> {merges["name"], merge(timeseries, merges)} end)
    Enum.reduce(transforms, timeseries, fn({metricName, map}, out) -> Map.put(out, metricName, map) end)
  end

  def transformTimeseries(timeseries, transform) do
    timeseries
    |> multimerge(transform)
    |> hide(transform)
    |> show(transform)
  end

end
