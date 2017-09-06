defmodule ProjectTest do
  use ExUnit.Case

  test "getTransform" do
    encoded = Base.encode64("{\"field\": \"val\"}")
    send self(), {:out, [%{"transform" => encoded}]}
    assert Project.getTransform("TestProject") == %{"field" => "val"}
    assert_received "SELECT ?transform WHERE { ?project rdf:type :project . ?project rdf:name \"TestProject\" . ?project :transform ?transform . }"
  end

  test "getTimeseries" do
    send self(), {:out, [%{"name" => "test", "date" => "2017-07-01T08:04:00+00:00", "value" => "1"}]}
    assert Project.getTimeseries("test") == %{"test" => %{"2017-07-01T08:04:00+00:00" => 1}}
    assert_received "SELECT ?name (SUM(?val) as ?value) ?date WHERE { ?project rdf:type :project . ?project rdf:name \"test\" . ?project ?type ?source . ?source :metric ?metric . ?metric rdf:name ?name . ?metric :data  ?data . ?data xsd:integer ?val . ?data xsd:dateTime ?date . FILTER (?type IN (:repo, :trello)) } GROUP BY ?name ?metricName ?date ORDER BY ?date"
  end

  test "getTransformedSeries" do
    date1 = "2017-06-05T22:04:00+00:00"
    date2 = "2017-06-06T22:04:00+00:00"
    timeseries = [%{"name" => "Issues", "date" => date1, "value" => "1"},
                  %{"name" => "Issues", "date" => date2, "value" => "3"},
                  %{"name" => "Bugs", "date"  => date1, "value"  => "2"},
                  %{"name" => "Bugs", "date" => date2, "value" => "4"}]
    transform = Base.encode64("{\"merge\": [{\"fields\": [\"Issues\", \"Bugs\"], \"name\": \"newfield\"}]}")
    send self(), {:out, [%{"transform" => transform}]}
    send self(), {:out, timeseries}
    assert Project.getTransformedSeries("TestProject") == %{"newfield" => %{date1 => 3, date2 => 7},"Issues" => %{date1 => 1, date2 => 3}, "Bugs" => %{date1 => 2, date2 => 4}}
    assert_received "SELECT ?transform WHERE { ?project rdf:type :project . ?project rdf:name \"TestProject\" . ?project :transform ?transform . }"
    assert_received "SELECT ?name (SUM(?val) as ?value) ?date WHERE { ?project rdf:type :project . ?project rdf:name \"TestProject\" . ?project ?type ?source . ?source :metric ?metric . ?metric rdf:name ?name . ?metric :data  ?data . ?data xsd:integer ?val . ?data xsd:dateTime ?date . FILTER (?type IN (:repo, :trello)) } GROUP BY ?name ?metricName ?date ORDER BY ?date"
  end

  test "transformTimeseries hide" do
    assert Project.transformTimeseries(%{"Issues" => %{"date1" => 1, "date2" => 3}, "Bugs" => %{"date1" => 2, "date2" => 4}}, %{"hide" => ["Bugs", "Issues"]}) == %{}
  end

  test "transformTimeseries show" do
    assert Project.transformTimeseries(%{"Issues" => %{"date1" => 1, "date2" => 3}, "Bugs" => %{"date1" => 2, "date2" => 4}}, %{"show" => ["Bugs"]}) == %{"Bugs" => %{"date1" => 2, "date2" => 4}}
  end

  test "transformTimeseries merge" do
    date1 = "2017-06-05T22:04:00+00:00"
    date2 = "2017-06-06T22:04:00+00:00"
    assert Project.transformTimeseries(%{"Issues" => %{date1 => 1, date2 => 3}, "Bugs" => %{date1 => 2, date2 => 4}}, %{"merge" => [%{"fields" => ["Issues", "Bugs"], "name" => "newfield"}]}) == %{"newfield" => %{date1 => 3, date2 => 7},"Issues" => %{date1 => 1, date2 => 3}, "Bugs" => %{date1 => 2, date2 => 4}}
  end

  test "congregateDates" do
    date1 = "2017-06-06T22:04:00+00:00"
    date2 = "2017-06-06T22:04:04+00:00"
    assert Project.congregateDates(%{"Issues" => %{date1 => 1, date2 => 3}}) == %{"Issues" => %{date1 => 4}}
    
  end
end
