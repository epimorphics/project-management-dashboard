# Epimorphics project dashboard

You will also need Fuseki and [`Epi-Dash`](https://github.com/epimorphics/epi-dash) for this project. Once you have these, start up a fuseki in memory database with

```bash
# start an in memory database for development
./fuseki-server --update --file=projects.ttl /ds

# start a production persistent store
./fuseki-server --update --db=<nameofdb> /ds
#then load project.ttl via the web interface localhost:3030/ds
```

# start up Epi-dash

``` bash
#install dependencies
npm install
#run
npm start
```

# enter credentials

copy prod.secret.example.exs to prod.secret.exs and fill out credentials you need
this to access the API's needed for the dashboard

# start this server

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

# perform update

visit localhost:4000/update in the browser or run iex -S mix then Sources.directUpdate
this will take a little while and returns on completion

# run tests

run mix test to perform tests
run MIX_ENV=test mix coveralls.html to perform a coverage report

# problems

Timeouts from API's arent handled currently, the update will still complete but
the timed out source will not be updated

Inserts potentially take more database calls than necessary, consider outputting
a string and performing one call instead

dates, numbers and booleans were not inserted to the triple store as xsd:types, this needs to be rectified

further issues and suggestions can be found in this projects Github issues and the Epimorphics dashboard trello board
