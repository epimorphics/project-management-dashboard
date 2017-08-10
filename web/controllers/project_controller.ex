defmodule HelloPhoenix.ProjectController do
  use HelloPhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def projectJson(conn, _params) do
    cb = Source.get(:codebaseHQ, :repos)
    standardcb = Enum.map(cb, &CodebaseHQ.toStandardForm(&1))

    git = Source.get(:github, :repos)
    standardgit = Enum.map(git, &Github.toStandardForm(&1))

    allprojects = Enum.concat(standardgit, standardcb)
    |> Enum.sort(fn(x, y) -> Timex.compare(x.time, y.time) >= 0 end)
    json conn, %{projects: allprojects}
  end

  def projectsJson(conn, %{"project" => project}) do
    cb = Source.get(:codebaseHQ, :repos)
    standardcb = Enum.map(cb, &CodebaseHQ.toStandardForm(&1))

    git = Source.get(:github, :repos)
    standardgit = Enum.map(git, &Github.toStandardForm(&1))

    allprojects = Enum.concat(standardgit, standardcb)
      |> Enum.find(%{}, fn(x) -> x.name == project end)
    json conn, allprojects
  end

  def testJson(conn, _params) do
    jenkins = Source.get(:jenkins)
    json conn, %{tests: jenkins}
  end

  def userJson(conn, _params) do
    users = Source.get(:users)
    json conn, %{users: users}
  end

  def testMultiSourceJSON(conn, _params) do
    json conn, %{:name => "Test Project",:cb => [%{:name => "data-platform"}, %{:name =>"fsa-projects"}], :git => [%{:name => "epi-dash"}], :trello => [%{"1fLs9xuC" => %{:transform=> %{:merge => ["current sprint BACKLOG", "Task BACKLOG"], :name => "Backlog", :show => ["Backlog", "Due"]}}}]}
  end

end
