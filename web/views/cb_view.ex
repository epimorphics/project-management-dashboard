defmodule HelloPhoenix.CodebaseHQView do
  use HelloPhoenix.Web, :view

  def repos do
    Source.get(:codebaseHQ, :repos)
  end

  def bugs (repo) do
    repo
    |> Map.get(:bugs, 0)
  end

end
