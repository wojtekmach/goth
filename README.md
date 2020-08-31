# Goth

<!-- MDOC !-->

A re-implementation of [Goth](https://hex.pm/packages/goth).

Notable differences:

  * Configurable HTTP client (with built-in support for Finch)

  * Use JOSE package directly instead of going through Joken.

  * Use `persistent_term` to avoid single-process bottleneck.

  * Configure different servers for different tokens instead of global config.

  * You add it to your own supervision tree.

  * Simple built-in backoff.

On the flip side, we don't support everything Goth has, notably we:

  * support only JSON credentials (and not the metadata service)

  * support one scope per credentials

  * haven't been around for more than 4 years!

## Usage

Add Goth to your supervision tree:

    credentials = "GOOGLE_APPLICATION_CREDENTIALS_JSON" |> System.fetch_env!() |> Jason.decode!()

    children = [
      {Finch, name: MyApp.Finch},
      {Goth, name: MyApp.Goth, http_client: {Goth.HTTPClient.Finch, name: MyApp.Finch}, credentials: credentials},
      ...
    ]

    Supervisor.start_link(children, ...)

And use it:

    Goth.fetch(MyApp.Goth)
    #=> {:ok, %Goth.Token{}}

<!-- MDOC !-->

## Installation

Add `goth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:goth, github: "wojtekmach/goth"}]
end
```

## License

Copyright 2020 Dashbit

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
