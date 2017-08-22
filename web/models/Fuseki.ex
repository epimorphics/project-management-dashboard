defmodule Fuseki do

  def queryDB(sparqlquery) do
    HTTPoison.start
    HTTPoison.get!("http://localhost:3030/ds/query", [], params: [{"query", prefixes() <> sparqlquery}, {"output", "json"}]).body
    |> Poison.decode!
  end

  def updateDB(sparqlquery) do
    HTTPoison.start
    {:ok, status} = HTTPoison.post("http://localhost:3030/ds/update", Poison.encode!(%{}), [{"Content-Type", "application/x-www-form-urlencoded"}], params: [{"update", prefixes() <> sparqlquery}])
	{:ok, status.status_code}
	
  end

  def putStandardForm(project) do
     [ updateDB("INSERT DATA { " <>
      "_:project" <> " rdf:type :" <> Atom.to_string(project.source) <> " ;" <>
      " rdf:name \"" <> project.name <> "\" ; " <>
      " :displayName \"" <> project.displayName <> "\"; " <>
      " rdf:Description \"" <> to_string(project.description) <> "\"; " <>
      Enum.reduce(project.metrics, "", fn({k, v}, all) ->
        all <> " :metric [" <>
          " rdf:name \"" <> to_string(k) <>  "\" ;" <>
          " :data [ " <>
            "xsd:integer " <> to_string(v) <> " ; " <>
            "xsd:dateTime \"" <> Timex.format!(Timex.now, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}+00:00") <> "\" " <>
        " ] ] ;" end) <>
      " rdf:resource <http://localhost:4000/json/" <> Atom.to_string(project.source) <> "/" <> project.name <> "> ; " <>
    "}") ]
    |> Kernel.++ Enum.map(project.avatars, fn(x) ->
      updateDB("INSERT {
        ?person :worksOn ?project ;
      } WHERE {
        ?person :login \"" <> x <> "\" .
        ?project rdf:name \"" <> project.name <> "\" .
      }") end)
  end

  def putUsers() do
    Source.get(:users)
    |> Enum.filter(fn(x) -> 
      x.company == "Epimorphics Limited" end)
    |> Enum.map(fn(user) -> updateDB("INSERT DATA { " <>
      "_:tempUser rdf:type foaf:person ; " <>
        Enum.reduce(user, "", fn({k, v}, all) ->
          all <> " :" <> to_string(k) <> " \"" <> v <> "\" ; " end) <>
    "} ") end)
  end

  def parseJSON(json) do
    Enum.map(json["results"]["bindings"], fn(x) ->
      Enum.map(json["head"]["vars"], fn(y) ->
        %{y => Map.get(x, y)["value"]}
      end)
      |> Enum.reduce(%{}, fn(all, y) -> 
        Map.merge(all, y)
      end)
    end)
  end

  def putTrello(json) do
    updateDB("INSERT DATA { " <>
      "_:trello rdf:type :trello ; " <>
                       " rdf:resource <http://localhost:4000/json/" <> to_string(json.source) <> "/" <> json.shortLink <> "> ; " <>
      ":shortlink \"" <> json.shortLink <> "\" ; " <>
      Enum.reduce(json.metrics, "", fn({k, v}, all) ->
        all <> " :metric [" <>
          " rdf:name \"" <> k <>  "\" ;" <>
          " :data [ " <>
            "xsd:integer " <> to_string(v) <> " ; " <>
            "xsd:dateTime \"" <> Timex.format!(Timex.now, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}+00:00") <> "\" " <>
        " ] ] ;" end) <>
       "rdf:name \"" <> json.name <> "\" " <>
      " }")
  end

  def prefixes do
    "prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
     prefix owl: <http://www.w3.org/2002/07/owl#>
     prefix : <http://example/>
     prefix doap: <http://usefulinc.com/ns/doap#>
     prefix foaf: <http://xmlns.com/foaf/0.1/>
     prefix xsd: <http://www.w3.org/2001/XMLSchema#>
     "
  end

  def getProjects do
    queryDB("SELECT ?name WHERE { ?project rdf:type doap:project. ?project rdf:name ?name. }")
    |> parseJSON
    |> Enum.reduce([], fn(y, all) -> all ++ [y["name"]] end)
                   |> Enum.uniq
    |> Enum.reduce([], fn(x, all) -> all ++  [%{:name => x, :cb => [], :git => [], :trello => []}] end)
    |> getCB
    |> getGit
    |> getTrello
  end

  def getCB(projects) do
    cb = queryDB(
      "SELECT ?projectName ?name ?url ?displayName
       WHERE {
       ?project rdf:type doap:project .
       ?project rdf:name ?projectName .
       ?project :cb/rdf:rest*/rdf:first ?name .
       ?a rdf:name ?name .
       ?a rdf:resource ?url .
       ?a :displayName ?displayName . }")
    |> parseJSON
     Enum.map(projects, fn(project) ->
      list = Enum.filter(cb, fn(result) -> Map.get(result, "projectName") == project.name end)
             |> Enum.map(fn(x) -> %{:transform => %{}, :url => x["url"]} end)
      Map.put(project, :cb, list) end)
  end

  def getGit(projects) do
    git = queryDB(
      "SELECT ?projectName ?name ?url ?displayName
       WHERE {
       ?project rdf:type doap:project .
       ?project rdf:name ?projectName .
       ?project :git/rdf:rest*/rdf:first ?name .
       ?a rdf:name ?name .
       ?a rdf:resource ?url .
       ?a :displayName ?displayName . }")
    |> parseJSON
     Enum.map(projects, fn(project) ->
      list = Enum.filter(git, fn(result) -> Map.get(result, "projectName") == project.name end)
      |> Enum.map(fn(x) -> %{:transform => %{}, :url => x["url"]} end)
      Map.put(project, :git, list) end)
  end

  def getTrello(projects) do
    trello = queryDB(
      "SELECT ?projectName ?name ?displayName ?url
      WHERE {
           ?project rdf:type doap:project .
           ?project rdf:name ?projectName .
           ?project :trello/rdf:rest*/rdf:first ?displayName .
           ?itemid rdf:name ?displayName .
           ?itemid :shortlink ?name .
           ?itemid rdf:resource ?url .
      }"
    )
    |> parseJSON
    Enum.map(projects, fn(project) ->
    
    list = Enum.filter(trello, fn(result) -> Map.get(result, "projectName") == project.name end)
      |> Enum.map(fn(x) -> %{:transform => %{}, :url => x["url"]} end)
      Map.put(project, :trello, list) end)
  end

  def getTrelloJSON(shortlink) do
    out = %{:source => :trello, :shortlink => shortlink}
    metrics = queryDB("
      SELECT ?metricName ?value
      WHERE {
        ?a :shortlink \"" <> shortlink <> "\" .
        ?a rdf:name ?name .
        ?a :metric ?metric .
        ?metric rdf:name ?metricName .
        ?metric :data ?x .
        ?x xsd:integer ?value
      }")
      |> parseJSON
      |> Enum.reduce(%{}, fn(x, all) -> Map.put(all, x["metricName"], x["value"]) end)
    details = queryDB("
      SELECT ?name ?url
      WHERE {
        ?a :shortlink \"" <> shortlink <> "\" .
        ?a rdf:name ?name .
        ?a rdf:resource ?url .
      }
      ")
    |> parseJSON
    |> List.first

    Map.put(out, :metrics, metrics)
    |> Map.put(:stats, metrics)
    |> Map.merge(details)
  end

  def getTrelloJSON do
    metrics = queryDB("
      SELECT ?shortlink ?metricName ?value
      WHERE {
        ?a :shortlink ?shortlink .
        ?a rdf:name ?name .
        ?a :metric ?metric .
        ?metric rdf:name ?metricName .
        ?metric :data ?x .
        ?x xsd:integer ?value
      }")
    |> parseJSON
    |> Enum.reduce(%{}, fn(x, all) ->
      update = Map.get(all, x["shortlink"], %{})
      |> Map.put(x["metricName"], String.to_integer(x["value"]))

      Map.put(all, x["shortlink"], update)
    end)
    details = queryDB("
      SELECT ?shortlink ?name ?url
      WHERE {
        ?a :shortlink ?shortlink .
        ?a rdf:name ?name .
        ?a rdf:resource ?url .
      }
      ")
    |> parseJSON

    Enum.map(details, fn(x) ->
      Map.put(x, "metrics", metrics[x["shortlink"]])
      |> Map.put("stats", metrics[x["shortlink"]])
      |> Map.put("source", "trello")
    end)
  end

  def getProjectJSON do
    avatars = queryDB("
      select ?name ?avatar
      where {
        ?project rdf:name ?name .
        ?person :worksOn ?project .
        ?person :first_name ?first .
        ?person :last_name ?last .
        ?person :avatar_url ?avatar .
        ?person :login ?login
      }
    ")
    |> parseJSON
    |> Enum.reduce(%{}, fn(x, all) ->
      avatars = Map.get(all, x["name"], [])
      |> Kernel.++ [ x["avatar"] ]

      Map.put(all, x["name"], avatars) end)
    details = queryDB("
      select ?name ?displayName ?description ?source ?test
      where {
        ?x rdf:name ?name .
        ?x :displayName ?displayName .
        ?x rdf:type ?type .
        ?type rdf:label ?source .
        OPTIONAL {
          ?x rdf:Description ?description .
          ?x :lastTest ?testId .
          ?testId xsd:boolean ?test .
        }
      }
    ")
    |> parseJSON
    metrics = queryDB("
      select ?projectName ?metricName ?value
      where {
        ?x rdf:name ?projectName .
        ?x rdf:type ?type .
        ?x :metric ?y.
        ?y rdf:name ?metricName.
        ?y :data ?data.
        ?data xsd:integer ?value .
        FILTER(?type IN (:cb, :git))
      }
    ")
    |> parseJSON
    |> Enum.reduce(%{}, fn(x, all) ->
      update = Map.get(all, x["projectName"], %{})
      |> Map.put(x["metricName"], String.to_integer(x["value"]))

      Map.put(all, x["projectName"], update)
    end)
    Enum.map(details, fn(x) ->
      x
      |> Map.put("metrics", metrics[x["name"]])
      |> Map.put("avatars", avatars[x["name"]])
    end)
  end

  def getProjectJSON(name) do
    avatars = queryDB("
      select ?name ?avatar
      where {
        ?project rdf:name \"" <> name  <> "\" .
        ?project rdf:name ?name .
        ?person :worksOn ?project .
        ?person :first_name ?first .
        ?person :last_name ?last .
        ?person :avatar_url ?avatar .
        ?person :login ?login
      }
    ")
    |> parseJSON
    |> Enum.reduce(%{}, fn(x, all) ->
      avatars = Map.get(all, x["name"], [])
      |> Kernel.++ [ x["avatar"] ]

      Map.put(all, x["name"], avatars) end)
    details = queryDB("
      select ?name ?displayName ?description ?source ?test
      where {
        ?x rdf:name \"" <> name  <> "\" .
        ?x rdf:name ?name .
        ?x :displayName ?displayName .
        ?x rdf:type ?type .
        ?type rdf:label ?source .
        OPTIONAL {
          ?x rdf:Description ?description .
          ?x :lastTest ?testId .
          ?testId xsd:boolean ?test .
        }
      }
    ")
    |> parseJSON
    metrics = queryDB("
      select ?projectName ?metricName ?value
      where {
        ?x rdf:name \"" <> name  <> "\" .
        ?x rdf:name ?projectName .
        ?x rdf:type ?type .
        ?x :metric ?y.
        ?y rdf:name ?metricName.
        ?y :data ?data.
        ?data xsd:integer ?value .
        FILTER(?type IN (:cb, :git))
      }
    ")
    |> parseJSON
    |> Enum.reduce(%{}, fn(x, all) ->
      update = Map.get(all, x["projectName"], %{})
      |> Map.put(x["metricName"], String.to_integer(x["value"]))

      Map.put(all, x["projectName"], update)
    end)
    Enum.map(details, fn(x) ->
      x
      |> Map.put("metrics", metrics[x["name"]])
      |> Map.put("avatars", avatars[x["name"]])
    end)
    |> List.first
  end

  def putTests do
    Source.get(:jenkins)
    |> Enum.map(fn(x) ->
      updateDB("
        DELETE { ?project :lastTest ?a }
        WHERE {
          ?project rdf:name \"" <> x.name <> "\" .
          ?project :lastTest ?a
        };

        INSERT {
          _:newTest xsd:boolean " <> to_string(x.success) <> " .
          _:newTest xsd:dateTime \"" <> Timex.format!(Timex.now, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}+00:00") <> "\" .
          ?project :test _:newTest .
          ?project :lastTest _:newTest .
        }
        WHERE {
          ?project rdf:name \"" <> x.name <> "\" .
        }
       ") end)
  end
end


