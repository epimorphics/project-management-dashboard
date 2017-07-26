defmodule Github do
  @api "https://api.github.com"
  @epiEndpoint "/orgs/epimorphics"
  @reposEndpoint "/repos"
  @token "39be9ef43db366946cd8669b0ad164bc0d119031"

  def headers do
    token = Application.fetch_env!(:hello_phoenix, :api_key)
    ["Authorization": "token #{token}", "Accept": "Application/json; Charset=utf-8"]
  end

  def options do
    [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 500]
  end

  def getOrg do
    HTTPoison.start
    HTTPoison.get!(@api <> @epiEndpoint, headers, options).body
    |> Poison.decode
  end

  def getRepos do
    HTTPoison.start
    HTTPoison.get!(@api <> @epiEndpoint <> @reposEndpoint , headers, options).body
    |> Poison.decode!
  end

  def getContributors(contLink) do
    HTTPoison.start
    resp = HTTPoison.get!(contLink, headers, options)
    for person <- Poison.decode!(resp.body) do
      person
    end
  end

end
