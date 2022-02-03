defmodule AppcuesIncrementWeb.Router do
  use AppcuesIncrementWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppcuesIncrementWeb do
    pipe_through :api
    post("/increment", KVController, :create)
    get("/increment/:key", KVController, :show)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/live" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: AppcuesIncrementWeb.Telemetry
    end
  end
end
