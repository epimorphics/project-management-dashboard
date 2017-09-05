defmodule Jenkins.Test do
  def getStatus(headers, auth) do
    File.read!("./jenkinsresp")
  end
end

defmodule JenkinsTest do
  use ExUnit.Case

  test "get status" do
    assert Jenkins.getStatus == [%{ciname: "bwm-scala-expt-1", name: "bwm",
           source: :codebaseHQ, success: true},
        %{ciname: "cairn-catalog-browser", name: "data-platform",
             source: :codebaseHQ, success: true},
        %{ciname: "ea-app-bwq-widgets", name: "bwq",
             source: :codebaseHQ, success: true},
        %{ciname: "ea-bwq-app", name: "bwq", source: :codebaseHQ,
             success: true},
        %{ciname: "epi-dkr-capybara", name: "operations",
             source: :codebaseHQ, success: true},
        %{ciname: "lr-app-ppd", name: "ppd-explorer",
             source: :github, success: true},
        %{ciname: "lr-app-standard-reports",
             name: "standard-reports-ui", source: :github,
             success: true},
        %{ciname: "lr-app-ukhpi", name: "ukhpi",
             source: :github, success: true},
        %{ciname: "qlassroom", name: "training",
             source: :codebaseHQ, success: true},
        %{ciname: "wims-ui", name: "engagements",
             source: :codebaseHQ, success: true}]
  end

  test "remote string codebase" do
    assert Jenkins.remoteStringToSource("git@codebasehq.com:epimorphics/bwm/scala-expt-1.git") == %{:source => :codebaseHQ, :name => "bwm"}
  end

  test "remote string github" do
    assert Jenkins.remoteStringToSource("git@github.com:epimorphics/test/scala-expt-1.git") == %{:source => :github, :name => "test"}
  end
end
