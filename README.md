# Mixpanel

[![Module Version](https://img.shields.io/hexpm/v/mixpanel_api_ex.svg)](https://hex.pm/packages/mixpanel_api_ex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/mixpanel_api_ex/)
[![Total Downloads](https://img.shields.io/hexpm/dt/mixpanel_api_ex.svg)](https://hex.pm/packages/mixpanel_api_ex)
[![License](https://img.shields.io/hexpm/l/mixpanel_api_ex.svg)](https://github.com/asakura/mixpanel_api_ex/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/asakura/mixpanel_api_ex.svg)](https://github.com/asakura/mixpanel_api_ex/commits/master)
[![Coverage Status](https://coveralls.io/repos/github/asakura/mixpanel_api_ex/badge.svg?branch=master)](https://coveralls.io/github/asakura/mixpanel_api_ex?branch=master)
[![CI](https://github.com/asakura/mixpanel_api_ex/actions/workflows/elixir.yml/badge.svg)](https://github.com/asakura/mixpanel_api_ex/actions)

This is a non-official third-party Elixir client for the
[Mixpanel](https://mixpanel.com/).

> Note that this README refers to the `master` branch of `mixpanel_api_ex`, not
  the latest released version on Hex. See
  [the documentation](https://hexdocs.pm/mixpanel_api_ex) for the documentation
  of the version you're using.

For the list of changes, checkout the latest
[release notes](https://github.com/asakura/mixpanel_api_ex/CHANGESET.md).

## Installation

Add `mixpanel_api_ex` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:mixpanel_api_ex, "~> 1.2"},

    # optional, but recommended adapter
    {:hackney, "~> 1.20"}
  ]
end
```

> The default adapter is Erlang's built-in `httpc`, but it is not recommended to
  use it in a production environment as it does not validate SSL certificates
  among other issues.

And ensure that `mixpanel_api_ex` is started before your application:

```elixir
def application do
  [applications: [:mixpanel_api_ex, :my_app]]
end
```

## Usage Example

Define an interface module with `use Mixpanel`.

```elixir
# lib/my_app/mixpanel.ex

defmodule MyApp.Mixpanel do
  use Mixpanel
end
```

Configure the interface module in `config/config.exs`.

```elixir
# config/config.exs

config :mixpanel_api_ex, MyApp.Mixpanel,
  project_token: System.get_env("MIXPANEL_PROJECT_TOKEN")
```

And then to track an event:

```elixir
MyApp.Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
# => :ok
```

## TOC

- [Configuration](#configuration)
- [EU Data Residency](#eu-data-residency)
- [Supported HTTP clients](#supported-http-clients)
- [Running multiple instances](#running-multiple-instances)
- [Running tests](#running-tests)
- [Runtime/Dynamic configuration](#runtime-dynamic-configuration)
- [Telemetry](#telemetry)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Configuration

### EU Data Residency

By default `mixpanel_api_ex` sends data to Mixpanels's US Servers. However,
this can be changes via `:base_url` parameter:

```elixir
# config/config.exs

config :mixpanel_api_ex, MyApp.Mixpanel,
  base_url: "https://api-eu.mixpanel.com",
  project_token: System.get_env("MIXPANEL_PROJECT_TOKEN")
```

`:base_url` is not limited specifically to this URL. So if you need you can
provide an proxy address to route Mixpanel events via.

### Supported HTTP clients

At the moment `httpc` and `hackney` libraries are supported. `:http_adapter`
param can be used to select which HTTP adapter you want to use.

```elixir
# config/config.exs

config :mixpanel_api_ex, MyApp.Mixpanel,
  http_adapter: Mixpanel.HTTP.Hackney,
  project_token: System.get_env("MIXPANEL_PROJECT_TOKEN")
```

> The default adapter is Erlang's built-in `httpc`, but it is not recommended to
  use it in a production environment as it does not validate SSL certificates
  among other issues.

### Running multiple instances

You can configure multiple instances to be used by different applications within
your VM. For instance the following example demonstrates having separate client
which is used specifically to sending data to Mixpanel's EU servers.

```elixir
# config/config.exs

config :mixpanel_api_ex, MyApp.Mixpanel,
  project_token: System.get_env("MIXPANEL_PROJECT_TOKEN")

config :mixpanel_api_ex, MyApp.Mixpanel.EU,
  base_url: "https://api-eu.mixpanel.com",
  project_token: System.get_env("MIXPANEL_EU_PROJECT_TOKEN")
```

```elixir
# lib/my_app/mixpanel.ex

defmodule MyApp.Mixpanel do
  use Mixpanel
end
```

```elixir
# lib/my_app/mixpanel_eu.ex

defmodule MyApp.MixpanelEU do
  use Mixpanel
end
```

### Running tests

Other than not running `mixpanel_api_ex` application in test environment you
have got two other options. Which one you need to use depends on if you want the
client process running or not.

If you prefer the client process to be up and running during the test suite
running you may provide `Mixpanel.HTTP.NoOp` adapter to `:http_adapter` param.
As the adapter's name suggests it won't do any actual work sending data to
Mixpanel, but everything else will be running (including emitting Telemetry's
event).

```elixir
# config/test.exs

config :mixpanel_api_ex, MyApp.Mixpanel,
  project_token: "",
  http_adapter: Mixpanel.HTTP.NoOp
```

The second options would be simply assign `nil` as configuration value. This way
that client won't be started by the application supervisor.

```elixir
# config/test.exs

config :mixpanel_api_ex, MyApp.Mixpanel, nil
```

### Runtime/Dynamic Configuration

In cases when you don't know upfront how many client instances you need and what
project tokens to use (for instance this information is read from a database or
a external configuration file during application startup) you can use
`Mixpanel.start_client/1` and `Mixpanel.terminate_client/1` to manually run and
kill instances when needed.

For instance this would start `MyApp.Mixpanel.US` named client with `"token"` project token:

```elixir
Mixpanel.start_client(Mixpanel.Config.client!(MyApp.Mixpanel.US, [project_token: "token"])
# => {:ok, #PID<0.123.0>}
```

`Mixpanel.Config.client!/2` makes sure that provided parameters are correct.

And when you done with it, this function would stop the client immediately:

```elixir
Mixpanel.terminate_client(MyApp.Mixpanel.US)
# => :ok
```

To make it possible to call this client process you might want to use some macro
magic, which would compile a new module in runtime:

```elixir
ast =
  quote do
    use Mixpanel
  end

Module.create(MyApp.Mixpanel.US, ast, Macro.Env.location(__ENV__))
# => {:module, _module, _bytecode, _exports}
```

If creating a module is not a case, you still can call the client's process
directly (it's a GenServer after all). For instance:

```elixir
Client.track(MyApp.Mixpanel.US, event, properties, opts)
# => :ok
```

## Usage

### Tracking events

Use `Mixpanel.track/3` function to track events:

```elixir
MyApp.Mixpanel.track(
  "Signed up",
  %{"Referred By" => "friend"},
  distinct_id: "13793"
)
# => :ok
```

The time an event occurred and IP address of an user can be provided via opts:

```elixir
MyApp.Mixpanel.track(
  "Level Complete",
  %{"Level Number" => 9},
  distinct_id: "13793",
  time: ~U[2013-01-15 00:00:00Z],
  ip: "203.0.113.9"
)
# => :ok
```

### Tracking profile updates

Use `Mixpanel.engage/3,4` function to track profile updates:

```elixir
MyApp.Mixpanel.engage(
  "13793",
  "$set",
  %{"Address" => "1313 Mockingbird Lane"}
)
# => :ok
```

The time an event occurred and IP address of an user can be provided via opts:

```elixir
MyApp.Mixpanel.engage(
  "13793",
  "$set",
  %{"Birthday" => "1948-01-01"},
  time: ~U[2013-01-15 00:00:00Z],
  ip: "123.123.123.123"
)
# => :ok
```

`Mixpanel.engage/2` works with batches:

```elixir
MyApp.Mixpanel.engage(
  [
    {"13793", "$set", %{"Address" => "1313 Mockingbird Lane"}},
    {"13793", "$set", %{"Birthday" => "1948-01-01"}}
  ],
  ip: "123.123.123.123"
)
# => :ok
```

### Merging two profiles

Use `Mixpanel.create_alias/2` create an alias for a district ID, effectively
merging two profiles:

```elixir
MyApp.Mixpanel.create_alias("13793", "13794")
# => :ok
```

## Telemetry

`mixpanel_api_ex` uses Telemetry to provide instrumentation. See the
`Mixpanel.Telemetry` module for details on specific events.

## Contributing

1. Fork it (https://github.com/asakura/mixpanel_api_ex/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test your changes by running unit tests and property based tests
   (`mix t && mix p`)
4. Check that provided changes does not have type errors (`mix dialyzer`)
5. Additionally you might run Gradient to have extra insight into type problems
   (`mix gradient`)
6. Make sure that code is formatted (`mix format`)
7. Run Credo to make sure that there is no code readability/maintainability
   issues (`mix credo --strict`)
8. Commit your changes (`git commit -am 'Add some feature'`)
9. Push to the branch (`git push origin my-new-feature`)
10. Create new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

Copyright (c) 2016-2023 [Mikalai Seva](https://github.com/asakura/)
