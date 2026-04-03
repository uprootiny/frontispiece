defmodule Frontispiece.Kernel.Well do
  @moduledoc """
  A copyable text block — the exact prompt, command, config, or code snippet
  that the episode demonstrates. Wells are the actionable core of each episode.

  On mobile: tap to copy (with haptic + flash confirmation).
  On desktop: click the copy button or select text.
  In TUI: yank to system clipboard.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @well_kinds ~w(prompt command config snippet schema)

  @type t :: %__MODULE__{
          id: integer() | nil,
          kind: String.t() | nil,
          label: String.t() | nil,
          content: String.t() | nil,
          language: String.t() | nil,
          copy_count: integer(),
          position: integer(),
          episode_id: integer() | nil
        }

  schema "wells" do
    field :kind, :string
    field :label, :string
    field :content, :string
    field :language, :string
    field :copy_count, :integer, default: 0
    field :position, :integer, default: 0

    belongs_to :episode, Frontispiece.Kernel.Episode

    timestamps()
  end

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(well, attrs) do
    well
    |> cast(attrs, [:kind, :label, :content, :language, :position, :episode_id])
    |> validate_required([:kind, :label, :content])
    |> validate_inclusion(:kind, @well_kinds)
  end

  @spec kinds() :: [String.t()]
  def kinds, do: @well_kinds
end
