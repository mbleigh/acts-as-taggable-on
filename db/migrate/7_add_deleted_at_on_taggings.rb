if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddMissingIndexesOnTaggings < ActiveRecord::Migration[4.2]; end
else
  class AddMissingIndexesOnTaggings < ActiveRecord::Migration; end
end
AddDeletedAtOnTaggings.class_eval do
  def self.up
    add_column ActsAsTaggableOn.taggings_table, :deleted_at, :datetime
    add_index ActsAsTaggableOn.taggings_table, :deleted_at unless index_exists? ActsAsTaggableOn.taggings_table, :deleted_at
  end

  def self.down
    index_exists? ActsAsTaggableOn.taggings_table, :deleted_at && remove_index ActsAsTaggableOn.taggings_table, :deleted_at
    column_exists? ActsAsTaggableOn.taggings_table, :deleted_at && remove_column ActsAsTaggableOn.taggings_table, :deleted_at
end
