defmodule Frontispiece.Kernel.ContentLoaderTest do
  use ExUnit.Case, async: true

  alias Frontispiece.Kernel.ContentLoader

  describe "parse_markdown_with_frontmatter/1" do
    test "parses YAML frontmatter" do
      content = """
      ---
      title: "Fleet Triage"
      context: "A server at 93% disk"
      ---

      The body text here.
      """

      {meta, body} = ContentLoader.parse_markdown_with_frontmatter(content)
      assert meta["title"] == "Fleet Triage"
      assert meta["context"] == "A server at 93% disk"
      assert body =~ "The body text here."
    end

    test "returns empty map for content without frontmatter" do
      {meta, body} = ContentLoader.parse_markdown_with_frontmatter("Just plain text.")
      assert meta == %{}
      assert body == "Just plain text."
    end

    test "handles BOM prefix" do
      content = "\uFEFF---\ntitle: Test\n---\nBody"
      {meta, body} = ContentLoader.parse_markdown_with_frontmatter(content)
      assert meta["title"] == "Test"
      assert body == "Body"
    end

    test "handles malformed YAML gracefully" do
      content = "---\n: invalid yaml [[\n---\nBody"
      {meta, _body} = ContentLoader.parse_markdown_with_frontmatter(content)
      # Should not crash — either parses or returns empty
      assert is_map(meta)
    end

    test "handles frontmatter with wells list" do
      content = """
      ---
      title: Test
      wells:
        - kind: prompt
          label: The prompt
          content: "Do the thing"
      ---

      Narration
      """

      {meta, _body} = ContentLoader.parse_markdown_with_frontmatter(content)
      assert [well] = meta["wells"]
      assert well["kind"] == "prompt"
      assert well["label"] == "The prompt"
      assert well["content"] == "Do the thing"
    end
  end

  describe "parse_toml/1" do
    test "parses simple key-value TOML" do
      path =
        write_tmp_file("""
        name = "Test Practice"
        one_liner = "A test"
        """)

      result = ContentLoader.parse_toml(path)
      assert result["name"] == "Test Practice"
      assert result["one_liner"] == "A test"
    end

    test "handles escaped quotes" do
      path = write_tmp_file(~s|name = "It\\"s a test"|)
      result = ContentLoader.parse_toml(path)
      assert result["name"] == ~s|It"s a test|
    end

    test "skips comments and blank lines" do
      path =
        write_tmp_file("""
        # This is a comment
        name = "Test"

        # Another comment
        slug = "test"
        """)

      result = ContentLoader.parse_toml(path)
      assert result["name"] == "Test"
      assert result["slug"] == "test"
    end
  end

  defp write_tmp_file(content) do
    path =
      Path.join(
        System.tmp_dir!(),
        "frontispiece_test_#{:erlang.unique_integer([:positive])}.toml"
      )

    File.write!(path, content)
    path
  end
end
