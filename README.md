# webless

Webless is an HTTP Client that doesn't make real HTTP requests. It's used for testing calls,
but much faster since it does not make any network calls.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     webless:
       github: crystal-loot/webless
   ```

2. Run `shards install`

## Usage

```crystal
require "webless"
```

TODO: Write usage instructions here

## Development

1. Write code
2. Write spec
3. `crystal spec`
4. `crystal tool format spec src`
5. `./bin/ameba`

## Contributing

1. Fork it (<https://github.com/crystal-loot/webless/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [matthewmcgarvey](https://github.com/matthewmcgarvey) - creator
