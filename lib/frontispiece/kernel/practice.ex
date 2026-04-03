defmodule Frontispiece.Kernel.Practice do
  @moduledoc """
  A Practice is a named pattern with 5-8 episodes showing the same move
  in different contexts. The repetition is the pedagogy.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          slug: String.t() | nil,
          one_liner: String.t() | nil,
          takeaway: String.t() | nil,
          position: integer()
        }

  schema "practices" do
    field :name, :string
    field :slug, :string
    field :one_liner, :string
    field :takeaway, :string
    field :position, :integer, default: 0

    has_many :episodes, Frontispiece.Kernel.Episode

    timestamps()
  end

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(practice, attrs) do
    practice
    |> cast(attrs, [:name, :slug, :one_liner, :takeaway, :position])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
