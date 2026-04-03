defmodule Frontispiece.Kernel.Sequencer do
  @moduledoc """
  Controls episode ordering within a practice. Episodes progress from
  simple to complex, each variation adding one twist. The sequencer
  tracks where the user is and what comes next.
  """

  alias Frontispiece.Kernel.{Practice, Episode}
  alias Frontispiece.Repo
  import Ecto.Query

  @type annotated_episode :: %{episode: Episode.t(), completed: boolean()}

  @spec next_episode(integer(), [String.t()]) :: Episode.t() | nil
  @doc "Get the next incomplete episode for a user in a practice."
  def next_episode(practice_id, completed_slugs \\ []) do
    episodes =
      Episode
      |> where(practice_id: ^practice_id)
      |> order_by(:position)
      |> Repo.all()

    Enum.find(episodes, List.first(episodes), fn ep ->
      ep.slug not in completed_slugs
    end)
  end

  @spec journey(integer(), [String.t()]) :: [annotated_episode()]
  @doc "Get all episodes for a practice, annotated with completion status."
  def journey(practice_id, completed_slugs \\ []) do
    Episode
    |> where(practice_id: ^practice_id)
    |> order_by(:position)
    |> preload([:wells, :media])
    |> Repo.all()
    |> Enum.map(fn ep ->
      %{episode: ep, completed: ep.slug in completed_slugs}
    end)
  end

  @spec all_practices() :: [Practice.t()]
  @doc "Get all practices with their episodes preloaded, sorted by position."
  def all_practices do
    Practice
    |> order_by(:position)
    |> preload(:episodes)
    |> Repo.all()
  end
end
