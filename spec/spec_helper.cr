require "../src/http_test"
require "spectator"

Spectator.configure do |config|
  config.fail_blank
  config.randomize
end
