# Changelog

## 1.2.1

* Fixes name of the default HTTP adapter

## 1.2.0

### Breaking changes

* Now you can configure the library in a such a way that it can be used to
  stream to multiple Mixpanel accounts simultaneously. Consult with README.md on
  how to use new API.

### Improvements

* Introduces Telemetry support.

## 1.1.0

### Improvements

* Supports Elixir 1.15 and Erlang/OTP 26: all compilation errors and warnings
  were fixed.
* User facing API now supports NaiveDateTime, DateTime, as well as Erlang's
  timestamps and Erlang's Calendar `t:datetime()`.
* Batch variant of engage function (`Mixpanel.engage/2`) has been added.
* `Mixpanel.create_alias/2` has been added.
* Poison has been replaced with Jason.
* `base_url` option has been added which enables selection EU Residency servers
  (or enables use of proxies of your choice).
* Supports plug-able adapters for http libraries via `:http_adapter`
  configuration parameter: implements default one using `httpc` OTP library and
  and another one using Hackney library (won't be available until it listed as
  dependency in your project's mix file).
* If a request to Mixpanel backend fails for any reason, then it will be retries
  up to 3 times.
* All dependencies have been upgraded to their latest versions.

### Breaking changes

* Mentions of the Token has been replaced with Project Token to reflect the
  official docs. Rename `token` to `project_token` in the `config.exs`.

### Deprecation

* HTTPoison has been removed
* Mock library was made obsolete
* InchEx integration was removed
* Dogma has been dropped

### General code quality improvements

* Travis has been obsolete and was replaced by GitHub actions.
* Now the library uses Dependabot.
* All typespecs were refined and thus improved the documentation.
* Dialyzer errors have been fixed.
* Credo's warnings and errors have been resolved
* A lot of code repetition has been eliminated.
* Better validation of user provided options has been added to user facing API
  functions.
* Since the library employs behaviours to implement HTTP client adapters, the
  test suit was moved to Mox mocking framework and thus was simplified.
* To test HTTP adapters, Bandit running in HTTPS mode was used.
* Due to changes listed above, the test suite coverage was greatly improved.

## 0.8.4

* Update deps

## 0.8.0

Initial release
