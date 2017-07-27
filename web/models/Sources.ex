defmodule Source do
  def start_link do
    Agent.start_link(fn -> %{} end, name: :sources)
    Source.put(:github, Github.github)
    Source.put(:codebaseHQ, CodebaseHQ.codebaseHQ)
  end

  def get(source, key) do
    Agent.get(:sources, &Kernel.get_in(&1, [source, key]))
  end

  def put(key, value) do
    Agent.update(:sources, &Map.put(&1, key, value))
  end

end

