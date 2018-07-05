if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class ActsAsTaggableOnMigration < ActiveRecord::Migration[4.2]; end
else
  class ActsAsTaggableOnMigration < ActiveRecord::Migration; end
end
ActsAsTaggableOnMigration.class_eval do
  def self.up
    create_table :acts_tags do |t|
      t.string :name
      t.timestamps
    end

    create_table :acts_taggings do |t|
      t.references :tag, foreign_key: { to_table: :acts_tags }

      # You should make sure that the column created is
      # long enough to store the required class names.
      t.references :taggable, polymorphic: true
      t.references :tagger, polymorphic: true

      # Limit is created to prevent MySQL error on index
      # length for MyISAM table type: http://bit.ly/vgW2Ql
      t.string :context, limit: 128

      t.datetime :created_at
    end

    add_index :acts_taggings, :tag_id
    add_index :acts_taggings, [:taggable_id, :taggable_type, :context], name: 'acts_taggings_taggable_context_idx'
  end

  def self.down
    drop_table :acts_taggings
    drop_table :acts_tags
  end
end
