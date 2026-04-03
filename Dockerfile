FROM elixir:1.18-otp-27-slim AS build

RUN apt-get update && apt-get install -y git nodejs npm && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force && mix deps.get --only prod

COPY config/config.exs config/prod.exs config/runtime.exs config/
RUN mix deps.compile

COPY assets/package.json assets/
RUN cd assets && npm install

COPY lib lib
COPY priv priv
COPY assets assets

RUN mix assets.deploy
RUN mix compile
RUN mix release

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
WORKDIR /app

COPY --from=build /app/_build/prod/rel/frontispiece ./

RUN mkdir -p /app/data
ENV DATABASE_PATH=/app/data/frontispiece.db
EXPOSE 4000

CMD ["sh", "-c", "/app/bin/frontispiece eval 'Frontispiece.Release.migrate()' && /app/bin/frontispiece eval 'Frontispiece.Release.seed()' && /app/bin/frontispiece start"]
