defmodule Frontispiece.Kernel.Engagement do
  @moduledoc """
  Tracks user engagement events: views, copies, reruns, time spent.
  Stored per-episode and aggregated per-practice. Used to understand
  which episodes land and which need rework.

  Includes debounce logic: rapid duplicate events (same episode + event
  within the debounce window) are silently dropped.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Frontispiece.Repo

  @valid_events ~w(view copy rerun complete skip scroll)
  @debounce_ms 2_000

  @type t :: %__MODULE__{
          id: integer() | nil,
          event: String.t() | nil,
          session_id: String.t() | nil,
          adapter_used: String.t() | nil,
          duration_ms: integer() | nil,
          metadata: map(),
          episode_id: integer() | nil
        }

  schema "engagements" do
    field :event, :string
    field :session_id, :string
    field :adapter_used, :string
    field :duration_ms, :integer
    field :metadata, :map, default: %{}

    belongs_to :episode, Frontispiece.Kernel.Episode

    timestamps()
  end

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(engagement, attrs) do
    engagement
    |> cast(attrs, [:event, :session_id, :adapter_used, :duration_ms, :metadata, :episode_id])
    |> validate_required([:event, :episode_id])
    |> validate_inclusion(:event, @valid_events)
  end

  @spec track(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()} | :debounced
  @doc """
  Record an engagement event with debounce.
  Rapid duplicate events (same episode + event type within #{@debounce_ms}ms) are dropped.
  """
  def track(attrs) do
    episode_id = attrs[:episode_id] || attrs["episode_id"]
    event = attrs[:event] || attrs["event"]

    if debounced?(episode_id, event) do
      :debounced
    else
      %__MODULE__{}
      |> changeset(attrs)
      |> Repo.insert()
    end
  end

  @spec generate_session_id() :: String.t()
  @doc "Generate a random session identifier for engagement tracking."
  def generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  @spec episode_stats(integer()) :: %{String.t() => integer()}
  @doc "Episode-level event counts grouped by event type."
  def episode_stats(episode_id) do
    __MODULE__
    |> where(episode_id: ^episode_id)
    |> group_by(:event)
    |> select([e], {e.event, count(e.id)})
    |> Repo.all()
    |> Map.new()
  end

  @spec practice_stats(integer()) :: [map()]
  @doc "Practice-level aggregate: event counts per episode."
  def practice_stats(practice_id) do
    from(e in __MODULE__,
      join: ep in assoc(e, :episode),
      where: ep.practice_id == ^practice_id,
      group_by: [ep.id, ep.title, e.event],
      select: %{
        episode_id: ep.id,
        episode_title: ep.title,
        event: e.event,
        count: count(e.id)
      }
    )
    |> Repo.all()
  end

  @spec top_copied(non_neg_integer()) :: [map()]
  @doc "Global: episodes ranked by copy count, with titles."
  def top_copied(limit \\ 10) do
    from(e in __MODULE__,
      join: ep in assoc(e, :episode),
      where: e.event == "copy",
      group_by: [ep.id, ep.title, ep.slug],
      order_by: [desc: count(e.id)],
      limit: ^limit,
      select: %{
        episode_id: ep.id,
        episode_title: ep.title,
        episode_slug: ep.slug,
        copies: count(e.id)
      }
    )
    |> Repo.all()
  end

  # Debounce: check if same episode+event was recorded in last N ms
  defp debounced?(nil, _event), do: false

  defp debounced?(episode_id, event) do
    cutoff =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-@debounce_ms, :millisecond)

    __MODULE__
    |> where(episode_id: ^episode_id, event: ^event)
    |> where([e], e.inserted_at > ^cutoff)
    |> limit(1)
    |> Repo.exists?()
  end
end
