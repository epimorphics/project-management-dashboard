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

end

