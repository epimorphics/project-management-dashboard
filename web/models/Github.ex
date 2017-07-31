defmodule Github do
  @api "https://api.github.com"
  @orgsEndpoint "/orgs"
  @epiEndpoint "/epimorphics"
  @reposEndpoint "/repos"

  def github do
    repos = Github.getRepos
    |> addContributors
    %{:repos => repos}
  end

  def headers do
    token = Application.fetch_env!(:hello_phoenix, :api_key)
    ["Authorization": "token #{token}", "Accept": "Application/json; Charset=utf-8"]
  end

  def options do
    [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 2000]
  end

  def getOrg do
    HTTPoison.start
    HTTPoison.get!(@api <> @orgsEndpoint <> @epiEndpoint, headers, options)
  end

  def getRepos do
    expected_fields = ~w(name description open_issues )
    HTTPoison.start
    HTTPoison.get!(@api <> @orgsEndpoint <> @epiEndpoint <> @reposEndpoint , headers, options).body
    |> Poison.decode!
    |> Enum.map(fn (x) ->
         x
         |> Map.take(expected_fields)
         |> Enum.reduce(%{}, fn({k,v}, all) ->
              Map.merge(all, %{String.to_atom(k) => v})
            end)
       end)
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

  def addContributors(repos) do
    repos
    |> Enum.map(fn (repo) ->
         Map.put(repo, :contributors, getContributors(repo.name))
       end)
  end

  def getIssues(repoName) do
    expected_fields = ~w(state labels)
    issuesLink = @api <> @reposEndpoint <> @epiEndpoint <> "/" <> repoName <> "/issues"
    HTTPoison.get!(issuesLink, headers, options).body
    |> Poison.decode!
    |> Enum.map(fn (x) ->
         x
         |> Map.take(expected_fields)
         |> Enum.reduce(%{}, fn({k,v}, all) ->
              Map.merge(all, %{String.to_atom(k) => v})
            end)
       end)
  end

  def addIssues(repos) do
    repos
    |> Enum.map(fn (repo) ->
         Map.put(repo, :issues, getIssues(repo.name)) end)
  end

  def getOpen(issue) do
    case Map.get(issue, "state") do
      "open" -> true
      _ -> false
    end
  end

  def getType(issue) do
    issue
    |> Map.get("labels")
    |> Enum.reduce([], fn (x, acc) ->
         [ x["name"] | acc]
      end)
  end

  def getIssueTypes(issues) do
    issues
    |> Enum.map(fn(y) ->
       y
       |> Map.get(:labels)
       |> Enum.map(fn(y) -> Map.get(y, "name") end) end)
    |> Enum.reduce([], &Enum.concat(&1, &2))
    |> Enum.reduce(%{}, fn(x, map) -> Map.put(map, x, Map.get(map, x, 0) + 1) end)
  end

  def addIssueTypes(repos) do
    repos
    |> Enum.map(fn (repo) ->
         Map.put(repo, :issueTypes, getIssueTypes(repo.issues)) end)
  end


end
