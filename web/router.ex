defmodule HelloPhoenix.Router do
  use HelloPhoenix.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
#    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloPhoenix do
    pipe_through :browser # Use the default browser stack

    get "/json/repos", ProjectController, :reposJson

    get "/json/git/:repo", ProjectController, :repoJSON
    get "/json/cb/:repo", ProjectController, :repoJSON
    get "/json/project/:repo", ProjectController, :repoJSON
    get "/json/trello/:repo", ProjectController, :repoJSON

    get "/json/trello", TrelloController, :trelloJSON

    get "/json/timeseries/:repo", ProjectController, :repoTimeSeries

    get "/json/testproject", ProjectController, :testMultiSourceJSON
    get "/json/projects/:project", ProjectController, :testMultiSourceJSON
    get "/json/projects", ProjectController, :testProjectJSON

    get "/update", ProjectController, :update
    post "/test", ProjectController, :test
    resources "/users", UserController
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloPhoenix do
  #   pipe_through :api
  # end
end
