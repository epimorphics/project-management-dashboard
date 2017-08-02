defmodule HelloPhoenix.GitView do
  use HelloPhoenix.Web, :view

  def repos do
    gitRepos = Source.get(:github, :repos)
    gitRepos
    |> Enum.sort(fn(x, y) -> x.open_issues > y.open_issues end)
    |> Enum.map(&Github.toStandardForm(&1))
  end

end
