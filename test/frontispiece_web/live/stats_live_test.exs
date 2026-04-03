defmodule FrontispieceWeb.StatsLiveTest do
  use FrontispieceWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    seed_practice()
  end

  test "renders stats page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/stats")
    assert html =~ "Stats"
    assert html =~ "Adapters"
    assert html =~ "Claude"
  end

  test "shows practice in stats", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/stats")
    assert html =~ "Test Practice"
  end
end
