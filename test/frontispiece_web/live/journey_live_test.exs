defmodule FrontispieceWeb.JourneyLiveTest do
  use FrontispieceWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    seed_practice()
  end

  test "renders episode content", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/p/test-practice")
    assert html =~ "Test Episode"
    assert html =~ "testing"
    assert html =~ "markdown"
  end

  test "shows progress indicator", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/p/test-practice")
    assert html =~ "1/1"
  end

  test "redirects on bad slug", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/p/nonexistent")
  end

  test "copy well emits event", %{conn: conn, well: well} do
    {:ok, view, _html} = live(conn, "/p/test-practice")

    view
    |> element("[phx-click=copy_well]")
    |> render_click(%{"id" => to_string(well.id)})

    # Should not crash — engagement tracked
    assert render(view) =~ "Test Episode"
  end
end
