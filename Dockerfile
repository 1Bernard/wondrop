# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of
# Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20240130-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.16.2-erlang-26.2.1-debian-bullseye-20240130-slim
#
ARG ELIXIR_VERSION=1.16.2
ARG OTP_VERSION=26.2.1
ARG DEBIAN_VERSION=bullseye-20240130-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install Node.js (required for assets)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# copy config files
COPY config/ config/

# copy source content
COPY lib/ lib/
COPY assets/ assets/
COPY priv/ priv/
COPY rel/ rel/

# install asset dependencies
RUN cd assets && npm ci

# compile application
RUN mix compile

# compile assets
RUN mix assets.deploy

# changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

# generate release
RUN mix release

# copy overlays
RUN cp -r rel/overlays/bin/* _build/prod/rel/aether_drop/bin/ && \
    chmod +x _build/prod/rel/aether_drop/bin/server && \
    chmod +x _build/prod/rel/aether_drop/bin/migrate

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/prod/rel/aether_drop ./

USER nobody

CMD ["/app/bin/server"]
