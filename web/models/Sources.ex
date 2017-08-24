defmodule Source do

  def directAdd do
    git = Github.github
    cb =  CodebaseHQ.codebaseHQ
    jenkins = Jenkins.getStatus
    trello = Trello.getBoards
    users = Users.createUsers(git, cb)
    Fuseki.putUsers(users)
    |> Kernel.++  Enum.map(cb.repos, fn(x) -> Fuseki.putStandardForm(CodebaseHQ.toStandardForm(x, users)) end)
    |> Kernel.++ Enum.map(git.repos, fn(x) -> Fuseki.putStandardForm(Github.toStandardForm(x)) end)
    |> Kernel.++ Enum.map(trello, fn(x) -> Fuseki.putStandardForm(Trello.toStandardForm(x)) end)
    |> Kernel.++ Fuseki.putTests(jenkins)
  end

end

