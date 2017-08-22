defmodule HelloPhoenix.CodebaseHQController do
  use HelloPhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def projectJSON(conn, %{"project" => project}) do
    json conn, Fuseki.getProjectJSON(project)
  end
end
