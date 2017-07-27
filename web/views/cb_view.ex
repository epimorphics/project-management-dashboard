defmodule HelloPhoenix.CodebaseHQView do
  use HelloPhoenix.Web, :view

  def repos do
    Source.get(:codebaseHQ, :repos)
  end

  def bugs(permalink) do
    Source.get(:codebaseHQ, :bugs)
    |> Map.get(permalink)
    |> Map.get("Bug", 0)
  end

end
