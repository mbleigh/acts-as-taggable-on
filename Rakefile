require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  STDERR.puts "Bundler not loaded"
end

desc 'Default: run specs'
task :default => :spec

begin
  require 'appraisal'
  desc 'Run tests across gemfiles specified in Appraisals'
  task :appraise => ['appraisal:cleanup', 'appraisal:install', 'appraisal']
rescue LoadError
  puts "appraisal tasks not available"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

Bundler::GemHelper.install_tasks
