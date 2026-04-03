defmodule FrontispieceWeb.API.EngagementController do
  @moduledoc "JSON API for engagement tracking."

  use FrontispieceWeb, :controller

  alias Frontispiece.Kernel.Engagement

  @allowed_keys ~w(event episode_id session_id adapter_used duration_ms)

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, params) do
    sanitized = Map.take(params, @allowed_keys)

    case Engagement.track(sanitized) do
      {:ok, _} ->
        json(conn, %{ok: true})

      :debounced ->
        json(conn, %{ok: true, debounced: true})

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

        conn |> put_status(422) |> json(%{errors: errors})
    end
  end
end
