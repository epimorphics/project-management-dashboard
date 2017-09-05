defmodule Slack.Test do
  def getHooks do
    [%{"name" => "Max Projects",
         "webhook" => "https://hooks.slack.com/services/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"},
      %{"name" => "New Project",
           "webhook" => "https://hooks.slack.com/services/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"}]
  end

  def sendToHook(message, hook) do
    {message, hook}
  end

  def getTimeseries(name) do
    case name do
      "up" -> %{"To Do" => %{"2017-8-29T09:24:00+00:00" => 2,
        "2017-8-31T07:27:00+00:00" => 8,
        "2017-8-31T07:30:00+00:00" => 8,
        "2017-9-1T09:23:00+00:00" => 9}}
      "down" -> %{"Bugs" => %{"2017-8-29T09:24:00+00:00" => 3,
        "2017-8-31T07:29:00+00:00" => 3,
        "2017-8-31T07:30:00+00:00" => 2,
        "2017-9-1T09:23:00+00:00" => 1}}
      "nil" -> %{"Bugs" => %{"2017-8-29T09:24:00+00:00" => 0,
        "2017-8-31T07:30:00+00:00" => 0,
        "2017-9-1T09:23:00+00:00" => 0}}
    end
  end
end

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
