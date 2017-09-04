defmodule Github.API do
  @api "https://api.github.com"
  @orgsEndpoint "/orgs"
  @epiEndpoint "/epimorphics"
  @reposEndpoint "/repos"

  def headers do
    token = Application.fetch_env!(:hello_phoenix, :api_key)
    ["Authorization": "token #{token}", "Accept": "Application/json; Charset=utf-8"]
  end

  def options do
    [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 30000]
  end

  def getIssues(repoName) do
    expected_fields = ~w(state labels)
    issues_link = @api <> @reposEndpoint <> @epiEndpoint <> "/" <> repoName <> "/issues"
    HTTPoison.get!(issues_link, headers, options).body
    |> Poison.decode!
    |> Enum.map(fn (x) ->
         x
         |> Map.take(expected_fields)
         |> Enum.reduce(%{}, fn({k,v}, all) ->
              Map.merge(all, %{String.to_atom(k) => v})
            end)
       end)
  end

  def getRepos do
    expected_fields = ~w(name description open_issues pushed_at)
    HTTPoison.start
    resp = HTTPoison.get!(@api <> @orgsEndpoint <> @epiEndpoint <> @reposEndpoint , headers, options)
    resp.body
    |> decodeRepos
    |> Enum.concat(getNext resp.headers)
  end

  def getContributors(name) do
    expected_fields = ~w(login avatar_url contributions)
    HTTPoison.start
    HTTPoison.get!(@api <> @reposEndpoint <> @epiEndpoint <> "/" <> name <> "/contributors", headers, options).body
    |> Poison.decode!
    |> Enum.map(fn (x) ->
         x
         |> Map.take(expected_fields)
         |> Enum.reduce(%{}, fn({k,v}, all) ->
              Map.merge(all, %{String.to_atom(k) => v})
            end)
       end)
  end

  # HACK this will stop working once there are more than 91 repos
  def getNext(responseHeaders) do
    responseHeaders
    |> Enum.find(fn(x) -> elem(x,0) == "Link" end)
    |> elem(1)
    |> String.split([";", ","])
    |> Enum.map(&String.split(&1, ["<", ">"]))
    |> List.flatten
    |> Enum.filter(&String.contains?(&1, ["http"]))
    |> Enum.reduce([], fn(url, all) ->
      HTTPoison.get!(url , headers, options).body
      |> decodeRepos
      |> Enum.concat(all)
    end)
  end

  def decodeRepos(responseBody) do
    expected_fields = ~w(name description open_issues pushed_at)
    responseBody
    |> Poison.decode!
    |> Enum.map(fn (x) ->
         x
         |> Map.take(expected_fields)
         |> Enum.reduce(%{}, fn({k,v}, all) ->
              Map.merge(all, %{String.to_atom(k) => v})
            end)
       end)
  end
end

defmodule Github.Test do

  def getIssues(repoName) do
    case repoName do
      "open" -> [%{:labels=> [], :state=> "open"}]
      "closed" -> [%{:labels=>[], :state=> "closed"}]
      "epi-dash" -> [%{labels: [%{"color" => "ee0701", "default" => true,
              "id" => 661234153, "name" => "bug",
              "url" => "https://api.github.com/repos/epimorphics/epi-dash/labels/bug"}],
           state: "open"}]
    end
  end

  def getRepos do
    [%{:description=> "Dashboard for epimorphics",
      :name=> "epi-dash", :open_issues=> 1,
      :pushed_at=> "2017-09-01T15:03:17Z"}]
  end

  def getContributors(repoName) do
    case repoName do
      "epi-dash" -> [%{avatar_url: "https://avatars2.githubusercontent.com/u/3824538?v=4",
           contributions: 35, login: "heshoots"}]
    end
  end

end

defmodule Github do
  @github_api Application.get_env(:hello_phoenix, :github_api)

  def github do
    repos = @github_api.getRepos
    |> addContributors
    |> addIssues
    |> addIssueTypes
    %{:repos => repos}
  end

  def toStandardForm(project) do
    avatars = Enum.map(project.contributors, &Map.get(&1, :login))
    metrics = %{:Bugs=> Map.get(project.issueTypes, "bug", 0), :Issues => project.open_issues}
    time = Timex.parse!(project.pushed_at, "{YYYY}-{M}-{D}T{h24}:{m}:{s}Z")
    %{source: :git, name: project.name, displayName: project.name, description: project.description, avatars: avatars, time: time, metrics: metrics}
  end

  def addContributors(repos) do
    repos
    |> Enum.map(fn (repo) ->
         Map.put(repo, :contributors, @github_api.getContributors(repo.name))
       end)
  end

  def addIssues(repos) do
    repos
    |> Enum.map(fn (repo) ->
         Map.put(repo, :issues, @github_api.getIssues(repo.name)) end)
  end

  def getOpen(issue) do
    case Map.get(issue, :state, "undefined") do
      "open" -> true
      _ -> false
    end
  end

  def getIssueTypes(issues) do
    issues
    |> Enum.map(fn(y) ->
       y
       |> Map.get(:labels, [])
       |> Enum.map(fn(y) -> Map.get(y, "name", nil) end)
       |> Enum.filter(fn(y) -> y != nil end) end)
    |> Enum.reduce([], &Enum.concat(&1, &2))
    |> Enum.reduce(%{}, fn(x, map) -> Map.put(map, x, Map.get(map, x, 0) + 1) end)
  end

  def addIssueTypes(repos) do
    repos
    |> Enum.map(fn (repo) ->
         Map.put(repo, :issueTypes, getIssueTypes(repo.issues)) end)
  end


end
