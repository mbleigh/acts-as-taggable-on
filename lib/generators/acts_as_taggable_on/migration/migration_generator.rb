require 'rails/generators'
require 'rails/generators/migration'

module ActsAsTaggableOn
  class MigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "Generates migration for Tag and Tagging models"

    # @return [Symbol] The ORM configured by Rails
    def self.orm
      Rails::Generators.options[:rails][:orm]
    end

    # @return [String] The path to the migration templates
    def self.source_root
      File.join(File.dirname(__FILE__), 'templates', (orm.to_s unless orm.class.eql?(String)) )
    end

    # @return [Boolean] true if the orm is active_record
    def self.orm_has_migration?
      [:active_record].include? orm
    end

    # Generate the next migration number
    # @note sleeps to ensure we don't return the same timestamped migration number twice
    # @return [String] Unique, sequential migration number based on either the time
    #   for timestamped migrations, or by incrementing the last migration number
    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        sleep 1
        migration_number = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        migration_number += 1
        migration_number.to_s
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

    # @return [Array<Array>] An array of migration source files and destination paths
    #   if the orm supports migrations
    # @return [Array] an empty array if the orm does not support migrations
    # @example [ ['migration.rb', 'db/migrate/acts_as_taggable_on_migration'] ]
    # @note For historical reasons, all migrations are ordered by the format
    #   migrationsNUMBER-migration_name, where the migration_name is separated
    #   by a '-', exept for the first migration
    def self.available_migrations
      if orm_has_migration?
        Dir["#{self.source_root}/*.rb"].sort.map do |filepath|
          ext = '.rb'
          name = File.basename(filepath, ext)
          migration_name = name.split('-')[-1]
          [ "#{name}#{ext}", "db/migrate/acts_as_taggable_on_#{migration_name}"]
        end
      else
        []
      end
    end

    # Setting the class_option :skip to  creating a migration that already exists
    # @note see https://github.com/rails/rails/blob/3-2-stable/railties/lib/rails/generators/migration.rb#L53
    #   see Rails::Generators::Base.class_option # 198
    #   see Thor::Base#options
    class_option :skip, :type => :boolean, :default => true, :desc => 'Skip copying existing migrations'

    # Creates migrations that do not yet exist
    def create_migration_file
      self.class.available_migrations.each do |source, destination|
        migration_template(source, destination)
      end
    end
  end
end
