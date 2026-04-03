defmodule Mix.Tasks.Frontispiece.Author do
  @moduledoc "Scaffold a new practice directory with template files."
  @shortdoc "Create a new practice: mix frontispiece.author \"Practice Name\""

  use Mix.Task

  @impl true
  def run([name | _]) do
    slug = slugify(name)
    dir = Path.join("priv/content", slug)

    if File.exists?(dir) do
      Mix.shell().error("Practice directory already exists: #{dir}")
    else
      File.mkdir_p!(dir)

      # practice.toml
      toml_path = Path.join(dir, "practice.toml")

      File.write!(toml_path, """
      name = "#{name}"
      one_liner = ""
      takeaway = ""
      """)

      # First episode template
      episode_path = Path.join(dir, "01-first-episode.md")

      File.write!(episode_path, """
      ---
      title: "First Episode"
      context: "Describe the context here"
      llm_used: "claude-opus-4"
      wells:
        - kind: prompt
          label: "The prompt"
          content: |
            Your prompt here
      ---

      Write your narration here. Explain what's happening, why this
      variation matters, and what connects it to the next episode.
      """)

      Mix.shell().info("Created practice: #{dir}/")
      Mix.shell().info("  #{toml_path}")
      Mix.shell().info("  #{episode_path}")
      Mix.shell().info("")
      Mix.shell().info("Next: edit the files, then run `mix run priv/repo/seeds.exs` to load.")
    end
  end

  def run([]) do
    Mix.shell().error("Usage: mix frontispiece.author \"Practice Name\"")
  end

  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
