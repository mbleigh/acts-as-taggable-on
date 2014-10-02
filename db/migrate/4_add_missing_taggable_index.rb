class AddMissingTaggableIndex < ActiveRecord::Migration
  def self.up
  	ActsAsTaggableOn::Migrator.add_missing_taggable_index!
  end

  def self.down
  	ActsAsTaggableOn::Migrator.destroy_missing_taggable_index!
  end
end
