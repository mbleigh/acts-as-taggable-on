$:.push File.dirname(__FILE__) + '/lib'
require 'acts-as-taggable-on/version'

Gem::Specification.new do |gem|
  gem.name = %q{acts-as-taggable-on}
  gem.authors = ["Michael Bleigh"]
  gem.date = %q{2012-07-16}
  gem.description = %q{With ActsAsTaggableOn, you can tag a single model on several contexts, such as skills, interests, and awards. It also provides other advanced functionality.}
  gem.summary = "Advanced tagging for Rails."
  gem.email = %q{michael@intridea.com}
  gem.homepage      = ''

  gem.add_runtime_dependency 'rails', '~> 4.0.0.beta'
  gem.add_development_dependency 'rspec', '~> 2.6'
  #gem.add_development_dependency 'ammeter', '~> 0.1.3'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'mysql2', '~> 0.3.7'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "acts-as-taggable-on"
  gem.require_paths = ['lib']
  gem.version       = ActsAsTaggableOn::VERSION
end
