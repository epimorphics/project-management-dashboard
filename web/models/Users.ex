defmodule Users do
  def gitUsers(repos) do
    repos
    |> Map.get(:repos)
    |> Enum.map(&Map.get(&1, :contributors))
    |> Enum.reduce([], &Enum.concat(&2, &1))
    |> Enum.map(&Map.take(&1, [:login, :avatar_url]))
    |> Enum.uniq
  end

  def cbUsers(projects) do
    projects
    |> Map.get(:users)
    |> Enum.map(&Map.take(&1, [:email_address, :company, :first_name, :last_name, :username]))
  end

  def createUsers(gitrepo, cbrepo) do
    gitusers = gitUsers(gitrepo)
    cbusers = cbUsers(cbrepo)
    mapping = %{"ijdickinson" => "ian.dickinson@epimorphics.com", "der" => "dave@epimorphics.com", "bwmcbride" => "brian@epimorphics.com",  "ehedgehog" => "chris.dollin@epimorphics.com", "paperclipmonkey" => "mike.waterworth@epimorphics.com", "alexrcoley" => "alex.coley@epimorphics.com", "pshab" => "paul@epimorphics.com", "skwlilac" => "skw@epimorphics.com", "heshoots" => "max.prettyjohns@epimorphics.com", "mika018" => "mihajlo.milosavljevic@epimorphics.com"}
    cb = Enum.map(gitusers, fn(x) ->
      gitmap = Enum.find(cbusers, %{}, fn(user) ->
        user.email_address == mapping[x.login]
      end)
      Map.merge(gitmap, x)
    end)
  end
end
