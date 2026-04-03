defmodule Frontispiece.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:practices) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :one_liner, :text
      add :takeaway, :text
      add :position, :integer, default: 0
      timestamps()
    end

    create unique_index(:practices, [:slug])

    create table(:episodes) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :context, :string
      add :narration, :text
      add :position, :integer, default: 0
      add :llm_used, :string
      add :view_count, :integer, default: 0
      add :copy_count, :integer, default: 0
      add :rerun_count, :integer, default: 0
      add :avg_time_spent_ms, :integer, default: 0
      add :practice_id, references(:practices, on_delete: :delete_all), null: false
      add :variation_of_id, references(:episodes, on_delete: :nilify_all)
      timestamps()
    end

    create unique_index(:episodes, [:practice_id, :slug])
    create index(:episodes, [:practice_id, :position])

    create table(:wells) do
      add :kind, :string, null: false
      add :label, :string, null: false
      add :content, :text, null: false
      add :language, :string
      add :copy_count, :integer, default: 0
      add :position, :integer, default: 0
      add :episode_id, references(:episodes, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:wells, [:episode_id, :position])

    create table(:media) do
      add :kind, :string, null: false
      add :path, :string, null: false
      add :alt_text, :string
      add :caption, :string
      add :width, :integer
      add :height, :integer
      add :duration_ms, :integer
      add :position, :integer, default: 0
      add :episode_id, references(:episodes, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:media, [:episode_id, :position])

    create table(:engagements) do
      add :event, :string, null: false
      add :session_id, :string
      add :adapter_used, :string
      add :duration_ms, :integer
      add :metadata, :map, default: %{}
      add :episode_id, references(:episodes, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:engagements, [:episode_id])
    create index(:engagements, [:event])
    create index(:engagements, [:inserted_at])
  end
end
