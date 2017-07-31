defmodule HelloPhoenix.GitView do
  use HelloPhoenix.Web, :view

  def id do
    elem(Github.getOrg,1)["id"]
  end

  def repos do
    Source.get(:github, :repos)
    |> Enum.map(&Github.toStandardForm(&1))
  end

end
