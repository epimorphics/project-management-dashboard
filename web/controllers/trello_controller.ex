defmodule HelloPhoenix.TrelloController do
  use HelloPhoenix.Web, :controller

  def trelloJSON(conn, _params) do
    json conn, Enum.map(Source.get(:trello), &Trello.toStandardForm(&1))
  end

  def boardJSON(conn, %{"name" => name}) do
    IO.puts(name)
    selected = Source.get(:trello)
      |> Enum.find(fn(x) -> Map.get(x, :shortLink) == name end)
    json conn, Trello.toStandardForm(selected)
  end

end
