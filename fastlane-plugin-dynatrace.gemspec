# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/dynatrace/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-dynatrace'
  spec.version       = Fastlane::Dynatrace::VERSION
  spec.author        = 'Dynatrace LLC'
  spec.email         = 'mobile.agent@dynatrace.com'

  spec.summary       = 'This action processes and uploads your symbol files to Dynatrace'
  spec.homepage      = 'https://github.com/Dynatrace/fastlane-plugin-dynatrace'
  spec.license       = 'Apache 2.0'

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_development_dependency('pry')
  spec.add_development_dependency('bundler')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop', '0.49.1')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov')
  spec.add_development_dependency('fastlane', '>= 2.142.0')

  spec.add_runtime_dependency('rubyzip')
  spec.add_runtime_dependency('digest')
  spec.add_runtime_dependency('net-http')
  spec.add_runtime_dependency('tempfile')
  spec.add_runtime_dependency('open-uri')
  spec.add_runtime_dependency('os')
  spec.add_runtime_dependency('json')
end
