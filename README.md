
# Design Choices and Postmortem

There are 2 implemented strategies

1. Sync, which uses DB locks to synchronously create/update keys in the DB atomically
2. Dist, which uses eventual consistency, by storing key/values in a map in GenServer's state and an append only log that is aggregated every X seconds (5secs by default)

The advantages about the both approaches is that both can scale as every node in the system will be allowed to get request, execute them and eventually get the same result, although with Sync strategy we will hit lock contention when updating a single key multiple times as it will be locked "FOR UPDATE", so, even tho every node in the system can update the same key in parallel atomically, they will need to wait for the lock to be released.

On the other hand the Dist strategy will handle a set of processes holding key/values, to choose a process we use consistent hashing to pick always the same node to store that key, and instead of adding values, we store them in an append only log to aggregate them every X time, this allow us to not have race conditions, and always increment, even across many nodes. with 1 disadvantage which would be a TODO, it uses local registry, so every node in the system will have its own process, maybe holding the same keys as other nodes, that is not a problem as every process has a log, and we can aggregate them separately and atomically update (increment) the DB, but when we grow in keys, we may be using a lot of memory as each node may be holding all the keys, in that case we should use a distributed registry as pg2 in order to co-locate a key across the cluster, so only 1 process holds that key, and if that node crashes or is removed we can still use consistent hashing to restart the key in another node (We would need to re-implement key re-balancing across nodes, so that's why cluster should be static at the beginning). Also for this approach using pg2, we would need a fully connected cluster, so we would need to use libcluster, and node monitoring for node crashes and re-balancing

Note: on the Dist strategy we can also use ets for performance using write concurrency, and still use the log to not have race conditions (Left as TODO), and use "value" as a counter cache.

Note2: Both solutions needs a load balancer in top of them to distribute the load, the nodes don't need to be connected.

Other Options:
- Append only log on DB level and aggregation doing "rollups" every X time (5sec) and updating a counter cache which doesn't have the lock contention bottleneck the sync strategy has, but is also scalable.

Constraints:
- My approaches are NOT IDEMPOTENT, so, same request multiple times will cause mutations, that would be solved by adding a unique key to the payload, checking if the key has been already processed and if not process it. For this to work, the Dist strategy would need to have the pg2 process group for locating a single process a cross the cluster, to check if that unique key has been already processed.

Production Ready:
- Taking into account the described constraints, the solution is production ready, safe and you can choose between being always consistent (Sync) or eventually consistent (Dist), if i have more time i would improve it with the described approach using libcluster, pg2, and node monitoring so we don't lost any update.

DB:
- Postgres all the things!!! also because support select with lock for update to get rid for select/update transactions

Metrics:
- Telemetry is best metrics lib right now in Elixir land so that's why, and Statix for simplicity, we can use telemetry_metrics_statsd in prod using datadog format to send them to DataDog.

Phoenix:
- Just for simplicity and its generators, also because i have experience with it

RateLimit:
- It has rate a limiter, 1000req/5sec

Benchmarking:
- Benchmarking eventual consistency against the Sync strategy is hard on a single computer, that would require, an special setup in order to meet lock contention on DB, and also assert that the values are the same on a threshold

Tests:
Almost all cases are tested (edge cases and happy path) 84.3% test coverage, it can be improved but good enough.

# Setup

## StatsD console backend

```
git clone https://github.com/statsd/statsd.git
cd statsd
# create config.js to look like: { port: 8125, mgmt_port: 8126, backends: [ "./backends/console" ] }
# run
node stats.js config.js
```
# AppcuesKV

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:3333`](http://localhost:3333) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

# Running Tests

```
mix test
```

# Usage

```bash
curl --request POST \
  --url http://localhost:3333/increment \
  --header 'Content-Type: application/json' \
  --data '{
	"key": "hello world",
	"value": 20
}'
```

```bash
$ curl --request POST \
  --url http://localhost:3333/increment \
  --header 'Content-Type: application/json' \
  --data '{
	"key": "hello world",
	"value": 20
}'

$ curl --request GET --url http://localhost:3333/increment/hello%20world
{ "hello world": 20 }
```

