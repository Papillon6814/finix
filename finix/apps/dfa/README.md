[![hex.pm version](https://img.shields.io/hexpm/v/dfa.svg)](https://hex.pm/packages/dfa)

# Dfa
Finite state machine implementation on redis.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dfa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dfa, "~> 0.1.0"}
  ]
end
```

**config.exs(dev.exs or prod.exs)**
```elixir
config :dfa, :redis_host, "localhost"
config :dfa, :redis_port, 6379
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dfa](https://hexdocs.pm/dfa).

