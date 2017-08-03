defmodule HelloPhoenix.CodebaseHQView do
  use HelloPhoenix.Web, :view

  def repos do
    cb_repos = Source.get(:codebaseHQ, :repos)
    Enum.map(cb_repos, &CodebaseHQ.toStandardForm(&1))
  end

  def repo(name) do
    Source.get(:codebaseHQ, :repos)
    |> Enum.map(&CodebaseHQ.toStandardForm(&1))
    |> Enum.find(fn(x) -> x.name == name end)
  end

end
