defmodule HelloPhoenix.GitController do
  use HelloPhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def project(conn, %{"project" => project}) do
    render conn, "project.html", %{project: project}
  end
end
