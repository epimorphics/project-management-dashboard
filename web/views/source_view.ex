defmodule HelloPhoenix.GitView do
  use HelloPhoenix.Web, :view

  def id do
    elem(Github.getOrg,1)["id"]
  end

  def repos do
    Github.getRepos
  end

  def contributors(repo) do
    Github.getContributors(repo["contributors_url"])
  end

end
