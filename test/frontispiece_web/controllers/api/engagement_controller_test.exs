defmodule FrontispieceWeb.API.EngagementControllerTest do
  use FrontispieceWeb.ConnCase, async: true

  setup do
    seed_practice()
  end

  test "POST /api/engage records event", %{conn: conn, episode: episode} do
    conn =
      post(conn, "/api/engage", %{
        "event" => "view",
        "episode_id" => episode.id
      })

    assert json_response(conn, 200)["ok"] == true
  end

  test "strips unknown fields", %{conn: conn, episode: episode} do
    conn =
      post(conn, "/api/engage", %{
        "event" => "copy",
        "episode_id" => episode.id,
        "evil_field" => "hacked",
        "admin" => true
      })

    assert json_response(conn, 200)["ok"] == true

    # Verify the evil_field didn't land in the DB
    [eng] = Frontispiece.Repo.all(Frontispiece.Kernel.Engagement)
    assert eng.event == "copy"
    refute Map.has_key?(eng.metadata, "evil_field")
  end

  test "returns 422 for invalid event type", %{conn: conn, episode: episode} do
    conn =
      post(conn, "/api/engage", %{
        "event" => "hack",
        "episode_id" => episode.id
      })

    assert json_response(conn, 422)["errors"]
  end

  test "returns 422 for missing episode_id", %{conn: conn} do
    conn = post(conn, "/api/engage", %{"event" => "view"})
    assert json_response(conn, 422)
  end
end
