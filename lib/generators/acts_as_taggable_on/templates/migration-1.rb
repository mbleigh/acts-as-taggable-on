class <%= @namespace_migration_class %> < ActiveRecord::Migration
  def self.up
    migrator = ActsAsTaggableOn::Migrator.new(namespace: :<%= @namespace %>)
  	migrator.make_tables!
  	migrator.make_unique_indexes!
  	migrator.make_taggings_counter_cache!
  	migrator.add_missing_taggable_index!
  end
  def self.down
    migrator = ActsAsTaggableOn::Migrator.new(namespace: :<%= @namespace %>)
  	migrator.destroy_tables!
  	migrator.destroy_unique_indexes!
  	migrator.destroy_taggings_counter_cache!
  	migrator.destroy_missing_taggable_index!
  end
end
