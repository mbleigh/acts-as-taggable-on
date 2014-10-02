class AddTaggingsCounterCacheToTags < ActiveRecord::Migration
  def self.up
    ActsAsTaggableOn::Migrator.make_taggings_counter_cache!
  end

  def self.down
    ActsAsTaggableOn::Migrator.destroy_taggings_counter_cache!
  end
end
