defmodule FrontispieceWeb.Router do
  use FrontispieceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FrontispieceWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :rate_limited_api do
    plug :accepts, ["json"]
    plug FrontispieceWeb.Plugs.RateLimit
  end

  scope "/", FrontispieceWeb do
    pipe_through :browser

    live "/", PracticeLive, :index
    live "/p/:slug", JourneyLive, :show
    live "/p/:practice_slug/:episode_slug", EpisodeLive, :show
    live "/compare/:practice_slug/:episode_slug", CompareLive, :show
    live "/stats", StatsLive, :index
  end

  # JSON API for TUI and other surfaces
  scope "/api", FrontispieceWeb.API do
    pipe_through :api

    get "/health", HealthController, :index
    get "/practices", PracticeController, :index
    get "/practices/:slug", PracticeController, :show
    get "/practices/:practice_slug/episodes/:episode_slug", EpisodeController, :show
    post "/engage", EngagementController, :create
    get "/adapters", AdapterController, :index
  end

  # Rate-limited API routes (burn real API credits)
  scope "/api", FrontispieceWeb.API do
    pipe_through :rate_limited_api

    post "/run", RunController, :create
  end
end
