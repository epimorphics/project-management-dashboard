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

    #get "/", ProjectController, :index
    #get "/git", GitController, :index
    #get "/git/:project", GitController, :project
    #get "/cb", CodebaseHQController, :index
    #get "/cb/:project", CodebaseHQController, :project
    get "/json", ProjectController, :projectJson
    get "/json/tests", ProjectController, :testJson
    get "/json/users", ProjectController, :userJson
    get "/json/git/:project", GitController, :projectJSON
    get "/json/cb/:project", CodebaseHQController, :projectJSON
    get "/json/project/:project", ProjectController, :projectsJson
    get "/json/testproject", ProjectController, :testMultiSourceJSON
    get "/json/trello", TrelloController, :trelloJSON
    get "/json/trello/:name", TrelloController, :boardJSON
    resources "/users", UserController
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloPhoenix do
  #   pipe_through :api
  # end
end
