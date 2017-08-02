defmodule HelloPhoenix.ProjectView do
  use HelloPhoenix.Web, :view

  def repos do
    cb = Source.get(:codebaseHQ, :repos)
    standardcb = Enum.map(cb, &CodebaseHQ.toStandardForm(&1))

    git = Source.get(:github, :repos)
    standardgit = Enum.map(git, &Github.toStandardForm(&1))

    allprojects = Enum.concat(standardgit, standardcb)
    Enum.sort(allprojects, fn(x, y) -> Timex.compare(x.time, y.time) >= 0 end)
  end

end
