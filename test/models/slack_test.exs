defmodule SlackTest do
  use ExUnit.Case

  test "difference up" do
    assert Slack.difference("up") == [%{"color" => "good", "title" => "To Do is up by 1"}]
  end

  test "difference down" do
    assert Slack.difference("down") == [%{"color" => "good", "title" => "Bugs is down by -1"}]
  end

  test "difference nil" do
    assert Slack.difference("nil") == [nil]
  end
end
