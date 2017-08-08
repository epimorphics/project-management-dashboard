defmodule HelloPhoenix.GitController do
  use HelloPhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def project(conn, %{"project" => project}) do
    render conn, "project.html", %{project: project}
  end

  def projectJSON(conn, %{"project" => project}) do
    git = Source.get(:github, :repos)
      |> Enum.map(&Github.toStandardForm(&1))
      |> Enum.find(%{}, fn(x) -> x.name == project end)
    json conn, git
  end
end
