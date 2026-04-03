defmodule Frontispiece.Repo do
  use Ecto.Repo,
    otp_app: :frontispiece,
    adapter: Ecto.Adapters.SQLite3
end
