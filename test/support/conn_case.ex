defmodule FrontispieceWeb.ConnCase do
  @moduledoc "Test case for controller and LiveView tests."

  use ExUnit.CaseTemplate

  alias Frontispiece.Kernel.{Practice, Episode, Well}
  alias Frontispiece.Repo

  using do
    quote do
      @endpoint FrontispieceWeb.Endpoint

      use FrontispieceWeb, :verified_routes
      import Plug.Conn
      import Phoenix.ConnTest
      import FrontispieceWeb.ConnCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @spec seed_practice(map()) :: %{practice: Practice.t(), episode: Episode.t(), well: Well.t()}
  @doc "Insert a practice with one episode and one well for testing."
  def seed_practice(attrs \\ %{}) do
    practice =
      %Practice{}
      |> Practice.changeset(
        Map.merge(
          %{name: "Test Practice", slug: "test-practice", one_liner: "A test", position: 0},
          attrs
        )
      )
      |> Repo.insert!()

    episode =
      %Episode{practice_id: practice.id}
      |> Episode.changeset(%{
        title: "Test Episode",
        slug: "test-episode",
        context: "testing",
        narration: "Some **markdown** text.",
        position: 0,
        llm_used: "claude"
      })
      |> Repo.insert!()

    well =
      %Well{episode_id: episode.id}
      |> Well.changeset(%{
        kind: "prompt",
        label: "The prompt",
        content: "Do the thing",
        language: nil,
        position: 0
      })
      |> Repo.insert!()

    %{practice: practice, episode: episode, well: well}
  end
end
