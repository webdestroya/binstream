# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'binstream/version'

Gem::Specification.new do |spec|
  spec.name          = "binstream"
  spec.version       = Binstream::VERSION
  spec.authors       = ["Mitch Dempsey"]
  spec.email         = ["gems@mitchdempsey.com"]

  spec.summary       = %q{Binary stream processor}
  spec.description   = %q{Binary stream processor}
  spec.homepage      = "https://github.com/webdestroya/binstream"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"
  
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
end