defmodule FrontispieceWeb.API.AdapterController do
  @moduledoc "JSON API for listing LLM adapters."

  use FrontispieceWeb, :controller

  alias Frontispiece.LLM.Router

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    json(conn, Router.list_adapters())
  end
end
