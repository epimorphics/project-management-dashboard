FROM elixir:1.5.1
WORKDIR /app
RUN apt-get update && apt-get install --yes \
      curl \
      inotify-tools
RUN curl --silent --location https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install --yes nodejs
RUN apt-get install --yes build-essential
RUN mix local.hex --force
RUN mix local.rebar --force
CMD ["mix", "phoenix.server"]
