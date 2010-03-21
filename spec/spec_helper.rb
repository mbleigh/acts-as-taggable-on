require File.expand_path('../../lib/acts-as-taggable-on', __FILE__)

begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path("../.bundle/environment", __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

Bundler.require

if defined?(Rspec::Core::ExampleGroupSubject)
  module Rspec::Core::ExampleGroupSubject
    alias :context :describe
  end
end

class Array
  def freq
    k=Hash.new(0)
    each {|e| k[e]+=1}
    k
  end
end

# Setup a database
TEST_DATABASE_FILE = File.join(File.dirname(__FILE__), '..', 'test.sqlite3')
File.unlink(TEST_DATABASE_FILE) if File.exist?(TEST_DATABASE_FILE)
ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => TEST_DATABASE_FILE

ActiveRecord::Base.silence do
  ActiveRecord::Migration.verbose = false
  load(File.dirname(__FILE__) + '/schema.rb')
  load(File.dirname(__FILE__) + '/models.rb')
end

def clean_database!
  $debug = false
  models = [Tag, Tagging, TaggableModel, OtherTaggableModel, InheritingTaggableModel,
            AlteredInheritingTaggableModel, TaggableUser]
  models.each do |model|
    model.destroy_all
  end
end
