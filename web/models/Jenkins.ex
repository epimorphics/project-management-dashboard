defmodule Jenkins.API do
  def getStatus(headers, auth) do
    HTTPoison.start
    HTTPoison.get!("https://epi-jenkins.epimorphics.net/api/json?depth=2", headers, auth).body
  end
end

defmodule Jenkins.Test do
  def getStatus(headers, auth) do
    File.read!("./jenkinsresp")
  end
end

defmodule Jenkins do
  @jenkins_api Application.get_env(:hello_phoenix, :jenkins_api)

  def auth do
    user = Application.fetch_env!(:hello_phoenix, :jenkins_user)
    pass = Application.fetch_env!(:hello_phoenix, :jenkins_pass)
    hackney = [basic_auth: {user, pass}]
    [hackney: hackney]
  end

  def headers do
    headers = ["Content-type": "application/json", "Accept": "application/json"]
  end

  def getStatus do
    expected_fields = ~w(name remote result)
    @jenkins_api.getStatus(headers, auth)
    |> Poison.decode!
    |> Map.get("jobs")
    |> Enum.map(fn(x) -> 
      remote = Map.get(x, "lastCompletedBuild")
      |> Map.get("actions")
      |> Enum.find(fn(x) -> Map.get(x, "_class") == "hudson.plugins.git.util.BuildData" end)
      |> Map.get("remoteUrls")
        |> List.first
      |> remoteStringToSource

      success = Map.get(x, "lastBuild")
        |> Map.get("result")
        |> Kernel.== "SUCCESS"

      Map.put(remote, :success, success)
      |> Map.put(:ciname, Map.get(x, "name"))
      end)
  end

  def remoteStringToSource(remote) do
    vals = String.split(remote, ["@", ".", ":", "/"])
    source = Enum.at(vals, 1)
    link = Enum.at(vals, 4)
    case source do
      "codebasehq" ->
        %{:source => :codebaseHQ, :name => link}
      "github" ->
        %{:source => :github, :name => link}
    end
  end
end
