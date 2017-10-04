defmodule CodebaseHQ.Test do
  def getTickets(name) do
    case name do
      "priorities 1" -> [%{"ticket" => %{"priority" => %{"name" => "test"}, "status" => %{"treat-as-closed" => false }}}]
      _ -> ""
    end
  end

  def getProjectUsers(projectPermalink) do
    case projectPermalink do
      "test1" -> [%{"user" => %{"company" => "Epimorphics Limited", "email_address" => "test@epimorphics.com",
       "email_addresses" => ["test@epimorphics.com"], "first_name" => "testuser",
       "id" => 10, "last_name" => "testlast", "username" => "testuname"}}]
      _ -> []
    end
  end
end

defmodule CodebaseHQTest do
  use ExUnit.Case

  test "getPriority 1" do
    assert CodebaseHQ.getPriority(%{"ticket" => %{"priority" => %{"name" => "test"}}}) ==  "test"
  end

  test "getPriority 2" do
    assert CodebaseHQ.getPriority(%{"ticket" => %{"priority" => %{}}}) == nil
  end

  test "getPriority 3" do
    assert CodebaseHQ.getPriority(%{"ticket" => %{}}) == nil
  end

  test "getPriorities 1" do
    assert CodebaseHQ.getPriorities([%{"ticket" => %{"priority" => %{"name" => "test"}, "status" => %{"treat-as-closed" => false }}}]) == %{"test" => 1}
  end

  test "getPriorities 2" do
    assert CodebaseHQ.getPriorities([%{"ticket" => %{"priority" => %{"name" => "test"}, "status" => %{"treat-as-closed" => true}}}]) == %{"test" => 0}
  end

  test "getBugs 1" do
    assert CodebaseHQ.getBugs([%{"ticket" => %{"type" => %{"name" => "Bug"}, "status" => %{"treat-as-closed" => false }}}]) == 1
  end

  test "getBugs 2" do
    assert CodebaseHQ.getBugs([%{"ticket" => %{"priority" => %{"name" => "Bug"}, "status" => %{"treat-as-closed" => true}}}]) == 0
  end


  test "getStatus 1" do
    assert CodebaseHQ.getStatus(%{"ticket" => %{"status" => %{"treat-as-closed" => "test"}}}) ==  "test"
  end

  test "getStatus 2" do
    assert CodebaseHQ.getStatus(%{"ticket" => %{"status" => %{}}}) == nil
  end

  test "getStatus 3" do
    assert CodebaseHQ.getStatus(%{"ticket" => %{}}) == nil
  end

  test "getType 1" do
    assert CodebaseHQ.getType(%{"ticket" => %{"type" => %{"name" => "test"}}}) ==  "test"
  end

  test "getType 2" do
    assert CodebaseHQ.getType(%{"ticket" => %{"type" => %{}}}) == nil
  end

  test "getType 3" do
    assert CodebaseHQ.getType(%{"ticket" => %{}}) == nil
  end

  test "getUsers 1" do
    assert CodebaseHQ.getUsers([%{:permalink => "test1"}]) == [
      %{company: "Epimorphics Limited",
        email_address: "test@epimorphics.com",
        email_addresses: ["test@epimorphics.com"],
        first_name: "testuser", id: 10, last_name: "testlast",
        username: "testuname"}]
  end

  test "getUsers 2" do
    assert CodebaseHQ.getUsers([%{:permalink => "niltest"}]) == []
  end

  test "toStandardForm 1" do
    assert CodebaseHQ.toStandardForm(%{:users => ["test@epimorphics.com"],
      :open_tickets => 50, :bugs => 23, :priorities => %{"Critical" => 2},
      :permalink => "http://testperma.com", :name => "TestProject",
      :time => ~N[2017-09-04 17:54:16], :overview => "a test project",
    }, [
      %{:company => "Epimorphics Limited",
        :email_address => "test@epimorphics.com",
        :email_addresses => ["test@epimorphics.com"], :login => "testu",
        :avatar_url => "http://test.com/test.png",
        :first_name => "testuser", :id => 10, :last_name => "testlast",
        :username => "testuname"}]) == %{
        avatars: ["testu"], description: "a test project",
        displayName: "TestProject",
        metrics: %{Bugs: 23, Critical: 2, Issues: 50},
        name: "http://testperma.com", source: :cb,
        time: ~N[2017-09-04 17:54:16]}

  end

  test "codebase authenticated" do
    HTTPoison.start()
    assert HTTPoison.get!("https://api3.codebasehq.com/projects", CodebaseHQ.API.headers(), CodebaseHQ.API.auth()).status_code == 200
  end
end
