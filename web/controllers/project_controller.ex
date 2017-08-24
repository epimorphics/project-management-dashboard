defmodule HelloPhoenix.ProjectController do
  use HelloPhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def reposJson(conn, _params) do
    json conn, %{projects: Fuseki.getProjectJSON}
  end

  def repoJson(conn, %{"project" => project}) do
    json conn, Fuseki.getProjectJSON(project)
  end

  def repoTimeSeries(conn, %{"repo" => repo}) do
    json conn, Fuseki.getTimeseries(repo)
  end

  def trelloTimeSeries(conn, %{"shortlink" => shortlink}) do
    json conn, Fuseki.getTimeseriesTrello(shortlink)
  end

  #def userJson(conn, _params) do
  #  users = Source.get(:users)
  #  json conn, %{users: users}
  #end

  def testMultiSourceJSON(conn, _params) do
    json conn, List.first Fuseki.getProjects
  end

  def testProjectJSON(conn, _params) do
    json conn, Fuseki.getProjects
  end

  def update(conn, _params) do
    Source.start_link
    Source.addToGraph
    json conn, %{:done => "success"}
  end

end
