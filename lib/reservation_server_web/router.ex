defmodule ReservationServerWeb.Router do
  use ReservationServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # plug ReservationServerWeb.Auth, repo: nil
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/auth", ReservationServerWeb do
    pipe_through(:browser)

    get("/:provider", AuthController, :index)
    get("/:provider/callback", AuthController, :callback)
    delete("/logout", AuthController, :delete)
  end

  scope "/", ReservationServerWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ReservationServerWeb do
  #   pipe_through :api
  # end
end
