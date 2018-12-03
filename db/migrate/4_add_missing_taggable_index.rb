if ActiveRecord.gem_version >= Gem::Version.new('5.1')
  class AddMissingTaggableIndex < ActiveRecord::Migration[5.1]; end
else
  class AddMissingTaggableIndex < ActiveRecord::Migration[5.0]; end
end
AddMissingTaggableIndex.class_eval do
  def self.up
    add_index ActsAsTaggableOn.taggings_table, [:taggable_id, :taggable_type, :context], name: 'taggings_taggable_context_idx'
  end

  def self.down
    remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_taggable_context_idx'
  end
end
