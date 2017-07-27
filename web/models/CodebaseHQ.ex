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
    repos = CodebaseHQ.getProjects
    bugs = Enum.reduce(repos, %{}, fn (x, all) ->
      Map.put(all, x["permalink"], getBugs(getTickets(x["permalink"]))) end)
    %{:repos => CodebaseHQ.getProjects, :bugs => bugs}
  end

  def getProjects do
    HTTPoison.start
    HTTPoison.get!(@api <> @projectEndpoint, headers, auth).body
    |> Poison.decode!
    |> Enum.map(fn (x) -> x["project"] end)
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
