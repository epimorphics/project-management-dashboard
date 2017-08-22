defmodule HelloPhoenix.Router do
  use HelloPhoenix.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloPhoenix do
    pipe_through :browser # Use the default browser stack

    #get "/json/users", ProjectController, :userJson
    get "/json/repos", ProjectController, :reposJson
    get "/json/git/:project", ProjectController, :repoJson
    get "/json/cb/:project", ProjectController, :repoJson
    get "/json/project/:project", ProjectController, :repoJson
    get "/json/testproject", ProjectController, :testMultiSourceJSON
    get "/json/trello", TrelloController, :trelloJSON
    get "/json/trello/:name", TrelloController, :boardJSON
    get "/json/projects", ProjectController, :testProjectJSON
    get "/update", ProjectController, :update
    resources "/users", UserController
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloPhoenix do
  #   pipe_through :api
  # end
end
