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
    Fuseki.putUsers()
    |> Kernel.++  Enum.map(cb, fn(x) -> Fuseki.putStandardForm(CodebaseHQ.toStandardForm(x)) end)
    |> Kernel.++ Enum.map(git, fn(x) -> Fuseki.putStandardForm(Github.toStandardForm(x)) end)
    |> Kernel.++ Enum.map(trello, fn(x) -> Fuseki.putTrello(Trello.toStandardForm(x)) end)
    |> Kernel.++ Fuseki.putTests(jenkins)
  end

  def updateGraph do
    git = Github.github
    cb =  CodebaseHQ.codebaseHQ
    trello = Trello.getBoards
    users = Users.createUsers(git, cb)
    Fuseki.putTests(Jenkins.getStatus)
    |> Kernel.++ Enum.map(git.repos, fn(x) -> Fuseki.putMetricData(Github.toStandardForm(x)) end)
    |> Kernel.++ Enum.map(cb.repos, fn(x) -> Fuseki.putMetricData(CodebaseHQ.toStandardForm(x, users)) end)
    |> Kernel.++ Enum.map(trello, fn(x) -> Fuseki.putMetricData(Trello.toStandardForm(x)) end)
  end

end

