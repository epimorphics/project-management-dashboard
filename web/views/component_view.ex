defmodule HelloPhoenix.ComponentView do
  use HelloPhoenix.Web, :view

  def hasTest(name) do
    Source.get(:jenkins)
    |> Enum.any?(fn(x) ->
         x.name == name end)
  end

  def passingTests(name) do
    successful = Source.get(:jenkins)
    |> Enum.find(fn(x) -> x.name == name end)
    |> Map.get(:success)

    case successful do
      true -> "passing"
      false -> "failing"
    end
  end

end
