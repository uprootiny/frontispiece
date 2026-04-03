defmodule FrontispieceWeb.API.PracticeControllerTest do
  use FrontispieceWeb.ConnCase, async: true

  setup do
    seed_practice()
  end

  test "GET /api/practices returns list including seeded practice", %{conn: conn} do
    conn = get(conn, "/api/practices")
    body = json_response(conn, 200)
    assert is_list(body)
    assert Enum.any?(body, &(&1["slug"] == "test-practice"))
    test_practice = Enum.find(body, &(&1["slug"] == "test-practice"))
    assert test_practice["name"] == "Test Practice"
    assert test_practice["episode_count"] == 1
  end

  test "GET /api/practices/:slug returns practice with episodes", %{conn: conn} do
    conn = get(conn, "/api/practices/test-practice")
    body = json_response(conn, 200)
    assert body["name"] == "Test Practice"
    assert [%{"title" => "Test Episode", "slug" => "test-episode"}] = body["episodes"]
  end

  test "GET /api/practices/:slug returns 404 for missing", %{conn: conn} do
    conn = get(conn, "/api/practices/nonexistent")
    assert json_response(conn, 404)["error"] == "not found"
  end
end
