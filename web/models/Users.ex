defmodule Users do
  def gitUsers(repos) do
    repos
    |> Map.get(:repos)
    |> Enum.map(&Map.get(&1, :contributors))
    |> Enum.reduce([], &Enum.concat(&1, &2))
    |> Enum.map(&Map.take(&1, [:login, :avatar_url]))
    |> Enum.uniq
  end

  def cbUsers(projects) do
    Map.get(projects, :users)
    |> Enum.map(&Map.take(&1, [:email_address, :company, :first_name, :last_name, :username]))
  end

  def createUsers(gitrepo, cbrepo) do
    gitusers = gitUsers(gitrepo)
    cbusers = cbUsers(cbrepo)
    mapping = %{"ian.dickinson@epimorphics.com" => "ijdickinson",  "dave@epimorphics.com" => "der", "brian@epimorphics.com" => "bwmcbride", "chris.dollin@epimorphics.com" => "ehedgehog"}
    Enum.map(cbusers, fn(x) ->
      gitmap = Enum.find(gitusers, %{}, fn(user) ->
        user.login == mapping[x.email_address]
      end)
      Map.merge(gitmap, x)
    end)
  end
end
