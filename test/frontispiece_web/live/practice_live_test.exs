defmodule FrontispieceWeb.PracticeLiveTest do
  use FrontispieceWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    seed_practice()
  end

  test "renders L1 with practice cards by default", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Why this exists"
    assert html =~ "Test Practice"
    assert html =~ "practice = shape that recurs"
  end

  test "switching levels works", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Switch to L2: Subsystems
    html = view |> element("[phx-value-level=\"2\"]") |> render_click()
    assert html =~ "What exists"
    assert html =~ "Kernel"
    assert html =~ "LLM Router"

    # Switch to L5: Formal
    html = view |> element("[phx-value-level=\"5\"]") |> render_click()
    assert html =~ "Invariants"
    assert html =~ "Adapter contract"
  end

  test "composition tree shows full structure", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = view |> element("[phx-value-level=\"tree\"]") |> render_click()
    assert html =~ "Composition"
    assert html =~ "kernel/"
    assert html =~ "surfaces/"
    assert html =~ "Test Practice"
  end

  test "practice cards link to journey", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ ~s(href="/p/test-practice")
  end
end
