$LOAD_PATH << '.' unless $LOAD_PATH.include?('.')
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'logger'

require File.expand_path('../../lib/acts-as-taggable-on', __FILE__)
I18n.enforce_available_locales = true
require 'rails'
require 'rspec/its'
require 'ammeter/init'
require 'barrier'

unless [].respond_to?(:freq)
  class Array
    def freq
      k=Hash.new(0)
      each { |e| k[e]+=1 }
      k
    end
  end
end

def init_logger
  ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'debug.log'))
  ActiveRecord::Migration.verbose = false
end

def logger_on
  ActiveRecord::Base.logger.level = ::Logger::DEBUG
end

def logger_off
  ActiveRecord::Base.logger.level = ::Logger::UNKNOWN
end


# set adapter to use, default is sqlite3
# to use an alternative adapter run => rake spec DB='postgresql'
db_name = ENV['DB'] || 'sqlite3'
database_yml = File.expand_path('../internal/config/database.yml', __FILE__)

if File.exists?(database_yml)
  active_record_configuration = YAML.load_file(database_yml)

  ActiveRecord::Base.configurations = active_record_configuration
  config = ActiveRecord::Base.configurations[db_name]

  begin
    #activerecord 4 uses symbol
    #todo remove when activerecord 3 support is dropped
    if ActsAsTaggableOn::Utils.active_record4?
      ActiveRecord::Base.establish_connection(db_name.to_sym)
    else
      ActiveRecord::Base.establish_connection(db_name)
    end
    ActiveRecord::Base.connection
  rescue
    case db_name
      when /mysql/
        ActiveRecord::Base.establish_connection(config.merge('database' => nil))
        ActiveRecord::Base.connection.create_database(config['database'], {:charset => 'utf8', :collation => 'utf8_unicode_ci'})
      when 'postgresql'
        ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
        ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => 'utf8'))
    end

    ActiveRecord::Base.establish_connection(config)
  end

  init_logger
  ActiveRecord::Base.default_timezone = :utc

  begin
    logger_off
    load(File.dirname(__FILE__) + '/internal/db/schema.rb')
    Dir[File.dirname(__FILE__) + '/internal/app/models/*.rb'].each { |file| load file }
  ensure
    logger_on
  end

else
  raise "Please create #{database_yml} first to configure your database. Take a look at: #{database_yml}.sample"
end

def clean_database!
  models = [ActsAsTaggableOn::Tag, ActsAsTaggableOn::Tagging, TaggableModel, OtherTaggableModel,
            InheritingTaggableModel, AlteredInheritingTaggableModel, User, UntaggableModel,
            OrderedTaggableModel]
  models.each do |model|
    #Sqlite don't support truncate
    if ActsAsTaggableOn::Utils.using_sqlite?
      ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
    else
      ActiveRecord::Base.connection.execute "TRUNCATE #{model.table_name}"
    end
  end
end

clean_database!


