defmodule HelloPhoenix.TrelloController do
  use HelloPhoenix.Web, :controller

  def trelloJSON(conn, _params) do
    json conn, Fuseki.getTrelloJSON
  end

end
