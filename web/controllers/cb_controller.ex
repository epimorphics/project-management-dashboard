defmodule HelloPhoenix.CodebaseHQController do
  use HelloPhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def project(conn, %{"project" => project}) do
    render conn, "project.html", %{project: project}
  end

  def projectJSON(conn, %{"project" => project}) do
    #cb = Source.get(:codebaseHQ, :repos)
    # |> Enum.map(&CodebaseHQ.toStandardForm(&1))
    #  |> Enum.find(%{}, fn(x) -> x.name == project end)
    #json conn, cb
    json conn, %{projects: Fuseki.getProjectJSON(project)}
  end
end
