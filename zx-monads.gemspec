# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'zx/version'

Gem::Specification.new do |spec|
  spec.name          = 'zx-monads'
  spec.version       = Zx::VERSION
  spec.authors       = ['Thadeu Esteves']
  spec.email         = ['tadeuu@gmail.com']
  spec.summary       = 'FP Monads for Ruby'
  spec.description   = 'Use Maybe to handle errors in your code'
  spec.homepage      = 'https://github.com/thadeu/zx-monads'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.required_ruby_version = '>= 2.7.6'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.14'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'rubocop', '>= 0.70'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
