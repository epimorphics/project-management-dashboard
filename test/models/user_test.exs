defmodule UsersTest do
  use ExUnit.Case

  test "gitUsers" do
    assert Users.gitUsers(%{:repos => [
      %{:contributors => [%{:login => "testuser1", :avatar_url => "url1"}]}
    ]}) == [%{:login => "testuser1", :avatar_url => "url1"}]
  end

  test "gitUsers handles duplicates" do
    assert Users.gitUsers(%{:repos => [
      %{:contributors => [%{:login => "testuser1", :avatar_url => "url1"}]},
      %{:contributors => [%{:login => "testuser1", :avatar_url => "url1"}]}
    ]}) == [%{:login => "testuser1", :avatar_url => "url1"}]
  end

  test "gitUsers concattenates correctly" do
    assert Users.gitUsers(%{:repos => [
      %{:contributors => [%{:login => "testuser1", :avatar_url => "url1"}]},
      %{:contributors => [%{:login => "testuser2", :avatar_url => "url2"}]}
    ]}) == [
      %{:login => "testuser1", :avatar_url => "url1"},
      %{:login => "testuser2", :avatar_url => "url2"}
    ]
  end

  test "cbUsers" do
    assert Users.cbUsers(%{:users => [%{
      :email_address => "testemail",
      :company => "testcompany",
      :first_name=> "testfirst",
      :ignored => "i shouldn't arrive",
      :last_name=> "testlast",
      :username=> "testuser"
    }]}) == [%{
      :email_address => "testemail",
      :company => "testcompany",
      :first_name=> "testfirst",
      :last_name=> "testlast",
      :username=> "testuser"
    }]
  end

  test "createUsers" do
    assert Users.createUsers(%{:repos => [
      %{:contributors => [%{:login => "der", :avatar_url => "url1"}]}
    ]}, %{:users => [%{
      :email_address => "dave@epimorphics.com",
      :company => "testcompany",
      :first_name=> "testfirst",
      :ignored => "i shouldn't arrive",
      :last_name=> "testlast",
      :username=> "testuser"
    }]}) == [%{
      :email_address => "dave@epimorphics.com",
      :company => "testcompany",
      :login => "der",
      :avatar_url => "url1",
      :first_name=> "testfirst",
      :last_name=> "testlast",
      :username=> "testuser"
    }]
{}
  end
end
