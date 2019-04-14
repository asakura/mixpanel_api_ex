# Mixpanel

[![Build Status](https://travis-ci.org/agevio/mixpanel_api_ex.svg?branch=master)](https://travis-ci.org/agevio/mixpanel_api_ex)
[![Hex.pm](https://img.shields.io/hexpm/v/mixpanel_api_ex.svg?style=flat-square)](https://hex.pm/packages/mixpanel_api_ex)
[![Hex.pm](https://img.shields.io/hexpm/dt/mixpanel_api_ex.svg?style=flat-square)](https://hex.pm/packages/mixpanel_api_ex)
[![Inline docs](http://inch-ci.org/github/agevio/mixpanel_api_ex.svg?branch=master&style=flat)](http://inch-ci.org/github/agevio/mixpanel_api_ex)

Elixir client for the Mixpanel API.

## Installation

The package can be installed as:

  1. Add `mixpanel_api_ex` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:mixpanel_api_ex, "~> 1.0.1"}]
  end
  ```

  2. Ensure `mixpanel_api_ex` is started before your application:

  ```elixir
  def application do
    [applications: [:mixpanel_api_ex]]
  end
  ```

  3. Ensure your Mixpanel token was placed in config file:
  ```elixir
  config :mixpanel_api_ex, :config, token: "<Put API token here>", active: true
  ```

  4. Disable sending requests to API for tests:
  ```elixir
  config :mixpanel_api_ex, :config, token: "", active: false
  ```

## Usage

  1. Track events with `Mixpanel.track/3` function:

  ```elixir
  iex> Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
  :ok
  iex> Mixpanel.track("Level Complete", %{"Level Number" => 9}, distinct_id: "13793", time: 1358208000, ip: "203.0.113.9")
  :ok
  ```

  2. Track profile updates with `Mixpanel.engage/4` function:

  ```elixir
  iex> Mixpanel.engage("13793", "$set", %{"Address" => "1313 Mockingbird Lane"}, ip: "123.123.123.123")
  :ok
  iex> Mixpanel.engage("13793", "$set", %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}, ip: "123.123.123.123")
  :ok
  ```
