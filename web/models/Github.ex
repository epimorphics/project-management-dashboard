defmodule Github do
  @api "https://api.github.com"
  @orgsEndpoint "/orgs"
  @epiEndpoint "/epimorphics"
  @reposEndpoint "/repos"

  def github do
    repos = Github.getRepos
    out = Enum.reduce(repos, [] , fn(repo, all) -> [%{"name" => repo["name"], "contributors" => repo["contributors_url"]}| all] end)
    contList = Enum.reduce(out, %{}, fn(repo, all) -> Map.merge(all, %{repo["name"] => Github.getContributors(repo["contributors"])}) end)
    %{:repos => repos, :contributors => contList}
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
    HTTPoison.start
    HTTPoison.get!(@api <> @orgsEndpoint <> @epiEndpoint <> @reposEndpoint , headers, options).body
    |> Poison.decode!
  end

  def getContributors(contLink) do
    HTTPoison.start
    resp = HTTPoison.get!(contLink, headers, options)
    for person <- Poison.decode!(resp.body) do
      person
    end
  end

  def getIssues(repoName) do
    issuesLink = @api <> "/repos" <> @epiEndpoint <> "/" <> repoName <> "/issues"
    resp = HTTPoison.get!(issuesLink, headers, options)
    Poison.decode!(resp.body)
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

end
