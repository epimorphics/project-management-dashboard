defmodule CodebaseHQ do
  @api "https://api3.codebasehq.com"
  @projectEndpoint "/projects"

  def auth do
    user = Application.fetch_env!(:hello_phoenix, :cb_user)
    pass = Application.fetch_env!(:hello_phoenix, :cb_pass)
    hackney = [basic_auth: {user, pass}]
    [hackney: hackney]
  end

  def headers do
    headers = ["Content-type": "application/json", "Accept": "application/json"]
  end

  def codebaseHQ do
    repos = Enum.map(CodebaseHQ.getProjects, fn(y) ->
      tickets = getTickets(y[:permalink])
	  y
      |> Map.put(:bugs, getBugs(tickets))
      |> Map.put(:priorities, getPriorities(tickets))
    end)
    %{:repos => repos}
  end

  def getProjects do
    expected_fields = ~w(open_tickets name overview permalink status)
    HTTPoison.get!(@api <> @projectEndpoint, headers, auth).body
    |> Poison.decode!
    |> Enum.map(fn (x) -> x["project"] end)
    |> Enum.map(fn (x) -> 
         x
         |> Map.take(expected_fields)
         |> Enum.reduce(%{}, fn({k,v}, all) ->
              Map.merge(all, %{String.to_atom(k) => v})
            end)
       end)
  end

  def getTickets(projectPermalink) do
    HTTPoison.get!(@api <> "/" <> projectPermalink <> "/tickets/", headers, auth).body
    |> Poison.decode!
  end

  def getBugs(tickets) do
    Enum.reduce(tickets, %{}, fn (x, acc) ->
      currentAcc = Map.get(acc, CodebaseHQ.getType(x), 0)
      currentAcc = case CodebaseHQ.getStatus(x) do
        true -> currentAcc
        false -> currentAcc + 1
      end
      Map.put(acc, CodebaseHQ.getType(x), currentAcc)
    end)
    |> Map.get("Bug", 0)
  end

  def getPriorities(tickets) do
    Enum.reduce(tickets, %{}, fn (x, acc) ->
      currentAcc = Map.get(acc, CodebaseHQ.getPriority(x), 0)
      currentAcc = case CodebaseHQ.getStatus(x) do
        true -> currentAcc
        false -> currentAcc + 1
      end
      Map.put(acc, CodebaseHQ.getPriority(x), currentAcc)
    end)
  end

  def getPriority(ticket) do
    ticket
	|> Map.get("ticket")
	|> Map.get("priority")
	|> Map.get("name")
  end

  def getStatus(ticket) do
    ticket
    |> Map.get("ticket")
    |> Map.get("status")
    |> Map.get("treat-as-closed")
  end

  def getType(ticket) do
    ticket
    |> Map.get("ticket")
    |> Map.get("type")
    |> Map.get("name")
  end

end
