import Config

config :frontispiece, Frontispiece.Repo,
  database: Path.expand("../frontispiece_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :frontispiece, FrontispieceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "test-only-key-do-not-use-in-production-must-be-at-least-64-bytes-long-for-phoenix-test",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
