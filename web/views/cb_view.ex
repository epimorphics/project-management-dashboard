defmodule HelloPhoenix.CodebaseHQView do
  use HelloPhoenix.Web, :view

  def id do
    elem(Github.getOrg,1)["id"]
  end

  def repos do
    Source.get(:codebaseHQ, :repos)
  end

  def tickets do

  end

  def bugs(permalink) do
    Source.get(:codebaseHQ, :bugs)
    |> Map.get(permalink)
    |> Map.get("Bug", 0)
  end

end
