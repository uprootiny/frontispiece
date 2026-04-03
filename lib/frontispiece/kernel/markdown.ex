defmodule Frontispiece.Kernel.Markdown do
  @moduledoc """
  Cached, sanitized Markdown rendering. Uses Earmark for parsing and
  strips dangerous HTML tags to prevent XSS from user-authored content.
  """

  @allowed_tags ~w(
    p br hr h1 h2 h3 h4 h5 h6
    em strong code pre blockquote
    ul ol li
    a img
    table thead tbody tr th td
    span div
  )

  @allowed_attrs ~w(href src alt title class id name)

  @spec render(String.t() | nil) :: String.t()
  @doc "Render markdown to sanitized HTML. Returns empty string for nil input."
  def render(nil), do: ""
  def render(""), do: ""

  def render(text) do
    case get_cached(text) do
      {:ok, html} ->
        html

      :miss ->
        html =
          text
          |> Earmark.as_html!(escape: false, smartypants: false)
          |> sanitize_html()

        put_cached(text, html)
        html
    end
  end

  # Simple ETS-based cache keyed on content hash.
  # Created lazily on first access. Entries never expire (content is static).

  @cache_table :frontispiece_markdown_cache

  defp get_cached(text) do
    ensure_table()
    key = :erlang.phash2(text)

    case :ets.lookup(@cache_table, key) do
      [{^key, html}] -> {:ok, html}
      [] -> :miss
    end
  end

  defp put_cached(text, html) do
    ensure_table()
    key = :erlang.phash2(text)
    :ets.insert(@cache_table, {key, html})
  end

  defp ensure_table do
    case :ets.whereis(@cache_table) do
      :undefined -> :ets.new(@cache_table, [:set, :public, :named_table, read_concurrency: true])
      _ref -> :ok
    end
  rescue
    ArgumentError -> :ok
  end

  # Strip tags not in allowlist, strip attrs not in allowlist
  defp sanitize_html(html) do
    # Remove script/style/iframe entirely (including content)
    html = Regex.replace(~r/<(script|style|iframe|object|embed|form)[^>]*>.*?<\/\1>/si, html, "")

    # Remove event handler attributes (onload, onclick, etc.)
    html = Regex.replace(~r/\s+on\w+\s*=\s*("[^"]*"|'[^']*'|[^\s>]*)/i, html, "")

    # Remove javascript: URLs
    html = Regex.replace(~r/(href|src)\s*=\s*["']javascript:[^"']*["']/i, html, "")

    # Strip disallowed tags but keep their content
    allowed_pattern = @allowed_tags |> Enum.join("|")

    html =
      Regex.replace(
        ~r/<\/?(?!(?:#{allowed_pattern})\b)[a-z][a-z0-9]*[^>]*>/i,
        html,
        ""
      )

    # Strip disallowed attributes from remaining tags
    allowed_attr_pattern = @allowed_attrs |> Enum.join("|")

    Regex.replace(
      ~r/(<[a-z][a-z0-9]*)\s+(?!(?:#{allowed_attr_pattern})\s*=)[a-z][-a-z]*\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]*)/i,
      html,
      "\\1"
    )
  end
end
