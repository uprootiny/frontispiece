defmodule FrontispieceWeb do
  @moduledoc "Phoenix web module macros for Frontispiece."

  @spec static_paths() :: [String.t()]
  def static_paths, do: ~w(assets fonts images media favicon.ico robots.txt manifest.json sw.js)

  @spec router() :: Macro.t()
  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @spec channel() :: Macro.t()
  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  @spec controller() :: Macro.t()
  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: FrontispieceWeb.Layouts]

      import Plug.Conn
      unquote(verified_routes())
    end
  end

  @spec live_view() :: Macro.t()
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {FrontispieceWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  @spec live_component() :: Macro.t()
  def live_component do
    quote do
      use Phoenix.LiveComponent
      unquote(html_helpers())
    end
  end

  @spec html() :: Macro.t()
  def html do
    quote do
      use Phoenix.Component
      import Phoenix.Controller, only: [get_csrf_token: 0]
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import Phoenix.Component
      unquote(verified_routes())
    end
  end

  @spec verified_routes() :: Macro.t()
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: FrontispieceWeb.Endpoint,
        router: FrontispieceWeb.Router,
        statics: FrontispieceWeb.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
