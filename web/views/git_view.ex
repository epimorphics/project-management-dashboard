defmodule HelloPhoenix.GitView do
  use HelloPhoenix.Web, :view

  def id do
    elem(Github.getOrg,1)["id"]
  end

  def repos do
    Source.get(:github, :repos)
  end

  def contributors(name) do
    Source.get(:github, :contributors)
    |> Map.get(name)
  end

end
