if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddMissingTaggableIndex < ActiveRecord::Migration[4.2]; end
else
  class AddMissingTaggableIndex < ActiveRecord::Migration; end
end
AddMissingTaggableIndex.class_eval do
  def self.up
    add_index :acts_taggings, [:taggable_id, :taggable_type, :context], name: 'acts_taggings_taggable_context_idx'
  end

  def self.down
    remove_index :acts_taggings, name: 'acts_taggings_taggable_context_idx'
  end
end
