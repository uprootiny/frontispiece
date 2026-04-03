defmodule Frontispiece.Kernel.ContentLoader do
  @moduledoc """
  Loads practice and episode content from `priv/content/` on disk.
  Each practice is a directory with a `practice.toml` and numbered
  episode markdown files with YAML frontmatter.

  This is the authoring interface — write markdown, restart, see it live.
  """

  alias Frontispiece.Kernel.{Practice, Episode, Well, Media}
  alias Frontispiece.Repo
  import Ecto.Query
  require Logger

  @content_dir "priv/content"

  @spec load_all() :: :ok
  @doc "Load all practices from disk into the database. Idempotent by slug."
  def load_all do
    path = content_path()

    case File.ls(path) do
      {:ok, entries} ->
        entries
        |> Enum.filter(&File.dir?(Path.join(path, &1)))
        |> Enum.sort()
        |> Enum.with_index()
        |> Enum.each(fn {dir, idx} ->
          case load_practice(dir, idx) do
            {:ok, _} ->
              :ok

            {:error, reason} ->
              Logger.warning("Failed to load practice #{dir}: #{inspect(reason)}")
          end
        end)

        :ok

      {:error, reason} ->
        Logger.warning("Content directory #{path} not readable: #{inspect(reason)}")
        :ok
    end
  end

  @spec content_path() :: String.t()
  @doc "Resolve the content directory path."
  def content_path do
    case Application.fetch_env(:frontispiece, :content_dir) do
      {:ok, path} -> path
      :error -> default_content_path()
    end
  end

  # -- Private --

  defp default_content_path do
    Application.app_dir(:frontispiece, @content_dir)
  rescue
    ArgumentError -> @content_dir
  end

  defp load_practice(dir, position) do
    Repo.transaction(fn ->
      practice_path = Path.join(content_path(), dir)
      meta = load_practice_meta(practice_path, dir)

      practice = upsert_practice!(dir, meta, position)
      load_episodes(practice, practice_path)
      practice
    end)
  end

  defp load_practice_meta(practice_path, dir) do
    toml_path = Path.join(practice_path, "practice.toml")

    if File.exists?(toml_path) do
      parse_toml(toml_path)
    else
      %{"name" => dir, "one_liner" => "", "takeaway" => ""}
    end
  end

  defp upsert_practice!(slug, meta, position) do
    case Repo.get_by(Practice, slug: slug) do
      nil -> %Practice{}
      existing -> existing
    end
    |> Practice.changeset(%{
      name: meta["name"] || slug,
      slug: slug,
      one_liner: meta["one_liner"] || "",
      takeaway: meta["takeaway"] || "",
      position: position
    })
    |> Repo.insert_or_update!()
  end

  defp load_episodes(practice, practice_path) do
    case File.ls(practice_path) do
      {:ok, files} ->
        # Delete wells and media for this practice's episodes first (idempotent reload)
        practice_id = practice.id

        episode_ids =
          from(e in Episode, where: e.practice_id == ^practice_id, select: e.id)
          |> Repo.all()

        if episode_ids != [] do
          from(w in Well, where: w.episode_id in ^episode_ids) |> Repo.delete_all()
          from(m in Media, where: m.episode_id in ^episode_ids) |> Repo.delete_all()
        end

        files
        |> Enum.filter(&String.match?(&1, ~r/^\d+-.*\.md$/))
        |> Enum.sort()
        |> Enum.with_index()
        |> Enum.each(fn {file, idx} ->
          load_episode(practice, practice_path, file, idx)
        end)

      {:error, reason} ->
        Logger.warning("Cannot read practice dir #{practice_path}: #{inspect(reason)}")
    end
  end

  defp load_episode(practice, practice_path, file, position) do
    full_path = Path.join(practice_path, file)
    slug = file |> String.replace_suffix(".md", "") |> String.replace(~r/^\d+-/, "")

    {frontmatter, body} = parse_markdown_with_frontmatter(File.read!(full_path))

    episode =
      case Repo.get_by(Episode, practice_id: practice.id, slug: slug) do
        nil -> %Episode{practice_id: practice.id}
        existing -> existing
      end
      |> Episode.changeset(%{
        title: frontmatter["title"] || slug,
        slug: slug,
        context: frontmatter["context"] || "",
        narration: body,
        position: position,
        llm_used: frontmatter["llm_used"]
      })
      |> Repo.insert_or_update!()

    # Batch-insert wells and media (no N+1)
    insert_wells(episode, frontmatter["wells"] || [])
    insert_media(episode, practice_path, file)
  end

  defp insert_wells(episode, wells_data) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      wells_data
      |> Enum.with_index()
      |> Enum.map(fn {w, idx} ->
        %{
          kind: w["kind"] || "snippet",
          label: w["label"] || "Code",
          content: w["content"] || "",
          language: w["language"],
          copy_count: 0,
          position: idx,
          episode_id: episode.id,
          inserted_at: now,
          updated_at: now
        }
      end)

    if entries != [] do
      Repo.insert_all(Well, entries)
    end
  end

  defp insert_media(episode, practice_path, md_file) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    basename = String.replace_suffix(md_file, ".md", "")

    entries =
      [".png", ".gif", ".cast", ".mp4"]
      |> Enum.with_index()
      |> Enum.filter(fn {ext, _idx} ->
        File.exists?(Path.join(practice_path, basename <> ext))
      end)
      |> Enum.map(fn {ext, idx} ->
        %{
          kind: ext_to_kind(ext),
          path: "/media/#{basename}#{ext}",
          alt_text: "#{basename}#{ext}",
          caption: nil,
          width: nil,
          height: nil,
          duration_ms: nil,
          position: idx,
          episode_id: episode.id,
          inserted_at: now,
          updated_at: now
        }
      end)

    if entries != [] do
      Repo.insert_all(Media, entries)
    end
  end

  defp ext_to_kind(".png"), do: "screenshot"
  defp ext_to_kind(".gif"), do: "gif"
  defp ext_to_kind(".cast"), do: "asciinema"
  defp ext_to_kind(".mp4"), do: "video"
  defp ext_to_kind(_), do: "screenshot"

  @spec parse_markdown_with_frontmatter(String.t()) :: {map(), String.t()}
  @doc "Parse a markdown string with YAML frontmatter. Returns {frontmatter_map, body_string}."
  def parse_markdown_with_frontmatter(content) do
    # Strip BOM if present
    content = String.replace_prefix(content, "\uFEFF", "")

    case Regex.run(~r/\A---[ \t]*\n(.*?)\n---[ \t]*\n(.*)\z/s, content) do
      [_, yaml, body] ->
        case YamlElixir.read_from_string(yaml) do
          {:ok, map} when is_map(map) -> {map, String.trim(body)}
          {:ok, _other} -> {%{}, content}
          {:error, _} -> {%{}, content}
        end

      nil ->
        {%{}, String.trim(content)}
    end
  end

  @spec parse_toml(String.t()) :: map()
  @doc "Parse a simple TOML file into a string map. Supports single-line and multiline values."
  def parse_toml(path) do
    path
    |> File.read!()
    |> String.replace_prefix("\uFEFF", "")
    |> parse_toml_string()
  end

  # Minimal TOML parser: key = "value" (single-line) and key = """...""" (multiline)
  defp parse_toml_string(content) do
    lines = String.split(content, "\n")
    parse_toml_lines(lines, %{})
  end

  defp parse_toml_lines([], acc), do: acc

  defp parse_toml_lines([line | rest], acc) do
    trimmed = String.trim(line)

    cond do
      # Skip comments and blank lines
      trimmed == "" or String.starts_with?(trimmed, "#") ->
        parse_toml_lines(rest, acc)

      # Multiline: key = """
      String.contains?(trimmed, "= \"\"\"") ->
        case Regex.run(~r/^(\w+)\s*=\s*"""(.*)$/, trimmed) do
          [_, key, first_line_content] ->
            {value, remaining} = collect_multiline(rest, [first_line_content])
            parse_toml_lines(remaining, Map.put(acc, key, value))

          nil ->
            parse_toml_lines(rest, acc)
        end

      # Single-line: key = "value"
      true ->
        case Regex.run(~r/^(\w+)\s*=\s*"((?:[^"\\]|\\.)*)"/, trimmed) do
          [_, key, value] ->
            unescaped = value |> String.replace("\\\"", "\"") |> String.replace("\\n", "\n")
            parse_toml_lines(rest, Map.put(acc, key, unescaped))

          nil ->
            parse_toml_lines(rest, acc)
        end
    end
  end

  defp collect_multiline([], acc), do: {acc |> Enum.reverse() |> Enum.join("\n"), []}

  defp collect_multiline([line | rest], acc) do
    if String.contains?(line, "\"\"\"") do
      # Take content before closing """
      before = String.replace(line, ~r/""".*$/, "")
      value = [before | acc] |> Enum.reverse() |> Enum.join("\n") |> String.trim()
      {value, rest}
    else
      collect_multiline(rest, [line | acc])
    end
  end
end
