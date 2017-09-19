# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chart_helpers/version'

Gem::Specification.new do |spec|
  spec.name          = 'chart_helpers'
  spec.version       = ChartHelpers::VERSION
  spec.authors       = ['Julian Nadeau']
  spec.email         = ['julian@jnadeau.ca']

  spec.summary       = 'Create SVG and PNG Charts'
  spec.description   = 'Create SVG and PNG ChartHelpers. Includes Gantt Charts'
  spec.homepage      = "https://github.com/jules2689/chart_helpers"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'byebug'

  spec.add_dependency 'victor', '0.2.1'
  spec.add_dependency 'ruby-graphviz'
  spec.add_dependency 'ttfunk'
end
