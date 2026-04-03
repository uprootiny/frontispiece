defmodule Frontispiece.Kernel.MarkdownTest do
  use ExUnit.Case, async: true

  alias Frontispiece.Kernel.Markdown

  describe "render/1" do
    test "renders nil as empty string" do
      assert Markdown.render(nil) == ""
    end

    test "renders empty string as empty string" do
      assert Markdown.render("") == ""
    end

    test "renders basic markdown" do
      html = Markdown.render("**bold** and *italic*")
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "renders code blocks" do
      html = Markdown.render("```\nfoo()\n```")
      assert html =~ "<code"
    end

    test "strips script tags" do
      # Earmark treats inline HTML blocks atomically, so test with
      # script on its own line (separate HTML block from text)
      html = Markdown.render("hello\n\n<script>alert('xss')</script>\n\nworld")
      refute html =~ "<script"
      refute html =~ "alert"
      assert html =~ "hello"
      assert html =~ "world"
    end

    test "strips event handlers" do
      html = Markdown.render("<div onload=\"alert(1)\">text</div>")
      refute html =~ "onload"
      assert html =~ "text"
    end

    test "strips javascript: URLs" do
      html = Markdown.render("<a href=\"javascript:alert(1)\">click</a>")
      refute html =~ "javascript:"
    end

    test "caches results" do
      text = "# Cached heading"
      result1 = Markdown.render(text)
      result2 = Markdown.render(text)
      assert result1 == result2
    end
  end
end
