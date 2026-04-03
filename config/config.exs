import Config

config :frontispiece,
  ecto_repos: [Frontispiece.Repo]

config :frontispiece, Frontispiece.Repo,
  database: Path.expand("../frontispiece.db", __DIR__),
  pool_size: 5,
  show_sensitive_data_on_connection_error: true

config :frontispiece, FrontispieceWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FrontispieceWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: Frontispiece.PubSub,
  live_view: [signing_salt: "frontispiece_lv"]

config :esbuild,
  version: "0.21.5",
  frontispiece: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.13",
  frontispiece: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
