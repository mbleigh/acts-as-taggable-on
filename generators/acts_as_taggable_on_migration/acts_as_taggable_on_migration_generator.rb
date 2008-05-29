class ActsAsTaggableOnMigrationGenerator < Rails::Generator::Base 
  def manifest 
    record do |m| 
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => "acts_as_taggable_on_migration"
      m.migration_template 'add_users_migration.rb', 'db/migrate', :migration_file_name => "add_users_to_acts_as_taggable_on_migration"
    end 
  end
end
