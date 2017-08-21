defmodule Source do

  def start_link do
    Agent.start_link(fn -> %{} end, name: :sources)
    HTTPoison.start
    git = Github.github
    cb =  CodebaseHQ.codebaseHQ
    Source.put(:github, git)
    Source.put(:codebaseHQ, cb)
    Source.put(:users, Users.createUsers(git, cb))
    Source.put(:jenkins, Jenkins.getStatus)
    Source.put(:trello, Trello.getBoards)
  end

  def get(source) do
    Agent.get(:sources, &Map.get(&1, source))
  end

  def get(source, key) do
    Agent.get(:sources, &Kernel.get_in(&1, [source, key]))
  end

  def put(key, value) do
    Agent.update(:sources, &Map.put(&1, key, value))
  end

  def addToGraph do
    git = Source.get(:github, :repos)
    cb = Source.get(:codebaseHQ, :repos)
    jenkins = Source.get(:jenkins)
    trello = Source.get(:trello)
    users = Source.get(:users)
    Enum.map(cb, fn(x) -> Fuseki.putStandardForm(CodebaseHQ.toStandardForm(x)) end)
    |> Kernel.++ Enum.map(git, fn(x) -> Fuseki.putStandardForm(Github.toStandardForm(x)) end)
    |> Kernel.++ Enum.map(trello, fn(x) -> Fuseki.putTrello(Trello.toStandardForm(x)) end)
    |> Kernel.++ Enum.map(jenkins, fn(x) ->
      Fuseki.updateDB("INSERT DATA { :" <> x.name<> " :test " <> to_string(x.success) <> "}")
    end)
  end

end

