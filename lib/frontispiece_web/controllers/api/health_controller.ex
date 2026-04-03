defmodule FrontispieceWeb.API.HealthController do
  @moduledoc "Health check endpoint for deployment monitoring."

  use FrontispieceWeb, :controller

  alias Frontispiece.Repo

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    db_ok = check_db()

    status = if db_ok, do: 200, else: 503

    conn
    |> put_status(status)
    |> json(%{
      status: if(db_ok, do: "ok", else: "degraded"),
      db: db_ok,
      version: Application.spec(:frontispiece, :vsn) |> to_string()
    })
  end

  defp check_db do
    case Repo.query("SELECT 1") do
      {:ok, _} -> true
      _ -> false
    end
  rescue
    _ -> false
  end
end
