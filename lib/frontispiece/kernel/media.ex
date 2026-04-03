defmodule Frontispiece.Kernel.Media do
  @moduledoc """
  Media attached to an episode: screenshots, GIFs, asciinema terminal
  recordings. Each has a kind, a file path, alt text, and display hints.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @media_kinds ~w(screenshot gif asciinema video)

  @type t :: %__MODULE__{
          id: integer() | nil,
          kind: String.t() | nil,
          path: String.t() | nil,
          alt_text: String.t() | nil,
          caption: String.t() | nil,
          width: integer() | nil,
          height: integer() | nil,
          duration_ms: integer() | nil,
          position: integer(),
          episode_id: integer() | nil
        }

  schema "media" do
    field :kind, :string
    field :path, :string
    field :alt_text, :string
    field :caption, :string
    field :width, :integer
    field :height, :integer
    field :duration_ms, :integer
    field :position, :integer, default: 0

    belongs_to :episode, Frontispiece.Kernel.Episode

    timestamps()
  end

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(media, attrs) do
    media
    |> cast(attrs, [
      :kind,
      :path,
      :alt_text,
      :caption,
      :width,
      :height,
      :duration_ms,
      :position,
      :episode_id
    ])
    |> validate_required([:kind, :path])
    |> validate_inclusion(:kind, @media_kinds)
  end

  @spec kinds() :: [String.t()]
  def kinds, do: @media_kinds
end
