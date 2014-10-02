module ActsAsTaggableOn
  module Generators
    class NamespacingGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      argument :namespace, type: :string, required: true

      def initialize(*args, &block)
        super
        @namespace = @namespace.tableize.singularize
        @namespace_migration_class = "Create#{ @namespace.gsub(/\//, '_').camelize }ActsAsTaggableOnTables"
      end

      # Implement the required interface for Rails::Generators::Migration.
      # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          Time.now.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def create_migration_file
        migration_template 'migration-1.rb', "db/migrate/#{ @namespace_migration_class.underscore }.rb"
      end
    end
  end
end