defmodule CodebaseHQ.API do
  @api "https://api3.codebasehq.com"
  @projectEndpoint "/projects"

  def auth do
    user = Application.fetch_env!(:hello_phoenix, :cb_user)
    pass = Application.fetch_env!(:hello_phoenix, :cb_pass)
    hackney = [basic_auth: {user, pass}]
    [hackney: hackney]
  end

  def headers do
    ["Content-type": "application/json", "Accept": "application/json"]
  end

  def getProjects do
    HTTPoison.start
    expected_fields = ~w(open_tickets name overview permalink status)
    HTTPoison.get!(@api <> @projectEndpoint, headers(), auth()).body
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
    HTTPoison.start
    HTTPoison.get!(@api <> "/" <> projectPermalink <> "/tickets/", headers(), auth()).body
    |> Poison.decode!
  end

  def getLastUpdate(project) do
    HTTPoison.start
    url = @api <> "/" <> Map.get(project, :permalink) <> "/activity"
    HTTPoison.get!(url, headers(), auth()).body
    |> Poison.decode!
    |> List.first
    |> Map.get("event")
    |> Map.get("timestamp")
    |> Timex.parse!("{YYYY}-{M}-{D} {h24}:{m}:{s} UTC")
  end

  def getAssignments(project) do
    HTTPoison.start
    url = @api <> "/" <>  Map.get(project, :permalink) <> "/assignments"
    HTTPoison.get!(url, headers(), auth()).body
    |> Poison.decode!
    |> Enum.map(&Map.get(&1, "user"))
    |> Enum.filter(fn(x) -> x["company"] == "Epimorphics Limited" end)
    |> Enum.map(&Map.get(&1, "email_address"))
  end

  def getProjectUsers(projectPermalink) do
    HTTPoison.start
    url = @api <> "/" <> projectPermalink <> "/assignments"
    HTTPoison.get!(url, headers(), auth()).body
    |> Poison.decode!
  end
end

defmodule CodebaseHQ do
  @codebasehq_api Application.get_env(:hello_phoenix, :codebasehq_api)

  def codebaseHQ do
    repos = Enum.map(@codebasehq_api.getProjects, fn(y) ->
      tickets = @codebasehq_api.getTickets(y[:permalink])
      y
      |> Map.put(:users, @codebasehq_api.getAssignments(y))
      |> Map.put(:bugs, getBugs(tickets))
      |> Map.put(:priorities, getPriorities(tickets))
      |> Map.put(:time, @codebasehq_api.getLastUpdate(y))
    end)
    %{:repos => repos, :users => getUsers(repos)}
  end

  def toStandardForm(project, users) do
    avatars = Enum.filter(users, &Enum.member?(project.users, Map.get(&1, :email_address, "")))
    |> Enum.map(&Map.get(&1, :login, nil))
    |> Enum.filter(&Kernel.!=(&1, nil))

    metrics = %{
      :Issues => project.open_tickets,
      :Bugs => project.bugs,
      :Critical => Map.get(project.priorities, "Critical", 0)}

    %{
      :source => :cb,
      :name => project.permalink,
      :displayName => project.name,
      :time => project.time,
      :description => project.overview,
      :avatars => avatars,
      :metrics => metrics
    }
  end

  def getUsers(projects) do
    projects
    |> Enum.map(fn(x) ->
      @codebasehq_api.getProjectUsers(Map.get(x, :permalink))
    end)
    |> List.flatten
    |> Enum.uniq
    |> Enum.map(&Map.get(&1, "user"))
    |> Enum.map(fn (x) ->
         x
         |> Enum.reduce(%{}, fn({k,v}, all) ->
              Map.merge(all, %{String.to_atom(k) => v})
            end)
       end)
  end

  def getBugs(tickets) do
    tickets
    |> Enum.reduce(%{}, fn (x, acc) ->
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
      current_acc = Map.get(acc, getPriority(x), 0)
      current_acc = case CodebaseHQ.getStatus(x) do
        true -> current_acc
        false -> current_acc + 1
      end
      Map.put(acc, CodebaseHQ.getPriority(x), current_acc)
    end)
  end

  def getPriority(ticket) do
    ticket
    |> Map.get("ticket", %{})
    |> Map.get("priority", %{})
    |> Map.get("name")
  end

  def getStatus(ticket) do
    ticket
    |> Map.get("ticket", %{})
    |> Map.get("status", %{})
    |> Map.get("treat-as-closed")
  end

  def getType(ticket) do
    ticket
    |> Map.get("ticket", %{})
    |> Map.get("type", %{})
    |> Map.get("name")
  end
end
