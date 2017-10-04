defmodule Fuseki.Test do
  def queryDB(query) do
    send self(), query
    receive do
      {:out, x} -> x
    after
      1_000 -> "nothing"
    end
  end

  def updateDB(query) do
    send self(), query
    receive do
      {:out, x} -> x
    after
      1_000 -> "nothing"
    end
  end
end

defmodule FusekiTests do
  use ExUnit.Case

  test "getRepoNames" do
    send self(), {:out, [%{"name" => "test1"}, %{"name" => "test2"}]}
    assert Fuseki.getRepoNames == ["test1", "test2"]
    assert_received "SELECT ?name WHERE { ?project rdf:type ?type . ?project rdf:name ?name FILTER(?type IN (:cb, :git, :trello)) }"
  end

  test "getWebhook" do
    send self(), {:out, [%{"webhook" => "testhook"}]}
    assert Fuseki.getWebhook(%{:name => "testproject"}) == ["testhook"]
    assert_received "SELECT ?webhook WHERE { ?project rdf:type :project . ?project rdf:name \"testproject\" . ?project :webhook ?webhook . }"
  end

  test "getMetrics" do
    send self(), {:out, [%{"name" => "Issues"}]}
    assert Fuseki.getMetrics(%{:name => "testproject"}) == ["Issues"]
    assert_received "SELECT ?name WHERE { ?project rdf:name \"testproject\" . ?project :metric ?metric . ?metric rdf:name ?name . }"
  end

  test "getAvatars" do
    send self(), {:out, [%{"login" => "avatarurl"}]}
    assert Fuseki.getAvatars(%{:name => "testproject"}) == ["avatarurl"]
    assert_received "SELECT ?login WHERE { ?project rdf:name \"testproject\" . ?a :worksOn ?project . ?a :login ?login . }"
  end

  test "getUsers" do
    send self(), {:out, [%{"login" => "username"}]}
    assert Fuseki.getUsers == ["username"]
    assert_received "SELECT DISTINCT ?login WHERE { ?person rdf:type foaf:person . ?person :login ?login . }"
  end

  test "getTrello" do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    send self(), {:out, [%{"projectName" => "testProject", "trelloname" => "trelloName"}]}
    assert Fuseki.getTrello([%{:name => "testProject"}]) == [%{:name => "testProject", :trello => [%{:transform => %{}, :url=> db_loc <> "trello/" <> "trelloName"}]}]
    assert_received "SELECT ?projectName ?trelloname WHERE { ?project rdf:type :project . ?project rdf:name ?projectName . ?project :trello ?trello . ?trello rdf:name ?trelloname . }"
  end

  test "getRepos" do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    send self(), {:out, [%{"projectName" => "testProject", "url" => "projecturl", "reponame" => "projectName"}]}
    assert Fuseki.getRepos([%{:name => "testProject"}]) == [%{:name => "testProject", :repos => [%{:transform => %{}, :url => db_loc <> "repo/" <> "projectName"}]}]
    assert_received "SELECT ?projectName ?reponame WHERE { ?project rdf:type :project . ?project rdf:name ?projectName . ?project :repo ?repo . ?repo rdf:name ?reponame . }"
  end

  test "getTimeseries" do
    send self(), {:out, [%{"name" => "testProject", "value" => 4, "date" => "a date"}]}
    assert Fuseki.getTimeseries("testProject") == %{"testProject" => [%{"a date" => 4}]}
  end

  test "getProject" do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    front_end = Application.get_env(:hello_phoenix, :front_end)
    send self(), {:out, [%{"transform" => "eyAiaGlkZSI6IFsiRG9uZSIsICJEb2luZyJdfQ==", "webhook" => "test webhook"}]}

    send self(), {:out, [%{"projectName" => "testProject", "reponame" => "repoName"}]}
    send self(), {:out, [%{"projectName" => "testProject", "trelloname" => "trelloName"}]}
    assert Fuseki.getProject("testProject") ==  %{name: "testProject", repos: [%{transform: %{}, url: db_loc <> "repo/" <> "repoName"}], source: :epi, transform: "{ \"hide\": [\"Done\", \"Doing\"]}", trello: [%{transform: %{}, url: db_loc <> "trello/" <> "trelloName"}], url: front_end <> "project?name=testProject", webhook: "test webhook"}
    assert_received "SELECT ?transform ?webhook WHERE { ?project rdf:type :project . ?project :transform ?transform . ?project rdf:name \"testProject\" . OPTIONAL { ?project :webhook ?webhook}}"
  end

  test "getProjects" do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    front_end = Application.get_env(:hello_phoenix, :front_end)
    send self(), {:out, [%{"transform" => "eyAiaGlkZSI6IFsiRG9uZSIsICJEb2luZyJdfQ==", "url" => "test url", "name" => "testProject"}]}
    send self(), {:out, [%{"projectName" => "testProject", "reponame" => "repoName"}]}
    send self(), {:out, [%{"projectName" => "testProject", "trelloname" => "trelloName"}]}
    assert Fuseki.getProjects ==  [%{name: "testProject", repos: [%{transform: %{}, url: db_loc <> "repo/" <> "repoName"}], source: :epi, transform: "{ \"hide\": [\"Done\", \"Doing\"]}", trello: [%{transform: %{}, url: db_loc <> "trello/" <> "trelloName"}], url: front_end <> "project?name=testProject"}]
    assert_received "SELECT ?name ?transform WHERE { ?project rdf:type :project . ?project :transform ?transform . ?project rdf:name ?name . }"
  end

  test "getRepoJSON" do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    send self(), {:out, [%{"name" => "TestProject", "avatar" => "testavatarurl"}]}
    send self(), {:out, [%{"name" => "TestProject", "url" => "repoUrl", "displayName" => "Test Project", "description" => "a test project", "source" => "cb", "test" => true}]}
    send self(), {:out, [%{"projectName" => "TestProject", "metricName" => "testMetric", "value" => "2"}]}
    assert Fuseki.getRepoJSON == [%{"avatars" => ["testavatarurl"], "description" => "a test project", "url" => db_loc <> "repo/" <> "TestProject", "displayName" => "Test Project", "metrics" => %{"testMetric" => 2}, "name" => "TestProject", "source" => "cb", "test" => true}]
    assert_received "select ?name ?avatar where { ?project rdf:name ?name . ?person :worksOn ?project . ?person :avatar_url ?avatar . }"
    assert_received "select ?name ?displayName ?description ?source ?test where { ?x rdf:name ?name . ?x :displayName ?displayName . ?x rdf:type ?type . ?type rdf:label ?source . OPTIONAL { ?x rdf:Description ?description . ?x :lastTest ?testId . ?testId xsd:boolean ?test . } FILTER(?type IN (:cb, :git)) }"
    assert_received "select ?projectName ?metricName ?value where { ?x rdf:name ?projectName . ?x rdf:type ?type . ?x :metric ?y . ?y rdf:name ?metricName . ?y :data ?data . ?data xsd:integer ?value . FILTER(?type IN (:cb, :git)) }"
  end

  test "getRepoJSON(name)" do
    send self(), {:out, [%{"name" => "TestProject", "avatar" => "testavatarurl"}]}
    send self(), {:out, [%{"name" => "TestProject", "url" => "repoUrl", "displayName" => "Test Project", "description" => "a test project", "source" => "cb", "test" => true}]}
    send self(), {:out, [%{"projectName" => "TestProject", "metricName" => "testMetric", "value" => "2"}]}
    assert Fuseki.getRepoJSON("TestProject") == %{"avatars" => ["testavatarurl"], "description" => "a test project", "url" => "repoUrl", "displayName" => "Test Project", "metrics" => %{"testMetric" => 2}, "name" => "TestProject", "source" => "cb", "test" => true}
    assert_received "select ?name ?avatar where { ?project rdf:name \"TestProject\" . ?project rdf:name ?name . ?person :worksOn ?project . ?person :avatar_url ?avatar . }"
    assert_received "select ?name ?displayName ?description ?source ?test where { ?x rdf:name \"TestProject\" . ?x rdf:name ?name . ?x :displayName ?displayName . ?x rdf:type ?type . ?type rdf:label ?source . OPTIONAL { ?x rdf:Description ?description . ?x :lastTest ?testId . ?testId xsd:boolean ?test . }}"
    assert_received "select ?projectName ?metricName ?value where { ?x rdf:name \"TestProject\" . ?x rdf:name ?projectName . ?x rdf:type ?type . ?x :metric ?y . ?y rdf:name ?metricName . ?y :lastData ?data . ?data xsd:integer ?value . FILTER(?type IN (:cb, :git, :trello)) }"
  end

  test "getTrelloJSON" do
    db_loc = Application.get_env(:hello_phoenix, :db_loc)
    send self(), {:out, [%{"name" => "TestProject", "metricName" => "test metric", "value" => "2"}]}
    send self(), {:out, [%{"name" => "TestProject", "displayName" => "Test Project", "url" => "test url"}]}
    assert Fuseki.getTrelloJSON == [%{"displayName" => "Test Project", "metrics" => %{"test metric" => 2}, "name" => "TestProject", "source" => "trello", "stats" => %{"test metric" => 2}, "url" => db_loc <> "trello/" <> "TestProject"}]
    assert_received "SELECT ?name ?metricName ?value WHERE { ?trello rdf:name ?name . ?trello :metric ?metric . ?trello rdf:type :trello . ?metric rdf:name ?metricName . ?metric :lastData ?x . ?x xsd:integer ?value }"
    assert_received "SELECT ?name ?displayName WHERE { ?trello rdf:name ?name . ?trello rdf:type :trello . ?trello :displayName ?displayName . }"
  end

  test "putMetrics" do
    send self(), {:out, [%{"name" => "Issues"}]}
    send self(), {:out, [200]}
    assert Fuseki.putMetrics(%{:name => "TestProject", :metrics => [{"Issues", 6}, {"Bugs", 4}]}) == [200]
    assert_received "SELECT ?name WHERE { ?project rdf:name \"TestProject\" . ?project :metric ?metric . ?metric rdf:name ?name . }"
    assert_received "INSERT { _:Bugs rdf:type :metric ; rdf:name \"Bugs\" . ?project :metric _:Bugs . } WHERE { ?project rdf:name \"TestProject\" }; "
  end

  test "putMetrics duplicate" do
    send self(), {:out, [%{"name" => "Issues"}]}
    assert Fuseki.putMetrics(%{:name => "TestProject", :metrics => [{"Issues", 6}]}) == []
    assert_received "SELECT ?name WHERE { ?project rdf:name \"TestProject\" . ?project :metric ?metric . ?metric rdf:name ?name . }"
  end

  test "putRepoData" do
    send self(), {:out, [%{"name" => "No Project"}]}
    send self(), {:out, [200]}
    assert Fuseki.putRepoData(%{:source => :cb, :name => "TestProject", :displayName => "Test Project", :description => "A test project"}) == [200]
    assert_received "INSERT DATA { _:project rdf:type :cb ; rdf:name \"TestProject\" ; :displayName \"Test Project\" ; rdf:Description \"A test project\" ; }"
    assert_received "SELECT ?name WHERE { ?project rdf:type ?type . ?project rdf:name ?name FILTER(?type IN (:cb, :git, :trello)) }"
  end

  test "putRepoData duplicate" do
    send self(), {:out, [%{"name" => "TestProject"}]}
    send self(), {:out, [200]}
    assert Fuseki.putRepoData(%{:source => :cb, :name => "TestProject", :displayName => "Test Project", :description => "A test project",}) == []
    assert_received "SELECT ?name WHERE { ?project rdf:type ?type . ?project rdf:name ?name FILTER(?type IN (:cb, :git, :trello)) }"
  end

  test "putAvatars" do
    send self(), {:out, [%{"login" => "testlogin"}]}
    send self(), {:out, [200]}
    assert Fuseki.putAvatars(%{:avatars => ["otherlogin"], :name => "TestProject"}) == [200]
    assert_received "SELECT ?login WHERE { ?project rdf:name \"TestProject\" . ?a :worksOn ?project . ?a :login ?login . }"
    assert_received "INSERT { ?person :worksOn ?project ; } WHERE { ?person :login \"otherlogin\" . ?project rdf:name \"TestProject\" . }; "
  end

  test "putAvatars duplicate" do
    send self(), {:out, [%{"login" => "testlogin"}]}
    assert Fuseki.putAvatars(%{:avatars => ["testlogin"], :name => "TestProject"}) == []
    assert_received "SELECT ?login WHERE { ?project rdf:name \"TestProject\" . ?a :worksOn ?project . ?a :login ?login . }"
  end

  test "putMetricData" do
    send self(), {:out, [200]}
    timeexpected = Timex.format!(Timex.now, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}+00:00")
    expecteddb = "DELETE { ?metric :lastData ?z } WHERE { ?project rdf:name \"TestProject\" . ?project :metric ?metric . ?metric rdf:name \"Issues\" . ?metric :lastData ?z } ; INSERT { _:Issues rdf:type :data ; xsd:integer 5 ; xsd:dateTime \"" <> timeexpected <> "\" . ?metric :data _:Issues . ?metric :lastData _:Issues } WHERE { ?project rdf:name \"TestProject\" . ?project :metric ?metric . ?metric rdf:name \"Issues\" }; "
    assert Fuseki.putMetricData(%{:metrics => [{"Issues", 5}], :name => "TestProject"}) == [200]
    assert_received expecteddb
  end

  test "putUsers" do
    send self(), {:out, [%{"login" => "username"}]}
    send self(), {:out, [200]}
    assert Fuseki.putUsers([%{:login => "otherusername", :test_field => "testval"}]) == [200]
    assert_received "SELECT DISTINCT ?login WHERE { ?person rdf:type foaf:person . ?person :login ?login . }"
    assert_received "INSERT DATA { _:tempUser rdf:type foaf:person ; :login \"otherusername\" ; :test_field \"testval\" ; } "
  end

  test "putUsers duplicate" do
    send self(), {:out, [%{"login" => "username"}]}
    assert Fuseki.putUsers([%{:login => "username", :test_field => "testval"}]) == []
    assert_received "SELECT DISTINCT ?login WHERE { ?person rdf:type foaf:person . ?person :login ?login . }"
  end

  test "deleteProject" do
    send self(), {:out, [200]}
    assert Fuseki.deleteProject(%{"name" => "todelete"}) == [200]
    assert_received "DELETE {?project ?a ?b} WHERE {?project rdf:type :project . ?project rdf:name \"todelete\" . ?project ?a ?b .}"
  end

  test "putProject" do
    send self(), {:out, [200]}
    assert Fuseki.putProject(%{"name" => "TestProject", "transform" => "{}", "repos" => [%{"name" => "testrepo", "url" => "testrepourl"}], "trello" => [%{"name" => "testtrello", "url" => "testtrellourl"}], "webhook" => "testhook"}) == [200]
    assert_received "DELETE { ?project ?a ?b } WHERE { ?project rdf:type :project . ?project rdf:name \"TestProject\" . ?project ?a ?b . } ; INSERT { _:project rdf:type :project . _:project rdf:name \"TestProject\" . _:project :transform \"e30=\" . _:project :source :epi . } WHERE {} ; INSERT {  ?project :repo ?repo ; } WHERE { ?project rdf:type :project . ?project rdf:name \"TestProject\" . ?repo rdf:name \"testrepo\" . } ; INSERT { ?project :trello ?repo ; } WHERE { ?project rdf:type :project . ?project rdf:name \"TestProject\" . ?repo rdf:name \"testtrello\" . } ; INSERT { ?project :webhook <testhook> . } WHERE { ?project rdf:name \"TestProject\" }; "
  end

  test "putTests" do
    send self(), {:out, [200]}
    timeexpected = Timex.format!(Timex.now, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}+00:00")
    expectedstr = "DELETE { ?project :lastTest ?a } WHERE { ?project rdf:name \"testname\" . ?project :lastTest ?a }; INSERT { _:newTest xsd:boolean true . _:newTest xsd:dateTime \"" <> timeexpected <> "\" . ?project :test _:newTest . ?project :lastTest _:newTest . } WHERE { ?project rdf:name \"testname\" . }"

    assert Fuseki.putTests([%{:name => "testname", :success => true }]) == [200]
    assert_received expectedstr
  end

  test "putStandardForm" do
    send self(), {:out, [%{"name" => "No Project"}]}
    send self(), {:out, [200]}
    send self(), {:out, [%{"login" => "testlogin"}]}
    send self(), {:out, [200]}
    send self(), {:out, [%{"name" => "Bugs"}]}
    send self(), {:out, [200]}
    send self(), {:out, [200]}
    project = %{
      :source => :cb,
      :name => "TestProject",
      :displayName => "Test Project",
      :metrics => [{"Issues", 6}],
      :avatars => ["otherlogin"],
      :description => "A test project"
    }
    assert Fuseki.putStandardForm(project) == [200]
  end
end
