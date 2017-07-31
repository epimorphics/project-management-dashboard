defmodule Source do

  def start_link do
    Agent.start_link(fn -> %{} end, name: :sources)
    HTTPoison.start
    git = Github.github
    Source.put(:github, git)
    cb = CodebaseHQ.codebaseHQ
    Source.put(:codebaseHQ, cb)
    Source.put(:users, Users.createUsers(git, cb))
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

