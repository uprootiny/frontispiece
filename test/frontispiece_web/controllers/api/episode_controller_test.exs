defmodule FrontispieceWeb.API.EpisodeControllerTest do
  use FrontispieceWeb.ConnCase, async: true

  setup do
    seed_practice()
  end

  test "GET episode returns episode with wells", %{conn: conn} do
    conn = get(conn, "/api/practices/test-practice/episodes/test-episode")
    body = json_response(conn, 200)
    assert body["title"] == "Test Episode"
    assert body["context"] == "testing"

    assert [%{"kind" => "prompt", "label" => "The prompt", "content" => "Do the thing"}] =
             body["wells"]
  end

  test "returns 404 for missing practice", %{conn: conn} do
    conn = get(conn, "/api/practices/nope/episodes/test-episode")
    assert json_response(conn, 404)
  end

  test "returns 404 for missing episode", %{conn: conn} do
    conn = get(conn, "/api/practices/test-practice/episodes/nope")
    assert json_response(conn, 404)
  end
end
