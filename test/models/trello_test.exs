defmodule Trello.Test do
  def getBoards do
    [%{"memberships" => [%{"deactivated" => false,
          "id" => "57beaa38f0d1139ce2eef451",
          "idMember" => "5435781d46048c4c6d2a7514",
      "memberType" => "admin", "unconfirmed" => false}],
      "name" => "Test Board",
      "shortLink" => "testshort"}]
  end

  def getCards(shortLink) do
    [%{"idList" => "listid", "due" => "2017-07-07T11:00:00.000Z"}]
  end

  def getLists(shortLink) do
    [%{"name" => "testlist", "id" => "listid"}]
  end
end

defmodule TrelloTest do
  use ExUnit.Case

  test "toStandardForm" do
    assert Trello.toStandardForm(%{
      :cards => [%{"idList" => "listid", "due" => "2017-07-07T11:00:00.000Z"}],
      :deadlines => %{"Due" => 1},
      :stats => %{"testlist" => 1},
      :lists => [%{"name" => "testlist", "id" => "listid"}],
      :memberships => [%{"deactivated" => false,
          "id" => "57beaa38f0d1139ce2eef451",
          "idMember" => "5435781d46048c4c6d2a7514",
      "memberType" => "admin", "unconfirmed" => false}],
      :name => "Test Board",
      :shortLink => "testshort"
    }) == %{
      :source => :trello, :avatars => [], :name => "testshort",
      :metrics => %{"Due" => 1, "testlist" => 1}, :stats => %{"testlist" => 1},
      :deadlines => %{"Due" => 1} , :description => "", :displayName => "Test Board"}
  end

  test "getBoards" do
    assert Trello.getBoards == [%{
      :cards => [%{"idList" => "listid", "due" => "2017-07-07T11:00:00.000Z"}],
      :deadlines => %{"Due" => 1},
      :stats => %{"testlist" => 1},
      :lists => [%{"name" => "testlist", "id" => "listid"}],
      :memberships => [%{"deactivated" => false,
          "id" => "57beaa38f0d1139ce2eef451",
          "idMember" => "5435781d46048c4c6d2a7514",
      "memberType" => "admin", "unconfirmed" => false}],
      :name => "Test Board",
      :shortLink => "testshort"
    }]
  end

  test "trello auth" do
    HTTPoison.start()
    assert HTTPoison.get!("https://api.trello.com/1/organization/epimorphics/boards" <> Trello.API.auth()).status_code == 200
  end

end
