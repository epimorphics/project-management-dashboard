defmodule HelloPhoenix.ProjectController do
  use HelloPhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def reposJson(conn, _params) do
    json conn, %{projects: Fuseki.getProjectJSON}
  end

  def repoJSON(conn, %{"repo" => repo}) do
    json conn, Fuseki.getProjectJSON(repo)
  end

  def repoTimeSeries(conn, %{"repo" => repo}) do
    json conn, Fuseki.getTimeseries(repo)
  end

  def testMultiSourceJSON(conn, _params) do
    json conn, List.first Fuseki.getProjects
  end

  def testProjectJSON(conn, _params) do
    json conn, Fuseki.getProjects
  end

  def update(conn, _params) do
    Source.directAdd
    json conn, %{:done => "success"}
  end

  def test(conn, _params) do
    json(conn, %{body: _params})
  end

end
