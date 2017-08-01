defmodule HelloPhoenix.GitView do
  use HelloPhoenix.Web, :view

  def repos do
    Source.get(:github, :repos)
    |> Enum.sort(fn(x, y) -> x.open_issues > y.open_issues end)
    |> Enum.map(&Github.toStandardForm(&1))
  end

end
