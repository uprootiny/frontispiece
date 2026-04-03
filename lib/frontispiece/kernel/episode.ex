defmodule Frontispiece.Kernel.Episode do
  @moduledoc """
  One demonstration of a practice in a specific context.

  Each episode has narration (markdown), media (screenshots, GIFs,
  terminal recordings), and wells (copyable text blocks). Episodes
  within a practice are ordered by complexity — each variation adds
  one twist to the base pattern.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          title: String.t() | nil,
          slug: String.t() | nil,
          context: String.t() | nil,
          narration: String.t() | nil,
          position: integer(),
          llm_used: String.t() | nil,
          practice_id: integer() | nil,
          variation_of_id: integer() | nil,
          view_count: integer(),
          copy_count: integer(),
          rerun_count: integer(),
          avg_time_spent_ms: integer()
        }

  schema "episodes" do
    field :title, :string
    field :slug, :string
    field :context, :string
    field :narration, :string
    field :position, :integer, default: 0
    field :llm_used, :string

    belongs_to :practice, Frontispiece.Kernel.Practice
    belongs_to :variation_of, __MODULE__
    has_many :wells, Frontispiece.Kernel.Well
    has_many :media, Frontispiece.Kernel.Media

    field :view_count, :integer, default: 0
    field :copy_count, :integer, default: 0
    field :rerun_count, :integer, default: 0
    field :avg_time_spent_ms, :integer, default: 0

    timestamps()
  end

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(episode, attrs) do
    episode
    |> cast(attrs, [
      :title,
      :slug,
      :context,
      :narration,
      :position,
      :llm_used,
      :practice_id,
      :variation_of_id
    ])
    |> validate_required([:title, :slug, :context, :narration])
    |> unique_constraint([:practice_id, :slug])
  end
end
