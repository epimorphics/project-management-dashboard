defmodule Trello.API do
  @api "https://api.trello.com/1/"
  @orgsEndpoint "organization/epimorphics/"
  @boardsEndpoint "boards"
  @cardsEndpoint "/cards/"
  @listsEndpoint "/lists/"

  def auth do
    token = Application.fetch_env!(:hello_phoenix, :trello_token)
    key = Application.fetch_env!(:hello_phoenix, :trello_key)
    "?key=" <> key <> "&token=" <> token
  end

  def options do
    [recv_timeout: 10000]
  end

  def getBoards do
    expected_fields = ~w(memberships name shortLink)
    HTTPoison.start
    HTTPoison.get!(@api <> @orgsEndpoint <> @boardsEndpoint <> auth <> "&filter=open", options).body
    |> Poison.decode!
    |> Enum.map(&Map.take(&1, expected_fields))
  end

  def getCards(boardLink) do
    expected_fields = ~w(idList due)
    HTTPoison.start
    HTTPoison.get!(@api <> "boards/" <> boardLink <> @cardsEndpoint <> auth, options).body
    |> Poison.decode!
    |> Enum.map(&Map.take(&1, expected_fields))
  end

  def getLists(boardLink) do
    expected_fields = ~w(name id)
    HTTPoison.start
    HTTPoison.get!(@api <> "boards/" <> boardLink <> @listsEndpoint <> auth, options).body
    |> Poison.decode!
    |> Enum.map(fn(x) -> Map.take(x, expected_fields) end)
  end

end

defmodule Trello do
  @trello_api Application.get_env(:hello_phoenix, :trello_api)

  def toStandardForm(board) do
    %{:source => :trello, :avatars => [], :name => board.shortLink, :metrics => Map.merge(board.deadlines, board.stats), :stats => board.stats, :deadlines => board.deadlines, :description => "", :displayName => board.name}
  end

  def getBoards do
    @trello_api.getBoards
    |> Enum.map(fn(x) ->
       x
       |> Enum.reduce(%{}, fn({k,v}, all) ->
            Map.merge(all, %{String.to_atom(k) => v})
          end)
       |> Map.put(:cards, @trello_api.getCards(Map.get(x, "shortLink")))
       |> Map.put(:lists, @trello_api.getLists(Map.get(x, "shortLink")))
       |> boardStats
       |> boardDue
    end)
  end

  def boardStats(board) do
    listNames = Enum.map(board.cards, fn(x) ->
      list = Map.get(x, "idList")

      name = Enum.find(board.lists, fn(x) -> Map.get(x, "id") == list end)
      |> Map.get("name")
    end)
    Map.put(board, :stats, Enum.reduce(listNames, %{}, fn(x, all) ->
      Map.put(all, x, Map.get(all, x, 0) + 1) end))
  end

  def boardDue(board) do
    due_dates = Enum.map(board.cards, &Map.get(&1, "due"))
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.map(fn(x) -> Timex.parse!(x, "{YYYY}-{M}-{D}T{h24}:{m}:{s}{ss}Z") end)
    |> Enum.map(fn(date) ->
      case Timex.diff(Timex.now, date, :hours) do
        x when x < 0 -> "Lapsed"
        x when x < 7 * 24 -> "Due this week"
        _ -> "Due"
      end
    end)
    |> Enum.reduce(%{}, fn(x, all) -> 
      Map.put(all, x, Map.get(all, x, 0) + 1) end)

    Map.put(board, :deadlines, due_dates)
  end

end
