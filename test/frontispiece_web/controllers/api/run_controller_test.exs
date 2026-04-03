defmodule FrontispieceWeb.API.RunControllerTest do
  use FrontispieceWeb.ConnCase, async: true

  test "returns 400 for unknown adapter", %{conn: conn} do
    conn = post(conn, "/api/run", %{"adapter" => "fake", "prompt" => "test"})
    body = json_response(conn, 400)
    assert body["error"] =~ "unknown adapter"
  end

  test "returns 400 for empty prompt", %{conn: conn} do
    conn = post(conn, "/api/run", %{"adapter" => "claude", "prompt" => "   "})
    body = json_response(conn, 400)
    assert body["error"] =~ "empty"
  end

  test "returns 400 for missing fields", %{conn: conn} do
    conn = post(conn, "/api/run", %{"adapter" => "claude"})
    body = json_response(conn, 400)
    assert body["error"] =~ "missing"
  end

  test "returns 400 for completely empty body", %{conn: conn} do
    conn = post(conn, "/api/run", %{})
    body = json_response(conn, 400)
    assert body["error"] =~ "missing"
  end
end
