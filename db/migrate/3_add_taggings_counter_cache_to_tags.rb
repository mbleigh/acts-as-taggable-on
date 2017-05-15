if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddTaggingsCounterCacheToTags < ActiveRecord::Migration[4.2]; end
else
  class AddTaggingsCounterCacheToTags < ActiveRecord::Migration; end
end
AddTaggingsCounterCacheToTags.class_eval do
  def self.up
    add_column :tags, :taggings_count, :integer, default: 0

    ActsAsTaggableOn::Tag.reset_column_information
    ActsAsTaggableOn::Tag.find_each do |tag|
      ActsAsTaggableOn::Tag.reset_counters(tag.id, :taggings)
    end
  end

  def self.down
    remove_column :tags, :taggings_count
  end
end
