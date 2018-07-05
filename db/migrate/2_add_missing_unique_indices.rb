if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddMissingUniqueIndices < ActiveRecord::Migration[4.2]; end
else
  class AddMissingUniqueIndices < ActiveRecord::Migration; end
end
AddMissingUniqueIndices.class_eval do
  def self.up
    add_index :acts_tags, :name, unique: true

    remove_index :acts_taggings, :tag_id if index_exists?(:acts_taggings, :tag_id)
    remove_index :acts_taggings, name: 'acts_taggings_taggable_context_idx'
    add_index :acts_taggings,
              [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
              unique: true, name: 'acts_taggings_idx'
  end

  def self.down
    remove_index :acts_tags, :name

    remove_index :acts_taggings, name: 'acts_taggings_idx'

    add_index :acts_taggings, :tag_id unless index_exists?(:acts_taggings, :tag_id)
    add_index :acts_taggings, [:taggable_id, :taggable_type, :context], name: 'acts_taggings_taggable_context_idx'
  end
end
