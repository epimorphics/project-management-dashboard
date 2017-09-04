defmodule GithubTest do
  use ExUnit.Case

  test "getOpen false on closed" do
    testclosed = Github.Test.getIssues("closed") |> List.first
    assert Github.getOpen(testclosed) == false
  end

  test "getOpen true on open" do
    testopen = Github.Test.getIssues("open") |> List.first
    assert Github.getOpen(testopen) == true
  end

  test "getTypes" do
    assert Github.getIssueTypes([%{:labels=> [%{"name" => "bug"}, %{"name" => "question"}]}, %{:labels => [%{"name" => "bug"}]}]) == %{"bug" => 2, "question" => 1}
  end

  test "getTypes empty" do
    assert Github.getIssueTypes([%{:labels => []}, %{}]) == %{}
  end

  test "get github" do
    assert Github.github == %{:repos =>
        [%{:contributors =>
          [%{:avatar_url => "https://avatars2.githubusercontent.com/u/3824538?v=4",
             :contributions => 35, :login => "heshoots"}],
             :description => "Dashboard for epimorphics",
             :issueTypes => %{"bug" => 1},
             :issues =>
             [%{:labels =>
               [%{"color" => "ee0701",
                 "default" => true,
                 "id" => 661234153,
                 "name" => "bug",
                 "url" => "https://api.github.com/repos/epimorphics/epi-dash/labels/bug"
               }],
               :state => "open"
             }],
             :name => "epi-dash",
             :open_issues => 1,
          :pushed_at => "2017-09-01T15:03:17Z"
        }]
      }
  end

  test "to StandardForm" do
    assert Github.toStandardForm(List.first Github.github.repos) == %{avatars: ["heshoots"],
        description: "Dashboard for epimorphics",
        displayName: "epi-dash",
        metrics: %{Bugs: 1, Issues: 1}, name: "epi-dash",
        source: :git, time: ~N[2017-09-01 15:03:17]}
  end
end
