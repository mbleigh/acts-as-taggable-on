$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'logger'
require File.expand_path('../../lib/acts-as-taggable-on', __FILE__)
require 'combustion'
require 'database_cleaner'
I18n.enforce_available_locales = true


unless [].respond_to?(:freq)
  class Array
    def freq
      k=Hash.new(0)
      each { |e| k[e]+=1 }
      k
    end
  end
end

Combustion.initialize! :active_record, :active_support, :action_view  do

  #TODO we should configure the database here
  #For now it will select just the test(sqlite3)
end

## set adapter to use, default is sqlite3
## to use an alternative adapter run => rake spec DB='postgresql'
#db_name = ENV['DB'] || 'sqlite3'
#database_yml = File.expand_path('../internal/config/database.yml', __FILE__)
#
#if File.exists?(database_yml)
#  active_record_configuration = YAML.load_file(database_yml)
#
#  ActiveRecord::Base.configurations = active_record_configuration
#  config = ActiveRecord::Base.configurations[db_name]
#
#  begin
#    ActiveRecord::Base.establish_connection(db_name)
#    ActiveRecord::Base.connection
#  rescue
#    case db_name
#      when /mysql/
#        ActiveRecord::Base.establish_connection(config.merge('database' => nil))
#        ActiveRecord::Base.connection.create_database(config['database'], {:charset => 'utf8', :collation => 'utf8_unicode_ci'})
#      when 'postgresql'
#        ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
#        ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => 'utf8'))
#    end
#
#    ActiveRecord::Base.establish_connection(config)
#  end
#
#  logger = ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))
#  ActiveRecord::Base.default_timezone = :utc
#
#  begin
#    old_logger_level, logger.level = logger.level, ::Logger::ERROR
#    ActiveRecord::Migration.verbose = false
#
#  ensure
#    logger.level = old_logger_level
#  end
#
#else
#  raise "Please create #{database_yml} first to configure your database. Take a look at: #{database_yml}.sample"
#end
