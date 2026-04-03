defmodule FrontispieceWeb.API.HealthControllerTest do
  use FrontispieceWeb.ConnCase, async: true

  test "GET /api/health returns 200 with db status", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert %{"status" => "ok", "db" => true, "version" => _} = json_response(conn, 200)
  end
end
