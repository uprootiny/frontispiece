import Config

config :frontispiece, FrontispieceWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    "dev-only-key-do-not-use-in-production-must-be-at-least-64-bytes-long-for-phoenix",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:frontispiece, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:frontispiece, ~w(--watch)]}
  ]

config :frontispiece, FrontispieceWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/frontispiece_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"priv/content/.*(md|toml)$"
    ]
  ]

config :frontispiece, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
