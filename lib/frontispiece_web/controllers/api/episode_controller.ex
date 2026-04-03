defmodule FrontispieceWeb.API.EpisodeController do
  @moduledoc "JSON API for episodes."

  use FrontispieceWeb, :controller

  alias Frontispiece.Kernel.{Practice, Episode}
  alias Frontispiece.Repo
  import Ecto.Query

  action_fallback FrontispieceWeb.API.FallbackController

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def show(conn, %{"practice_slug" => p_slug, "episode_slug" => e_slug}) do
    with %Practice{} = practice <- Repo.get_by(Practice, slug: p_slug),
         %Episode{} = episode <-
           Episode
           |> where(practice_id: ^practice.id, slug: ^e_slug)
           |> preload([:wells, :media])
           |> Repo.one() do
      json(conn, %{
        title: episode.title,
        slug: episode.slug,
        context: episode.context,
        narration: episode.narration,
        wells:
          Enum.map(episode.wells, fn w ->
            %{kind: w.kind, label: w.label, content: w.content, language: w.language}
          end),
        media:
          Enum.map(episode.media, fn m ->
            %{kind: m.kind, path: m.path, alt_text: m.alt_text, caption: m.caption}
          end)
      })
    else
      nil -> {:error, :not_found}
    end
  end
end
