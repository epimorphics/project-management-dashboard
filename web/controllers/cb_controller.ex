defmodule HelloPhoenix.CodebaseHQController do
  use HelloPhoenix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
