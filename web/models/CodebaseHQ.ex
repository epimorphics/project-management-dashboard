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
      |> Map.put(:users, getAssignments(y))
      |> Map.put(:bugs, getBugs(tickets))
      |> Map.put(:priorities, getPriorities(tickets))
      |> Map.put(:time, getLastUpdate(y))
    end)
    %{:repos => repos, :users => getUsers(repos)}
  end

  def toStandardForm(project) do
    users = Source.get(:users)
    project_emails = project.users

    avatars = project.users
    |> Enum.map(fn(email) ->
      user = Enum.find(users, fn(user) ->
        user.email_address == email
      end)
      Map.get(user, :login)
    end)
    |> Enum.filter(fn(x) -> x != nil end)

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
      current_acc = Map.get(acc, CodebaseHQ.getPriority(x), 0)
      current_acc = case CodebaseHQ.getStatus(x) do
        true -> current_acc
        false -> current_acc + 1
      end
      Map.put(acc, CodebaseHQ.getPriority(x), current_acc)
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

  def getLastUpdate(project) do
    url = @api <> "/" <> Map.get(project, :permalink) <> "/activity"
    HTTPoison.get!(url, headers, auth).body
    |> Poison.decode!
    |> List.first
    |> Map.get("event")
    |> Map.get("timestamp")
    |> Timex.parse!("{YYYY}-{M}-{D} {h24}:{m}:{s} UTC")
  end

  def getAssignments(project) do
    url = @api <> "/" <>  Map.get(project, :permalink) <> "/assignments"
    HTTPoison.get!(url, headers, auth).body
    |> Poison.decode!
    |> Enum.map(&Map.get(&1, "user"))
    |> Enum.filter(fn(x) -> x["company"] == "Epimorphics Limited" end)
    |> Enum.map(&Map.get(&1, "email_address"))
  end

  def getUsers(projects) do
    projects
    |> Enum.map(fn(x) ->
      url = @api <> "/" <>  Map.get(x, :permalink) <> "/assignments"
      HTTPoison.get!(url, headers, auth).body
      |> Poison.decode!
    end)
    |> Enum.reduce([], &Enum.concat(&1, &2))
    |> Enum.uniq
    |> Enum.map(&Map.get(&1, "user"))
    |> Enum.map(fn (x) -> 
         x
         |> Enum.reduce(%{}, fn({k,v}, all) ->
              Map.merge(all, %{String.to_atom(k) => v})
            end)
       end)
  end
end
