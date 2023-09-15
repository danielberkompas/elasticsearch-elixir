# Elixir + Phoenix

FROM hexpm/elixir:1.15.5-erlang-26.0.2-ubuntu-focal-20230126

# Install debian packages
RUN apt-get update
RUN apt-get install --yes git build-essential inotify-tools postgresql-client lsof

# Install Elixir tools
RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /app