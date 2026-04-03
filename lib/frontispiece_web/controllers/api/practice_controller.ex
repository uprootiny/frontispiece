defmodule FrontispieceWeb.API.PracticeController do
  @moduledoc "JSON API for practices."

  use FrontispieceWeb, :controller

  alias Frontispiece.Kernel.{Practice, Episode}
  alias Frontispiece.Repo
  import Ecto.Query

  action_fallback FrontispieceWeb.API.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    practices =
      Practice
      |> order_by(:position)
      |> Repo.all()
      |> Repo.preload(:episodes)
      |> Enum.map(fn p ->
        %{name: p.name, slug: p.slug, one_liner: p.one_liner, episode_count: length(p.episodes)}
      end)

    json(conn, practices)
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def show(conn, %{"slug" => slug}) do
    case Repo.get_by(Practice, slug: slug) do
      nil ->
        {:error, :not_found}

      practice ->
        episodes =
          Episode
          |> where(practice_id: ^practice.id)
          |> order_by(:position)
          |> Repo.all()
          |> Enum.map(fn e ->
            %{title: e.title, slug: e.slug, context: e.context}
          end)

        json(conn, %{
          name: practice.name,
          slug: practice.slug,
          one_liner: practice.one_liner,
          takeaway: practice.takeaway,
          episodes: episodes
        })
    end
  end
end
