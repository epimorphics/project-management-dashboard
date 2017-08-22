defmodule HelloPhoenix.TrelloController do
  use HelloPhoenix.Web, :controller

  def trelloJSON(conn, _params) do
    #json conn, Enum.map(Source.get(:trello), &Trello.toStandardForm(&1))
    json conn, Fuseki.getTrelloJSON
  end

  def boardJSON(conn, %{"name" => name}) do
    IO.puts(name)
    json conn, Fuseki.getTrelloJSON(name)
  end

end
