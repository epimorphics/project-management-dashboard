defmodule Fuseki.API do
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

  def queryDB(sparqlquery) do
    fuseki_loc = Application.get_env(:hello_phoenix, :fuseki_loc)
    HTTPoison.start
    HTTPoison.get!(fuseki_loc <> "ds/query", [], params: [{"query", prefixes() <> sparqlquery}, {"output", "json"}]).body
    |> Poison.decode!
    |> parseJSON
  end

  def updateDB(sparqlquery) do
    fuseki_loc = Application.get_env(:hello_phoenix, :fuseki_loc)
    HTTPoison.start
    {:ok, status} = HTTPoison.post(fuseki_loc <> "ds/update", Poison.encode!(%{}), [{"Content-Type", "application/x-www-form-urlencoded"}], params: [{"update", prefixes() <> sparqlquery}])
    [status.status_code]
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
end

defmodule Fuseki do
  @fuseki_api Application.get_env(:hello_phoenix, :fuseki_api)

  def putStandardForm(project) do
    out = putRepoData(project)
    |> Kernel.++(putAvatars(project))
    |> Kernel.++(putMetrics(project))
    |> Kernel.++(putMetricData(project))
    Enum.uniq(out)
  end

  def getRepoNames do
     @fuseki_api.queryDB(
      "SELECT ?name " <>
      "WHERE { " <>
        "?project rdf:type ?type . " <>
        "?project rdf:name ?name " <>
        "FILTER(?type IN (:cb, :git, :trello)) " <>
      "}")
      |> Enum.map(fn(x) -> x["name"] end)
  end

  def putRepoData(project) do
    current = getRepoNames()
    case !Enum.member?(current, project.name) do
      true -> @fuseki_api.updateDB("INSERT DATA { " <>
      "_:project" <> " rdf:type :" <> Atom.to_string(project.source) <> " ; " <>
      "rdf:name \"" <> project.name <> "\" ; " <>
      ":displayName \"" <> project.displayName <> "\" ; " <>
      "rdf:Description \"" <> to_string(project.description) <> "\" ; " <>
        "}")
      false -> []
    end
  end

  def getWebhook(project) do
    @fuseki_api.queryDB(
    "SELECT ?webhook " <>
    "WHERE { " <>
      "?project rdf:type :project . " <>
      "?project rdf:name \"" <> project.name <> "\" . " <>
      "?project :webhook ?webhook . " <>
    "}")
    |> Enum.map(fn(x) -> x["webhook"] end)
  end

  def getMetrics(project) do
    @fuseki_api.queryDB(
    "SELECT ?name " <>
    "WHERE { " <>
    "?project rdf:name \"" <> project.name <> "\" . " <>
    "?project :metric ?metric . " <>
    "?metric rdf:name ?name . " <>
    "}")
    |> Enum.map(&Map.get(&1, "name"))
  end

  def putMetrics(project) do
    current = getMetrics(project)
    toAdd = Enum.filter(project.metrics, fn({k,_}) ->
      !Enum.member?(current, to_string(k))
    end)
    case length(toAdd) > 0 do
      true -> @fuseki_api.updateDB(Enum.reduce(toAdd, "", fn({k, _}, all) ->
        #remove special characters fuseki wont handle
        stripped = Regex.replace(~r/[^a-zA-Z0-9]/, to_string(k), "", global: true)
        all <> "INSERT { " <>
               "_:" <> stripped <> " rdf:type :metric ; " <>
               "rdf:name \"" <> to_string(k) <>  "\" . " <>
               "?project :metric _:" <> stripped <> " . " <>
               "} WHERE { ?project rdf:name \"" <> project.name <> "\" }; " end))
      false -> []
    end
  end

  def getAvatars(project) do
    @fuseki_api.queryDB(
      "SELECT ?login " <>
      "WHERE { " <>
      "?project rdf:name \"" <> project.name <> "\" . " <>
      "?a :worksOn ?project . " <>
      "?a :login ?login . " <>
      "}")
        |> Enum.map(&Map.get(&1, "login"))
  end

  def putAvatars(project) do
    current = getAvatars(project)
    toAdd = Enum.filter(Map.get(project, :avatars, []), fn(avatar) ->
      !Enum.member?(current, avatar)
    end)
    case length(toAdd) > 0 do
      true -> @fuseki_api.updateDB(Enum.reduce(toAdd, "", fn(x, all) ->
      all <> "INSERT { " <>
      "?person :worksOn ?project ; " <>
      "} WHERE { " <>
      "?person :login \"" <> x <> "\" . " <>
      "?project rdf:name \"" <> project.name <> "\" . " <>
      "}; " end))
      false -> []
    end
  end

  def putMetricData(project) do
    @fuseki_api.updateDB(Enum.reduce(project.metrics, "", fn({k, v}, all) ->
      #remove special characters fuseki wont handle
      stripped = Regex.replace(~r/[^a-zA-Z0-9]/, to_string(k), "", global: true)
      all <>
      "DELETE { " <>
        "?metric :lastData ?z " <>
      "} " <>
      "WHERE { " <>
       "?project rdf:name \"" <> project.name <> "\" . " <>
       "?project :metric ?metric . " <>
       "?metric rdf:name \"" <> to_string(k) <> "\" . " <>
       "?metric :lastData ?z } ; " <>
     "INSERT { " <>
     "_:" <> stripped <> " rdf:type :data ; " <>
        "xsd:integer " <> to_string(v) <> " ; " <>
        "xsd:dateTime \"" <> Timex.format!(Timex.now, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}+00:00") <> "\" . " <>
     "?metric :data _:" <> stripped <> " . " <>
     "?metric :lastData _:" <> stripped <>
     " } " <>
     "WHERE { " <>
     "?project rdf:name \"" <> project.name <> "\" . " <>
     "?project :metric ?metric . " <>
     "?metric rdf:name \"" <> to_string(k) <> "\" " <>
     "}; " end))
  end

  def getUsers do
    @fuseki_api.queryDB(
    "SELECT DISTINCT ?login " <>
    "WHERE { " <>
    "?person rdf:type foaf:person . " <>
    "?person :login ?login . " <>
    "}")
    |> Enum.map(fn(user) -> user["login"] end)
  end

  def putUsers(users) do
    current = getUsers()
    users
    |> Enum.filter(fn(x) -> !Enum.member?(current, x.login) end)
    |> Enum.map(fn(user) -> @fuseki_api.updateDB("INSERT DATA { " <>
     "_:tempUser rdf:type foaf:person ; " <>
        Enum.reduce(user, "", fn({k, v}, all) ->
         all <> ":" <> to_string(k) <> " \"" <> v <> "\" ; " end) <>
     "} ") end)
    |> List.flatten
  end

  #transforms stored as base64 strings to avoid writing unwanted characters to db
  def getProject(name) do
    front_end = Application.get_env(:hello_phoenix, :front_end)
    @fuseki_api.queryDB("SELECT ?transform ?webhook WHERE { ?project rdf:type :project . ?project :transform ?transform . ?project rdf:name \"" <> name <> "\" . OPTIONAL { ?project :webhook ?webhook}}")
    |> Enum.reduce([], fn(x, all) -> all ++  [%{:name => name, :source => :epi, :transform => Base.decode64!(x["transform"]), :url => front_end <> "project?name=" <> name, :webhook => x["webhook"], :repos => [], :trello => []}] end)
    |> getRepos
    |> getTrello
    |> List.first
  end

  def getRepos(projects) do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    git = @fuseki_api.queryDB(
     "SELECT ?projectName ?reponame " <>
     "WHERE { " <>
     "?project rdf:type :project . " <>
     "?project rdf:name ?projectName . " <>
     "?project :repo ?repo . " <>
     "?repo rdf:name ?reponame . " <>
     "}")
     Enum.map(projects, fn(project) ->
      list = Enum.filter(git, fn(result) -> Map.get(result, "projectName") == project.name end)
      |> Enum.map(fn(x) -> %{:name => x["reponame"], :transform => %{}, :url => db_loc <>  "repo/" <> x["reponame"]} end)
      Map.put(project, :repos , list) end)
  end

  def getProjects do
    front_end = Application.get_env(:hello_phoenix, :front_end)
    @fuseki_api.queryDB("SELECT ?name ?transform WHERE { ?project rdf:type :project . ?project :transform ?transform . ?project rdf:name ?name . }")
    |> Enum.reduce([], fn(x, all) -> all ++  [%{:name => x["name"], :source => :epi, :transform => Base.decode64!(x["transform"]), :url => front_end <> "project?name=" <> URI.encode(x["name"]), :repos => [], :trello => []}] end)
    |> getRepos
    |> getTrello
  end

  def deleteProject(project) do
    @fuseki_api.updateDB("DELETE {?project ?a ?b} " <>
      "WHERE {?project rdf:type :project . " <>
      "?project rdf:name \"" <> project["name"] <> "\" . " <>
      "?project ?a ?b .}")
  end

  def putProject(project) do
    @fuseki_api.updateDB("DELETE { ?project ?a ?b } " <>
      "WHERE { ?project rdf:type :project . " <>
      "?project rdf:name \"" <> project["name"] <> "\" . " <>
      "?project ?a ?b . } ; " <>
    "INSERT { "<>
    "_:project rdf:type :project . " <>
    "_:project rdf:name \"" <> project["name"] <> "\" . " <>
    "_:project :transform \"" <> Base.encode64(project["transform"]) <> "\" . " <>
    "_:project :source :epi . " <>
    "} WHERE {} ; " <>
    Enum.reduce(project["repos"], "", fn(x, all) ->
    all <> "INSERT { " <>
    " ?project :repo ?repo ; " <>
    "} WHERE { " <>
    "?project rdf:type :project . " <>
    "?project rdf:name \"" <>  project["name"]  <> "\" . " <>
    "?repo rdf:name \"" <> x["name"] <> "\" . " <>
    "} ; "
    end) <>
    Enum.reduce(project["trello"], "", fn(x, all) ->
    all <> "INSERT { " <>
    "?project :trello ?repo ; " <>
    "} WHERE { " <>
    "?project rdf:type :project . " <>
    "?project rdf:name \"" <> project["name"] <> "\" . " <>
    "?repo rdf:name \"" <> x["name"] <> "\" . " <>
    "} ; " end) <>
    if Map.has_key?(project, "webhook") do
    "INSERT { " <>
    "?project :webhook <" <> project["webhook"] <> "> . " <>
    "} WHERE { ?project rdf:name \"" <> project["name"] <> "\" }; "
    else
    ""
    end)
  end

  def getTrello(projects) do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    trello = @fuseki_api.queryDB(
    "SELECT ?projectName ?trelloname " <>
    "WHERE { " <>
    "?project rdf:type :project . " <>
    "?project rdf:name ?projectName . " <>
    "?project :trello ?trello . " <>
    "?trello rdf:name ?trelloname . " <>
    "}")
    Enum.map(projects, fn(project) ->
    list = Enum.filter(trello, fn(result) -> Map.get(result, "projectName") == project.name end)
    |> Enum.map(fn(x) -> %{:name => x["trelloname"], :transform => %{}, :url => db_loc <> "trello/" <> x["trelloname"]} end)
    Map.put(project, :trello, list) end)
  end

  def getTrelloJSON do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    metrics = @fuseki_api.queryDB(
      "SELECT ?name ?metricName ?value " <>
      "WHERE { " <>
        "?trello rdf:name ?name . " <>
        "?trello :metric ?metric . " <>
        "?trello rdf:type :trello . " <>
        "?metric rdf:name ?metricName . " <>
        "?metric :lastData ?x . " <>
        "?x xsd:integer ?value " <>
      "}")
    |> Enum.reduce(%{}, fn(x, all) ->
      update = Map.get(all, x["name"], %{})
      |> Map.put(x["metricName"], String.to_integer(x["value"]))

      Map.put(all, x["name"], update)
    end)
    details = @fuseki_api.queryDB(
      "SELECT ?name ?displayName " <>
      "WHERE { " <>
        "?trello rdf:name ?name . " <>
        "?trello rdf:type :trello . " <>
        "?trello :displayName ?displayName . " <>
      "}")

    Enum.map(details, fn(x) ->
      Map.put(x, "metrics", metrics[x["name"]])
      |> Map.put("url", db_loc <> "trello/" <> x["name"])
      |> Map.put("stats", metrics[x["name"]])
      |> Map.put("source", "trello")
    end)
  end

  def getRepoJSON do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    avatars = @fuseki_api.queryDB(
      "select ?name ?avatar " <>
      "where { " <>
        "?project rdf:name ?name . " <>
        "?person :worksOn ?project . " <>
        "?person :avatar_url ?avatar . " <>
      "}")
    |> Enum.reduce(%{}, fn(x, all) ->
      avatars = Map.get(all, x["name"], [])
      |> Kernel.++([ x["avatar"] ])

      Map.put(all, x["name"], avatars) end)
    details = @fuseki_api.queryDB(
      "select ?name ?displayName ?description ?source ?test " <>
      "where { " <>
       "?x rdf:name ?name . " <>
       "?x :displayName ?displayName . " <>
       "?x rdf:type ?type . " <>
       "?type rdf:label ?source . " <>
       "OPTIONAL { " <>
         "?x rdf:Description ?description . " <>
         "?x :lastTest ?testId . " <>
         "?testId xsd:boolean ?test . " <>
       "} " <>
       "FILTER(?type IN (:cb, :git)) " <>
    "}")
    metrics = @fuseki_api.queryDB(
      "select ?projectName ?metricName ?value " <>
      "where { " <>
      "?x rdf:name ?projectName . " <>
      "?x rdf:type ?type . " <>
      "?x :metric ?y . " <>
      "?y rdf:name ?metricName . " <>
      "?y :data ?data . " <>
      "?data xsd:integer ?value . " <>
      "FILTER(?type IN (:cb, :git)) " <>
    "}")
    |> Enum.reduce(%{}, fn(x, all) ->
      update = Map.get(all, x["projectName"], %{})
      |> Map.put(x["metricName"], String.to_integer(x["value"]))

      Map.put(all, x["projectName"], update)
    end)
    Enum.map(details, fn(x) ->
      x
      |> Map.put("url", db_loc <> "repo/" <> x["name"])
      |> Map.put("metrics", metrics[x["name"]])
      |> Map.put("avatars", avatars[x["name"]])
    end)
  end

  def getRepoJSON(name) do
    avatars = @fuseki_api.queryDB(
      "select ?name ?avatar " <>
      "where { " <>
      "?project rdf:name \"" <> name  <> "\" . " <>
      "?project rdf:name ?name . " <>
      "?person :worksOn ?project . " <>
      "?person :avatar_url ?avatar . " <>
      "}")
    |> Enum.reduce(%{}, fn(x, all) ->
      avatars = Map.get(all, x["name"], [])
      |> Kernel.++([x["avatar"]])

      Map.put(all, x["name"], avatars) end)
    details = @fuseki_api.queryDB(
      "select ?name ?displayName ?description ?source ?test " <>
      "where { " <>
        "?x rdf:name \"" <> name  <> "\" . " <>
        "?x rdf:name ?name . " <>
        "?x :displayName ?displayName . " <>
        "?x rdf:type ?type . " <>
        "?type rdf:label ?source . " <>
        "OPTIONAL { " <>
          "?x rdf:Description ?description . " <>
          "?x :lastTest ?testId . " <>
          "?testId xsd:boolean ?test . " <>
        "}" <>
      "}")
    metrics = @fuseki_api.queryDB(
      "select ?projectName ?metricName ?value " <>
      "where { " <>
        "?x rdf:name \"" <> name  <> "\" . " <>
        "?x rdf:name ?projectName . " <>
        "?x rdf:type ?type . " <>
        "?x :metric ?y . " <>
        "?y rdf:name ?metricName . " <>
        "?y :lastData ?data . " <>
        "?data xsd:integer ?value . " <>
        "FILTER(?type IN (:cb, :git, :trello)) " <>
      "}")
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

  def bool_to_int("true"), do: 1
  def bool_to_int("false"), do: 0

  def getTimeseries(name) do
    time = @fuseki_api.queryDB("
    SELECT ?name ?value ?date
    WHERE {
        ?a rdf:name \"" <> name <> "\".
        ?a :metric ?metric .
        ?metric rdf:name ?name .
        ?metric :data ?data .
        ?data xsd:integer ?value .
        ?data xsd:dateTime ?date .
        } ORDER BY ASC(?date)")
        |> Enum.reduce(%{}, fn(x, all) ->
          update = Map.get(all, x["name"], []) |> Kernel.++([%{x["date"] => x["value"]}])
          Map.put(all, x["name"], update)
        end)
    @fuseki_api.queryDB("
    SELECT ?projectname ?date ?value WHERE {
    ?project rdf:name \"" <> name <> "\" .
    ?project :test ?test .
    ?test xsd:dateTime ?date .
    ?test xsd:boolean ?value .
    } ORDER BY ?date
    ")
    |> Enum.reduce(time, fn(x, all) ->
       update = Map.get(all, "test", []) |> Kernel.++([%{x["date"] => bool_to_int(x["value"])}])
       Map.put(all, "test", update)
    end)
  end


  def testTimeseries(name) do
  end

  def putTests(tests) do
    tests
    |> Enum.map(fn(x) ->
      @fuseki_api.updateDB(
        "DELETE { ?project :lastTest ?a } " <>
        "WHERE { " <>
          "?project rdf:name \"" <> x.name <> "\" . " <>
          "?project :lastTest ?a " <>
        "}; " <>
        "INSERT { " <>
          "_:newTest xsd:boolean " <> to_string(x.success) <> " . " <>
          "_:newTest xsd:dateTime \"" <> Timex.format!(Timex.now, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}+00:00") <> "\" . " <>
          "?project :test _:newTest . " <>
          "?project :lastTest _:newTest . " <>
        "} " <>
        "WHERE { " <>
          "?project rdf:name \"" <> x.name <> "\" . " <>
      "}") end)
       |> List.flatten
  end
end

