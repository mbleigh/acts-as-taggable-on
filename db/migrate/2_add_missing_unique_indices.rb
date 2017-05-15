if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddMissingUniqueIndices < ActiveRecord::Migration[4.2]; end
else
  class AddMissingUniqueIndices < ActiveRecord::Migration; end
end
AddMissingUniqueIndices.class_eval do
  def self.up
    add_index :tags, :name, unique: true

    remove_index :taggings, :tag_id if index_exists?(:taggings, :tag_id)
    remove_index :taggings, [:taggable_id, :taggable_type, :context]
    add_index :taggings,
              [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
              unique: true, name: 'taggings_idx'
  end

  def self.down
    remove_index :tags, :name

    remove_index :taggings, name: 'taggings_idx'

    add_index :taggings, :tag_id unless index_exists?(:taggings, :tag_id)
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
end
