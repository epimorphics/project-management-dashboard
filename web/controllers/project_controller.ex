defmodule HelloPhoenix.ProjectController do
  use HelloPhoenix.Web, :controller

  def reposJson(conn, _params) do
    json conn, %{projects: Fuseki.getRepoJSON}
  end

  def repoJSON(conn, %{"repo" => repo}) do
    json conn, Fuseki.getRepoJSON(repo)
  end

  def repoTimeSeries(conn, %{"repo" => repo}) do
    json conn, Fuseki.getTimeseries(repo)
  end

  def testMultiSourceJSON(conn, %{"project" => project}) do
    json conn, Fuseki.getProject(URI.decode(project))
  end

  def deleteProject(conn, _params) do
    Fuseki.deleteProject(_params)
    json(conn, %{:done => "success"})
  end

  def testProjectJSON(conn, _params) do
    json conn, Fuseki.getProjects
  end

  def update(conn, _params) do
    Source.directAdd
    json conn, %{:done => "success"}
  end

  def test(conn, _params) do
    Fuseki.putProject(_params)
    json(conn, %{:done => "success"})
  end

end
