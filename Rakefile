require 'rubygems'
require 'bundler/setup'
require 'appraisal'

desc 'Default: run specs'
task :default => :spec  

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

Bundler::GemHelper.install_tasks
