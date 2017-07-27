defmodule APIPuller do
  def start do
    HTTPoison.start
  end

  def getJSON!(url, headers, options) do
    HTTPoison.get!(url, headers, options).body
    |> Poison.decode!
    |> Enum.map(fn({k,v}) -> {String.to_atom(k), v} end)
  end

  def getJSON(url, headers, options) do
    {:ok, body} = HTTPoison.get(url, headers, options)
    newBody = Poison.decode(body)
    |> Enum.map(fn({k,v}) -> {String.to_atom(k), v} end)
    {:ok, newBody}
  end

  def getArray!(url, headers, options) do
    HTTPoison.get!(url, headers, options).body
    |> Poison.decode!
    |> Enum.map(fn(x) ->
      Enum.map(x, fn({k,v}) ->
        {String.to_atom(k), v} end)
    end)
  end

  def mapToAtoms do

  end
end
