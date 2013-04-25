$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require 'logger'

begin
  require "rubygems"
  require "bundler"

  if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.5")
    raise RuntimeError, "Your bundler version is too old." +
     "Run `gem install bundler` to upgrade."
  end

  # Set up load paths for all bundled gems
  Bundler.setup
rescue Bundler::GemNotFound
  raise RuntimeError, "Bundler couldn't find some gems." +
    "Did you run \`bundlee install\`?"
end

Bundler.require
require File.expand_path('../../lib/acts-as-taggable-on', __FILE__)
require 'ammeter/init'

unless [].respond_to?(:freq)
  class Array
    def freq
      k=Hash.new(0)
      each {|e| k[e]+=1}
      k
    end
  end
end

# set adapter to use, default is sqlite3
# to use an alternative adapter run => rake spec DB='postgresql'
db_name = ENV['DB'] || 'sqlite3'
database_yml = File.expand_path('../database.yml', __FILE__)

if File.exists?(database_yml)
  active_record_configuration = YAML.load_file(database_yml)
  
  ActiveRecord::Base.configurations = active_record_configuration
  config = ActiveRecord::Base.configurations[db_name]
  
  begin
    ActiveRecord::Base.establish_connection(db_name)
    ActiveRecord::Base.connection
  rescue
    case db_name
    when /mysql/      
      ActiveRecord::Base.establish_connection(config.merge('database' => nil))
      ActiveRecord::Base.connection.create_database(config['database'],  {:charset => 'utf8', :collation => 'utf8_unicode_ci'})
    when 'postgresql'
      ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
      ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => 'utf8'))
    end
    
    ActiveRecord::Base.establish_connection(config)
  end
    
  logger = ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))
  ActiveRecord::Base.default_timezone = :utc
  
  begin
    old_logger_level, logger.level = logger.level, ::Logger::ERROR
    ActiveRecord::Migration.verbose = false
    
    load(File.dirname(__FILE__) + '/schema.rb')
    load(File.dirname(__FILE__) + '/models.rb')
  ensure
    logger.level = old_logger_level
  end
  
else
  raise "Please create #{database_yml} first to configure your database. Take a look at: #{database_yml}.sample"
end

def clean_database!
  models = [ActsAsTaggableOn::Tag, ActsAsTaggableOn::Tagging, TaggableModel, OtherTaggableModel, InheritingTaggableModel,
            AlteredInheritingTaggableModel, User, UntaggableModel, OrderedTaggableModel]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  end
end

clean_database!
