# Elixir + Phoenix

FROM hexpm/elixir:1.14.0-erlang-25.1-ubuntu-focal-20211006

# Install debian packages
RUN apt-get update
RUN apt-get install --yes git build-essential inotify-tools postgresql-client lsof

# Install Elixir tools
RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /app