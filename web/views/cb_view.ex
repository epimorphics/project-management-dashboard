defmodule HelloPhoenix.CodebaseHQView do
  use HelloPhoenix.Web, :view

  def repos do
    cb_repos = Source.get(:codebaseHQ, :repos)
    Enum.map(cb_repos, &CodebaseHQ.toStandardForm(&1))
  end

end
