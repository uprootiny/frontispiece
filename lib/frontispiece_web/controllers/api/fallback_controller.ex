defmodule FrontispieceWeb.API.FallbackController do
  @moduledoc "Handles errors from API controllers."

  use FrontispieceWeb, :controller

  @spec call(Plug.Conn.t(), {:error, term()}) :: Plug.Conn.t()
  def call(conn, {:error, :not_found}) do
    conn |> put_status(404) |> json(%{error: "not found"})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    conn |> put_status(422) |> json(%{errors: errors})
  end

  def call(conn, {:error, reason}) do
    conn |> put_status(500) |> json(%{error: inspect(reason)})
  end
end
