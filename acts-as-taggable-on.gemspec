# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acts_as_taggable_on/version'

Gem::Specification.new do |gem|
  gem.name          = "acts-as-taggable-on"
  gem.version       = ActsAsTaggableOn::VERSION
  gem.authors       = ["Michael Bleigh", "Joost Baaij"]
  gem.email         = ["michael@intridea.com", "joost@spacebabies.nl"]
  gem.description   = %q{With ActsAsTaggableOn, you can tag a single model on several contexts, such as skills, interests, and awards. It also provides other advanced functionality.}
  gem.summary       = "Advanced tagging for Rails."
  gem.homepage      = 'https://github.com/mbleigh/acts-as-taggable-on'
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  if File.exists?('UPGRADING')
    gem.post_install_message = File.read('UPGRADING')
  end

  gem.add_runtime_dependency 'rails', ['>= 3', '< 5']

  gem.add_development_dependency 'rspec-rails', '2.13.0' # 2.13.1 is broken
  gem.add_development_dependency 'rspec', '~> 2.6'
  gem.add_development_dependency 'ammeter'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'mysql2', '~> 0.3.7'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
end
