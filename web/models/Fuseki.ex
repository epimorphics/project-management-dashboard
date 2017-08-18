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
    updateDB("INSERT DATA { " <>
      ":" <> project.name <> " rdf:type :" <> Atom.to_string(project.source) <> " ;" <>
                             " rdf:name \"" <> project.displayName <> "\"; " <>
                             " rdf:resource <http://localhost:4000/json/" <> Atom.to_string(project.source) <> "/" <> project.name <> "> ; " <>
    "}")
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


  def prefixes do
    "prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
     prefix owl: <http://www.w3.org/2002/07/owl#>
     prefix : <http://example/>
     prefix doap: <http://usefulinc.com/ns/doap#>
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
    cb = queryDB("SELECT ?item ?url ?transform WHERE { ?project rdf:type doap:project. ?project rdf:name ?name. ?project :cb/rdf:rest*/rdf:first ?item. ?item :transform/rdf:resource ?transform. ?item rdf:resource ?url. }")
    |> parseJSON
    Enum.map(projects, fn(project) ->
      list = Enum.filter(cb, fn(result) -> Map.get(result, "name") == project["name"] end)
      |> Enum.map(fn(x) -> %{:transform => Poison.decode!(x["transform"]), :url => x["url"]} end)
      Map.put(project, :cb, list) end)
  end

  def getGit(projects) do
    git = queryDB("SELECT ?item ?url ?transform WHERE { ?project rdf:type doap:project. ?project rdf:name ?name. ?project :git/rdf:rest*/rdf:first ?item. ?item :transform/rdf:resource ?transform. ?item rdf:resource ?url. }")
    |> parseJSON
    Enum.map(projects, fn(project) ->
      list = Enum.filter(git, fn(result) -> Map.get(result, "name") == project["name"] end)
      |> Enum.map(fn(x) -> %{:transform => Poison.decode!(x["transform"]), :url => x["url"]} end)
      Map.put(project, :git, list) end)
  end

  def getTrello(projects) do
    trello = queryDB("SELECT ?item ?url ?transform WHERE { ?project rdf:type doap:project. ?project rdf:name ?name. ?project :trello/rdf:rest*/rdf:first ?item. ?item :transform/rdf:resource ?transform. ?item rdf:resource ?url. }")
    |> parseJSON
    Enum.map(projects, fn(project) ->
      list = Enum.filter(trello, fn(result) -> Map.get(result, "name") == project["name"] end)
      |> Enum.map(fn(x) -> %{:transform => Poison.decode!(x["transform"]), :url => x["url"]} end)
      Map.put(project, :trello, list) end)
  end
end
