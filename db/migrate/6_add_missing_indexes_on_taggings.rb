if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddMissingIndexesOnTaggings < ActiveRecord::Migration[4.2]; end
else
  class AddMissingIndexesOnTaggings < ActiveRecord::Migration; end
end
AddMissingIndexesOnTaggings.class_eval do
  def change
    add_index :acts_taggings, :tag_id unless index_exists? :acts_taggings, :tag_id
    add_index :acts_taggings, :taggable_id unless index_exists? :acts_taggings, :taggable_id
    add_index :acts_taggings, :taggable_type unless index_exists? :acts_taggings, :taggable_type
    add_index :acts_taggings, :tagger_id unless index_exists? :acts_taggings, :tagger_id
    add_index :acts_taggings, :context unless index_exists? :acts_taggings, :context

    unless index_exists? :acts_taggings, [:tagger_id, :tagger_type]
      add_index :acts_taggings, [:tagger_id, :tagger_type]
    end

    unless index_exists? :acts_taggings, [:taggable_id, :taggable_type, :tagger_id, :context], name: 'acts_taggings_idy'
      add_index :acts_taggings, [:taggable_id, :taggable_type, :tagger_id, :context], name: 'acts_taggings_idy'
    end
  end
end
