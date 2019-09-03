$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$TESTING = true

require 'simplecov'
SimpleCov.start do
  add_filter '/vendor/'
  add_filter '/test/'
  add_filter '/spec/'

  add_group "Streams", "lib/binstream/streams"

  add_group "Tracking", [
    "lib/binstream/tracker.rb",
    "lib/binstream/tracking.rb"
  ]

  add_group "Misc", [
    "lib/binstream/errors.rb",
    "lib/binstream/configuration.rb"
  ]
end

require 'binstream'

ROOT_PATH = File.realpath("..", File.dirname(__FILE__))

Dir[File.join(ROOT_PATH, "spec/support/**/*.rb")].each do |f| 
  require f
end

def fixture_path(file)
  File.join("spec", "fixtures", file)
end