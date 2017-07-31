defmodule HelloPhoenix.CodebaseHQView do
  use HelloPhoenix.Web, :view

  def repos do
    Source.get(:codebaseHQ, :repos)
    |> Enum.map(&CodebaseHQ.toStandardForm(&1))
  end

end
